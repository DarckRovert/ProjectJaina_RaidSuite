--[[
    SEQUITO - Raid Assist Module
    Collaborative raid features for guilds using Sequito
]]--

local addonName, S = ...
S.RaidAssist = {}
local RA = S.RaidAssist

-- Constants
local ADDON_PREFIX = "Sequito"
local VERSION_CHECK_INTERVAL = 300 -- 5 minutes
local SYNC_INTERVAL = 2 -- 2 seconds for regular updates

-- State
RA.users = {} -- Players in raid with Sequito
RA.cooldowns = {} -- Shared cooldowns
RA.interrupts = {} -- Interrupt rotation
RA.assignments = {} -- Role assignments
RA.pullTimer = nil
RA.wipeCount = 0
RA.mode = "FARM" -- FARM or PROGRESSION
RA.cooldowns = {} -- Shared cooldowns
RA.interrupts = {} -- Interrupt rotation
RA.assignments = {} -- Role assignments
RA.pullTimer = nil
RA.wipeCount = 0
RA.mode = "FARM" -- FARM or PROGRESSION
RA.consumables = {} -- Consumable status
RA.RaidGUIDs = {} -- Cache for IsRaidMember optimization

-- Helper para obtener configuración
function RA:GetOption(key)
    if S.ModuleConfig then
        return S.ModuleConfig:GetValue("RaidAssist", key)
    end
    return true
end

function RA:Initialize()
    if self.initialized then return end
    if not self:GetOption("enabled") then
        return
    end
    self.initialized = true
    
    -- Register addon communication
    if RegisterAddonMessagePrefix then
        RegisterAddonMessagePrefix(ADDON_PREFIX)
    end
    
    -- Initialize data tables from SpellData
    self:LoadSpellData()
    
    self.frame = CreateFrame("Frame")
    self.frame:RegisterEvent("CHAT_MSG_ADDON")
    self.frame:RegisterEvent("RAID_ROSTER_UPDATE")
    self.frame:RegisterEvent("PARTY_MEMBERS_CHANGED")
    self.frame:RegisterEvent("PLAYER_REGEN_DISABLED") -- Enter combat
    self.frame:RegisterEvent("PLAYER_REGEN_ENABLED") -- Leave combat
    self.frame:RegisterEvent("PLAYER_DEAD")
    self.frame:RegisterEvent("UNIT_SPELLCAST_SUCCEEDED")
    self.frame:RegisterEvent("COMBAT_LOG_EVENT_UNFILTERED") -- Added for Interrupts
    self.frame:RegisterEvent("UNIT_AURA")
    
    self.frame:SetScript("OnEvent", function(frame, event, ...)
        if RA[event] then
            RA[event](RA, ...)
        end
    end)
    
    -- Start sync timer
    self.syncTimer = 0
    self.frame:SetScript("OnUpdate", function(frame, elapsed)
        RA:OnUpdate(elapsed)
    end)
    
    -- Load data from SpellData
    self:LoadSpellData()
    
    -- Cache Initial Roster
    self:UpdateRoster()
    
    -- Announce presence
    self:AnnouncePresence()
    
    print(S.L["RA_INITIALIZED"] or "|cFF00FFFFSequito RaidAssist|r: Inicializado")
end

function RA:LoadSpellData()
    if not S.SpellData then
        print("|cFFFF0000Error:|r SpellData not loaded")
        return
    end
    
    -- Load interrupt spells
    self.interruptSpells = {}
    self.interruptSpellsByID = {}
    self.interruptSpellsByName = {}
    if S.SpellData.Interrupts then
        for class, spells in pairs(S.SpellData.Interrupts) do
            for _, spell in ipairs(spells) do
                self.interruptSpells[spell.id] = true
                self.interruptSpellsByID[spell.id] = { name = spell.name, class = class }
                if spell.name then
                    self.interruptSpells[spell.name] = spell.id
                    self.interruptSpellsByName[spell.name] = spell.id
                end
            end
        end
    end
    
    -- Load important cooldowns
    self.importantCooldowns = {}
    if S.SpellData.ImportantCooldowns then
        for class, spells in pairs(S.SpellData.ImportantCooldowns) do
            for _, spell in ipairs(spells) do
                self.importantCooldowns[spell.id] = {
                    name = spell.name,
                    duration = spell.duration or 0
                }
            end
        end
    end
    
    -- Load consumable buffs
    self.requiredBuffs = {}
    if S.SpellData.Consumables then
        for _, buff in ipairs(S.SpellData.Consumables) do
            self.requiredBuffs[buff.id] = buff.type
        end
    end
end

-- ============================================
-- COMMUNICATION SYSTEM
-- ============================================

function RA:GetGroupChannel()
    local inInstance, instanceType = IsInInstance()
    if inInstance and (instanceType == "pvp" or instanceType == "arena") then
        return "BATTLEGROUND"
    elseif GetNumRaidMembers() > 0 then
        return "RAID"
    elseif GetNumPartyMembers() > 0 then
        return "PARTY"
    end
    return nil
end

function RA:SendMessage(msgType, data)
    local channel = self:GetGroupChannel()
    if not channel then return end
    
    local payload = msgType .. ":" .. (data or "")
    if #payload > 240 then payload = payload:sub(1, 240) end
    if RegisterAddonMessagePrefix then
        RegisterAddonMessagePrefix(ADDON_PREFIX)
    end
    SendAddonMessage(ADDON_PREFIX, payload, channel)
end

function RA:CHAT_MSG_ADDON(prefix, message, channel, sender)
    if prefix ~= ADDON_PREFIX then return end
    
    local msgType, data = message:match("^([^:]+):(.*)$")
    if not msgType then return end
    
    -- Route to appropriate handler
    local handler = "Handle_" .. msgType
    if self[handler] then
        self[handler](self, sender, data)
    end
end

function RA:AnnouncePresence()
    self:SendMessage("PRESENCE", S.Version)
end

function RA:Handle_PRESENCE(sender, version)
    self.users[sender] = {
        version = version,
        lastSeen = time()
    }
end

-- ============================================
-- 1. COORDINADOR DE INTERRUPCIONES
-- ============================================
-- Note: interruptSpells is loaded from SpellData in Initialize()

function RA:RecordInterrupt(playerName, spellID)
    if not playerName or not spellID then return end
    if not self.interrupts[playerName] then
        self.interrupts[playerName] = {}
    end

    local curTime = time()
    local list = self.interrupts[playerName]

    -- Deduplicación idempotente: evitar registrar duplicados en ventana de 2s
    if #list > 0 then
        local last = list[#list]
        if last.spellID == spellID and (curTime - last.time) < 2 then
            return
        end
    end

    table.insert(list, {
        spellID = tonumber(spellID),
        time = curTime
    })

    -- Limpieza de entradas antiguas (> 30s)
    for i = #list, 1, -1 do
        if curTime - list[i].time > 30 then
            table.remove(list, i)
        end
    end
end

function RA:COMBAT_LOG_EVENT_UNFILTERED(...)
    local timestamp, event, sourceGUID, sourceName, _, _, _, _, spellId, spellName = ...
    
    if event ~= "SPELL_CAST_SUCCESS" then return end
    
    -- Check if it's an interrupt spell
    if self.interruptSpells[spellId] and self:IsRaidMember(sourceGUID) then
        -- 1. Registro directo e inmediato en el cliente local (cero latencia)
        self:RecordInterrupt(sourceName, spellId)

        -- 2. Anti-Flooding: SOLO el propio jugador que realizó el corte emite el mensaje
        if sourceGUID == UnitGUID("player") then
            self:SendMessage("INTERRUPT_USED", sourceName .. ":" .. spellId)
        end
    end
end

-- Helper to check if GUID is in raid (similar to WipeAnalyzer)
function RA:UpdateRoster()
    wipe(self.RaidGUIDs)
    
    if GetNumRaidMembers() > 0 then
        for i = 1, GetNumRaidMembers() do
            local guid = UnitGUID("raid"..i)
            if guid then self.RaidGUIDs[guid] = true end
        end
    end
    
    -- Always include player
    local pGUID = UnitGUID("player")
    if pGUID then self.RaidGUIDs[pGUID] = true end
    
    -- Include party
    if GetNumPartyMembers() > 0 then
        for i = 1, GetNumPartyMembers() do
             local guid = UnitGUID("party"..i)
             if guid then self.RaidGUIDs[guid] = true end
        end
    end
end

function RA:IsRaidMember(guid)
    return self.RaidGUIDs[guid]
end

-- Removed unreliable UNIT_SPELLCAST_SUCCEEDED for Interrupts
function RA:UNIT_SPELLCAST_SUCCEEDED(unit, spell, rank)
    -- Reserved for other logic if needed
end

function RA:Handle_INTERRUPT_USED(sender, data)
    local playerName, spellID = data:match("^([^:]+):(.+)$")
    if not playerName or not spellID then return end
    self:RecordInterrupt(playerName, tonumber(spellID))
end

function RA:GetNextInterrupter()
    -- Find who should interrupt next based on rotation
    local interrupters = {}
    local numRaid = GetNumRaidMembers()
    local isRaid = numRaid > 0
    local total = isRaid and numRaid or GetNumPartyMembers()
    local localPlayer = UnitName("player")
    local curTime = time()

    local INTERRUPT_CD = {
        [47528] = 10, -- Mind Freeze (DK)
        [34490] = 20, -- Silencing Shot (Hunter)
        [2139]  = 24, -- Counterspell (Mage)
        [15487] = 45, -- Silence (Priest)
        [1766]  = 10, -- Kick (Rogue)
        [57994] = 6,  -- Wind Shear (Shaman)
        [19647] = 24, -- Spell Lock (Warlock)
        [6552]  = 10, -- Pummel (Warrior)
        [72]    = 10, -- Shield Bash (Warrior)
    }

    local CLASS_HAS_INTERRUPT = {
        DEATHKNIGHT = 10,
        HUNTER      = 20,
        MAGE        = 24,
        PRIEST      = 45,
        ROGUE       = 10,
        SHAMAN      = 6,
        WARLOCK     = 24,
        WARRIOR     = 10,
    }

    for i = 1, total do
        local name, rank, subgroup, level, class, fileName, zone, online, isDead
        if isRaid then
            name, rank, subgroup, level, class, fileName, zone, online, isDead = GetRaidRosterInfo(i)
        else
            local unit = (i == total) and "player" or ("party" .. i)
            name = UnitName(unit)
            _, fileName = UnitClass(unit)
            online = UnitIsConnected(unit)
            isDead = UnitIsDeadOrGhost(unit)
        end

        if name and online and not isDead then
            local baseCD = fileName and CLASS_HAS_INTERRUPT[fileName]
            if baseCD then
                local hasInterrupt = false
                local lastUsed = 0

                if name == localPlayer then
                    -- Para el jugador local sí es válido comprobar el cooldown nativo de su spellbook
                    if self.interruptSpellsByID then
                        for spellID in pairs(self.interruptSpellsByID) do
                            if IsSpellKnown(spellID) then
                                local start, duration = GetSpellCooldown(spellID)
                                if start == 0 or (start + duration - GetTime()) < 1 then
                                    hasInterrupt = true
                                    break
                                end
                            end
                        end
                    end
                else
                    -- Para otros miembros, verificar historial de uso en self.interrupts
                    if self.interrupts[name] and #self.interrupts[name] > 0 then
                        local lastEntry = self.interrupts[name][#self.interrupts[name]]
                        lastUsed = lastEntry.time or 0
                        local spellCD = (lastEntry.spellID and INTERRUPT_CD[lastEntry.spellID]) or baseCD
                        if (curTime - lastUsed) >= spellCD then
                            hasInterrupt = true
                        end
                    else
                        -- No ha usado interrupción en la ventana reciente; está disponible
                        hasInterrupt = true
                        lastUsed = 0
                    end
                end

                if hasInterrupt then
                    table.insert(interrupters, {name = name, lastUsed = lastUsed})
                end
            end
        end
    end

    -- Ordenar por el que usó la interrupción hace más tiempo (o nunca: lastUsed = 0)
    table.sort(interrupters, function(a, b) return a.lastUsed < b.lastUsed end)

    return interrupters[1] and interrupters[1].name
end

-- ============================================
-- 2. COMPARTIR COOLDOWNS IMPORTANTES
-- ============================================

RA.importantCooldowns = {
    -- Bloodlust/Heroism
    [2825] = {name = "Bloodlust", duration = 600},
    [32182] = {name = "Heroism", duration = 600},
    -- Battle Rez
    [20484] = {name = "Rebirth", duration = 600},
    [61999] = {name = "Raise Ally", duration = 600},
    -- Defensive CDs
    [871] = {name = "Shield Wall", duration = 300},
    [48707] = {name = "Anti-Magic Shell", duration = 45},
    [47788] = {name = "Guardian Spirit", duration = 180},
    [33206] = {name = "Pain Suppression", duration = 144},
    [6940] = {name = "Hand of Sacrifice", duration = 120},
    [1022] = {name = "Hand of Protection", duration = 300},
}

function RA:TrackCooldowns()
    self.activeCDStates = self.activeCDStates or {}
    for spellID, info in pairs(self.importantCooldowns) do
        if IsSpellKnown(spellID) then
            local start, duration = GetSpellCooldown(spellID)
            local onCD = (start > 0 and duration > 1.5)
            local wasOnCD = self.activeCDStates[spellID]

            -- Transmitir ÚNICAMENTE en transiciones de estado (inicio o reset)
            if onCD and not wasOnCD then
                self.activeCDStates[spellID] = true
                local remaining = math.floor((start + duration) - GetTime())
                self:SendMessage("COOLDOWN_UPDATE", spellID .. ":" .. remaining)
            elseif not onCD and wasOnCD then
                self.activeCDStates[spellID] = nil
                self:SendMessage("COOLDOWN_UPDATE", spellID .. ":0")
            end
        end
    end
end

function RA:Handle_COOLDOWN_UPDATE(sender, data)
    local spellID, remaining = data:match("^([^:]+):(.+)$")
    if not spellID then return end
    
    if not self.cooldowns[sender] then
        self.cooldowns[sender] = {}
    end
    
    self.cooldowns[sender][tonumber(spellID)] = {
        remaining = tonumber(remaining),
        updated = time()
    }
end

function RA:GetAvailableCooldowns(spellID)
    local available = {}
    local now = time()
    
    for name, cds in pairs(self.cooldowns) do
        local cd = cds[spellID]
        local remaining = 0
        if cd then
            local elapsed = now - (cd.updated or now)
            remaining = math.max(0, cd.remaining - elapsed)
        end
        if remaining <= 0 then
            table.insert(available, name)
        end
    end
    
    return available
end

-- ============================================
-- 3. SISTEMA DE MARCADORES INTELIGENTE
-- ============================================

function RA:AssignTargets(targets)
    -- targets = {unit1, unit2, unit3, ...}
    -- Distribute among DPS
    
    local dps = {}
    local numRaid = GetNumRaidMembers()
    local isRaid = numRaid > 0
    local total = isRaid and numRaid or GetNumPartyMembers()

    for i = 1, total do
        local name, online, isDead, role, fileName
        local unit
        if isRaid then
            local rName, _, _, _, _, rFile, _, rOnline, rDead, rRole = GetRaidRosterInfo(i)
            name = rName
            fileName = rFile
            online = rOnline
            isDead = rDead
            role = rRole
            unit = "raid" .. i
        else
            unit = (i == total) and "player" or ("party" .. i)
            name = UnitName(unit)
            _, fileName = UnitClass(unit)
            online = UnitIsConnected(unit)
            isDead = UnitIsDeadOrGhost(unit)
            role = nil
        end

        if name and online and not isDead then
            local isDps = false

            -- 1. Verificación por rol asignado nativo (Dungeon Finder / LFG 3.3.5a)
            if UnitGroupRolesAssigned then
                local assignedRole = UnitGroupRolesAssigned(unit)
                if assignedRole == "DAMAGER" then
                    isDps = true
                elseif assignedRole == "TANK" or assignedRole == "HEALER" then
                    isDps = false
                end
            end

            -- 2. Fallback estándar para bandas 3.3.5a: No es MainTank ni MainAssist ni Healer
            if not isDps and role ~= "MAINTANK" and role ~= "MAINASSIST" then
                local assignedRole = UnitGroupRolesAssigned and UnitGroupRolesAssigned(unit)
                if assignedRole ~= "TANK" and assignedRole ~= "HEALER" then
                    isDps = true
                end
            end

            if isDps and (self.users[name] or not next(self.users)) then
                table.insert(dps, name)
            end
        end
    end
    
    if #dps == 0 then return end
    
    for i, target in ipairs(targets) do
        local assignee = dps[((i - 1) % #dps) + 1]
        self:SendMessage("TARGET_ASSIGN", assignee .. ":" .. target)
    end
end

function RA:Handle_TARGET_ASSIGN(sender, data)
    local assignee, target = data:match("^([^:]+):(.+)$")
    if not assignee then return end
    
    local playerName = UnitName("player")
    if assignee == playerName then
        -- This is for me
        S:Print((S.L["YOUR_ASSIGNED_TARGET"] or "Tu objetivo asignado:") .. " " .. target)
        -- Could show visual indicator
    end
end

-- ============================================
-- 4. AVISOS DE MECÁNICAS DE BOSS
-- ============================================

function RA:AnnouncePhase(phase)
    self:SendMessage("BOSS_PHASE", phase)
    S:Print(string.format(S.L["PHASE_ANNOUNCED"] or "¡FASE %s!", phase))
end

function RA:Handle_BOSS_PHASE(sender, phase)
    S:Print(string.format(S.L["PHASE_BY_PLAYER"] or "¡FASE %s! (anunciado por %s)", phase, sender))
    -- Visual/audio alert
    PlaySound("RaidWarning")
end

-- ============================================
-- 5. TRACKER DE CONSUMIBLES DEL RAID
-- ============================================
-- Note: requiredBuffs is loaded from SpellData in Initialize()

function RA:CheckConsumables()
    -- Check all raid members
    local numRaid = GetNumRaidMembers()
    
    if numRaid > 0 then
        -- In raid
        for i = 1, numRaid do
            local unit = "raid" .. i
            if UnitIsConnected(unit) and not UnitIsDeadOrGhost(unit) then
                self:CheckUnitConsumables(unit)
            end
        end
    else
        -- Solo or party
        self:CheckUnitConsumables("player")
        for i = 1, GetNumPartyMembers() do
            local unit = "party" .. i
            if UnitIsConnected(unit) and not UnitIsDeadOrGhost(unit) then
                self:CheckUnitConsumables(unit)
            end
        end
    end
end

function RA:CheckUnitConsumables(unit)
    local hasFlask = false
    local hasFood = false
    local playerName = UnitName(unit)
    
    if not playerName then return end
    
    -- Check buffs
    for i = 1, 40 do
        local name, rank, icon, count, debuffType, duration, expirationTime, unitCaster, isStealable = UnitBuff(unit, i)
        if not name then break end
        
        -- In 3.3.5, we need to check by buff name since spellId might not be reliable
        if S.SpellData and S.SpellData.IsConsumableBuff then
            local buffType = S.SpellData.IsConsumableBuff(name)
            if buffType == "Flask" then
                hasFlask = true
            elseif buffType == "Food" then
                hasFood = true
            end
        end
    end
    
    -- Update local consumables table
    self.consumables[playerName] = {
        flask = hasFlask,
        food = hasFood,
        updated = time()
    }
    
    -- If checking self, broadcast ONLY if status changed
    if UnitIsUnit(unit, "player") then
        local status = (hasFlask and "1" or "0") .. ":" .. (hasFood and "1" or "0")
        if self.lastSentConsumables ~= status then
            self.lastSentConsumables = status
            self:SendMessage("CONSUMABLE_STATUS", status)
        end
    end
end

function RA:Handle_CONSUMABLE_STATUS(sender, data)
    local flask, food = data:match("^([^:]+):(.+)$")
    if not flask then return end
    
    self.consumables[sender] = {
        flask = flask == "1",
        food = food == "1",
        updated = time()
    }
end

function RA:GetConsumableReport()
    local noFlask = {}
    local noFood = {}
    
    for name, status in pairs(self.consumables) do
        if not status.flask then
            table.insert(noFlask, name)
        end
        if not status.food then
            table.insert(noFood, name)
        end
    end
    
    local report = ""
    if #noFlask > 0 then
        report = report .. (S.L["NO_FLASK"] or "Sin Flask") .. ": " .. table.concat(noFlask, ", ") .. "\n"
    end
    if #noFood > 0 then
        report = report .. (S.L["NO_FOOD"] or "Sin Food") .. ": " .. table.concat(noFood, ", ") .. "\n"
    end
    if report == "" then
        report = S.L["ALL_HAVE_CONSUMABLES"] or "Todos tienen consumibles"
    end
    
    return report
end

-- ============================================
-- 6. SISTEMA DE ASIGNACIONES
-- ============================================

function RA:AssignRole(playerName, assignment)
    self:SendMessage("ROLE_ASSIGN", playerName .. ":" .. assignment)
end

function RA:Handle_ROLE_ASSIGN(sender, data)
    local playerName, assignment = data:match("^([^:]+):(.+)$")
    if not playerName then return end
    
    self.assignments[playerName] = assignment
    
    if playerName == UnitName("player") then
        S:Print((S.L["YOUR_ASSIGNMENT"] or "Tu asignación:") .. " " .. assignment)
        -- Show on sphere or create alert
    end
end

-- ============================================
-- 7. CONTADOR DE MUERTES/WIPES
-- ============================================

function RA:PLAYER_DEAD()
    -- Check if it's a wipe
    local alive = 0
    local total = 0
    
    if GetNumRaidMembers() > 0 then
        total = GetNumRaidMembers()
        for i = 1, total do
            if not UnitIsDeadOrGhost("raid" .. i) and UnitIsConnected("raid"..i) then
                alive = alive + 1
            end
        end
    else
        total = GetNumPartyMembers() + 1
        if not UnitIsDeadOrGhost("player") then alive = alive + 1 end
        for i = 1, GetNumPartyMembers() do
            if not UnitIsDeadOrGhost("party"..i) and UnitIsConnected("party"..i) then
                alive = alive + 1
            end
        end
    end
    
    -- Threshold logic: Raid (<=2) vs Party (0)
    local threshold = (total > 5) and 2 or 0
    
    if alive <= threshold and total > 0 then 
        self.wipeCount = self.wipeCount + 1
        self:SendMessage("WIPE", tostring(self.wipeCount))
    end
end

function RA:Handle_WIPE(sender, count)
    self.wipeCount = tonumber(count) or self.wipeCount
    S:Print(string.format(S.L["WIPE_NUMBER"] or "Wipe #%d", self.wipeCount))
end

function RA:ResetWipeCounter()
    self.wipeCount = 0
    self:SendMessage("WIPE_RESET", "")
end

function RA:Handle_WIPE_RESET(sender, data)
    self.wipeCount = 0
end

-- ============================================
-- 8. SINCRONIZACIÓN DE PULL TIMER
-- ============================================

function RA:StartPullTimer(seconds)
    self:SendMessage("PULL_TIMER", tostring(seconds))
    self:ShowPullTimer(seconds)
end

function RA:Handle_PULL_TIMER(sender, data)
    local seconds = tonumber(data)
    if not seconds then return end
    
    self:ShowPullTimer(seconds)
end

function RA:ShowPullTimer(seconds)
    self.pullTimer = seconds
    
    -- Create countdown
    local frame = self.pullTimerFrame or CreateFrame("Frame", "SequitoPullTimer", UIParent)
    self.pullTimerFrame = frame
    
    if not frame.text then
        frame:SetSize(200, 100)
        frame:SetPoint("CENTER", UIParent, "CENTER", 0, 200)
        frame.text = frame:CreateFontString(nil, "OVERLAY", "GameFontNormalHuge")
        frame.text:SetPoint("CENTER")
        frame.text:SetTextColor(1, 0.5, 0)
    end
    
    frame:Show()
    frame.countdown = seconds
    frame.hideDelay = nil -- Para el timer de ocultar
    frame:SetScript("OnUpdate", function(self, elapsed)
        -- Si estamos en modo "ocultar después de pull"
        if self.hideDelay then
            self.hideDelay = self.hideDelay - elapsed
            if self.hideDelay <= 0 then
                self:Hide()
                self:SetScript("OnUpdate", nil)
            end
            return
        end
        
        self.countdown = self.countdown - elapsed
        if self.countdown <= 0 then
            self.text:SetText(S.L["PULL_NOW"] or "¡PULL!")
            self.text:SetTextColor(1, 0, 0)
            PlaySound("RaidWarning")
            -- Iniciar timer de 2 segundos para ocultar (compatible con 3.3.5)
            self.hideDelay = 2
        else
            self.text:SetText(string.format(S.L["PULL_IN_SECONDS"] or "Pull en: %.1f", self.countdown))
        end
    end)
end

-- ============================================
-- 9. DETECTOR DE PROBLEMAS POST-WIPE
-- ============================================

RA.deathReasons = {}

function RA:AnalyzeWipe()
    -- Analyze death reasons
    local report = {}
    
    for reason, count in pairs(self.deathReasons) do
        table.insert(report, {reason = reason, count = count})
    end
    
    table.sort(report, function(a, b) return a.count > b.count end)
    
    S:Print(S.L["WIPE_ANALYSIS_HEADER"] or "=== Análisis de Wipe ===")
    for i, data in ipairs(report) do
        S:Print(string.format(S.L["WIPE_ANALYSIS_LINE"] or "%d. %s (%d jugadores)", i, data.reason, data.count))
    end
end

-- ============================================
-- 10. MODO PROGRESIÓN VS FARM
-- ============================================

function RA:SetMode(mode)
    self.mode = mode
    self:SendMessage("MODE_CHANGE", mode)
    S:Print(string.format(S.L["MODE_CHANGED_TO"] or "Modo cambiado a: %s", mode))
end

function RA:Handle_MODE_CHANGE(sender, mode)
    self.mode = mode
    -- Adjust UI based on mode
end

-- ============================================
-- UPDATE LOOP
-- ============================================

function RA:OnUpdate(elapsed)
    self.syncTimer = (self.syncTimer or 0) + elapsed
    
    if self.syncTimer >= SYNC_INTERVAL then
        self.syncTimer = 0
        
        -- Regular syncs
        if GetNumRaidMembers() > 0 or GetNumPartyMembers() > 0 then
            self:TrackCooldowns()
            self:CheckConsumables()
        end
    end
end

-- ============================================
-- RAID ROSTER UPDATES
-- ============================================

function RA:RAID_ROSTER_UPDATE()
    self:UpdateRoster()
    self:AnnouncePresence()
end

function RA:PARTY_MEMBERS_CHANGED()
    self:UpdateRoster()
    self:AnnouncePresence()
end

-- ============================================
-- COMBAT TRACKING
-- ============================================

function RA:PLAYER_REGEN_DISABLED()
    -- Entered combat
    self.inCombat = true
end

function RA:PLAYER_REGEN_ENABLED()
    -- Left combat
    self.inCombat = false
end

function RA:UNIT_AURA(unit)
    -- Track buff changes for consumables
    if unit == "player" then
        self:CheckConsumables()
    end
end

-- ============================================
-- 11. SISTEMA DE ALERTAS PERSONALIZABLES
-- ============================================

RA.alertSettings = {
    enabled = true,
    sound = true,
    flash = true,
    position = "TOP", -- TOP, CENTER, BOTTOM
    duration = 3,
}

function RA:ShowAlert(message, alertType, duration)
    if not self.alertSettings.enabled then return end
    if not S.db.profile.ShowAlerts then return end
    
    -- Crear frame de alerta si no existe
    if not self.alertFrame then
        self:CreateAlertFrame()
    end
    
    local frame = self.alertFrame
    local color = {1, 1, 1} -- Default white
    
    -- Colores según tipo
    if alertType == "WARNING" then
        color = {1, 0.8, 0} -- Amarillo
    elseif alertType == "DANGER" then
        color = {1, 0, 0} -- Rojo
    elseif alertType == "SUCCESS" then
        color = {0, 1, 0} -- Verde
    elseif alertType == "INFO" then
        color = {0, 0.8, 1} -- Cyan
    end
    
    frame.text:SetText(message)
    frame.text:SetTextColor(color[1], color[2], color[3])
    frame:SetAlpha(1)
    frame:Show()
    
    -- Sonido
    if self.alertSettings.sound and S.db.profile.AlertSound then
        if alertType == "DANGER" then
            PlaySound("RaidWarning")
        elseif alertType == "WARNING" then
            PlaySound("igQuestFailed")
        else
            PlaySound("igQuestComplete")
        end
    end
    
    -- Flash de pantalla
    if self.alertSettings.flash and S.db.profile.AlertFlash and alertType == "DANGER" then
        UIFrameFlash(frame.flashTexture, 0.2, 0.2, 1, true, 0, 0)
    end
    
    -- Timer para ocultar
    frame.hideTimer = duration or self.alertSettings.duration
end

function RA:CreateAlertFrame()
    local frame = CreateFrame("Frame", "SequitoRaidAlertFrame", UIParent)
    frame:SetSize(400, 60)
    
    -- Posición según configuración
    local yOffset = 200
    if self.alertSettings.position == "CENTER" then
        yOffset = 0
    elseif self.alertSettings.position == "BOTTOM" then
        yOffset = -200
    end
    frame:SetPoint("CENTER", UIParent, "CENTER", 0, yOffset)
    
    -- Fondo semi-transparente
    frame.bg = frame:CreateTexture(nil, "BACKGROUND")
    frame.bg:SetAllPoints()
    frame.bg:SetTexture("Interface\\Buttons\\WHITE8X8")
    frame.bg:SetVertexColor(0, 0, 0, 0.7)
    
    -- Texto
    frame.text = frame:CreateFontString(nil, "OVERLAY", "GameFontNormalHuge")
    frame.text:SetPoint("CENTER")
    frame.text:SetText("")
    
    -- Textura para flash
    frame.flashTexture = frame:CreateTexture(nil, "OVERLAY")
    frame.flashTexture:SetAllPoints()
    frame.flashTexture:SetTexture("Interface\\Buttons\\WHITE8X8")
    frame.flashTexture:SetVertexColor(1, 0, 0, 0.3)
    frame.flashTexture:Hide()
    
    -- OnUpdate para fade out (purga el script al terminar - Ley IV)
    frame:SetScript("OnUpdate", function(self, elapsed)
        if self.hideTimer then
            self.hideTimer = self.hideTimer - elapsed
            if self.hideTimer <= 0 then
                self.hideTimer = nil
                -- Fade out
                local alpha = self:GetAlpha() - elapsed * 2
                if alpha <= 0 then
                    self:SetScript("OnUpdate", nil)  -- purga antes de ocultar
                    self:Hide()
                    self:SetAlpha(1)
                else
                    self:SetAlpha(alpha)
                end
            end
        end
    end)
    
    frame:Hide()
    self.alertFrame = frame
end

function RA:SetAlertPosition(position)
    self.alertSettings.position = position
    if self.alertFrame then
        self.alertFrame:ClearAllPoints()
        local yOffset = 200
        if position == "CENTER" then
            yOffset = 0
        elseif position == "BOTTOM" then
            yOffset = -200
        end
        self.alertFrame:SetPoint("CENTER", UIParent, "CENTER", 0, yOffset)
    end
end

-- ============================================
-- 12. HISTORIAL DE WIPES CON ESTADÍSTICAS
-- ============================================

RA.wipeHistory = {}

function RA:RecordWipe()
    local wipeData = {
        timestamp = time(),
        date = date("%Y-%m-%d %H:%M:%S"),
        zone = GetRealZoneText() or "Unknown",
        raidSize = GetNumRaidMembers(),
        duration = self.combatDuration or 0,
        deaths = {},
        consumablesStatus = {},
    }
    
    -- Copiar estado de consumibles
    for name, status in pairs(self.consumables) do
        wipeData.consumablesStatus[name] = {
            flask = status.flask,
            food = status.food
        }
    end
    
    -- Copiar razones de muerte
    for reason, count in pairs(self.deathReasons) do
        wipeData.deaths[reason] = count
    end
    
    table.insert(self.wipeHistory, wipeData)
    
    -- Limitar historial a 50 wipes
    while #self.wipeHistory > 50 do
        table.remove(self.wipeHistory, 1)
    end
    
    -- Guardar en SavedVariables
    self:SaveWipeHistory()
end

function RA:SaveWipeHistory()
    if not SequitoDB then SequitoDB = {} end
    SequitoDB.wipeHistory = self.wipeHistory
end

function RA:LoadWipeHistory()
    if SequitoDB and SequitoDB.wipeHistory then
        self.wipeHistory = SequitoDB.wipeHistory
        self.wipeCount = #self.wipeHistory
    end
end

function RA:GetWipeStats()
    local stats = {
        total = #self.wipeHistory,
        byZone = {},
        avgDuration = 0,
        commonDeaths = {},
    }
    
    local totalDuration = 0
    
    for _, wipe in ipairs(self.wipeHistory) do
        -- Por zona
        stats.byZone[wipe.zone] = (stats.byZone[wipe.zone] or 0) + 1
        
        -- Duración promedio
        totalDuration = totalDuration + (wipe.duration or 0)
        
        -- Muertes comunes
        for reason, count in pairs(wipe.deaths or {}) do
            stats.commonDeaths[reason] = (stats.commonDeaths[reason] or 0) + count
        end
    end
    
    if stats.total > 0 then
        stats.avgDuration = totalDuration / stats.total
    end
    
    return stats
end

function RA:PrintWipeHistory()
    local stats = self:GetWipeStats()
    
    S:Print("|cFFFF6666=== Historial de Wipes ===|r")
    S:Print(string.format("Total de wipes: |cFFFFFFFF%d|r", stats.total))
    
    if stats.total > 0 then
        S:Print(string.format("Duración promedio: |cFFFFFFFF%.1f seg|r", stats.avgDuration))
        
        S:Print("|cFFFFCC00Por zona:|r")
        for zone, count in pairs(stats.byZone) do
            S:Print(string.format("  %s: |cFFFFFFFF%d|r", zone, count))
        end
        
        -- Top 3 causas de muerte
        local deathList = {}
        for reason, count in pairs(stats.commonDeaths) do
            table.insert(deathList, {reason = reason, count = count})
        end
        table.sort(deathList, function(a, b) return a.count > b.count end)
        
        if #deathList > 0 then
            S:Print("|cFFFFCC00Causas comunes de muerte:|r")
            for i = 1, math.min(3, #deathList) do
                S:Print(string.format("  %d. %s: |cFFFFFFFF%d|r", i, deathList[i].reason, deathList[i].count))
            end
        end
    end
end

function RA:ClearWipeHistory()
    self.wipeHistory = {}
    self.wipeCount = 0
    self:SaveWipeHistory()
    S:Print("|cFF00FF00Historial de wipes borrado.|r")
end

-- Cargar historial al inicializar
local oldInit = RA.Initialize
function RA:Initialize()
    oldInit(self)
    self:LoadWipeHistory()
end

-- ===========================================================================
-- REGISTRO EN MODULECONFIG
-- ===========================================================================
if S.ModuleConfig then
    S.ModuleConfig:RegisterModule("RaidAssist", {
        name = "Asistencia de Raid",
        description = "Sistema colaborativo de raid: sincroniza cooldowns, interrupciones, asignaciones y consumibles entre usuarios de Sequito.",
        category = "raid",
        icon = "Interface\\Icons\\Achievement_Boss_Lichking",
        options = {
            {
                key = "enabled",
                type = "checkbox",
                label = "Habilitar RaidAssist",
                tooltip = "Activa el sistema de asistencia de raid",
                default = true
            },
            {
                key = "syncCooldowns",
                type = "checkbox",
                label = "Sincronizar cooldowns",
                tooltip = "Comparte cooldowns importantes con otros usuarios de Sequito",
                default = true
            },
            {
                key = "trackConsumables",
                type = "checkbox",
                label = "Trackear consumibles",
                tooltip = "Monitorea buffs de consumibles (flasks, food, etc.)",
                default = true
            },
            {
                key = "announceWipes",
                type = "checkbox",
                label = "Anunciar wipes",
                tooltip = "Anuncia cuando el raid wipeó",
                default = true
            },
            {
                key = "interruptRotation",
                type = "checkbox",
                label = "Rotación de interrupciones",
                tooltip = "Coordina interrupciones automáticamente",
                default = true
            },
            {
                key = "showAssignments",
                type = "checkbox",
                label = "Mostrar asignaciones",
                tooltip = "Muestra asignaciones de roles y tareas",
                default = true
            },
            {
                key = "versionCheck",
                type = "checkbox",
                label = "Verificar versiones",
                tooltip = "Verifica que todos tengan la misma versión de Sequito",
                default = true
            }
        }
    })
end
