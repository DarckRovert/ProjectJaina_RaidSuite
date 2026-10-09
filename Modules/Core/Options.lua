--[[
    Jaina - Options.lua
    Panel de Configuración Principal
    Version: 8.0.0 (Refactorizado)
    
    Este módulo proporciona la interfaz principal de configuración usando
    el sistema ModuleConfig para gestionar opciones de todos los módulos.
]]--

local addonName, S = ...
S.Options = S.Options or {}

local Options = S.Options
local L = S.L or {}

-- ============================================
-- CONFIGURACIÓN POR DEFECTO (General/UI)
-- ============================================
local DEFAULT_GENERAL = {
    enabled = true,
    showWelcome = true,
    debugMode = false,
    language = "esMX",
    
    -- Interfaz
    scale = 1.0,
    alpha = 0.9,
    locked = false,
    showMinimap = true,
    showTooltips = true,
    
    -- Esfera
    showSphere = true,
    sphereScale = 1.0,
    sphereText = true,
    spherePercent = true,
    
    -- Alertas
    showAlerts = true,
    alertSound = true,
    alertFlash = true,
    alertCombatOnly = true,
}

-- ============================================
-- VARIABLES LOCALES
-- ============================================
local optionsFrame = nil
local currentCategory = "general"
local currentModuleId = nil
local categoryButtons = {}
local moduleButtons = {}
local controls = {}

-- Dimensiones
local PANEL_WIDTH = 600
local PANEL_HEIGHT = 500

-- Categorías
local CATEGORIES = {
    {id = "general", name = L["CAT_GENERAL"], icon = "Interface\\Icons\\INV_Misc_Gear_01"},
    {id = "interface", name = L["CAT_INTERFACE"], icon = "Interface\\Icons\\Spell_Holy_MindVision"},
    {id = "pvp", name = L["CAT_PVP"], icon = "Interface\\Icons\\Ability_DualWield"},
    {id = "raid", name = L["CAT_RAID"], icon = "Interface\\Icons\\Spell_Holy_DivineProvidence"},
    {id = "dungeon", name = L["CAT_DUNGEON"], icon = "Interface\\Icons\\INV_Misc_Key_10"},
    {id = "class", name = L["CAT_CLASS"], icon = "Interface\\Icons\\Spell_Holy_MagicalSentry"}, -- New Category
    {id = "utility", name = L["CAT_UTILITY"], icon = "Interface\\Icons\\Trade_Engineering"},
}

-- ============================================
-- FUNCIONES DE CREACIÓN DE CONTROLES
-- ============================================

local function CreateLabel(parent, text, x, y, size)
    local label = parent:CreateFontString(nil, "OVERLAY", size or "GameFontNormal")
    label:SetPoint("TOPLEFT", parent, "TOPLEFT", x, y)
    label:SetText(text)
    return label
end

local function CreateCheckbox(parent, key, label, x, y, tooltip, onChange)
    local cb = CreateFrame("CheckButton", nil, parent, "UICheckButtonTemplate")
    cb:SetPoint("TOPLEFT", parent, "TOPLEFT", x, y)
    cb:SetSize(24, 24)
    
    cb.text = cb:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    cb.text:SetPoint("LEFT", cb, "RIGHT", 5, 0)
    cb.text:SetText(label)
    
    cb.key = key
    cb.controlType = "checkbox"
    
    if onChange then
        cb:SetScript("OnClick", function(self)
            if onChange then onChange(self:GetChecked()) end
        end)
    end
    
    if tooltip and type(tooltip) == "string" then
        cb:SetScript("OnEnter", function(self)
            GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
            GameTooltip:SetText(tooltip, 1, 1, 1, 1, true)
            GameTooltip:Show()
        end)
        cb:SetScript("OnLeave", function() GameTooltip:Hide() end)
    end
    
    table.insert(controls, cb)
    return cb
end

local function CreateSlider(parent, key, label, x, y, minVal, maxVal, step, tooltip, onChange)
    -- Use a unique global name to access template regions
    local sliderName = "JainaOptSlider_" .. key
    local slider = CreateFrame("Slider", sliderName, parent, "OptionsSliderTemplate")
    slider:SetPoint("TOPLEFT", parent, "TOPLEFT", x, y)
    slider:SetSize(180, 17)
    slider:SetMinMaxValues(minVal, maxVal)
    slider:SetValueStep(step)
    slider:SetOrientation("HORIZONTAL")
    
    -- Reuse Template Regions
    local text = _G[sliderName .. "Text"]
    local low = _G[sliderName .. "Low"]
    local high = _G[sliderName .. "High"]
    
    if text then text:SetText(label) end
    if low then low:SetText(minVal) end
    if high then high:SetText(maxVal) end
    
    -- Custom Value Label
    slider.Value = slider:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
    slider.Value:SetPoint("TOP", slider, "BOTTOM", 0, -2)
    
    slider:SetScript("OnValueChanged", function(self, value)
        -- Round to 1 decimal
        self.Value:SetText(string.format("%.1f", value))
        if onChange then onChange(value) end
    end)
    
    slider.key = key
    slider.controlType = "slider"
    
    if tooltip and type(tooltip) == "string" then
        slider:SetScript("OnEnter", function(self)
            GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
            GameTooltip:SetText(tooltip, 1, 1, 1, 1, true)
            GameTooltip:Show()
        end)
        slider:SetScript("OnLeave", function() GameTooltip:Hide() end)
    end
    
    table.insert(controls, slider)
    return slider
end

local function CreateDropdown(parent, key, label, x, y, dropdownOptions, tooltip)
    local dropdown = CreateFrame("Frame", "JainaOpt_" .. key, parent, "UIDropDownMenuTemplate")
    dropdown:SetPoint("TOPLEFT", parent, "TOPLEFT", x - 15, y)
    
    local labelText = dropdown:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    labelText:SetPoint("BOTTOMLEFT", dropdown, "TOPLEFT", 20, 2)
    labelText:SetText(label)
    
    UIDropDownMenu_SetWidth(dropdown, 150)
    dropdown:SetFrameStrata("FULLSCREEN_DIALOG") -- Ensure on top of dialog
    UIDropDownMenu_JustifyText(dropdown, "LEFT")
    
    dropdown.options = dropdownOptions
    dropdown.key = key
    dropdown.controlType = "dropdown"
    
    UIDropDownMenu_Initialize(dropdown, function(self, level)
        for i, opt in ipairs(dropdownOptions) do
            local info = UIDropDownMenu_CreateInfo()
            info.text = opt.text
            info.value = opt.value
            info.func = function(self)
                UIDropDownMenu_SetSelectedValue(dropdown, self.value)
                UIDropDownMenu_SetText(dropdown, self:GetText())
            end
            UIDropDownMenu_AddButton(info, level)
        end
    end)
    
    table.insert(controls, dropdown)
    return dropdown
end

local function CreateButton(parent, label, x, y, width, onClick)
    local btn = CreateFrame("Button", nil, parent, "UIPanelButtonTemplate")
    btn:SetPoint("TOPLEFT", parent, "TOPLEFT", x, y)
    btn:SetSize(width, 22)
    btn:SetText(label)
    btn:SetScript("OnClick", onClick)
    return btn
end

-- ============================================
-- CONTENIDO DE CATEGORÍA: GENERAL
-- ============================================
local function CreateGeneralContent(parent)
    local content = CreateFrame("Frame", nil, parent)
    content:SetAllPoints()
    
    CreateLabel(content, "|cff9966ffOpciones Generales|r", 20, -10, "GameFontNormalLarge")
    
    CreateCheckbox(content, "enabled", "Addon Habilitado", 20, -45,
        "Activa o desactiva completamente el addon", function(v) S.db.profile.Enabled = v end)
    
    CreateCheckbox(content, "showWelcome", "Mensaje de bienvenida", 20, -75,
        "Muestra mensaje al iniciar sesión", function(v) S.db.profile.ShowWelcome = v end)
    
    CreateCheckbox(content, "debugMode", "Modo Debug", 20, -105,
        "Muestra mensajes de depuración", function(v) S.db.profile.Debug = v end)
    
    CreateCheckbox(content, "showMinimap", "Botón en minimapa", 20, -135,
        "Muestra botón de acceso rápido en el minimapa", function(checked)
            S.db.profile.ShowMinimap = checked
            if S.GUI and S.GUI.UpdateMinimap then
                S.GUI:UpdateMinimap()
            end
        end)
    
    CreateCheckbox(content, "showTooltips", "Mostrar tooltips", 20, -165,
        "Muestra información adicional al pasar el mouse", function(v) S.db.profile.ShowTooltips = v end)
    
    CreateDropdown(content, "language", "Idioma:", 20, -210, {
        {text = "Español (ES)", value = "esES"},
        {text = "Español (MX)", value = "esMX"},
        {text = "English", value = "enUS"},
    }, "Selecciona el idioma del addon")
    
    -- Separador
    local sep = content:CreateTexture(nil, "ARTWORK")
    sep:SetPoint("TOPLEFT", content, "TOPLEFT", 20, -265)
    sep:SetSize(330, 1)
    sep:SetTexture(0.4, 0.4, 0.5, 0.5)
    
    CreateLabel(content, "|cffffcc00Alertas:|r", 20, -280)
    
    CreateCheckbox(content, "showAlerts", "Alertas habilitadas", 20, -305,
        "Activa las alertas visuales y sonoras", function(v) S.db.profile.ShowAlerts = v end)
    
    CreateCheckbox(content, "alertSound", "Sonido de alertas", 20, -335,
        "Reproduce sonido con cada alerta", function(v) S.db.profile.AlertSound = v end)
    
    CreateCheckbox(content, "alertFlash", "Flash de pantalla", 20, -365,
        "Hace parpadear la pantalla en alertas importantes", function(v) S.db.profile.AlertFlash = v end)
    
    return content
end

-- ============================================
-- CONTENIDO DE CATEGORÍA: INTERFAZ
-- ============================================
local function CreateInterfaceContent(parent)
    local content = CreateFrame("Frame", nil, parent)
    content:SetAllPoints()
    
    CreateLabel(content, "|cff9966ffOpciones de Interfaz|r", 20, -10, "GameFontNormalLarge")
    
    CreateSlider(content, "scale", "Escala General", 20, -60, 0.5, 2.0, 0.1,
        "Ajusta el tamaño de todos los elementos", function(value)
            S.db.profile.Scale = value
            if S.Sphere and value > 0 then
                S.Sphere:SetScale(value)
            end
        end)
    
    CreateSlider(content, "alpha", "Transparencia", 20, -120, 0.3, 1.0, 0.1,
        "Ajusta la transparencia de los paneles", function(v) S.db.profile.Alpha = v end)
    
    -- Esfera
    local sep = content:CreateTexture(nil, "ARTWORK")
    sep:SetPoint("TOPLEFT", content, "TOPLEFT", 20, -165)
    sep:SetSize(330, 1)
    sep:SetTexture(0.4, 0.4, 0.5, 0.5)
    
    CreateLabel(content, "|cffffcc00Esfera Principal:|r", 20, -180)
    
    CreateCheckbox(content, "showSphere", "Mostrar Esfera", 20, -205,
        "Muestra la esfera principal de Jaina", function(v) 
            S.db.profile.ShowSphere = v
            if S.Sphere then
                if v then S.Sphere:Show() else S.Sphere:Hide() end
            end
        end)
    
    CreateSlider(content, "sphereScale", "Escala de Esfera", 20, -255, 0.5, 2.0, 0.1,
        "Ajusta el tamaño de la esfera", function(v)
            S.db.profile.SphereScale = v 
            if S.Sphere then S.Sphere:SetScale(v) end
        end)
    
    CreateCheckbox(content, "sphereText", "Texto en esfera", 20, -310,
        "Muestra información de texto en la esfera", function(v) S.db.profile.SphereText = v end)
    
    CreateCheckbox(content, "spherePercent", "Mostrar porcentaje", 20, -340,
        "Muestra el porcentaje de recurso", function(v) S.db.profile.SpherePercent = v end)
    
    CreateCheckbox(content, "locked", "Bloquear posición", 20, -370,
        "Bloquea la posición de todos los elementos", function(v) S.db.profile.Locked = v end)
    
    return content
end

-- ============================================
-- CONTENIDO DE MÓDULOS (PvP, Raid, Dungeon, Utility)
-- ============================================
local function CreateModuleContent(parent, category)
    local content = CreateFrame("Frame", nil, parent)
    content:SetAllPoints()
    
    -- Panel izquierdo: Lista de módulos con scroll
    local moduleList = CreateFrame("Frame", nil, content)
    moduleList:SetPoint("TOPLEFT", content, "TOPLEFT", 10, -10)
    moduleList:SetSize(170, 380)
    moduleList:SetBackdrop({
        bgFile = "Interface\\Tooltips\\UI-Tooltip-Background",
        edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
        tile = true, tileSize = 8, edgeSize = 8,
        insets = {left = 2, right = 2, top = 2, bottom = 2}
    })
    moduleList:SetBackdropColor(0.1, 0.1, 0.15, 0.9)
    content.moduleList = moduleList
    
    -- Scroll frame para la lista de módulos
    local scrollFrame = CreateFrame("ScrollFrame", "JainaModuleListScroll_" .. category, moduleList, "UIPanelScrollFrameTemplate")
    scrollFrame:SetPoint("TOPLEFT", moduleList, "TOPLEFT", 4, -4)
    scrollFrame:SetPoint("BOTTOMRIGHT", moduleList, "BOTTOMRIGHT", -24, 4)
    
    local scrollChild = CreateFrame("Frame", nil, scrollFrame)
    scrollChild:SetSize(140, 1) -- Height will be set dynamically
    scrollFrame:SetScrollChild(scrollChild)
    content.scrollChild = scrollChild
    
    -- Panel derecho: Configuración del módulo seleccionado (Wrapped in ScrollFrame)
    local configContainer = CreateFrame("Frame", nil, content)
    configContainer:SetPoint("TOPLEFT", moduleList, "TOPRIGHT", 10, 0)
    configContainer:SetPoint("BOTTOMRIGHT", content, "BOTTOMRIGHT", -10, 10)
    configContainer:SetBackdrop({
        bgFile = "Interface\\Tooltips\\UI-Tooltip-Background",
        edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
        tile = true, tileSize = 8, edgeSize = 8,
        insets = {left = 2, right = 2, top = 2, bottom = 2}
    })
    configContainer:SetBackdropColor(0.1, 0.1, 0.15, 0.9)

    -- Scroll Frame for Right Panel
    local configScroll = CreateFrame("ScrollFrame", "JainaOptionsConfigScroll_" .. category, configContainer, "UIPanelScrollFrameTemplate")
    configScroll:SetPoint("TOPLEFT", configContainer, "TOPLEFT", 6, -6)
    configScroll:SetPoint("BOTTOMRIGHT", configContainer, "BOTTOMRIGHT", -26, 6)
    
    local configPanel = CreateFrame("Frame", nil, configScroll)
    configPanel:SetSize(360, 1) -- Height dynamic
    configScroll:SetScrollChild(configPanel)
    
    content.configPanel = configPanel
    content.configScroll = configScroll
    
    -- Poblar lista de módulos (now in scrollChild)
    local yOffset = 0
    local MC = S.ModuleConfig
    
    if MC and MC.Modules then
        for moduleId, mod in pairs(MC.Modules) do
            if mod.category == category then
                local btn = CreateFrame("Button", nil, scrollChild)
                btn:SetSize(138, 26)
                btn:SetPoint("TOPLEFT", scrollChild, "TOPLEFT", 2, -yOffset)
                
                -- Background con gradiente sutil
                btn.bg = btn:CreateTexture(nil, "BACKGROUND")
                btn.bg:SetAllPoints()
                btn.bg:SetTexture("Interface\\Buttons\\WHITE8x8")
                btn.bg:SetVertexColor(0.15, 0.15, 0.2, 0)
                
                -- Borde sutil
                btn.border = btn:CreateTexture(nil, "BORDER")
                btn.border:SetPoint("BOTTOMLEFT", 2, 0)
                btn.border:SetPoint("BOTTOMRIGHT", -2, 0)
                btn.border:SetHeight(1)
                btn.border:SetTexture(0.4, 0.3, 0.5, 0)
                
                -- Icono del módulo
                btn.icon = btn:CreateTexture(nil, "ARTWORK")
                btn.icon:SetPoint("LEFT", 4, 0)
                btn.icon:SetSize(18, 18)
                if mod.icon and mod.icon ~= "" then
                    btn.icon:SetTexture(mod.icon)
                else
                    btn.icon:SetTexture("Interface\\Icons\\INV_Misc_QuestionMark")
                end
                
                -- Texto con offset para el icono
                btn.text = btn:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
                btn.text:SetPoint("LEFT", btn.icon, "RIGHT", 4, 0)
                btn.text:SetPoint("RIGHT", -4, 0)
                btn.text:SetJustifyH("LEFT")
                btn.text:SetText(mod.name)
                btn.text:SetTextColor(0.85, 0.85, 0.85)
                
                btn.moduleId = moduleId
                
                btn:SetScript("OnEnter", function(self)
                    self.bg:SetVertexColor(0.3, 0.2, 0.5, 0.7)
                    self.border:SetTexture(0.6, 0.4, 0.8, 0.8)
                    self.text:SetTextColor(1, 1, 1)
                end)
                btn:SetScript("OnLeave", function(self)
                    if currentModuleId ~= self.moduleId then
                        self.bg:SetVertexColor(0.15, 0.15, 0.2, 0)
                        self.border:SetTexture(0.4, 0.3, 0.5, 0)
                        self.text:SetTextColor(0.85, 0.85, 0.85)
                    end
                end)
                btn:SetScript("OnClick", function(self)
                    Options:ShowModuleOptions(content.configPanel, self.moduleId)
                    -- Actualizar visual de todos los botones
                    for _, b in pairs(moduleButtons) do
                        if b.bg then 
                            b.bg:SetVertexColor(0.15, 0.15, 0.2, 0)
                            b.border:SetTexture(0.4, 0.3, 0.5, 0)
                            b.text:SetTextColor(0.85, 0.85, 0.85)
                        end
                    end
                    -- Resaltar el seleccionado
                    self.bg:SetVertexColor(0.4, 0.2, 0.6, 0.9)
                    self.border:SetTexture(0.8, 0.5, 1, 1)
                    self.text:SetTextColor(1, 1, 1)
                    currentModuleId = self.moduleId
                end)
                
                moduleButtons[moduleId] = btn
                yOffset = yOffset + 28
            end
        end
        -- Set scroll child height based on content
        scrollChild:SetHeight(math.max(yOffset + 10, 370))
    end
    
    -- Mostrar primer módulo por defecto
    local firstModule = nil
    if MC and MC.Modules then
        for moduleId, mod in pairs(MC.Modules) do
            if mod.category == category then
                firstModule = moduleId
                break
            end
        end
    end
    
    if firstModule then
        C_Timer.After(0.1, function()
            if content.configPanel and content:IsVisible() then
                Options:ShowModuleOptions(content.configPanel, firstModule)
                if moduleButtons[firstModule] then
                    moduleButtons[firstModule].bg:SetTexture(0.5, 0.3, 0.7, 0.8)
                    currentModuleId = firstModule
                end
            end
        end)
    end
    
    return content
end

-- ============================================
-- MOSTRAR OPCIONES DE UN MÓDULO
-- ============================================
function Options:ShowModuleOptions(parent, moduleId)
    -- Limpiar controles anteriores (frames)
    for _, child in pairs({parent:GetChildren()}) do
        child:Hide()
        child:SetParent(nil)
    end
    
    -- Limpiar regiones anteriores (FontStrings, Textures, etc.)
    -- NOTA: No usar SetParent(nil) en regiones - no está permitido en WoW
    -- Además limpiamos el texto para evitar que se apile
    for _, region in pairs({parent:GetRegions()}) do
        region:Hide()
        if region.SetText then
            region:SetText("")
        end
        if region.SetTexture then
            region:SetTexture(nil)
        end
    end
    
    controls = {}
    
    local MC = S.ModuleConfig
    if not MC or not MC.Modules[moduleId] then return end
    
    local mod = MC.Modules[moduleId]
    
    -- Título
    local title = parent:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
    title:SetPoint("TOPLEFT", parent, "TOPLEFT", 15, -15)
    title:SetText("|cff9966ff" .. mod.name .. "|r")
    
    -- Descripción
    if mod.description and mod.description ~= "" then
        local desc = parent:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
        desc:SetPoint("TOPLEFT", title, "BOTTOMLEFT", 0, -5)
        desc:SetWidth(200)
        desc:SetJustifyH("LEFT")
        desc:SetText(mod.description)
    end
    
    -- Crear controles para cada opción
    local yOffset = -60
    
    -- Ajustar yOffset inicial para título/descripción
    -- (Nota: título y desc están en el configPanel ahora, que es hijo del scroll)
    
    for i, opt in ipairs(mod.options) do
        if opt.type == "checkbox" then
            local cb = CreateCheckbox(parent, opt.key, opt.label, 15, yOffset, opt.tooltip,
                function(checked)
                    MC:SetValue(moduleId, opt.key, checked)
                end)
            -- Cargar valor
            local value = MC:GetValue(moduleId, opt.key)
            cb:SetChecked(value)
            cb.moduleId = moduleId
            yOffset = yOffset - 30
            
        elseif opt.type == "slider" then
            local slider = CreateSlider(parent, opt.key, opt.label, 15, yOffset - 15,
                opt.min or 0, opt.max or 100, opt.step or 1, opt.tooltip,
                function(value)
                    MC:SetValue(moduleId, opt.key, value)
                end)
            -- Cargar valor
            local value = MC:GetValue(moduleId, opt.key)
            slider:SetValue(value or opt.default or opt.min or 0)
            slider.moduleId = moduleId
            yOffset = yOffset - 60
            
        elseif opt.type == "dropdown" then
            local dropdown = CreateDropdown(parent, opt.key, opt.label, 15, yOffset - 10,
                opt.options, opt.tooltip)
            -- Cargar valor
            local value = MC:GetValue(moduleId, opt.key)
            if value then
                UIDropDownMenu_SetSelectedValue(dropdown, value)
                for _, o in ipairs(opt.options) do
                    if o.value == value then
                        UIDropDownMenu_SetText(dropdown, o.text)
                        break
                    end
                end
            end
            dropdown.moduleId = moduleId
            yOffset = yOffset - 55
            
        elseif opt.type == "header" then
            local header = parent:CreateFontString(nil, "OVERLAY", "GameFontNormal")
            header:SetPoint("TOPLEFT", parent, "TOPLEFT", 15, yOffset)
            header:SetText("|cffffcc00" .. opt.label .. "|r")
            yOffset = yOffset - 25
        end
    end
    
    -- Update Scroll Child Height
    parent:SetHeight(math.abs(yOffset) + 20)
end

-- ============================================
-- CREAR FRAME PRINCIPAL
-- ============================================
function Options:Initialize()
    print("|cFF00FFFFJaina|r: [Options] Iniciando...")
    
    -- Create options frame
    self.frame = CreateFrame("Frame", "JainaOptionsFrame", UIParent)
    self.frame:SetSize(600, 400)
    
    -- Build UI with error protection
    local success, err = pcall(function()
        self:BuildUI(self.frame)
    end)
    
    if not success then
        print("|cFFFF0000Jaina ERROR:|r Options:BuildUI falló - " .. tostring(err))
        -- Still try to register a minimal frame
    end
    
    -- Register with Dashboard
    if S.Dashboard and S.Dashboard.RegisterTab then
        print("|cFF00FFFFJaina|r: [Options] Registrando tab en Dashboard...")
        
        -- Dashboard Integration Fixes:
        self.frame:SetMovable(false)
        self.frame:SetScript("OnDragStart", nil) -- REMOVE drag script
        self.frame:SetScript("OnDragStop", nil)  -- REMOVE drag script
        self.frame:SetFrameStrata("MEDIUM")
        
        -- Hide decorations
        if self.frame.bg then self.frame.bg:Hide() end
        if self.frame.border then self.frame.border:Hide() end
        if self.frame.closeBtn then self.frame.closeBtn:Hide() end
        if self.frame.header then self.frame.header:Hide() end
        
        S.Dashboard:RegisterTab("Configuración", "Interface\\Icons\\INV_Misc_Gear_01", self.frame)
        print("|cFF00FF00Jaina|r: [Options] Tab registrado exitosamente!")
    else
        print("|cFFFF0000Jaina ERROR:|r Dashboard no disponible para Options")
        self.frame:SetPoint("CENTER")
        self.frame:Hide()
    end
end

function Options:BuildUI(optionsFrame)
    -- Frame principal
    optionsFrame:SetMovable(true)
    optionsFrame:EnableMouse(true)
    optionsFrame:RegisterForDrag("LeftButton")
    optionsFrame:SetScript("OnDragStart", optionsFrame.StartMoving)
    optionsFrame:SetScript("OnDragStop", optionsFrame.StopMovingOrSizing)
    optionsFrame:SetClampedToScreen(true)
    optionsFrame:SetFrameStrata("DIALOG")
    -- optionsFrame:Hide() -- Handled by Dashboard or fallback
    
    -- Fondo con gradiente oscuro
    optionsFrame.bg = optionsFrame:CreateTexture(nil, "BACKGROUND")
    optionsFrame.bg:SetAllPoints()
    optionsFrame.bg:SetTexture(0.05, 0.05, 0.08, 0.95)
    
    -- Borde estilizado
    optionsFrame.border = CreateFrame("Frame", nil, optionsFrame)
    optionsFrame.border:SetAllPoints()
    optionsFrame.border:SetBackdrop({
        edgeFile = "Interface\\DialogFrame\\UI-DialogBox-Border",
        edgeSize = 24,
        insets = {left = 5, right = 5, top = 5, bottom = 5},
    })
    
    -- Título con branding del clan (Parented to border to stay on top)
    optionsFrame.titleHeader = optionsFrame.border:CreateTexture(nil, "ARTWORK")
    optionsFrame.titleHeader:SetPoint("TOP", 0, 16)
    optionsFrame.titleHeader:SetSize(256, 64)
    optionsFrame.titleHeader:SetTexture("Interface\\DialogFrame\\UI-DialogBox-Header")
    
    optionsFrame.title = optionsFrame.border:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    optionsFrame.title:SetPoint("TOP", optionsFrame.titleHeader, "TOP", 0, -14)
    optionsFrame.title:SetText("|cffff0000Project Jaina|r |cffffffffdel|r |cffff0000Terror|r")
    
    -- Versión (movida abajo)
    optionsFrame.version = optionsFrame:CreateFontString(nil, "OVERLAY", "GameFontDisableSmall")
    optionsFrame.version:SetPoint("BOTTOMRIGHT", optionsFrame, "BOTTOMRIGHT", -15, 12)
    optionsFrame.version:SetText("v" .. (S.Version or "8.0.0"))
    
    -- Status Text (izquierda abajo)
    optionsFrame.statusText = optionsFrame:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    optionsFrame.statusText:SetPoint("BOTTOMLEFT", optionsFrame, "BOTTOMLEFT", 15, 12)
    optionsFrame.statusText:SetText("|cff00ff00" .. L["SYSTEM_ONLINE"] .. "|r")
    
    -- Botón cerrar
    optionsFrame.closeBtn = CreateFrame("Button", nil, optionsFrame, "UIPanelCloseButton")
    optionsFrame.closeBtn:SetPoint("TOPRIGHT", optionsFrame, "TOPRIGHT", -5, -5)
    optionsFrame.closeBtn:SetScript("OnClick", function()
        Options:Hide()
    end)
    
    -- Panel de categorías (izquierda)
    optionsFrame.categoryPanel = CreateFrame("Frame", nil, optionsFrame)
    optionsFrame.categoryPanel:SetPoint("TOPLEFT", optionsFrame, "TOPLEFT", 10, -40)
    optionsFrame.categoryPanel:SetSize(100, PANEL_HEIGHT - 100)
    optionsFrame.categoryPanel:SetBackdrop({
        bgFile = "Interface\\Tooltips\\UI-Tooltip-Background",
        edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
        tile = true, tileSize = 8, edgeSize = 8,
        insets = {left = 2, right = 2, top = 2, bottom = 2}
    })
    optionsFrame.categoryPanel:SetBackdropColor(0.1, 0.1, 0.15, 0.9)
    
    -- Panel de contenido (derecha)
    optionsFrame.contentPanel = CreateFrame("Frame", nil, optionsFrame)
    optionsFrame.contentPanel:SetPoint("TOPLEFT", optionsFrame.categoryPanel, "TOPRIGHT", 10, 0)
    optionsFrame.contentPanel:SetPoint("BOTTOMRIGHT", optionsFrame, "BOTTOMRIGHT", -10, 50)
    
    -- Crear botones de categoría
    local yOffset = -10
    for i, cat in ipairs(CATEGORIES) do
        local btn = CreateFrame("Button", nil, optionsFrame.categoryPanel)
        btn:SetSize(88, 32)
        btn:SetPoint("TOPLEFT", optionsFrame.categoryPanel, "TOPLEFT", 6, yOffset)
        
        -- Fondo elegante
        btn.bg = btn:CreateTexture(nil, "BACKGROUND")
        btn.bg:SetAllPoints()
        btn.bg:SetTexture("Interface\\Buttons\\WHITE8x8")
        btn.bg:SetVertexColor(0.2, 0.2, 0.3, 0)
        
        -- Borde inferior sutil
        btn.border = btn:CreateTexture(nil, "BORDER")
        btn.border:SetPoint("BOTTOMLEFT", 4, 0)
        btn.border:SetPoint("BOTTOMRIGHT", -4, 0)
        btn.border:SetHeight(1)
        btn.border:SetTexture(0.3, 0.3, 0.4, 0.5)
        
        btn.icon = btn:CreateTexture(nil, "ARTWORK")
        btn.icon:SetSize(22, 22)  -- Iconos ligeramente más grandes
        btn.icon:SetPoint("LEFT", btn, "LEFT", 4, 0)
        btn.icon:SetTexture(cat.icon)
        
        btn.text = btn:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
        btn.text:SetPoint("LEFT", btn.icon, "RIGHT", 6, 0)
        btn.text:SetText(cat.name)
        btn.text:SetTextColor(0.8, 0.8, 0.8)
        
        btn.categoryId = cat.id
        
        btn:SetScript("OnEnter", function(self)
            if currentCategory ~= self.categoryId then
                self.bg:SetVertexColor(0.3, 0.3, 0.4, 0.5)
                self.text:SetTextColor(1, 1, 1)
            end
        end)
        btn:SetScript("OnLeave", function(self)
            if currentCategory ~= self.categoryId then
                self.bg:SetVertexColor(0.2, 0.2, 0.3, 0)
                self.text:SetTextColor(0.8, 0.8, 0.8)
            end
        end)
        btn:SetScript("OnClick", function(self)
            Options:SelectCategory(self.categoryId)
        end)
        
        categoryButtons[cat.id] = btn
        yOffset = yOffset - 36
    end
    
    -- Crear contenido de cada categoría (oculto por defecto)
    optionsFrame.categoryContents = {}
    optionsFrame.categoryContents["general"] = CreateGeneralContent(optionsFrame.contentPanel)
    optionsFrame.categoryContents["interface"] = CreateInterfaceContent(optionsFrame.contentPanel)
    optionsFrame.categoryContents["pvp"] = CreateModuleContent(optionsFrame.contentPanel, "pvp")
    optionsFrame.categoryContents["raid"] = CreateModuleContent(optionsFrame.contentPanel, "raid")
    optionsFrame.categoryContents["dungeon"] = CreateModuleContent(optionsFrame.contentPanel, "dungeon")
    optionsFrame.categoryContents["class"] = CreateModuleContent(optionsFrame.contentPanel, "class") -- New Content
    optionsFrame.categoryContents["utility"] = CreateModuleContent(optionsFrame.contentPanel, "utility")
    
    -- Ocultar todos
    for id, content in pairs(optionsFrame.categoryContents) do
        content:Hide()
    end
    
    -- Botones de acción
    local btnSave = CreateFrame("Button", nil, optionsFrame, "UIPanelButtonTemplate")
    btnSave:SetSize(100, 25)
    btnSave:SetPoint("BOTTOMRIGHT", optionsFrame, "BOTTOMRIGHT", -15, 15)
    btnSave:SetText("Guardar")
    btnSave:SetScript("OnClick", function()
        Options:SaveOptions()
        Options:Hide()
    end)
    
    local btnDefaults = CreateFrame("Button", nil, optionsFrame, "UIPanelButtonTemplate")
    btnDefaults:SetSize(100, 25)
    btnDefaults:SetPoint("RIGHT", btnSave, "LEFT", -10, 0)
    btnDefaults:SetText("Por Defecto")
    btnDefaults:SetScript("OnClick", function()
        StaticPopup_Show("SEQUITO_RESET_CONFIRM")
    end)
    
    local btnCancel = CreateFrame("Button", nil, optionsFrame, "UIPanelButtonTemplate")
    btnCancel:SetSize(100, 25)
    btnCancel:SetPoint("RIGHT", btnDefaults, "LEFT", -10, 0)
    btnCancel:SetText("Cancelar")
    btnCancel:SetScript("OnClick", function()
        Options:Hide()
    end)
    
    -- Popup de confirmación
    StaticPopupDialogs["SEQUITO_RESET_CONFIRM"] = {
        text = "¿Restaurar todas las opciones a valores por defecto?\n\n|cffff0000Esto requiere recargar la interfaz.|r",
        button1 = "Sí",
        button2 = "No",
        OnAccept = function()
            Options:ResetToDefaults()
        end,
        timeout = 0,
        whileDead = true,
        hideOnEscape = true,
    }
    
    -- Seleccionar categoría inicial
    Options:SelectCategory("general")
    
    return optionsFrame
end

-- ============================================
-- SELECCIONAR CATEGORÍA
-- ============================================
function Options:SelectCategory(categoryId)
    local f = self.frame
    if not f then return end

    currentCategory = categoryId
    currentModuleId = nil
    moduleButtons = {}
    
    -- Actualizar botones de categoría
    for id, btn in pairs(categoryButtons) do
        if id == categoryId then
            btn.bg:SetVertexColor(0.4, 0.2, 0.6, 0.9)
            btn.text:SetTextColor(1, 1, 1)
        else
            btn.bg:SetVertexColor(0.2, 0.2, 0.3, 0)
            btn.text:SetTextColor(0.8, 0.8, 0.8)
        end
    end
    
    -- Mostrar/ocultar contenido
    if f.categoryContents then
        for id, content in pairs(f.categoryContents) do
            if id == categoryId then
                content:Show()
            else
                content:Hide()
            end
        end
    end
    
    -- Cargar valores de la categoría
    if categoryId == "general" or categoryId == "interface" then
        self:LoadGeneralValues()
    end
end

-- ============================================
-- CARGAR/GUARDAR VALORES
-- ============================================
function Options:LoadGeneralValues()
    local db = S.db and S.db.profile or {}
    
    for _, control in ipairs(controls) do
        if control.key and not control.moduleId then
            local value = db[control.key]
            if value == nil then
                value = DEFAULT_GENERAL[control.key]
            end
            
            if value ~= nil then
                if control.controlType == "checkbox" then
                    control:SetChecked(value)
                elseif control.controlType == "slider" then
                    control:SetValue(value)
                elseif control.controlType == "dropdown" then
                    UIDropDownMenu_SetSelectedValue(control, value)
                    for _, opt in ipairs(control.options or {}) do
                        if opt.value == value then
                            UIDropDownMenu_SetText(control, opt.text)
                            break
                        end
                    end
                end
            end
        end
    end
end

function Options:SaveOptions()
    local db = S.db and S.db.profile or {}
    
    -- Guardar opciones generales
    for _, control in ipairs(controls) do
        if control.key then
            local value
            if control.controlType == "checkbox" then
                value = control:GetChecked()
            elseif control.controlType == "slider" then
                value = control:GetValue()
            elseif control.controlType == "dropdown" then
                value = UIDropDownMenu_GetSelectedValue(control)
            end
            
            if control.moduleId then
                -- Opción de módulo
                S.ModuleConfig:SetValue(control.moduleId, control.key, value)
            else
                -- Opción general
                db[control.key] = value
            end
        end
    end
    
    S:Print("Configuración guardada.")
end

function Options:ResetToDefaults()
    JainaDB.profile = {}
    ReloadUI()
end

-- ============================================
-- FUNCIONES PÚBLICAS
-- ============================================
function Options:Show()
    if not self.frame then
        self:Initialize()
    end
    self:LoadGeneralValues()
    self.frame:Show()
end

function Options:Hide()
    if self.frame then
        self.frame:Hide()
    end
end

function Options:Toggle()
    if S.Dashboard then
        S.Dashboard:Toggle()
        -- Optional: Switch to config tab if we want to force it
        -- S.Dashboard:SelectTab("Configuración") 
    else
        if self.frame and self.frame:IsVisible() then
            self:Hide()
        else
            self:Show()
        end
    end
end

function Options:Get(key)
    local db = S.db and S.db.profile or {}
    return db[key] or DEFAULT_GENERAL[key]
end

function Options:Set(key, value)
    local db = S.db and S.db.profile or {}
    db[key] = value
end

-- Registrar en Jaina
S.Options = Options
