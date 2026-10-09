--[[
    ProjectJaina_RaidSuite -- EcosystemBridge
    Puente de Integracion con el Ecosistema Project Jaina

    Conecta RaidSuite con los otros addons:
    1. -> Jaina_BattlePass: reporta logros de combate como progreso de misiones.
    2. -> ProjectJaina_GameModes: lee el modo activo y adapta alertas defensivas.

    PROTOCOLO: BP_QUEST_PROGRESS:<questId>:<delta>  (< 255 bytes, WHISPER)
    COMPATIBILIDAD: WoW 3.3.5a (Build 12340) | Lua 5.1 puro
    Copyright (c) 2026 DarckRovert (Ingame: Elnazzareno) & Antigravity (Mythos 5)
]]--

local addonName, S = ...
S.EcosystemBridge = {}
local Bridge = S.EcosystemBridge

-- IDs de misiones BattlePass que RaidSuite puede alimentar
local BP_QUEST = {
    DUNGEON_DAILY     = 1,   -- Mazmorra Diaria (+250 XP)
    RAID_WEEKLY       = 101, -- Azote de Bandas (3 jefes, +650 XP)
    ECO_RAID_CLEAR    = 201, -- Guardián de Banda (1 estancia de raid, +400 XP)
    ECO_DUNGEON_3     = 202, -- Mazmorrista del Andino (3 mazmorras semanales, +350 XP)
    ECO_HARDCORE_RAID = 203, -- Superviviente Hardcore (1 raid en modo HC sin morir, +750 XP)
}
local REPORT_COOLDOWN = 30

local lastReportTime = {}
local bossKillCount  = 0
local dungeonDone    = false

-- ============================================================
-- SECCION 1: PUENTE -> ProjectJaina_GameModes
-- ============================================================

--- Devuelve el modo de juego activo: NORMAL | HARDCORE | IRONMAN
function Bridge:GetPlayerGameMode()
    local db = ProjectJaina_GameModes_CharDB or ProjectJaina_GameModes_CharDB
    if db and db.hasSelectedMode and db.selectedMode then
        local mode = db.selectedMode
        if mode == "HARDCORE" or mode == "IRONMAN" or mode == "NORMAL" then
            return mode
        end
    end
    return "NORMAL"
end

--- Devuelve true si el jugador esta en Hardcore o Ironman.
function Bridge:IsHighRiskMode()
    local mode = self:GetPlayerGameMode()
    return mode == "HARDCORE" or mode == "IRONMAN"
end

--- Etiqueta con color para UI.
function Bridge:GetGameModeBadge()
    local mode = self:GetPlayerGameMode()
    if mode == "HARDCORE" then return "|cFFFF3333[HARDCORE]|r"
    elseif mode == "IRONMAN" then return "|cFFFF9900[IRONMAN]|r"
    end
    return "|cFF888888[Normal]|r"
end

-- ============================================================
-- SECCION 2: PUENTE -> Jaina_BattlePass
-- ============================================================

--- Envia progreso de mision al servidor BattlePass (WHISPER, < 255 bytes).
function Bridge:ReportQuestProgress(questId, delta, reason)
    if type(questId) ~= "number" or questId < 1 then return end
    delta = tonumber(delta) or 1

    local now = GetTime()
    if lastReportTime[questId] and (now - lastReportTime[questId]) < REPORT_COOLDOWN then
        return
    end
    lastReportTime[questId] = now

    local payload = string.format("BP_QUEST_PROGRESS:%d:%d", questId, delta)
    if #payload > 240 then return end

    local playerName = UnitName("player")
    if not playerName or playerName == "" or playerName == UNKNOWNOBJECT then return end

    if RegisterAddonMessagePrefix then RegisterAddonMessagePrefix("WP_BP") end
    SendAddonMessage("WP_BP", payload, "WHISPER", playerName)

    if S.Config and S.Config.Debug then
        S:Print(string.format("|cFF88FF88[EcoBridge]|r Quest %d +%d (%s)", questId, delta, reason or ""))
    end
end

-- ============================================================
-- SECCION 3: EVENTOS DE COMBATE
-- ============================================================

local bridgeFrame = CreateFrame("Frame", "WPRaidSuite_BridgeFrame")
Bridge.frame = bridgeFrame

function Bridge:Initialize()
    if self.initialized then return end
    self.initialized = true

    bridgeFrame:RegisterEvent("PLAYER_ENTERING_WORLD")
    bridgeFrame:RegisterEvent("ZONE_CHANGED_NEW_AREA")
    bridgeFrame:RegisterEvent("LFG_COMPLETION_REWARD")
    bridgeFrame:RegisterEvent("PLAYER_REGEN_ENABLED")

    -- Integración con CLEU centralizado de Jaina (WotLK 3.3.5a)
    if S.CLEU and S.CLEU.Register then
        S.CLEU:Register("UNIT_DIED", function(...)
            Bridge:OnUnitDied(...)
        end)
    end
end

bridgeFrame:SetScript("OnEvent", function(_, event, ...)
    if event == "PLAYER_ENTERING_WORLD" then
        Bridge:OnEnteringWorld()
    elseif event == "ZONE_CHANGED_NEW_AREA" then
        Bridge:OnZoneChanged()
    elseif event == "LFG_COMPLETION_REWARD" then
        Bridge:NotifyDungeonComplete()
    elseif event == "PLAYER_REGEN_ENABLED" then
        Bridge:OnCombatEnd()
    end
end)

function Bridge:OnEnteringWorld()
    dungeonDone   = false
    bossKillCount = 0
    if S.Config and S.Config.Debug then
        S:Print("[EcoBridge] Modo: " .. self:GetGameModeBadge())
    end
end

function Bridge:OnZoneChanged()
    local inInstance, instanceType = IsInInstance()
    -- Si salimos de la mazmorra o cambiamos de mapa, permitir cómputo de la siguiente
    if not inInstance or instanceType ~= "party" then
        dungeonDone = false
    end
end

function Bridge:OnUnitDied(...)
    local timestamp, subEvent, sourceGUID, sourceName, sourceFlags, destGUID, destName, destFlags = ...
    local inInstance, instanceType = IsInInstance()
    if not inInstance or not destFlags then return end

    -- Verificar si el objetivo abatido era un NPC hostil dentro de la estancia
    local isHostileNPC = (bit.band(destFlags, COMBATLOG_OBJECT_TYPE_NPC) > 0) and
                         (bit.band(destFlags, COMBATLOG_OBJECT_REACTION_HOSTILE) > 0)

    if isHostileNPC and instanceType == "raid" then
        if S.WipeAnalyzer and S.WipeAnalyzer.lastEncounterWon then
            S.WipeAnalyzer.lastEncounterWon = false
            self:NotifyBossKill(destName or "Jefe de Banda")
        end
    end
end

function Bridge:OnCombatEnd()
    local inInstance, instanceType = IsInInstance()
    if not inInstance then return end

    if instanceType == "raid" then
        local isBossKill = false
        if S.WipeAnalyzer and S.WipeAnalyzer.lastEncounterWon then
            isBossKill = S.WipeAnalyzer.lastEncounterWon
            S.WipeAnalyzer.lastEncounterWon = false
        end
        if isBossKill then
            self:NotifyBossKill("Jefe de Banda")
        end
    elseif instanceType == "party" and not dungeonDone then
        if S.DungeonTimer and S.DungeonTimer.lastRunCompleted then
            S.DungeonTimer.lastRunCompleted = false
            self:NotifyDungeonComplete()
        end
    end
end

-- ============================================================
-- SECCION 4: ADAPTACIONES POR MODO DE JUEGO
-- ============================================================

--- Aplica ajustes de comportamiento segun el modo de juego activo.
--- Llamado desde RaidSuite_Init.lua en PLAYER_ENTERING_WORLD.
function Bridge:ApplyGameModeAdaptations()
    local mode = self:GetPlayerGameMode()
    if mode == "HARDCORE" or mode == "IRONMAN" then
        if S.DefensiveAlerts then
            S.DefensiveAlerts.aggressionLevel = 2
        end
        if S.WipeAnalyzer and S.WipeAnalyzer.SetAutoRecord then
            S.WipeAnalyzer:SetAutoRecord(true)
        end
        S:Print(string.format(
            "|cFFFFD100[ProjectJaina_RaidSuite]|r Modo: %s -- Alertas reforzadas.",
            self:GetGameModeBadge()
        ))
    end
end

-- ============================================================
-- API PUBLICA (para modulos internos)
-- ============================================================

--- Notifica al bridge un kill de jefe confirmado por un modulo externo.
function Bridge:NotifyBossKill(bossName)
    bossKillCount = bossKillCount + 1
    -- Misión 101 se procesa autoritativamente en servidor; se notifica únicamente el ecosistema
    self:ReportQuestProgress(BP_QUEST.ECO_RAID_CLEAR, 1, "Raid encounter: " .. (bossName or "unknown"))
    if self:IsHighRiskMode() then
        self:ReportQuestProgress(BP_QUEST.ECO_HARDCORE_RAID, 1, "HC Raid: " .. (bossName or "unknown"))
    end
end

--- Notifica al bridge que se completo una mazmorra (idempotente).
function Bridge:NotifyDungeonComplete()
    if dungeonDone then return end
    dungeonDone = true
    -- Misión 1 se procesa autoritativamente en servidor; se notifica únicamente el ecosistema
    self:ReportQuestProgress(BP_QUEST.ECO_DUNGEON_3, 1, "Weekly Dungeon +1")
end

S.EcosystemBridge = Bridge
Bridge:Initialize()
