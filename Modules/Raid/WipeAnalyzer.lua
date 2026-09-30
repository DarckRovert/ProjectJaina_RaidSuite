--[[
    Sequito - WipeAnalyzer.lua
    Analizador de Wipes para Raids
    Version: 7.2.0
    
    Funcionalidades:
    - Registra muertes durante el combate
    - Detecta quién murió primero y por qué
    - Verifica uso de pociones/healthstones
    - Verifica interrupts fallidos
    - Muestra análisis post-wipe
]]

local addonName, S = ...
S.WipeAnalyzer = {}
local WA = S.WipeAnalyzer
local L = S.L or {}

-- Datos del combate actual
WA.CurrentFight = {
    inCombat = false,
    startTime = 0,
    deaths = {},
    interrupts = {
        successful = {},
        failed = {}
    },
    consumables = {},
    damage = {},
    healing = {}
}

-- Historial de peleas
WA.FightHistory = {}

-- Optimizacion: Cache de GUIDs de raid
WA.RaidGUIDs = {}

-- Pociones y consumibles a trackear
local TrackedConsumables = {
    -- Pociones de vida
    [33447] = "Runic Healing Potion",
    [43569] = "Endless Healing Potion",
    -- Pociones de maná
    [33448] = "Runic Mana Potion",
    [43570] = "Endless Mana Potion",
    -- Healthstones
    [47875] = "Healthstone",
    [47876] = "Healthstone",
    [47877] = "Healthstone",
    -- Pociones de combate
    [53908] = "Potion of Speed",
    [53909] = "Potion of Wild Magic",
}

-- Spells de interrupt
local InterruptSpells = {
    [1766] = "Kick",
    [6552] = "Pummel",
    [47528] = "Mind Freeze",
    [57994] = "Wind Shear",
    [2139] = "Counterspell",
    [34490] = "Silencing Shot",
    [15487] = "Silence",
    [19647] = "Spell Lock",
}

-- ===========================================================================
-- SMART COACH: PATTERN ANALYSIS (v10.0)
-- ===========================================================================
function WA:AnalyzePatterns()
    -- Only analyze if we have history
    if #self.FightHistory < 2 then return end
    
    local latestFight = self.FightHistory[#self.FightHistory]
    local previousFight = self.FightHistory[#self.FightHistory - 1]
    
    local playerName = UnitName("player")
    
    -- Check if player died in both fights
    local diedLatest = self:GetDeathSource(latestFight, playerName)
    local diedPrevious = self:GetDeathSource(previousFight, playerName)
    
    if diedLatest and diedPrevious then
        local match = false
        if diedLatest.spellId and diedPrevious.spellId and diedLatest.spellId > 0 and diedLatest.spellId == diedPrevious.spellId then
            match = true
        elseif diedLatest.spellName and diedPrevious.spellName and diedLatest.spellName ~= "Desconocido" and diedLatest.spellName == diedPrevious.spellName then
            match = true
        end
        if match then
            -- PATTERN DETECTED!
            local spellLink = (diedLatest.spellId and diedLatest.spellId > 0 and GetSpellLink(diedLatest.spellId)) or diedLatest.spellName
            local msg = string.format("Coach: Has muerto 2 veces seguidas por %s. ¡Cuidado!", spellLink)
            
            -- Send to SmartCoach (or print if not available)
            if S.Coach then
                S.Coach:ShowHint(msg)
            else
                print("|cFFFF0000" .. msg .. "|r")
            end
        end
    end
end

function WA:GetDeathSource(fight, playerName)
    if not fight or not fight.deaths then return nil end
    for _, death in ipairs(fight.deaths) do
        if death.name == playerName then
            return death.source -- Returns { spellId = 123, spellName = "Fire" }
        end
    end
    return nil
end

WA.Frame = nil
WA.Rows = {}
WA.IsVisible = false

-- Helper para obtener configuración
function WA:GetOption(key)
    if S.ModuleConfig then
        local val = S.ModuleConfig:GetValue("WipeAnalyzer", key)
        if val ~= nil then return val end
    end
    if key == "enabled" or key == "autoShow" or key == "announceResults" or key == "trackConsumables" or key == "trackInterrupts" then
        return true
    end
    if key == "minFightDuration" then return 10 end
    return false
end

function WA:Initialize()
    if self.initialized then return end
    if not self:GetOption("enabled") then
        return
    end
    self.initialized = true
    
    self:CreateFrame()
    self:RegisterEvents()
end

function WA:CreateFrame()
    if self.Frame then return end
    
    local f = CreateFrame("Frame", "SequitoWipeAnalyzer", UIParent)
    f:SetSize(500, 450) -- Un poco más ancho
    f:SetPoint("CENTER", UIParent, "CENTER", 0, 0)
    f:SetFrameStrata("HIGH") -- Ensure visibility
    
    -- Fondo elegante
    local bg = f:CreateTexture(nil, "BACKGROUND")
    bg:SetAllPoints()
    bg:SetTexture("Interface\\Buttons\\WHITE8X8")
    bg:SetVertexColor(0, 0, 0, 0.85)
    f.bg = bg
    
    -- Borde fino
    local border = CreateFrame("Frame", nil, f)
    border:SetAllPoints()
    border:SetBackdrop({
        edgeFile = "Interface\\Buttons\\WHITE8x8",
        edgeSize = 1,
    })
    border:SetBackdropBorderColor(0.6, 0.2, 0.2, 1) -- Borde rojizo para wipe
    
    -- Header Strip
    local headerBg = f:CreateTexture(nil, "ARTWORK")
    headerBg:SetPoint("TOPLEFT", f, "TOPLEFT", 0, 0)
    headerBg:SetPoint("BOTTOMRIGHT", f, "TOPRIGHT", 0, -24)
    headerBg:SetTexture("Interface\\Buttons\\WHITE8X8")
    headerBg:SetVertexColor(0.3, 0.1, 0.1, 1) -- Header rojo oscuro
    
    f:EnableMouse(true)
    f:SetMovable(true)
    f:RegisterForDrag("LeftButton")
    f:SetScript("OnDragStart", f.StartMoving)
    f:SetScript("OnDragStop", function(self)
        self:StopMovingOrSizing()
        if S.SmartDefaults then
            S.SmartDefaults:SavePosition("WipeAnalyzer", self)
        end
    end)
    f:SetClampedToScreen(true)
    f:Hide()
    
    -- Título
    local title = f:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    title:SetPoint("LEFT", headerBg, "LEFT", 10, 0)
    title:SetText("|cffff0000" .. L["WIPE_ANALYZER_TITLE"] .. "|r")
    f.title = title
    
    -- Botón cerrar
    local closeBtn = CreateFrame("Button", nil, f, "UIPanelCloseButton")
    closeBtn:SetPoint("TOPRIGHT", f, "TOPRIGHT", -2, -2)
    closeBtn:SetScript("OnClick", function() WA:Toggle() end)
    
    if S.SmartDefaults then
        S.SmartDefaults:RestorePosition("WipeAnalyzer", f)
    end
    
    -- Resumen
    local summary = f:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    summary:SetPoint("TOPLEFT", f, "TOPLEFT", 15, -35)
    summary:SetWidth(420)
    summary:SetJustifyH("LEFT")
    f.summary = summary
    
    -- Scroll frame para detalles
    local scrollFrame = CreateFrame("ScrollFrame", "SequitoWAScroll", f, "UIPanelScrollFrameTemplate")
    scrollFrame:SetPoint("TOPLEFT", f, "TOPLEFT", 10, -80)
    scrollFrame:SetPoint("BOTTOMRIGHT", f, "BOTTOMRIGHT", -30, 45)
    
    local content = CreateFrame("Frame", nil, scrollFrame)
    content:SetSize(400, 800)
    scrollFrame:SetScrollChild(content)
    f.content = content
    
    -- Botones inferiores
    local announceBtn = CreateFrame("Button", nil, f, "UIPanelButtonTemplate")
    announceBtn:SetSize(120, 24)
    announceBtn:SetPoint("BOTTOMLEFT", f, "BOTTOMLEFT", 10, 10)
    announceBtn:SetText("Anunciar")
    announceBtn:SetScript("OnClick", function() WA:AnnounceAnalysis() end)
    
    local clearBtn = CreateFrame("Button", nil, f, "UIPanelButtonTemplate")
    clearBtn:SetSize(120, 24)
    clearBtn:SetPoint("BOTTOMRIGHT", f, "BOTTOMRIGHT", -10, 10)
    clearBtn:SetText("Limpiar")
    clearBtn:SetScript("OnClick", function() WA:ClearCurrent() end)
    
    local historyBtn = CreateFrame("Button", nil, f, "UIPanelButtonTemplate")
    historyBtn:SetSize(120, 24)
    historyBtn:SetPoint("BOTTOM", f, "BOTTOM", 0, 10)
    historyBtn:SetText("Historial")
    historyBtn:SetScript("OnClick", function() WA:ShowHistory() end)
    
    self.Frame = f
end

function WA:RegisterEvents()
    local eventFrame = CreateFrame("Frame")
    eventFrame:RegisterEvent("PLAYER_REGEN_DISABLED")
    eventFrame:RegisterEvent("PLAYER_REGEN_ENABLED")
    eventFrame:RegisterEvent("RAID_ROSTER_UPDATE")
    eventFrame:RegisterEvent("PARTY_MEMBERS_CHANGED")
    
    eventFrame:SetScript("OnEvent", function(self, event, ...)
        if event == "PLAYER_REGEN_DISABLED" then
            WA:OnCombatStart()
        elseif event == "PLAYER_REGEN_ENABLED" then
            WA:OnCombatEnd()
        elseif event == "RAID_ROSTER_UPDATE" or event == "PARTY_MEMBERS_CHANGED" then
            WA:UpdateRoster()
        end
    end)

    if S.CLEU and S.CLEU.Register then
        local function onCLEU(...)
            WA:OnCombatLog(...)
        end
        S.CLEU:Register("UNIT_DIED", onCLEU)
        S.CLEU:Register("SPELL_CAST_SUCCESS", onCLEU)
        S.CLEU:Register("SPELL_INTERRUPT", onCLEU)
        S.CLEU:Register("SPELL_DAMAGE", onCLEU)
        S.CLEU:Register("SWING_DAMAGE", onCLEU)
        S.CLEU:Register("SPELL_PERIODIC_DAMAGE", onCLEU)
        S.CLEU:Register("RANGE_DAMAGE", onCLEU)
        S.CLEU:Register("SPELL_BUILDING_DAMAGE", onCLEU)
        S.CLEU:Register("ENVIRONMENTAL_DAMAGE", onCLEU)
    else
        eventFrame:RegisterEvent("COMBAT_LOG_EVENT_UNFILTERED")
        eventFrame:HookScript("OnEvent", function(self, event, ...)
            if event == "COMBAT_LOG_EVENT_UNFILTERED" then
                WA:OnCombatLog(...)
            end
        end)
    end
    
    -- Initial update
    WA:UpdateRoster()
end

function WA:DetectBossEncounter()
    if self.CurrentFight.isBossEncounter and self.CurrentFight.bossGUID then return end
    
    local unitsToCheck = { "target", "focus", "boss1", "boss2", "boss3", "boss4" }
    local numRaid = GetNumRaidMembers()
    if numRaid > 0 then
        for i = 1, numRaid do
            table.insert(unitsToCheck, "raid" .. i .. "target")
        end
    else
        local numParty = GetNumPartyMembers()
        for i = 1, numParty do
            table.insert(unitsToCheck, "party" .. i .. "target")
        end
    end
    
    for _, unit in ipairs(unitsToCheck) do
        if UnitExists(unit) and not UnitIsFriend("player", unit) then
            local classification = UnitClassification(unit)
            local level = UnitLevel(unit)
            if classification == "worldboss" or level == -1 then
                self.CurrentFight.isBossEncounter = true
                self.CurrentFight.encounterName = UnitName(unit)
                self.CurrentFight.bossGUID = UnitGUID(unit)
                return
            end
        end
    end
end

function WA:OnCombatStart()
    self.CurrentFight = {
        inCombat = true,
        startTime = GetTime(),
        deaths = {},
        interrupts = {
            successful = {},
            failed = {}
        },
        consumables = {},
        damage = {},
        healing = {},
        isBossEncounter = false,
        encounterName = nil,
        bossGUID = nil,
        bossKilled = false,
        success = false
    }
    self:DetectBossEncounter()
end

function WA:OnCombatEnd()
    if not self.CurrentFight.inCombat then return end
    
    self.CurrentFight.inCombat = false
    self.CurrentFight.endTime = GetTime()
    self.CurrentFight.duration = self.CurrentFight.endTime - self.CurrentFight.startTime
    
    local raidSize = GetNumRaidMembers()
    if raidSize == 0 then raidSize = GetNumPartyMembers() + 1 end
    local deathCount = #self.CurrentFight.deaths
    local inInstance, instanceType = IsInInstance()
    
    -- CASO 1: VICTORIA CONTRA BOSS (El jefe fue abatido)
    if self.CurrentFight.bossKilled or self.CurrentFight.success then
        self.CurrentFight.isWipe = false
        self.lastEncounterWon = true
        
        if inInstance and (instanceType == "raid" or instanceType == "party") then
            if S.EcosystemBridge and S.EcosystemBridge.NotifyBossKill then
                local encounterName = self.CurrentFight.encounterName or "Jefe de Banda"
                S.EcosystemBridge:NotifyBossKill(encounterName)
            end
        end
    else
        -- CASO 2: DERROTA / WIPE (Solo si hubo más del 50% de bajas y estábamos en boss o instancia)
        local isWipe = (deathCount >= (raidSize * 0.5)) and (deathCount > 0) and (self.CurrentFight.isBossEncounter or inInstance)
        
        if isWipe then
            self.CurrentFight.isWipe = true
            table.insert(self.FightHistory, self.CurrentFight)
            self:AnalyzeWipe()
            
            if self:GetOption("autoShow") then
                self:Show()
            end
            if self:GetOption("announceResults") then
                self:AnnounceAnalysis()
            end
            print("|cffff0000[Sequito]|r ¡Wipe detectado! Usa /sequito analyze para ver el análisis")
        end
    end
end

function WA:OnEncounterStart(encounterID, encounterName, difficultyID, raidSize)
    self.CurrentFight.encounterName = encounterName
    self.CurrentFight.encounterID = encounterID
    self.CurrentFight.difficulty = difficultyID
    self.CurrentFight.isBossEncounter = true
end

function WA:OnEncounterEnd(encounterID, encounterName, difficultyID, raidSize, success)
    self.CurrentFight.success = success
    if success then
        self.CurrentFight.bossKilled = true
    end
end

function WA:OnCombatLog(...)
    if not self.CurrentFight.inCombat then return end
    
    local timestamp, event, sourceGUID, sourceName, sourceFlags, destGUID, destName, destFlags, arg9, arg10, arg11, arg12 = ...
    
    -- Detección dinámica de Boss durante combate
    if sourceGUID and not self.CurrentFight.bossGUID and not self:IsRaidMember(sourceGUID) then
        if bit.band(sourceFlags or 0, COMBATLOG_OBJECT_REACTION_HOSTILE) > 0 then
            if UnitExists("target") and UnitGUID("target") == sourceGUID and (UnitClassification("target") == "worldboss" or UnitLevel("target") == -1) then
                self.CurrentFight.isBossEncounter = true
                self.CurrentFight.bossGUID = sourceGUID
                self.CurrentFight.encounterName = sourceName or UnitName("target")
            elseif UnitExists("focus") and UnitGUID("focus") == sourceGUID and (UnitClassification("focus") == "worldboss" or UnitLevel("focus") == -1) then
                self.CurrentFight.isBossEncounter = true
                self.CurrentFight.bossGUID = sourceGUID
                self.CurrentFight.encounterName = sourceName or UnitName("focus")
            end
        end
    end
    
    -- Detectar muertes
    if event == "UNIT_DIED" then
        if destName and self:IsRaidMember(destGUID) then
            self:RecordDeath(destName, destGUID)
        elseif destGUID and not self:IsRaidMember(destGUID) then
            local wasBoss = false
            if self.CurrentFight.bossGUID and destGUID == self.CurrentFight.bossGUID then
                wasBoss = true
            elseif self.CurrentFight.encounterName and destName == self.CurrentFight.encounterName then
                wasBoss = true
            elseif UnitExists("target") and UnitGUID("target") == destGUID and (UnitClassification("target") == "worldboss" or UnitLevel("target") == -1) then
                wasBoss = true
                self.CurrentFight.encounterName = destName
            elseif UnitExists("focus") and UnitGUID("focus") == destGUID and (UnitClassification("focus") == "worldboss" or UnitLevel("focus") == -1) then
                wasBoss = true
                self.CurrentFight.encounterName = destName
            end
            
            if wasBoss then
                self.CurrentFight.bossKilled = true
                self.CurrentFight.success = true
                self.CurrentFight.isBossEncounter = true
                self.CurrentFight.encounterName = self.CurrentFight.encounterName or destName
            end
        end
    end
    
    -- Detectar uso de consumibles (si está habilitado)
    if event == "SPELL_CAST_SUCCESS" then
        if self:GetOption("trackConsumables") and TrackedConsumables[arg9] and self:IsRaidMember(sourceGUID) then
            self:RecordConsumable(sourceName, arg9, TrackedConsumables[arg9])
        end
    end
    
    -- Detectar interrupts exitosos (si está habilitado)
    if event == "SPELL_INTERRUPT" then
        if self:GetOption("trackInterrupts") and self:IsRaidMember(sourceGUID) then
            self:RecordInterrupt(sourceName, destName, arg9, arg12, true)
        end
    end
    
    -- Registrar daño recibido (para análisis de muerte)
    if self:IsRaidMember(destGUID) then
        if event == "SWING_DAMAGE" then
            local amount = arg9
            self:RecordDamage(destName, sourceName, "Melee", amount, 0)
        elseif event == "SPELL_DAMAGE" or event == "SPELL_PERIODIC_DAMAGE" or event == "RANGE_DAMAGE" or event == "SPELL_BUILDING_DAMAGE" then
            local spellId = arg9
            local spellName = arg10 or "Hechizo"
            local amount = arg12
            self:RecordDamage(destName, sourceName, spellName, amount, spellId)
        elseif event == "ENVIRONMENTAL_DAMAGE" then
            local hazardType = arg9 or "Entorno"
            local amount = arg10
            self:RecordDamage(destName, "Medio ambiente", hazardType, amount, 0)
        end
    end
end

function WA:UpdateRoster()
    wipe(self.RaidGUIDs)
    
    if GetNumRaidMembers() > 0 then
        for i = 1, GetNumRaidMembers() do
            local unit = "raid" .. i
            local guid = UnitGUID(unit)
            if guid then self.RaidGUIDs[guid] = unit end
        end
    elseif GetNumPartyMembers() > 0 then
        for i = 1, GetNumPartyMembers() do
            local unit = "party" .. i
            local guid = UnitGUID(unit)
            if guid then self.RaidGUIDs[guid] = unit end
        end
    end
    
    local pGUID = UnitGUID("player")
    if pGUID then self.RaidGUIDs[pGUID] = "player" end
end

function WA:IsRaidMember(guid)
    return self.RaidGUIDs[guid] ~= nil
end

function WA:GetRaidUnit(guid)
    return self.RaidGUIDs[guid]
end

function WA:RecordDeath(playerName, playerGUID)
    local unit = self:GetRaidUnit(playerGUID)
    if unit and UnitExists(unit) and UnitIsFeignDeath(unit) then
        return -- Fingir muerte de cazador detectado
    end

    local deathTime = GetTime() - self.CurrentFight.startTime
    
    -- Obtener últimos daños recibidos
    local recentDamage = self.CurrentFight.damage[playerName] or {}
    local lastDamage = recentDamage[#recentDamage]
    
    -- Verificar si usó consumibles
    local usedConsumables = {}
    for _, cons in ipairs(self.CurrentFight.consumables) do
        if cons.player == playerName then
            table.insert(usedConsumables, cons.name)
        end
    end
    
    local isSacrifice = false
    if lastDamage and (lastDamage.spell == "Intervención divina" or lastDamage.spell == "Divine Intervention") then
        isSacrifice = true
    end
    
    local deathInfo = {
        name = playerName,
        guid = playerGUID,
        time = deathTime,
        killedBy = lastDamage and lastDamage.source or "Desconocido",
        lastSpell = lastDamage and lastDamage.spell or "Desconocido",
        lastSpellId = lastDamage and lastDamage.spellId or 0,
        lastDamage = lastDamage and lastDamage.amount or 0,
        usedConsumables = usedConsumables,
        isTacticalSacrifice = isSacrifice,
        order = #self.CurrentFight.deaths + 1,
        source = {
            spellId = lastDamage and lastDamage.spellId or 0,
            spellName = lastDamage and lastDamage.spell or "Desconocido"
        }
    }
    
    -- Obtener clase
    local _, classFile = GetPlayerInfoByGUID(playerGUID)
    deathInfo.class = classFile or (unit and select(2, UnitClass(unit)))
    
    table.insert(self.CurrentFight.deaths, deathInfo)
end

function WA:RecordConsumable(playerName, spellId, consumableName)
    table.insert(self.CurrentFight.consumables, {
        player = playerName,
        spellId = spellId,
        name = consumableName,
        time = GetTime() - self.CurrentFight.startTime
    })
end

function WA:RecordInterrupt(playerName, targetName, interruptSpellId, interruptedSpellId, success)
    local record = {
        player = playerName,
        target = targetName,
        interruptSpell = InterruptSpells[interruptSpellId] or "Interrupt",
        interruptedSpell = GetSpellInfo(interruptedSpellId) or "Unknown",
        time = GetTime() - self.CurrentFight.startTime,
        success = success
    }
    
    if success then
        table.insert(self.CurrentFight.interrupts.successful, record)
    else
        table.insert(self.CurrentFight.interrupts.failed, record)
    end
end

function WA:RecordDamage(destName, sourceName, spellName, amount, spellId)
    if not destName then return end
    if not self.CurrentFight.damage[destName] then
        self.CurrentFight.damage[destName] = {}
    end
    
    -- Mantener solo los últimos 5 daños
    local damageList = self.CurrentFight.damage[destName]
    if #damageList >= 5 then
        table.remove(damageList, 1)
    end
    
    table.insert(damageList, {
        source = sourceName or "Medio ambiente",
        spell = spellName or "Golpe",
        spellId = spellId or 0,
        amount = amount or 0,
        time = GetTime() - self.CurrentFight.startTime
    })
end

function WA:AnalyzeWipe()
    local fight = self.CurrentFight
    if #fight.deaths == 0 then return end
    
    -- Seleccionar primera muerte real (omitiendo sacrificios tácticos de Intervención Divina)
    local actualFirstDeath = nil
    for _, d in ipairs(fight.deaths) do
        if not d.isTacticalSacrifice then
            actualFirstDeath = d
            break
        end
    end
    actualFirstDeath = actualFirstDeath or fight.deaths[1]
    
    -- Análisis Básico
    local analysis = {
        firstDeath = actualFirstDeath,
        totalDeaths = #fight.deaths,
        duration = fight.duration,
        consumablesUsed = #fight.consumables,
        interruptsSuccessful = #fight.interrupts.successful,
        interruptsFailed = #fight.interrupts.failed,
        noConsumables = {},
        deathOrder = fight.deaths,
        causes = {} -- Top Killing Abilities
    }
    
    -- 1. Encontrar quién no usó consumibles
    local usedConsumables = {}
    for _, cons in ipairs(fight.consumables) do
        usedConsumables[cons.player] = true
    end
    
    for _, death in ipairs(fight.deaths) do
        if not usedConsumables[death.name] then
            table.insert(analysis.noConsumables, death.name)
        end
    end
    
    -- 2. Analizar CAUSAS DE MUERTE (Top Killers)
    local causeCounts = {}
    for _, death in ipairs(fight.deaths) do
        local cause = death.lastSpell or "Desconocido"
        -- Si fue meleé, mostrar quién golpeó
        if cause == "Melee" or cause == "Unknown" then
             cause = death.killedBy .. " (Melee)"
        end
        causeCounts[cause] = (causeCounts[cause] or 0) + 1
    end
    
    -- Convertir a lista ordenable
    for cause, count in pairs(causeCounts) do
        table.insert(analysis.causes, {name = cause, count = count})
    end
    -- Ordenar por número de víctimas
    table.sort(analysis.causes, function(a, b) return a.count > b.count end)
    
    self.LastAnalysis = analysis
    self:UpdateDisplay()
end

WA.ElementPool = {}
WA.ActiveElements = {}

function WA:AcquireElement(elementType)
    local pool = self.ElementPool[elementType] or {}
    local elem = table.remove(pool)
    
    if not elem then
        if elementType == "FontString" then
            elem = self.Frame.content:CreateFontString(nil, "OVERLAY", "GameFontNormal")
        elseif elementType == "Frame" then
            elem = CreateFrame("Frame", nil, self.Frame.content)
        end
    end
    
    table.insert(self.ActiveElements, {elem = elem, type = elementType})
    elem:SetParent(self.Frame.content)
    elem:Show()
    return elem
end

function WA:ReleaseElements()
    for _, item in ipairs(self.ActiveElements) do
        item.elem:Hide()
        item.elem:ClearAllPoints()
        
        if not self.ElementPool[item.type] then self.ElementPool[item.type] = {} end
        table.insert(self.ElementPool[item.type], item.elem)
    end
    self.ActiveElements = {}
end

function WA:UpdateDisplay()
    if not self.Frame or not self.LastAnalysis then return end
    
    local analysis = self.LastAnalysis
    local fight = self.CurrentFight
    
    -- Resumen
    local summaryText = string.format(
        L["WIPE_SUMMARY_FMT"],
        fight.encounterName or "Desconocido",
        analysis.duration or 0,
        analysis.totalDeaths
    )
    
    self.Frame.summary:SetText(summaryText)
    
    -- Limpiar contenido anterior
    self:ReleaseElements()
    
    local lastElement = nil
    local padding = 10
    
    -- Helper para layout relativo
    local function AddElement(elem, height, xOffset, yOffsetOverride)
        if not lastElement then
            elem:SetPoint("TOPLEFT", self.Frame.content, "TOPLEFT", xOffset, yOffsetOverride or -10)
        else
            elem:SetPoint("TOPLEFT", lastElement, "BOTTOMLEFT", 0, -(padding))
             -- Re-ajustar X si es necesario (el relative anchor usa el X del anterior)
             -- Pero queremos alinear todo a la izquierda del content frame, no del anterior.
             -- Mejor estrategia: Anchor to TOPLEFT of Parent but Y relative to lastElement BOTTOM
             elem:ClearAllPoints()
             elem:SetPoint("TOPLEFT", self.Frame.content, "TOPLEFT", xOffset, 0)
             elem:SetPoint("TOP", lastElement, "BOTTOM", 0, -padding)
        end
        
        if height then elem:SetHeight(height) end
        lastElement = elem
        return elem
    end
    
    -- MEJOR ESTRATEGIA: Anchor Chain simple
    local function AnchorToLast(elem, x, yPad)
        elem:ClearAllPoints()
        if not lastElement then
            elem:SetPoint("TOPLEFT", self.Frame.content, "TOPLEFT", x, -10)
        else
            elem:SetPoint("TOPLEFT", lastElement, "BOTTOMLEFT", 0, -yPad)
            -- Corregir X relativo: Si el anterior tiene X=10, el nuevo tendrá X=10+0.
            -- Si queremos X absoluto, debemos usar TOPLEFT parent con offset Y calculado?
            -- No, relative es mejor si todos tienen el mismo X.
            
            -- Si el anterior era un Frame ancho (FirstDeath) y el nuevo es texto indetado...
            -- Forzamos X seteando Point LEFT
             local _, _, _, prevX, _ = lastElement:GetPoint()
             local diffX = x - (prevX or 0)
             elem:SetPoint("TOPLEFT", lastElement, "BOTTOMLEFT", diffX, -yPad)
        end
        lastElement = elem
    end

    -- 1. PRIMERA MUERTE (SECTION CRÍTICA)
    if analysis.firstDeath then
        local fdFrame = self:AcquireElement("Frame")
        fdFrame:SetSize(380, 60)
        
        -- Fondo rojo tenue (recrear texture si no existe)
        if not fdFrame.bg then
            fdFrame.bg = fdFrame:CreateTexture(nil, "BACKGROUND")
            fdFrame.bg:SetAllPoints()
            fdFrame.bg:SetTexture("Interface\\Buttons\\WHITE8X8")
            fdFrame.bg:SetVertexColor(0.3, 0.1, 0.1, 0.4)
        end
        
        -- Textos internos (no manageados por pool principal para simplificar, hijos de fdFrame)
        if not fdFrame.title then
            fdFrame.title = fdFrame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
            fdFrame.title:SetPoint("TOPLEFT", 10, -8)
        end
        fdFrame.title:SetText("|cffff0000" .. L["SECTION_FIRST_DEATH"] .. "|r")
            
        if not fdFrame.info then
            fdFrame.info = fdFrame:CreateFontString(nil, "OVERLAY", "GameFontHighlightLarge")
            fdFrame.info:SetPoint("LEFT", 10, -5)
        end
        local classColor = analysis.firstDeath.class and RAID_CLASS_COLORS[analysis.firstDeath.class] or {r=1,g=1,b=1}
        fdFrame.info:SetText(string.format("|cff%02x%02x%02x%s|r", 
            classColor.r*255, classColor.g*255, classColor.b*255, 
            analysis.firstDeath.name))
            
        if not fdFrame.detail then
            fdFrame.detail = fdFrame:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
            fdFrame.detail:SetPoint("TOPLEFT", fdFrame.info, "BOTTOMLEFT", 0, -4)
        end
        fdFrame.detail:SetText(string.format(L["DEATH_REPORT_FMT"], 
            analysis.firstDeath.time, analysis.firstDeath.killedBy, analysis.firstDeath.lastSpell))
            
        AnchorToLast(fdFrame, 10, 10)
    end
    
    -- 1.5 TOP CAUSAS (NUEVO)
    if #analysis.causes > 0 then
        local h = self:CreateHeader("Principales Causas de Muerte")
        AnchorToLast(h, 10, 20)
        
        for i = 1, math.min(3, #analysis.causes) do
            local cause = analysis.causes[i]
            local line = self:CreateTextLine(string.format("%d. %s (|cffff0000%d víctimas|r)", i, cause.name, cause.count))
            AnchorToLast(line, 5, 5)
        end
    end
    
    -- 2. CONSUMIBLES
    if #analysis.noConsumables > 0 then
        local h = self:CreateHeader(L["SECTION_NO_CONSUMABLES"])
        AnchorToLast(h, 10, 20)
        
        local text = table.concat(analysis.noConsumables, ", ")
        local line = self:CreateTextLine(text)
        line:SetTextColor(1, 0.6, 0)
        AnchorToLast(line, 5, 5)
    end
    
    -- 3. INTERRUPTS
    if analysis.interruptsSuccessful > 0 or analysis.interruptsFailed > 0 then
         local h = self:CreateHeader(L["SECTION_INTERRUPTS"])
         AnchorToLast(h, 10, 20)
         
         local intText = string.format("Exitosos: |cff00ff00%d|r | Fallidos/Pisados: |cffff0000%d|r",
            analysis.interruptsSuccessful, analysis.interruptsFailed)
         local line = self:CreateTextLine(intText)
         AnchorToLast(line, 5, 5)
    end

    -- 4. CRONOLOGÍA DE MUERTES
    local hTimeline = self:CreateHeader(L["SECTION_TIMELINE"])
    AnchorToLast(hTimeline, 10, 20)
    
    for i, death in ipairs(analysis.deathOrder) do
        local classColor = death.class and RAID_CLASS_COLORS[death.class] or {r=1,g=1,b=1}
        local colorCode = string.format("|cff%02x%02x%02x", classColor.r*255, classColor.g*255, classColor.b*255)
        
        local deathLine = string.format("%d. [%.1fs] %s%s|r - %s", 
            i, death.time, colorCode, death.name, death.killedBy)
            
        local line = self:CreateTextLine(deathLine)
        AnchorToLast(line, 5, 5)
        
        if i >= 15 then 
            local more = self:CreateTextLine("... y " .. (#analysis.deathOrder - 15) .. " más")
            AnchorToLast(more, 5, 5)
            break 
        end
    end
    
    -- Ajustar altura final del contenido (estimada)
    -- Lo ideal sería obtener Bottom de lastElement relativo a Top de Content
    -- Pero lastElement:GetBottom() puede no estar listo.
    -- Usamos un timer o un valor seguro grande.
    self.Frame.content:SetHeight(800) -- Fallback seguro, el scroll lo maneja
end

function WA:CreateHeader(text)
    local h = self:AcquireElement("FontString")
    h:SetFontObject("GameFontNormal")
    h:SetText("|cffaaaaaa" .. text .. "|r")
    h:SetJustifyH("LEFT")
    h:SetWidth(400)
    return h
end

function WA:CreateTextLine(text)
    local line = self:AcquireElement("FontString")
    line:SetFontObject("GameFontNormalSmall")
    line:SetWidth(390)
    line:SetJustifyH("LEFT")
    line:SetText(text)
    return line
end

function WA:GetAnnouncementChannel()
    local zoneType = select(2, IsInInstance())
    if zoneType == "pvp" or zoneType == "arena" then
        return "BATTLEGROUND"
    elseif GetNumRaidMembers() > 0 then
        return "RAID"
    elseif GetNumPartyMembers() > 0 then
        return "PARTY"
    end
    return nil
end

function WA:AnnounceAnalysis()
    if not self.LastAnalysis then
        if S.Print then
            S:Print("|cffff0000[Sequito]|r No hay análisis disponible")
        else
            print("|cffff0000[Sequito]|r No hay análisis disponible")
        end
        return
    end
    
    local analysis = self.LastAnalysis
    local channel = self:GetAnnouncementChannel()
    
    local function send(msg)
        if not msg or msg == "" then return end
        if #msg > 240 then msg = msg:sub(1, 237) .. "..." end
        if channel then
            SendChatMessage(msg, channel)
        else
            if S.Print then S:Print(msg) else print(msg) end
        end
    end
    
    send("[Sequito] === ANÁLISIS DE WIPE ===")
    
    if analysis.firstDeath then
        send(string.format("Primera muerte: %s (%.1fs) - %s de %s",
            analysis.firstDeath.name or "Desconocido",
            analysis.firstDeath.time or 0,
            analysis.firstDeath.lastSpell or "Desconocido",
            analysis.firstDeath.killedBy or "Desconocido"))
    end
    
    if analysis.noConsumables and #analysis.noConsumables > 0 then
        local line = "Sin poción/healthstone: "
        for _, name in ipairs(analysis.noConsumables) do
            if #line + #name + 2 > 230 then
                send(line)
                line = "  " .. name
            else
                if line == "Sin poción/healthstone: " or line == "  " then
                    line = line .. name
                else
                    line = line .. ", " .. name
                end
            end
        end
        if line ~= "Sin poción/healthstone: " and line ~= "  " then
            send(line)
        end
    end
    
    -- Top Causas
    if analysis.causes and #analysis.causes > 0 then
        local top = {}
        for i = 1, math.min(3, #analysis.causes) do
            table.insert(top, string.format("%s (%d)", analysis.causes[i].name or "?", analysis.causes[i].count or 0))
        end
        send("Top Causas de Muerte: " .. table.concat(top, ", "))
    end
    
    send(string.format("Total muertes: %d - Interrupts: %d", 
        analysis.totalDeaths or 0, analysis.interruptsSuccessful or 0))
end

function WA:ClearCurrent()
    self.CurrentFight = {
        inCombat = false,
        startTime = 0,
        deaths = {},
        interrupts = {successful = {}, failed = {}},
        consumables = {},
        damage = {},
        healing = {}
    }
    self.LastAnalysis = nil
    print("|cff00ff00[Sequito]|r Análisis limpiado")
    self:Hide()
end

function WA:ShowHistory()
    if #self.FightHistory == 0 then
        print("|cffff0000[Sequito]|r No hay historial de wipes")
        return
    end
    
    print("|cff00ccff[Sequito]|r Historial de wipes:")
    for i, fight in ipairs(self.FightHistory) do
        local name = fight.encounterName or "Combate"
        print(string.format("  %d. %s - %d muertes (%.1fs)", 
            i, name, #fight.deaths, fight.duration or 0))
    end
end

function WA:Toggle()
    if not self.Frame then
        self:Initialize()
    end
    
    -- Check again after Initialize (module might be disabled)
    if not self.Frame then
        return
    end
    
    self.IsVisible = not self.IsVisible
    if self.IsVisible then
        self.Frame:Show()
        if self.LastAnalysis then
            self:UpdateDisplay()
        end
    else
        self.Frame:Hide()
    end
end

function WA:Show()
    if not self.Frame then
        self:Initialize()
    end
    self.IsVisible = true
    self.Frame:Show()
    if self.LastAnalysis then
        self:UpdateDisplay()
    end
end

function WA:Hide()
    if self.Frame then
        self.IsVisible = false
        self.Frame:Hide()
    end
end

-- Comando para análisis manual
function WA:Analyze()
    if self.CurrentFight and #self.CurrentFight.deaths > 0 then
        self:AnalyzeWipe()
        self:Show()
    elseif #self.FightHistory > 0 then
        -- Mostrar último wipe del historial
        self.CurrentFight = self.FightHistory[#self.FightHistory]
        self:AnalyzeWipe()
        self:Show()
    else
        print("|cffff0000[Sequito]|r No hay datos de wipe para analizar")
    end
end

-- Registrar configuración en ModuleConfig
if S.ModuleConfig then
    S.ModuleConfig:RegisterModule("WipeAnalyzer", {
        name = "Analizador de Wipes",
        icon = "Interface\\Icons\\Spell_Shadow_RitualOfSacrifice",
        description = "Analiza wipes de raid y muestra estadísticas de muertes y consumibles",
        category = "raid",
        options = {
            {key = "enabled", type = "checkbox", label = "Habilitar Wipe Analyzer", default = true},
            {key = "autoShow", type = "checkbox", label = "Mostrar automáticamente tras wipe", default = true},
            {key = "announceResults", type = "checkbox", label = "Anunciar análisis en banda/grupo", default = true},
            {key = "trackConsumables", type = "checkbox", label = "Verificar pociones y piedras de salud", default = true},
            {key = "trackInterrupts", type = "checkbox", label = "Rastrear interrupts", default = true},
            {key = "minFightDuration", type = "slider", label = "Duración mínima (segundos)", min = 5, max = 60, step = 5, default = 10},
        }
    })
end
