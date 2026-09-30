--[[
    Sequito - ContextEngine Module
    Motor de Contexto para Ventanas Automáticas
    Version: 8.0.0
    
    Este módulo detecta el contexto actual del jugador y muestra
    automáticamente las ventanas relevantes sin intervención manual.
]]--

local addonName, S = ...
S.ContextEngine = {}
local CE = S.ContextEngine

-- Estados de contexto
local CONTEXT = {
    SOLO = "solo",
    PARTY = "party", 
    RAID = "raid",
    BATTLEGROUND = "bg",
    ARENA = "arena",
    DUNGEON = "dungeon"
}

-- Variables locales
local currentContext = CONTEXT.SOLO
local shownWindows = {}
local registeredTriggers = {}

-- ============================================
-- INICIALIZACIÓN
-- ============================================
function CE:Initialize()
    if self.initialized then return end
    self.initialized = true

    self:RegisterEvents()
    self:RegisterDefaultTriggers()
    S:Print("|cff00ff00ContextEngine|r inicializado - Ventanas automáticas activas")
end

function CE:RegisterEvents()
    local frame = CreateFrame("Frame")
    frame:RegisterEvent("ZONE_CHANGED_NEW_AREA")
    frame:RegisterEvent("PLAYER_ENTERING_WORLD")
    frame:RegisterEvent("PARTY_MEMBERS_CHANGED")
    frame:RegisterEvent("RAID_ROSTER_UPDATE")
    frame:RegisterEvent("LOOT_OPENED")
    frame:RegisterEvent("READY_CHECK")
    frame:RegisterEvent("PLAYER_DEAD")
    -- NOTA: ENCOUNTER_START/END no existen en WotLK 3.3.5a
    frame:RegisterEvent("CHAT_MSG_ADDON")
    
    frame:SetScript("OnEvent", function(_, event, ...)
        CE:OnEvent(event, ...)
    end)
    
    self.eventFrame = frame
end

function CE:OnEvent(event, ...)
    if event == "ZONE_CHANGED_NEW_AREA" or event == "PLAYER_ENTERING_WORLD" or event == "PARTY_MEMBERS_CHANGED" or event == "RAID_ROSTER_UPDATE" then
        self:DetectContext()
    elseif event == "LOOT_OPENED" then
        self:OnLootOpened()
    elseif event == "READY_CHECK" then
        self:OnReadyCheck(...)
    elseif event == "PLAYER_DEAD" then
        self:OnPlayerDead()
    elseif event == "CHAT_MSG_ADDON" then
        self:OnAddonMessage(...)
    end
end

-- ============================================
-- DETECCIÓN DE CONTEXTO
-- ============================================
function CE:DetectContext()
    local oldContext = currentContext
    
    -- Detectar tipo de instancia
    local inInstance, instanceType = IsInInstance()
    
    if inInstance then
        if instanceType == "pvp" then
            currentContext = CONTEXT.BATTLEGROUND
        elseif instanceType == "arena" then
            currentContext = CONTEXT.ARENA
        elseif instanceType == "party" then
            currentContext = CONTEXT.DUNGEON
        elseif instanceType == "raid" then
            currentContext = CONTEXT.RAID
        else
            currentContext = CONTEXT.DUNGEON
        end
    elseif GetNumRaidMembers() > 0 then
        currentContext = CONTEXT.RAID
    elseif GetNumPartyMembers() > 0 then
        currentContext = CONTEXT.PARTY
    else
        currentContext = CONTEXT.SOLO
    end
    
    -- Si cambió el contexto, actuar
    if oldContext ~= currentContext then
        self:OnContextChanged(oldContext, currentContext)
    end
end

function CE:OnContextChanged(oldContext, newContext)
    S:Print("|cff00ff00Contexto|r: " .. (oldContext or "nil") .. " → " .. newContext)
    
    if S.SendMessage then
        S:SendMessage("CONTEXT_CHANGED", newContext, oldContext)
    end
    
    -- Ocultar ventanas del contexto anterior (si aplica)
    if oldContext == CONTEXT.RAID and newContext ~= CONTEXT.RAID then
        self:AutoHideRaidWindows()
    end
    
    -- Mostrar ventanas del nuevo contexto
    if newContext == CONTEXT.RAID then
        self:AutoShowRaidWindows()
        if S.PetManager and S.PetManager.CheckPetTauntInGroup then
            C_Timer.After(2, function() S.PetManager:CheckPetTauntInGroup() end)
        end
    elseif newContext == CONTEXT.PARTY or newContext == CONTEXT.DUNGEON then
        self:AutoShowPartyWindows()
        if S.PetManager and S.PetManager.CheckPetTauntInGroup then
            C_Timer.After(2, function() S.PetManager:CheckPetTauntInGroup() end)
        end
    elseif newContext == CONTEXT.BATTLEGROUND or newContext == CONTEXT.ARENA then
        self:AutoShowPvPWindows()
    end
end

-- ============================================
-- AUTO-SHOW VENTANAS POR CONTEXTO
-- ============================================
function CE:AutoShowRaidWindows()
    -- Mostrar CooldownMonitor si está habilitado
    if S.CooldownMonitor and self:IsModuleEnabled("CooldownMonitor") then
        self:ShowWindow("CooldownMonitor", function()
            if S.CooldownMonitor.Show then
                S.CooldownMonitor:Show()
            elseif S.CooldownMonitor.Frame then
                S.CooldownMonitor.Frame:Show()
            elseif S.CooldownMonitor.frame then
                S.CooldownMonitor.frame:Show()
            end
        end)
    end
    
    -- Mostrar RaidPanel si está habilitado
    if S.RaidPanel and self:IsModuleEnabled("RaidPanel") then
        self:ShowWindow("RaidPanel", function()
            if S.RaidPanel.Show then
                S.RaidPanel:Show()
            elseif S.RaidPanel.frame then
                S.RaidPanel.frame:Show()
            end
        end)
    end
end

function CE:AutoShowPartyWindows()
    -- En party/dungeon, mostrar PullGuide táctico
    if S.PullGuide and self:IsModuleEnabled("PullGuide") then
        self:ShowWindow("PullGuide", function()
            if S.PullGuide.Show then
                S.PullGuide:Show()
            elseif S.PullGuide.Frame then
                S.PullGuide.Frame:Show()
            end
        end)
    end
end

function CE:AutoShowPvPWindows()
    -- PvP específico: FocusFire y TrinketTracker
    if S.FocusFire and self:IsModuleEnabled("FocusFire") then
        self:ShowWindow("FocusFire", function()
            if S.FocusFire.Show then
                S.FocusFire:Show()
            elseif S.FocusFire.Frame then
                S.FocusFire.Frame:Show()
            elseif S.FocusFire.frame then
                S.FocusFire.frame:Show()
            end
        end)
    end
    if S.TrinketTracker and self:IsModuleEnabled("TrinketTracker") then
        self:ShowWindow("TrinketTracker", function()
            if S.TrinketTracker.Show then
                S.TrinketTracker:Show()
            elseif S.TrinketTracker.Frame then
                S.TrinketTracker.Frame:Show()
            end
        end)
    end
end

function CE:AutoHideRaidWindows()
    -- Al salir de raid, ocultar ventanas de raid
    if S.CooldownMonitor then
        if S.CooldownMonitor.Frame then
            S.CooldownMonitor.Frame:Hide()
        elseif S.CooldownMonitor.frame then
            S.CooldownMonitor.frame:Hide()
        end
    end
    if S.RaidPanel then
        if S.RaidPanel.Frame then
            S.RaidPanel.Frame:Hide()
        elseif S.RaidPanel.frame then
            S.RaidPanel.frame:Hide()
        end
    end
    if S.PullGuide and S.PullGuide.Frame then
        S.PullGuide.Frame:Hide()
    end
    if S.LootCouncil and S.LootCouncil.frame then
        S.LootCouncil.frame:Hide()
    end
end

-- ============================================
-- TRIGGERS POR EVENTO
-- ============================================
function CE:OnLootOpened()
    -- Verificar si hay loot épico
    local hasEpic = false
    for i = 1, GetNumLootItems() do
        local _, _, _, quality = GetLootSlotInfo(i)
        if quality and quality >= 4 then -- 4 = Epic
            hasEpic = true
            break
        end
    end
    
    -- Mostrar LootCouncil si hay épico Y estamos en raid
    if hasEpic and currentContext == CONTEXT.RAID then
        if S.LootCouncil and self:IsModuleEnabled("LootCouncil") then
            self:ShowWindow("LootCouncil", function()
                if S.LootCouncil.Show then
                    S.LootCouncil:Show()
                elseif S.LootCouncil.frame then
                    S.LootCouncil.frame:Show()
                end
            end)
        end
    end
end

function CE:OnReadyCheck(initiator)
    if S.ReadyChecker and self:IsModuleEnabled("ReadyChecker") then
        self:ShowWindow("ReadyChecker", function()
            if S.ReadyChecker.Show then
                S.ReadyChecker:Show()
            elseif S.ReadyChecker.Frame then
                S.ReadyChecker.Frame:Show()
            elseif S.ReadyChecker.frame then
                S.ReadyChecker.frame:Show()
            end
        end)
    end
end

function CE:OnPlayerDead()
    -- Potencial wipe - mostrar WipeAnalyzer después de unos segundos
    if currentContext == CONTEXT.RAID or currentContext == CONTEXT.DUNGEON then
        C_Timer.After(5, function()
            -- Verificar si varios están muertos (wipe)
            local deadCount = 0
            local groupSize = S.AutoSync and S.AutoSync:GetGroupSize() or 1
            
            if GetNumRaidMembers() > 0 then
                for i = 1, GetNumRaidMembers() do
                    if UnitIsDead("raid" .. i) then
                        deadCount = deadCount + 1
                    end
                end
            else
                if UnitIsDead("player") then deadCount = deadCount + 1 end
                for i = 1, GetNumPartyMembers() do
                    if UnitIsDead("party" .. i) then
                        deadCount = deadCount + 1
                    end
                end
            end
            
            -- Si más del 50% están muertos, es wipe
            if deadCount > groupSize * 0.5 then
                if S.WipeAnalyzer and CE:IsModuleEnabled("WipeAnalyzer") then
                    CE:ShowWindow("WipeAnalyzer", function()
                        if S.WipeAnalyzer.Show then
                            S.WipeAnalyzer:Show()
                        elseif S.WipeAnalyzer.Frame then
                            S.WipeAnalyzer.Frame:Show()
                        elseif S.WipeAnalyzer.frame then
                            S.WipeAnalyzer.frame:Show()
                        end
                    end)
                end
            end
        end)
    end
end

-- NOTA: OnEncounterStart/End removidos - esos eventos no existen en WotLK 3.3.5a
-- La detección de wipe se hace via OnPlayerDead()

function CE:OnAddonMessage(prefix, message, channel, sender)
    -- Detectar polls de VotingSystem
    if prefix == "SeqVote" then
        local cmd = strsplit(":", message)
        if cmd == "POLL" then
            if S.VotingSystem and self:IsModuleEnabled("VotingSystem") then
                self:ShowWindow("VotingSystem", function()
                    if S.VotingSystem.Show then
                        S.VotingSystem:Show()
                    elseif S.VotingSystem.frame then
                        S.VotingSystem.frame:Show()
                    end
                end)
            end
        end
    end
    
    -- Detectar LootCouncil
    if prefix == "SeqLC" then
        local cmd = strsplit(":", message)
        if cmd == "START" then
            if S.LootCouncil and self:IsModuleEnabled("LootCouncil") then
                self:ShowWindow("LootCouncil", function()
                    if S.LootCouncil.Show then
                        S.LootCouncil:Show()
                    elseif S.LootCouncil.frame then
                        S.LootCouncil.frame:Show()
                    end
                end)
            end
        end
    end
end

-- ============================================
-- SISTEMA DE VENTANAS
-- ============================================
function CE:ShowWindow(moduleId, showFunc)
    -- Verificar si el módulo está habilitado
    if not self:IsModuleEnabled(moduleId) then
        return
    end
    
    -- Restaurar posición guardada
    if S.SmartDefaults then
        S.SmartDefaults:RestorePosition(moduleId)
    end
    
    -- Mostrar
    if showFunc then
        showFunc()
    end
    
    shownWindows[moduleId] = true
end

function CE:HideWindow(moduleId, hideFunc)
    if hideFunc then
        hideFunc()
    end
    shownWindows[moduleId] = nil
end

function CE:IsModuleEnabled(moduleId)
    if S.ModuleConfig then
        local enabled = S.ModuleConfig:GetValue(moduleId, "enabled")
        return enabled ~= false -- Default true si no está definido
    end
    return true
end

-- ============================================
-- CALLBACKS DESDE AUTOSYNC
-- ============================================
function CE:OnGroupJoined()
    C_Timer.After(1, function()
        CE:DetectContext()
    end)
end

function CE:OnGroupLeft()
    currentContext = CONTEXT.SOLO
    -- Ocultar todas las ventanas de raid/party
    self:AutoHideRaidWindows()
end

-- ============================================
-- TRIGGERS REGISTRABLES
-- ============================================
function CE:RegisterTrigger(moduleId, event, callback)
    if not registeredTriggers[event] then
        registeredTriggers[event] = {}
    end
    registeredTriggers[event][moduleId] = callback
end

function CE:RegisterDefaultTriggers()
    -- Los módulos pueden registrar sus propios triggers aquí
end

-- ============================================
-- API PÚBLICA
-- ============================================
function CE:GetCurrentContext()
    return currentContext
end

function CE:IsInCombatContent()
    return currentContext == CONTEXT.RAID or 
           currentContext == CONTEXT.DUNGEON or
           currentContext == CONTEXT.BATTLEGROUND or
           currentContext == CONTEXT.ARENA
end

function CE:ForceContextCheck()
    self:DetectContext()
end

-- Registrar en Sequito
S.ContextEngine = CE
