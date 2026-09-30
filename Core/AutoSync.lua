--[[
    Sequito - AutoSync Module
    Sistema de Sincronización Automática por Eventos
    Version: 8.0.0
    
    Este módulo maneja la sincronización automática de datos entre
    todos los miembros del grupo/raid usando mensajes de addon.
    
    Características:
    - Sync automático al entrar/salir de grupo
    - Basado en eventos (no polling) para eficiencia
    - Escala de 2 a 40+ jugadores
    - Compresión simple de datos
]]--

local addonName, S = ...
S.AutoSync = {}
local AS = S.AutoSync

-- Constantes
local SYNC_PREFIX = "SeqSync"
local SYNC_VERSION = 1
local THROTTLE_INTERVAL = 0.5 -- Segundos entre broadcasts

-- Variables locales
local lastBroadcast = 0
local raidData = {}
local isInGroup = false

-- ============================================
-- INICIALIZACIÓN
-- ============================================
function AS:Initialize()
    if self.initialized then return end
    self.initialized = true

    self:RegisterEvents()
    if RegisterAddonMessagePrefix then
        RegisterAddonMessagePrefix(SYNC_PREFIX)
    end
    
    -- Verificar si ya estamos en grupo
    self:CheckGroupStatus()
    
    S:Print("|cff00ff00AutoSync|r inicializado - Sincronización automática activa")
end

function AS:RegisterEvents()
    local eventFrame = CreateFrame("Frame")
    eventFrame:RegisterEvent("PARTY_MEMBERS_CHANGED") -- WotLK
    eventFrame:RegisterEvent("RAID_ROSTER_UPDATE") -- WotLK
    eventFrame:RegisterEvent("PLAYER_ENTERING_WORLD")
    eventFrame:RegisterEvent("PLAYER_TALENT_UPDATE")
    eventFrame:RegisterEvent("CHAT_MSG_ADDON")
    eventFrame:RegisterEvent("UNIT_SPELLCAST_SUCCEEDED")
    eventFrame:RegisterEvent("PLAYER_REGEN_ENABLED") -- Salir de combate
    eventFrame:RegisterEvent("GUILD_ROSTER_UPDATE")
    eventFrame:RegisterEvent("CHAT_MSG_LOOT")
    
    eventFrame:SetScript("OnEvent", function(_, event, ...)
        if event == "PARTY_MEMBERS_CHANGED" or event == "RAID_ROSTER_UPDATE" then
            AS:OnGroupChanged()
        elseif event == "PLAYER_ENTERING_WORLD" then
            if C_Timer and C_Timer.After then
                C_Timer.After(2, function() AS:OnLogin() end)
            else
                AS:OnLogin()
            end
        elseif event == "PLAYER_TALENT_UPDATE" then
            AS:OnTalentChange()
        elseif event == "CHAT_MSG_ADDON" then
            AS:OnAddonMessage(...)
        elseif event == "UNIT_SPELLCAST_SUCCEEDED" then
            AS:OnSpellCast(...)
        elseif event == "PLAYER_REGEN_ENABLED" then
            AS:OnCombatEnd()
        elseif event == "GUILD_ROSTER_UPDATE" then
            AS:OnGuildUpdate()
        elseif event == "CHAT_MSG_LOOT" then
            AS:OnLootMessage(...)
        end
    end)
    
    self.eventFrame = eventFrame
end

function AS:GetGroupChannel()
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

-- ============================================
-- DETECCIÓN DE GRUPO
-- ============================================
function AS:CheckGroupStatus()
    local wasInGroup = isInGroup
    isInGroup = (self:GetGroupChannel() ~= nil)
    
    if isInGroup and not wasInGroup then
        -- Acabamos de entrar a grupo
        self:OnJoinGroup()
    elseif not isInGroup and wasInGroup then
        -- Acabamos de salir de grupo
        self:OnLeaveGroup()
    end
    
    return isInGroup
end

function AS:OnGroupChanged()
    self:CheckGroupStatus()
    
    if isInGroup then
        -- Actualizar datos del raid
        self:UpdateRaidRoster()
        -- Broadcast nuestros datos
        self:BroadcastPlayerData()
    end
end

function AS:OnJoinGroup()
    S:Print("|cff00ff00AutoSync|r: Grupo detectado - Iniciando sincronización...")
    
    -- Limpiar datos antiguos
    wipe(raidData)
    
    -- Broadcast inicial con pequeño delay
    C_Timer.After(1, function()
        AS:BroadcastPlayerData()
        AS:RequestAllData()
    end)
    
    -- Notificar al ContextEngine
    if S.ContextEngine then
        S.ContextEngine:OnGroupJoined()
    end
end

function AS:OnLeaveGroup()
    S:Print("|cff00ff00AutoSync|r: Grupo abandonado")
    wipe(raidData)
    
    if S.ContextEngine then
        S.ContextEngine:OnGroupLeft()
    end
end

function AS:OnLogin()
    self:CheckGroupStatus()
    if isInGroup then
        self:OnJoinGroup()
    end
end

-- ============================================
-- DATOS DEL JUGADOR
-- ============================================
function AS:GetPlayerData()
    local _, class = UnitClass("player")
    local name = UnitName("player")
    local level = UnitLevel("player")
    
    -- Detectar spec/rol usando métodos correctos de Universal
    local spec = "UNKNOWN"
    local role = "DAMAGER"
    
    if S.Universal and S.Universal.GetSpec then
        spec = S.Universal:GetSpec() or "UNKNOWN"
    end
    
    if S.Universal and S.Universal.GetRole then
        role = S.Universal:GetRole(class, spec) or "DAMAGER"
    end
    
    -- Cooldowns importantes listos
    local cooldowns = self:GetImportantCooldowns()
    
    return {
        name = name,
        class = class,
        level = level,
        spec = spec,
        role = role,
        cooldowns = cooldowns,
        version = S.Version or "8.0.0",
        syncVersion = SYNC_VERSION
    }
end

function AS:GetImportantCooldowns()
    -- Lista de CDs importantes por clase
    local cds = {}
    
    if S.CooldownMonitor and S.CooldownMonitor.GetPlayerCooldowns then
        local playerCDs = S.CooldownMonitor:GetPlayerCooldowns()
        if playerCDs then
            for _, cd in ipairs(playerCDs) do
                table.insert(cds, {
                    spellId = cd.spellId,
                    ready = cd.ready,
                    expires = cd.expires or 0
                })
            end
        end
    end
    
    return cds
end

-- ============================================
-- BROADCAST DE DATOS
-- ============================================
function AS:BroadcastPlayerData()
    local channel = self:GetGroupChannel()
    if not channel then return end
    
    -- Throttle para evitar spam
    local now = GetTime()
    if now - lastBroadcast < THROTTLE_INTERVAL then
        return
    end
    lastBroadcast = now
    
    local data = self:GetPlayerData()
    local encoded = self:EncodeData(data)
    local payload = "DATA:" .. encoded
    if #payload > 240 then payload = payload:sub(1, 240) end
    if RegisterAddonMessagePrefix then RegisterAddonMessagePrefix(SYNC_PREFIX) end
    SendAddonMessage(SYNC_PREFIX, payload, channel)
end

function AS:RequestAllData()
    local channel = self:GetGroupChannel()
    if not channel then return end
    
    if RegisterAddonMessagePrefix then RegisterAddonMessagePrefix(SYNC_PREFIX) end
    SendAddonMessage(SYNC_PREFIX, "REQUEST", channel)
end

function AS:EncodeData(data)
    -- Formato simple: name|class|level|spec|role|version
    -- Los cooldowns se envían aparte si es necesario
    local parts = {
        data.name or "",
        data.class or "",
        data.level or 0,
        data.spec or "",
        data.role or "",
        data.version or ""
    }
    return table.concat(parts, "|")
end

function AS:DecodeData(encoded)
    local parts = {strsplit("|", encoded)}
    return {
        name = parts[1],
        class = parts[2],
        level = tonumber(parts[3]) or 0,
        spec = parts[4],
        role = parts[5],
        version = parts[6]
    }
end

-- ============================================
-- RECEPCIÓN DE DATOS
-- ============================================
function AS:OnAddonMessage(prefix, message, channel, sender)
    if prefix ~= SYNC_PREFIX then return end
    
    -- Ignorar nuestros propios mensajes
    if sender == UnitName("player") then return end
    
    local cmd, data = strsplit(":", message, 2)
    
    if cmd == "DATA" then
        self:ProcessPlayerData(sender, data)
    elseif cmd == "REQUEST" then
        -- Alguien pidió datos, respondemos
        self:BroadcastPlayerData()
    elseif cmd == "CD" then
        self:ProcessCooldownUpdate(sender, data)
    end
end

function AS:ProcessPlayerData(sender, encoded)
    local data = self:DecodeData(encoded)
    data.lastUpdate = GetTime()
    
    raidData[sender] = data
    
    -- Notificar a módulos interesados
    if S.CooldownMonitor and S.CooldownMonitor.OnPlayerDataReceived then
        S.CooldownMonitor:OnPlayerDataReceived(sender, data)
    end
    
    if S.RaidPanel and S.RaidPanel.OnPlayerDataReceived then
        S.RaidPanel:OnPlayerDataReceived(sender, data)
    end
end

function AS:ProcessCooldownUpdate(sender, data)
    -- Formato: spellId|ready|expires
    local parts = {strsplit("|", data)}
    local spellId = tonumber(parts[1])
    local ready = parts[2] == "1"
    local expires = tonumber(parts[3]) or 0
    
    if S.CooldownMonitor and S.CooldownMonitor.OnCooldownUpdate then
        S.CooldownMonitor:OnCooldownUpdate(sender, spellId, ready, expires)
    end
end

-- ============================================
-- EVENTOS DE JUEGO
-- ============================================
function AS:OnTalentChange()
    -- Spec cambió, broadcast nuevos datos
    C_Timer.After(0.5, function()
        AS:BroadcastPlayerData()
    end)
end

function AS:OnSpellCast(unit, _, spellId)
    if unit ~= "player" then return end
    if not isInGroup then return end
    
    -- Verificar si es un CD importante
    if S.CooldownMonitor and S.CooldownMonitor.IsImportantCooldown then
        if S.CooldownMonitor:IsImportantCooldown(spellId) then
            -- Broadcast que usamos un CD
            local channel = self:GetGroupChannel()
            if not channel then return end
            local start, duration = GetSpellCooldown(spellId)
            if start and duration then
                local expires = start + duration
                local payload = "CD:" .. spellId .. "|0|" .. expires
                if #payload > 240 then payload = payload:sub(1, 240) end
                if RegisterAddonMessagePrefix then RegisterAddonMessagePrefix(SYNC_PREFIX) end
                SendAddonMessage(SYNC_PREFIX, payload, channel)
            end
        end
    end
end

function AS:OnCombatEnd()
    -- Al salir de combate, actualizar estado de CDs
    if isInGroup then
        C_Timer.After(1, function()
            AS:BroadcastPlayerData()
        end)
    end
end

-- ============================================
-- ACTUALIZACIÓN DE ROSTER
-- ============================================
function AS:UpdateRaidRoster()
    local currentMembers = {}
    
    if GetNumRaidMembers() > 0 then
        for i = 1, GetNumRaidMembers() do
            local name = GetRaidRosterInfo(i)
            if name then
                currentMembers[name] = true
            end
        end
    else
        currentMembers[UnitName("player")] = true
        for i = 1, GetNumPartyMembers() do
            local name = UnitName("party" .. i)
            if name then
                currentMembers[name] = true
            end
        end
    end
    
    -- Limpiar jugadores que ya no están
    for name in pairs(raidData) do
        if not currentMembers[name] then
            raidData[name] = nil
        end
    end
end

-- ============================================
-- GUILD SYNC & LOOT
-- ============================================
function AS:OnGuildUpdate()
    if not IsInGuild() then return end
    
    -- Sincronizar notas de guild localmente
    -- SequitoDB.guildNotes = SequitoDB.guildNotes or {}
    -- local numGuildMembers = GetNumGuildMembers()
    -- for i = 1, numGuildMembers do
    --     local name, rank, rankIndex, level, class, zone, note, officernote, online, status, classFileName = GetGuildRosterInfo(i)
    --     if name then
    --         SequitoDB.guildNotes[name] = note
    --     end
    -- end
    -- (Comentado para no spamear DB si no se pide explicitamente, placeholder)
end

function AS:OnLootMessage(msg)
    -- Detectar loot épico?
    -- Placeholder
end

function AS:BroadcastLoot(itemLink, player, reason)
    local channel = self:GetGroupChannel()
    if not channel then return end
    -- LOOT:ItemLink|Player|Reason
    local msg = string.format("LOOT:%s|%s|%s", itemLink, player, reason or "Gained")
    if #msg > 240 then msg = msg:sub(1, 240) end
    if RegisterAddonMessagePrefix then RegisterAddonMessagePrefix(SYNC_PREFIX) end
    SendAddonMessage(SYNC_PREFIX, msg, channel)
end

-- ============================================
-- API PÚBLICA
-- ============================================
function AS:GetRaidData()
    return raidData
end

function AS:GetPlayerInfo(name)
    return raidData[name]
end

function AS:GetGroupSize()
    if GetNumRaidMembers() > 0 then
        return GetNumRaidMembers()
    elseif GetNumPartyMembers() > 0 then
        return GetNumPartyMembers() + 1
    end
    return 1
end

function AS:IsInGroup()
    return isInGroup
end

function AS:ForceSync()
    if isInGroup then
        self:BroadcastPlayerData()
        self:RequestAllData()
    end
end

-- Registrar en Sequito
S.AutoSync = AS
