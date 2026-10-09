--[[
    SEQUITO - SpecWatcher.lua
    Sistema de deteccion automatica de cambio de especializacion
    Actualiza las macros automaticamente al cambiar de spec (Dual Spec WotLK)
]]--

local addonName, Jaina = ...
Jaina.SpecWatcher = Jaina.SpecWatcher or {}

local SpecWatcher = Jaina.SpecWatcher
local MacroGen = Jaina.MacroGen

-- Variables de estado
local currentSpec = 0
local currentTalentGroup = 0
local isInitialized = false

-- Configuracion
local CONFIG = {
    autoUpdateMacros = true,
    showNotification = true,
    delay = 0.5, -- Delay antes de actualizar macros
}

-- Obtener grupo de talentos activo (Dual Spec)
local function GetActiveTalentGroup()
    return _G.GetActiveTalentGroup and _G.GetActiveTalentGroup() or 1
end

-- Obtener spec actual basado en puntos de talento (sincronizado con Dual Spec)
local function GetCurrentSpec(talentGroup)
    local spec = 0
    local maxPoints = -1
    local group = talentGroup or GetActiveTalentGroup()
    
    for i = 1, 3 do
        local _, _, pointsSpent = GetTalentTabInfo(i, false, false, group)
        if pointsSpent and pointsSpent > maxPoints then
            maxPoints = pointsSpent
            spec = i
        end
    end
    
    return (spec > 0 and maxPoints > 0) and spec or 1
end

-- Nombres de especializacion por clase (fallback alineado con orden de TalentTab.dbc)
local SPEC_NAMES = {
    ["WARRIOR"] = {"Arms", "Fury", "Protection"},
    ["PALADIN"] = {"Holy", "Protection", "Retribution"},
    ["HUNTER"] = {"Beast Mastery", "Marksmanship", "Survival"},
    ["ROGUE"] = {"Assassination", "Combat", "Subtlety"},
    ["PRIEST"] = {"Discipline", "Holy", "Shadow"},
    ["DEATHKNIGHT"] = {"Blood", "Frost", "Unholy"},
    ["SHAMAN"] = {"Elemental", "Enhancement", "Restoration"},
    ["MAGE"] = {"Arcane", "Fire", "Frost"},
    ["WARLOCK"] = {"Affliction", "Demonology", "Destruction"},
    ["DRUID"] = {"Balance", "Feral", "Restoration"},
}

-- Obtener nombre de la spec (resolucion canonica en vivo desde el cliente)
local function GetSpecName(class, specIndex)
    local group = GetActiveTalentGroup()
    local name = GetTalentTabInfo(specIndex, false, false, group)
    if name and name ~= "" then
        return name
    end
    if SPEC_NAMES[class] and SPEC_NAMES[class][specIndex] then
        return SPEC_NAMES[class][specIndex]
    end
    return "Spec " .. tostring(specIndex)
end

-- Callback cuando cambia la spec
local function OnSpecChanged(newSpec, newTalentGroup)
    local _, class = UnitClass("player")
    local specName = GetSpecName(class, newSpec)
    
    if SpecWatcher:GetOption("showNotification") then
        Jaina:Print(string.format(
            "|cff00ff00Cambio de especializacion detectado!|r %s (Grupo %d)",
            specName, newTalentGroup
        ))
    end
    
    -- REDUNDANCY FIX: Macro generation is now handled directly in MacroGenerator.lua
    -- This block is commented out to prevent double-generation.
    -- if CONFIG.autoUpdateMacros and MacroGen then
    --    C_Timer.After(CONFIG.delay, function()
    --        MacroGen:GenerateClassMacros()
    --        Jaina:Print("|cff00ffffMacros actualizadas para " .. specName .. "|r")
    --    end)
    -- end
    
    -- Guardar en SavedVariables
    if JainaDB then
        JainaDB.lastSpec = newSpec
        JainaDB.lastTalentGroup = newTalentGroup
    end
end

-- Verificar si hubo cambio de spec
local function CheckSpecChange()
    local newTalentGroup = GetActiveTalentGroup()
    local newSpec = GetCurrentSpec(newTalentGroup)
    
    if isInitialized then
        if newSpec ~= currentSpec or newTalentGroup ~= currentTalentGroup then
            OnSpecChanged(newSpec, newTalentGroup)
        end
    end
    
    currentSpec = newSpec
    currentTalentGroup = newTalentGroup
    isInitialized = true
end

-- Frame de eventos
local eventFrame = CreateFrame("Frame")

eventFrame:RegisterEvent("PLAYER_LOGIN")
eventFrame:RegisterEvent("PLAYER_ENTERING_WORLD")
eventFrame:RegisterEvent("ACTIVE_TALENT_GROUP_CHANGED")
eventFrame:RegisterEvent("CHARACTER_POINTS_CHANGED")
eventFrame:RegisterEvent("PLAYER_TALENT_UPDATE")

eventFrame:SetScript("OnEvent", function(self, event, ...)
    if event == "PLAYER_LOGIN" or event == "PLAYER_ENTERING_WORLD" then
        -- Inicializar al entrar
        C_Timer.After(1, function()
            CheckSpecChange()
        end)
    elseif event == "ACTIVE_TALENT_GROUP_CHANGED" then
        -- Cambio de Dual Spec
        C_Timer.After(0.2, function()
            CheckSpecChange()
        end)
    elseif event == "CHARACTER_POINTS_CHANGED" or event == "PLAYER_TALENT_UPDATE" then
        -- Cambio de talentos
        C_Timer.After(0.5, function()
            CheckSpecChange()
        end)
    end
end)

-- API Publica

-- Obtener spec actual
function SpecWatcher:GetCurrentSpec()
    return currentSpec
end

-- Obtener grupo de talentos activo
function SpecWatcher:GetTalentGroup()
    return currentTalentGroup
end

-- Obtener nombre de spec actual
function SpecWatcher:GetSpecName()
    local _, class = UnitClass("player")
    return GetSpecName(class, currentSpec)
end

-- Forzar actualizacion de macros
function SpecWatcher:ForceUpdate()
    CheckSpecChange()
    if MacroGen then
        MacroGen:GenerateClassMacros()
    end
end

-- Activar/desactivar auto-update
function SpecWatcher:SetAutoUpdate(enabled)
    CONFIG.autoUpdateMacros = enabled
    Jaina:Print("Auto-update de macros: " .. (enabled and "Activado" or "Desactivado"))
end

-- Activar/desactivar notificaciones
function SpecWatcher:SetNotifications(enabled)
    CONFIG.showNotification = enabled
end

-- Obtener info completa
function SpecWatcher:GetInfo()
    local _, class = UnitClass("player")
    return {
        class = class,
        spec = currentSpec,
        specName = GetSpecName(class, currentSpec),
        talentGroup = currentTalentGroup,
        autoUpdate = CONFIG.autoUpdateMacros,
    }
end

-- Inicializacion

-- Helper para obtener configuración
function SpecWatcher:GetOption(key)
    if Jaina.ModuleConfig then
        return Jaina.ModuleConfig:GetValue("SpecWatcher", key)
    end
    return true
end

function SpecWatcher:Initialize()
    if not self:GetOption("enabled") then
        return
    end
    
    -- Cargar configuracion guardada
    if JainaDB and JainaDB.specWatcher then
        CONFIG.autoUpdateMacros = JainaDB.specWatcher.autoUpdate ~= false
        CONFIG.showNotification = JainaDB.specWatcher.showNotification ~= false
    end
    
    Jaina:Print("SpecWatcher cargado - Deteccion automatica de spec activa")
end

-- Registrar en Jaina
Jaina.SpecWatcher = SpecWatcher

-- Registrar módulo en ModuleConfig
if Jaina.ModuleConfig then
    Jaina.ModuleConfig:RegisterModule("SpecWatcher", {
        name = "Spec Watcher",
        description = "Detecta cambios de especialización y actualiza macros automáticamente",
        category = "utility",
        icon = "Interface\\Icons\\Ability_Marksmanship",
        options = {
            {key = "enabled", type = "checkbox", label = "Habilitar Spec Watcher", default = true},
            {key = "autoUpdate", type = "checkbox", label = "Actualizar macros automáticamente", default = true},
            {key = "showNotification", type = "checkbox", label = "Mostrar notificaciones", default = true},
        }
    })
end

