--[[
    Sequito - SmartDefaults Module
    Sistema de Posiciones y Defaults Inteligentes
    Version: 8.0.0
    
    Este módulo guarda y restaura las posiciones de las ventanas
    para que se recuerden aunque aparezcan automáticamente.
]]--

local addonName, S = ...
S.SmartDefaults = {}
local SD = S.SmartDefaults

-- SavedVariable para posiciones
SequitoPositionsDB = SequitoPositionsDB or {}

-- ============================================
-- INICIALIZACIÓN
-- ============================================
function SD:Initialize()
    self:HookFrames()
    S:Print("|cff00ff00SmartDefaults|r inicializado - Posiciones guardadas activas")
end

-- ============================================
-- HOOK A FRAMES PARA GUARDAR POSICIÓN
-- ============================================
function SD:HookFrames()
    -- Lista de módulos con frames
    local modules = {
        "CooldownMonitor",
        "RaidPanel",
        "LootCouncil",
        "VotingSystem",
        "WipeAnalyzer",
        "ReadyChecker",
        "FocusFire",
        "QuickWhisper",
        "PlayerNotes",
        "PerformanceStats",
        "BuildManager",
        "VersionSync",
        "EventCalendar",
        "Logistics",
        "Assignments",
        "DoTTracker",
        "RaidAssistUI",
        "DungeonTimer",
        "CCCoordinator",
        "CCTracker",
        "HealerTracker",
        "PullGuide",
        "Soulstones",
        "AlertHub"
    }
    
    -- Hookear después de un delay para asegurar que los frames existen
    C_Timer.After(3, function()
        for _, moduleId in ipairs(modules) do
            SD:HookModuleFrame(moduleId)
        end
    end)
end

function SD:HookModuleFrame(moduleId)
    local module = S[moduleId]
    if not module then return end
    
    -- Check both Frame (capital) and frame (lowercase)
    local frame = module.Frame or module.frame
    if not frame then return end
    
    -- Hook OnDragStop para guardar posición
    local originalOnDragStop = frame:GetScript("OnDragStop")
    frame:SetScript("OnDragStop", function(self)
        if originalOnDragStop then
            originalOnDragStop(self)
        end
        self:StopMovingOrSizing()
        SD:SavePosition(moduleId, self)
    end)
    
    -- También hook OnHide para guardar posición
    local originalOnHide = frame:GetScript("OnHide")
    frame:SetScript("OnHide", function(self)
        if originalOnHide then
            originalOnHide(self)
        end
        SD:SavePosition(moduleId, self)
    end)
end

-- ============================================
-- GUARDAR/RESTAURAR POSICIONES
-- ============================================
function SD:SavePosition(moduleId, frame)
    if not frame then return end
    
    local point, relativeTo, relativePoint, xOfs, yOfs = frame:GetPoint()
    
    SequitoPositionsDB[moduleId] = {
        point = point,
        relativePoint = relativePoint,
        x = xOfs,
        y = yOfs,
        width = frame:GetWidth(),
        height = frame:GetHeight()
    }
end

function SD:RestorePosition(moduleId)
    local saved = SequitoPositionsDB[moduleId]
    if not saved then return false end
    
    local module = S[moduleId]
    if not module then return false end
    
    local frame = module.Frame or module.frame
    if not frame then return false end
    
    frame:ClearAllPoints()
    frame:SetPoint(saved.point, UIParent, saved.relativePoint, saved.x, saved.y)
    
    if saved.width and saved.height then
        frame:SetSize(saved.width, saved.height)
    end
    
    return true
end

function SD:ResetPosition(moduleId)
    SequitoPositionsDB[moduleId] = nil
    
    local module = S[moduleId]
    if module then
        local frame = module.Frame or module.frame
        if frame then
            frame:ClearAllPoints()
            frame:SetPoint("CENTER", UIParent, "CENTER", 0, 0)
        end
    end
end

function SD:ResetAllPositions()
    wipe(SequitoPositionsDB)
    S:Print("Todas las posiciones han sido restauradas a default")
end

-- ============================================
-- DEFAULTS INTELIGENTES
-- ============================================
function SD:ApplySmartDefaults()
    -- Auto-detectar rol y ajustar UI
    local role = "DAMAGER"
    local _, class = UnitClass("player")
    if S.Universal and S.Universal.GetSpec and S.Universal.GetRole then
        local spec = S.Universal:GetSpec()
        role = S.Universal:GetRole(class, spec) or "DAMAGER"
    end
    
    -- Ajustes según rol
    if role == "HEALER" then
        -- Healers necesitan ver más del centro de pantalla
        self:SetDefaultPosition("CooldownMonitor", "TOPLEFT", 10, -100)
        self:SetDefaultPosition("RaidPanel", "LEFT", -200, 0)
    elseif role == "TANK" then
        -- Tanks necesitan ver sus CDs cerca del centro
        self:SetDefaultPosition("CooldownMonitor", "CENTER", 0, 200)
        self:SetDefaultPosition("DefensiveAlerts", "CENTER", 0, -100)
    else
        -- DPS: layout estándar
        self:SetDefaultPosition("CooldownMonitor", "TOPRIGHT", -10, -100)
    end
end

function SD:SetDefaultPosition(moduleId, point, x, y)
    -- Solo aplicar si no hay posición guardada
    if SequitoPositionsDB[moduleId] then return end
    
    local module = S[moduleId]
    if module then
        local frame = module.Frame or module.frame
        if frame then
            frame:ClearAllPoints()
            frame:SetPoint(point, UIParent, point, x, y)
        end
    end
end

-- ============================================
-- AUTO-SCALE BASADO EN TAMAÑO DE GRUPO
-- ============================================
function SD:AdjustForGroupSize(size)
    -- Para raids grandes, hacer algunas ventanas más compactas
    if size > 25 then
        -- Modo compacto para 40-man
        if S.CooldownMonitor and S.CooldownMonitor.SetCompactMode then
            S.CooldownMonitor:SetCompactMode(true)
        end
    elseif size > 10 then
        -- Modo normal para 10-25 man
        if S.CooldownMonitor and S.CooldownMonitor.SetCompactMode then
            S.CooldownMonitor:SetCompactMode(false)
        end
    end
end

-- ============================================
-- API PÚBLICA
-- ============================================
function SD:GetSavedPosition(moduleId)
    return SequitoPositionsDB[moduleId]
end

function SD:HasSavedPosition(moduleId)
    return SequitoPositionsDB[moduleId] ~= nil
end

-- Registrar en Sequito
S.SmartDefaults = SD
