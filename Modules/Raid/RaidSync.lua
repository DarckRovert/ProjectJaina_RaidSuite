--[[
    SEQUITO - Raid Synchronization (HiveMind)
    Sincronización de raid y comunicación addon-to-addon.
    Inspirado en NecrosisHiveMind.lua
]]--

local addonName, S = ...
S.RaidSync = {}
S.RaidSync.Prefix = "SEQUITO_SYNC"
S.RaidSync.RaidData = {} -- [PlayerName] = { class, spec, role, ready }
S.RaidSync.ChunkBuffer = {} -- [Sender] = { id, parts, count, total }

-- Helper para obtener configuración
function S.RaidSync:GetOption(key)
    if S.ModuleConfig then
        return S.ModuleConfig:GetValue("RaidSync", key)
    end
    return true
end

-- ===========================================================================
-- INICIALIZACIÓN
-- ===========================================================================
function S.RaidSync:Initialize()
    if self.initialized then return end
    if not self:GetOption("enabled") then
        return
    end
    self.initialized = true
    
    -- Registrar prefijo de addon
    if RegisterAddonMessagePrefix then
        RegisterAddonMessagePrefix(self.Prefix)
    end
    
    -- Frame de eventos
    local frame = CreateFrame("Frame")
    frame:RegisterEvent("CHAT_MSG_ADDON")
    frame:RegisterEvent("RAID_ROSTER_UPDATE")
    frame:RegisterEvent("PARTY_MEMBERS_CHANGED")
    frame:RegisterEvent("PLAYER_ENTERING_WORLD")
    
    frame:SetScript("OnEvent", function(self, event, ...)
        S.RaidSync:OnEvent(event, ...)
    end)
    
    print("|cFFFF00FFJaina|r: [RaidSync] Sistema de sincronización iniciado.")
end

function S.RaidSync:OnEvent(event, ...)
    if event == "CHAT_MSG_ADDON" then
        local prefix, msg, channel, sender = ...
        if prefix == self.Prefix then
            -- Ignorar mensajes propios
            if sender == UnitName("player") then return end
            self:ParseMessage(msg, sender)
        end
    elseif event == "RAID_ROSTER_UPDATE" or event == "PARTY_MEMBERS_CHANGED" then
        self:ScanRaid()
        self:BroadcastMyInfo()
    elseif event == "PLAYER_ENTERING_WORLD" then
        -- Delay para asegurar que todo esté cargado (WotLK compatible)
        if not self.pewFrame then
            self.pewFrame = CreateFrame("Frame")
        end
        self.pewFrame.timer = 0
        self.pewFrame:SetScript("OnUpdate", function(f, elapsed)
            f.timer = f.timer + elapsed
            if f.timer >= 2 then
                S.RaidSync:ScanRaid()
                S.RaidSync:BroadcastMyInfo()
                f:SetScript("OnUpdate", nil)
            end
        end)
    end
end

-- ===========================================================================
-- COMUNICACIÓN
-- ===========================================================================
function S.RaidSync:Broadcast(msg, targetChannel)
    -- Verificar si sync está habilitado
    if not self:GetOption("syncEnabled") then
        return
    end
    
    local channel = targetChannel
    if not channel then
        if IsInInstance then
            local inInstance, instanceType = IsInInstance()
            if inInstance and instanceType == "pvp" then
                channel = "BATTLEGROUND"
            end
        end
        if not channel then
            if GetNumRaidMembers() > 0 then
                channel = "RAID"
            elseif GetNumPartyMembers() > 0 then
                channel = "PARTY"
            elseif IsInGuild() then
                channel = "GUILD"
            end
        end
    end
    
    if channel then
        if #msg > 200 then
            self:SendLargeMessage(msg, channel)
        else
            SendAddonMessage(self.Prefix, msg, channel)
        end
    end
end

-- ===========================================================================
-- CHUNKING SYSTEM (Throttled for WoW 3.3.5a Stability)
-- ===========================================================================
function S.RaidSync:SendLargeMessage(data, channel)
    local msgID = string.format("%04x", math.random(0, 0xFFFF))
    local chunkSize = 200 -- Safe limit under 255 bytes
    local totalLen = #data
    local numChunks = math.ceil(totalLen / chunkSize)
    
    for i = 1, numChunks do
        local startIdx = (i - 1) * chunkSize + 1
        local endIdx = math.min(i * chunkSize, totalLen)
        local chunk = string.sub(data, startIdx, endIdx)
        
        -- Cmd: CHUNK:MsgID:Index:Total:Payload
        local payload = string.format("CHUNK:%s:%d:%d:%s", msgID, i, numChunks, chunk)
        if i == 1 then
            SendAddonMessage(self.Prefix, payload, channel)
        else
            -- Leaky-bucket delay (80ms spacing) to prevent Blizzard chat flood disconnect
            local delay = (i - 1) * 0.08
            C_Timer.After(delay, function()
                SendAddonMessage(S.RaidSync.Prefix, payload, channel)
            end)
        end
    end
end

function S.RaidSync:ProcessChunk(sender, payload)
    local msgID, index, total, chunkData = strsplit(":", payload, 4)
    index = tonumber(index)
    total = tonumber(total)
    
    if not msgID or not index or not total or not chunkData then return end
    
    local buffer = self.ChunkBuffer[sender]
    if not buffer or buffer.id ~= msgID then
        -- New message or overwritten
        buffer = { id = msgID, parts = {}, count = 0, total = total }
        self.ChunkBuffer[sender] = buffer
    end
    
    if not buffer.parts[index] then
        buffer.parts[index] = chunkData
        buffer.count = buffer.count + 1
        
        if buffer.count >= total then
            -- Reassemble
            local fullMsg = table.concat(buffer.parts)
            self.ChunkBuffer[sender] = nil -- Clear
            self:parseLogic(fullMsg, sender) -- Route to normal parser
        end
    end
end

function S.RaidSync:BroadcastMyInfo()
    if not S.Universal then return end
    
    local info = S.Universal:GetPlayerInfo()
    -- Formato: INFO:class:spec:role
    local msg = string.format("INFO:%s:%d:%s", info.class, info.spec, info.role)
    self:Broadcast(msg)
end

function S.RaidSync:ParseMessage(msg, sender)
    local cmd, payload = strsplit(":", msg, 2)
    
    if cmd == "CHUNK" then
        self:ProcessChunk(sender, payload)
        return
    end
    
    self:parseLogic(msg, sender)
end

function S.RaidSync:parseLogic(msg, sender)
    local cmd, payload = strsplit(":", msg, 2)

    if cmd == "INFO" then
        -- Payload: class:spec:role
        local class, spec, role = strsplit(":", payload)
        self:UpdateMemberInfo(sender, class, tonumber(spec), role)
    elseif cmd == "FOCUS" then
        if self:IsOfficer(sender) then
            self:OnFocusCommand(payload, sender)
        end
    elseif cmd == "ALPHA" then
        if self:IsOfficer(sender) then
            self:OnAlphaStrike(sender)
        end
    elseif cmd == "READY" then
        self:OnReadyCheck(payload, sender)
    elseif cmd == "STRAT" then
        if self:IsOfficer(sender) then
            self:OnBossStrat(payload, sender)
        end
    elseif cmd == "CONFIG" then
        if self:IsOfficer(sender) then
            self:OnRemoteConfig(payload, sender)
        else
            print("|cFFFF0000[Jaina] Intento de configuración no autorizada de: " .. sender .. "|r")
        end
    elseif cmd == "VETO" then
        if self:IsOfficer(sender) then
            self:OnVetoCommand(payload, sender)
        end
    elseif cmd == "PROFILE" then
        if self:IsOfficer(sender) then
            self:OnProfileReceived(payload, sender)
        end
    end
end

-- ===========================================================================
-- SEGURIDAD (HIVE MIND)
-- ===========================================================================
function S.RaidSync:IsOfficer(name)
    if not name then return false end

    -- En banda: verificar rango 2 (Líder) o 1 (Asistente/Oficial)
    local numRaid = GetNumRaidMembers()
    if numRaid > 0 then
        if name == UnitName("player") then
            return (IsRaidLeader() or IsRaidOfficer()) and true or false
        end
        for i = 1, numRaid do
            local n, rank = GetRaidRosterInfo(i)
            if n == name then
                return (rank and rank >= 1) and true or false
            end
        end
        return false
    end

    -- En grupo (Party): el líder es el oficial
    local numParty = GetNumPartyMembers()
    if numParty > 0 then
        if name == UnitName("player") then
            return (IsPartyLeader and IsPartyLeader()) and true or false
        end
        for i = 1, numParty do
            if UnitName("party" .. i) == name then
                return (UnitIsPartyLeader and UnitIsPartyLeader("party" .. i)) and true or false
            end
        end
        return false
    end

    -- En solitario (fuera de grupo, ej. pruebas locales)
    if name == UnitName("player") then
        return true
    end

    return false
end

function S.RaidSync:OnReadyCheck(payload, sender)
    if not sender then return end
    if not self.RaidData[sender] then
        self.RaidData[sender] = {
            class = "UNKNOWN",
            spec = 0,
            role = "UNKNOWN",
            hasJaina = true
        }
    end
    self.RaidData[sender].ready = (payload == "1" or payload == "READY" or payload == "true")
    if S.RaidSync.UpdateUI then
        S.RaidSync:UpdateUI()
    end
end

-- ===========================================================================
-- COMANDOS HIVE MIND
-- ===========================================================================

-- 1. REMOTE CONFIG & PROFILE SYNC
function S.RaidSync:BroadcastProfile()
    if not self:IsOfficer(UnitName("player")) then
        print("|cFFFF0000[Jaina] Solo Oficiales pueden transmitir su perfil.|r")
        return
    end
    
    -- Serialize Profile
    -- Simple serialization: key=value;key2=value2;...
    -- Limitation: Only supports top-level keys and simple values for now to avoid complexity
    local data = ""
    for k, v in pairs(S.db.profile) do
        if type(v) == "boolean" or type(v) == "number" or type(v) == "string" then
            data = data .. k .. "=" .. tostring(v) .. ";"
        end
    end
    
    self:Broadcast("PROFILE:" .. data)
    print("|cFF00FF00[Jaina] Perfil transmitido a la raid (Chunking activo).|r")
end

function S.RaidSync:OnProfileReceived(payload, sender)
    -- Popup asking to accept
    StaticPopupDialogs["SEQUITO_PROFILE_SYNC"] = {
        text = "|cFFFFD700[Perfil Recibido] " .. sender .. "|r quiere sobrescribir tu configuración.\n¿Aceptar?",
        button1 = "Aceptar",
        button2 = "Cancelar",
        OnAccept = function()
            S.RaidSync:ApplyProfile(payload)
        end,
        timeout = 0,
        whileDead = true,
        hideOnEscape = true,
    }
    StaticPopup_Show("SEQUITO_PROFILE_SYNC")
end

function S.RaidSync:ApplyProfile(data)
    local count = 0
    for key, value in string.gmatch(data, "([^=]+)=([^;]+);") do
        -- Restore types
        if value == "true" then value = true
        elseif value == "false" then value = false
        elseif tonumber(value) then value = tonumber(value)
        end
        
        S.db.profile[key] = value
        count = count + 1
    end
    print("|cFF00FF00[Jaina] Perfil aplicado exitosamente (" .. count .. " valores actualizados).|r")
    
    -- Reload UI suggestion
    StaticPopupDialogs["SEQUITO_RELOAD"] = {
        text = "Perfil aplicado. Es recomendable recargar la UI.",
        button1 = "Recargar",
        button2 = "Más tarde",
        OnAccept = function() ReloadUI() end,
        timeout = 0,
        whileDead = true,
        hideOnEscape = true,
    }
    StaticPopup_Show("SEQUITO_RELOAD")
end

function S.RaidSync:SendConfig(module, key, value)
    if not self:IsOfficer(UnitName("player")) then
        print("|cFFFF0000[Jaina] No tienes rango de Oficial para enviar configuraciones.|r")
        return
    end
    -- Payload format: Module|Key|Value
    local payload = string.format("%s|%s|%s", module, key, tostring(value))
    self:Broadcast("CONFIG:" .. payload)
    print("|cFF00FF00[Jaina] Configuración enviada: |r" .. payload)
end

function S.RaidSync:OnRemoteConfig(payload, sender)
    local module, key, value = strsplit("|", payload)
    
    -- Basic validation
    if module and key and value then
        if S.ModuleConfig then
            -- Convert value types if needed (simplification: bools and numbers)
            if value == "true" then value = true 
            elseif value == "false" then value = false
            elseif tonumber(value) then value = tonumber(value)
            end
            
            S.ModuleConfig:SetValue(module, key, value)
            print(string.format("|cFF00FFFF[Jaina] Configuración actualizada remotamente por %s: %s -> %s|r", sender, key, tostring(value)))
        end
    end
end

-- 2. BOSS STRATEGIES
function S.RaidSync:SendBossStrat(bossName, stratText)
    if not self:IsOfficer(UnitName("player")) then
         print("|cFFFF0000[Jaina] Solo Oficiales pueden enviar estrategias.|r")
         return
    end
    -- Payload: BossName|Text
    -- Text limit ~200 chars depending on channel. For v9.0 we assume short notes or need chunking.
    -- For now simple implementation.
    local payload = string.format("%s|%s", bossName, stratText)
    self:Broadcast("STRAT:" .. payload)
    print("|cFF00FF00[Jaina] Estrategia enviada para: " .. bossName)
end

function S.RaidSync:OnBossStrat(payload, sender)
    local bossName, stratText = strsplit("|", payload)
    
    -- Show Popup
    StaticPopupDialogs["SEQUITO_STRAT"] = {
        text = "|cFFFFD700[Estrategia] " .. bossName .. "|r\n\n" .. stratText .. "\n\n(Enviado por: " .. sender .. ")",
        button1 = "Entendido",
        timeout = 0,
        whileDead = true,
        hideOnEscape = true,
        preferredIndex = 3,
    }
    StaticPopup_Show("SEQUITO_STRAT")
    PlaySound("ReadyCheck")
end

-- 3. VETO SYSTEM
function S.RaidSync:SendVeto(targetName, reason)
     if not self:IsOfficer(UnitName("player")) then return end
     self:Broadcast("VETO:" .. targetName .. "|" .. (reason or "Sin razón"))
end

function S.RaidSync:OnVetoCommand(payload, sender)
    local targetName, reason = strsplit("|", payload)
    print(string.format("|cFFFF0000[SEQUITO] ALERTA DE VETO: %s ha sido marcado por %s. Razón: %s|r", targetName, sender, reason or "N/A"))
    PlaySound("RaidWarning")
    
    -- Add to internal blacklist DB if implemented
    if S.Blacklist then
        -- S.Blacklist:Add(targetName, reason, sender)
    end
end


-- ===========================================================================
-- ESCANEO DE RAID
-- ===========================================================================
function S.RaidSync:ScanRaid()
    self.RaidData = {}
    
    local numRaid = GetNumRaidMembers()
    local numParty = GetNumPartyMembers()
    
    if numRaid > 0 then
        for i = 1, numRaid do
            local name, _, _, _, _, class = GetRaidRosterInfo(i)
            if name then
                self.RaidData[name] = {
                    class = class,
                    spec = 0,
                    role = "UNKNOWN",
                    hasJaina = false
                }
            end
        end
    elseif numParty > 0 then
        for i = 1, numParty do
            local unit = "party" .. i
            if UnitExists(unit) then
                local name = UnitName(unit)
                local _, class = UnitClass(unit)
                self.RaidData[name] = {
                    class = class,
                    spec = 0,
                    role = "UNKNOWN",
                    hasJaina = false
                }
            end
        end
        -- Añadir al jugador
        local myName = UnitName("player")
        local _, myClass = UnitClass("player")
        self.RaidData[myName] = {
            class = myClass,
            spec = S.Universal and S.Universal:GetSpec() or 1,
            role = S.PlayerRole or "DPS",
            hasJaina = true
        }
    end
end

function S.RaidSync:UpdateMemberInfo(name, class, spec, role)
    if not self.RaidData[name] then
        self.RaidData[name] = {}
    end
    
    self.RaidData[name].class = class
    self.RaidData[name].spec = spec
    self.RaidData[name].role = role
    self.RaidData[name].hasJaina = true
    
    -- Actualizar UI si existe
    if S.RaidSync.UpdateUI then
        S.RaidSync:UpdateUI()
    end
end

-- ===========================================================================
-- COMPOSICIÓN DE RAID
-- ===========================================================================
function S.RaidSync:GetRaidComposition()
    local comp = {
        tanks = {},
        healers = {},
        dps = {},
        unknown = {},
        total = 0,
        byClass = {}
    }
    
    for name, data in pairs(self.RaidData) do
        comp.total = comp.total + 1
        
        -- Por rol
        if data.role == "TANK" then
            table.insert(comp.tanks, name)
        elseif data.role == "HEALER" then
            table.insert(comp.healers, name)
        elseif data.role == "DPS" then
            table.insert(comp.dps, name)
        else
            table.insert(comp.unknown, name)
        end
        
        -- Por clase
        if data.class then
            if not comp.byClass[data.class] then
                comp.byClass[data.class] = {}
            end
            table.insert(comp.byClass[data.class], name)
        end
    end
    
    return comp
end

function S.RaidSync:PrintRaidComposition()
    local comp = self:GetRaidComposition()
    
    print("|cFFFF00FF=== Jaina: Composición de Raid ===")
    print(string.format("|cFFFFFFFFTotal: %d jugadores|r", comp.total))
    print(string.format("|cFF00FF00Tanks: %d|r - %s", #comp.tanks, table.concat(comp.tanks, ", ")))
    print(string.format("|cFF00FFFFHealers: %d|r - %s", #comp.healers, table.concat(comp.healers, ", ")))
    print(string.format("|cFFFF0000DPS: %d|r - %s", #comp.dps, table.concat(comp.dps, ", ")))
    
    if #comp.unknown > 0 then
        print(string.format("|cFF888888Sin Jaina: %d|r - %s", #comp.unknown, table.concat(comp.unknown, ", ")))
    end
    
    print("|cFFFF00FF--- Por Clase ---|r")
    for class, players in pairs(comp.byClass) do
        local r, g, b = S.Universal:GetClassColor(class)
        print(string.format("|cFF%02x%02x%02x%s (%d)|r: %s", 
            r*255, g*255, b*255, class, #players, table.concat(players, ", ")))
    end
end

-- ===========================================================================
-- COMANDOS TÁCTICOS
-- ===========================================================================
function S.RaidSync:SendFocus(targetName)
    if not self:IsOfficer(UnitName("player")) then
        print("|cFFFF0000[Jaina]|r Solo Líderes u Oficiales pueden ordenar FOCUS táctico.")
        return
    end
    if not targetName then
        targetName = UnitName("target")
    end
    if not targetName then
        print("|cFFFF0000[Jaina]|r No hay objetivo seleccionado.")
        return
    end
    
    self:Broadcast("FOCUS:" .. targetName)
    print("|cFFFF00FF[Jaina]|r Orden de FOCUS enviada: " .. targetName)
end

function S.RaidSync:SendAlphaStrike()
    if not self:IsOfficer(UnitName("player")) then
        print("|cFFFF0000[Jaina]|r Solo Líderes u Oficiales pueden ordenar ALPHA STRIKE.")
        return
    end
    self:Broadcast("ALPHA:NOW")
    print("|cFFFF00FF[Jaina]|r ¡ALPHA STRIKE enviado!")
end

function S.RaidSync:OnAlphaStrike(sender)
    print(string.format("|cFFFFD700[SEQUITO] ¡¡ALPHA STRIKE!! ordenado por %s|r", sender))
    PlaySound("RaidWarning")
    
    -- Efecto visual si existe
    if S.FX and S.FX.PlayAlphaStrike then
        S.FX:PlayAlphaStrike()
    end
    
    if S.SendMessage then
        S:SendMessage("ALPHA_STRIKE_CALLED")
    end
end

-- ===========================================================================
-- FRAME DE ALERTA VISUAL
-- ===========================================================================
-- ===========================================================================
-- FRAME DE ALERTA VISUAL (TACTICAL DISPLAY)
-- ===========================================================================
function S.RaidSync:CreateAlertFrame()
    local f = CreateFrame("Frame", "JainaTacticalFrame", UIParent)
    f:SetSize(400, 100)
    f:SetPoint("TOP", UIParent, "TOP", 0, -180) -- Un poco mas abajo que los errores
    f:Hide()
    
    -- Fondo semi-transparente para darle peso
    f.bg = f:CreateTexture(nil, "BACKGROUND")
    f.bg:SetAllPoints()
    f.bg:SetTexture("Interface\\Buttons\\WHITE8X8")
    f.bg:SetVertexColor(0, 0, 0, 0.6)
    f.bg:SetBlendMode("MOD") -- Efecto oscurecedor
    
    -- Texto Gigante
    f.text = f:CreateFontString(nil, "OVERLAY", "GameFontNormalHuge")
    f.text:SetPoint("CENTER", f, "CENTER", 20, 0)
    f.text:SetTextColor(1, 0.1, 0.1) -- Rojo Intenso
    f.text:SetShadowColor(0, 0, 0)
    f.text:SetShadowOffset(2, -2)
    
    -- Icono de Calavera (Skull)
    f.icon = f:CreateTexture(nil, "OVERLAY")
    f.icon:SetSize(50, 50)
    f.icon:SetPoint("RIGHT", f.text, "LEFT", -10, 0)
    f.icon:SetTexture("Interface\\TargetingFrame\\UI-RaidTargetingIcon_8")
    
    -- Oscilador nativo 3.3.5a (sin AnimationGroup/BOUNCE)
    f.flashTimer = 0
    
    self.AlertFrame = f
end

function S.RaidSync:ShowFocusAlert(targetName, sender)
    if not self.AlertFrame then
        self:CreateAlertFrame()
    end
    
    local f = self.AlertFrame
    f.text:SetText("MATAR: " .. (targetName or "TARGET"))
    f:Show()
    f.flashTimer = 0
    
    -- Oscilador de parpadeo: math.sin sin dependencia de AnimationGroup
    f:SetScript("OnUpdate", function(frame, elapsed)
        frame.flashTimer = frame.flashTimer + elapsed
        local sine = (math.sin(frame.flashTimer * 5) + 1) / 2
        frame:SetAlpha(0.4 + (sine * 0.6))
    end)
    
    -- Sonido de Alerta de Raid
    PlaySound("RaidWarning")
    
    -- Auto-ocultar tras 6 segundos usando ticker nativo
    local hideFrame = CreateFrame("Frame")
    hideFrame.elapsed = 0
    hideFrame:SetScript("OnUpdate", function(self, elapsed)
        self.elapsed = self.elapsed + elapsed
        if self.elapsed >= 6 then
            f:Hide()
            f:SetScript("OnUpdate", nil)
            self:SetScript("OnUpdate", nil)
        end
    end)
end

-- Registrar módulo en ModuleConfig
if S.ModuleConfig then
    S.ModuleConfig:RegisterModule("RaidSync", {
        name = "Raid Sync",
        description = "Sincronización de raid y comunicación addon-to-addon",
        category = "raid",
        icon = "Interface\\Icons\\Spell_Holy_PrayerOfHealing",
        options = {
            {key = "enabled", type = "checkbox", label = "Habilitar Raid Sync", default = true},
            {key = "broadcastInfo", type = "checkbox", label = "Transmitir información de spec/rol", default = true},
            {key = "showAlerts", type = "checkbox", label = "Mostrar alertas tácticas", default = true},
            {key = "syncCooldowns", type = "checkbox", label = "Sincronizar cooldowns", default = true},
        }
    })
end

