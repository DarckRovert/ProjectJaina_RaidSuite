--[[
    WoWPeru_RaidSuite -- EcosystemBridge
    Puente de Integracion con el Ecosistema WoW Peru

    Conecta RaidSuite con los otros addons:
    1. -> WoWPeru_BattlePass: reporta logros de combate como progreso de misiones.
    2. -> WoWPeru_GameModes: lee el modo activo y adapta alertas defensivas.

    PROTOCOLO: BP_QUEST_PROGRESS:<questId>:<delta>  (< 255 bytes, WHISPER)
    COMPATIBILIDAD: WoW 3.3.5a (Build 12340) | Lua 5.1 puro
    Copyright (c) 2026 DarckRovert (Ingame: Elnazzareno) & WoW Peru Team
]]--

local addonName, S = ...
S.EcosystemBridge = {}
local Bridge = S.EcosystemBridge

-- IDs de misiones BattlePass que RaidSuite puede alimentar
local BP_QUEST = {
    DUNGEON_DAILY = 1,   -- Mazmorra Diaria
    RAID_WEEKLY   = 101, -- Azote de Bandas (3 jefes)
}
local REPORT_COOLDOWN = 30

local lastReportTime = {}
local bossKillCount  = 0
local dungeonDone    = false

-- ============================================================
-- SECCION 1: PUENTE -> WoWPeru_GameModes
-- ============================================================

--- Devuelve el modo de juego activo: NORMAL | HARDCORE | IRONMAN
function Bridge:GetPlayerGameMode()
    if WoWPeru_GameModes_CharDB
       and WoWPeru_GameModes_CharDB.hasSelectedMode
       and WoWPeru_GameModes_CharDB.selectedMode then
        local mode = WoWPeru_GameModes_CharDB.selectedMode
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
-- SECCION 2: PUENTE -> WoWPeru_BattlePass
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

bridgeFrame:RegisterEvent("PLAYER_ENTERING_WORLD")
bridgeFrame:RegisterEvent("CHAT_MSG_COMBAT_HOSTILE_DEATH")
bridgeFrame:RegisterEvent("CHAT_MSG_ADDON")

bridgeFrame:SetScript("OnEvent", function(_, event, ...)
    if event == "PLAYER_ENTERING_WORLD" then
        Bridge:OnEnteringWorld()
    elseif event == "CHAT_MSG_COMBAT_HOSTILE_DEATH" then
        Bridge:OnCombatDeath(...)
    elseif event == "CHAT_MSG_ADDON" then
        Bridge:OnAddonMessage(...)
    end
end)

function Bridge:OnEnteringWorld()
    dungeonDone   = false
    bossKillCount = 0
    if S.Config and S.Config.Debug then
        S:Print("[EcoBridge] Modo: " .. self:GetGameModeBadge())
    end
end

function Bridge:OnCombatDeath(msg)
    if not msg then return end
    local inInstance, instanceType = IsInInstance()
    if not inInstance then return end

    if instanceType == "raid" then
        local isBossKill = false
        if S.WipeAnalyzer and S.WipeAnalyzer.lastEncounterWon then
            isBossKill = S.WipeAnalyzer.lastEncounterWon
            S.WipeAnalyzer.lastEncounterWon = false
        end
        if isBossKill then
            bossKillCount = bossKillCount + 1
            self:ReportQuestProgress(BP_QUEST.RAID_WEEKLY, 1, "Boss kill #" .. bossKillCount)
            if self:IsHighRiskMode() then
                self:ReportQuestProgress(BP_QUEST.RAID_WEEKLY, 1, "HC bonus")
            end
        end
    elseif instanceType == "party" and not dungeonDone then
        if S.DungeonTimer and S.DungeonTimer.lastRunCompleted then
            dungeonDone = true
            S.DungeonTimer.lastRunCompleted = false
            self:ReportQuestProgress(BP_QUEST.DUNGEON_DAILY, 1, "Dungeon complete")
        end
    end
end

function Bridge:OnAddonMessage(prefix, message, channel, sender)
    if prefix ~= "WP_BP" then return end
    if WoWPeru_BattlePass and WoWPeru_BattlePass.OnAddonMessage then
        WoWPeru_BattlePass:OnAddonMessage(prefix, message, channel, sender)
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
            "|cFFFFD100[WoWPeru_RaidSuite]|r Modo: %s -- Alertas reforzadas.",
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
    self:ReportQuestProgress(BP_QUEST.RAID_WEEKLY, 1, "Boss: " .. (bossName or "unknown"))
    if self:IsHighRiskMode() then
        self:ReportQuestProgress(BP_QUEST.RAID_WEEKLY, 1, "HC bonus")
    end
end

--- Notifica al bridge que se completo una mazmorra (idempotente).
function Bridge:NotifyDungeonComplete()
    if dungeonDone then return end
    dungeonDone = true
    self:ReportQuestProgress(BP_QUEST.DUNGEON_DAILY, 1, "Dungeon complete")
end

S.EcosystemBridge = Bridge