--[[
    Sequito - ModuleConfig.lua
    Sistema de Configuración Modular
    Version: 8.0.0
    
    Este módulo proporciona un sistema unificado para que cada módulo
    tenga su propia interfaz de configuración accesible desde el panel principal.
]]

local addonName, S = ...
S.ModuleConfig = S.ModuleConfig or {}

local MC = S.ModuleConfig

-- Registro de módulos configurables
MC.Modules = {}

-- Frame principal de configuración de módulo
MC.ConfigFrame = nil
MC.CurrentModule = nil
MC.Initialized = false

-- ============================================
-- FUNCIONES DE UI
-- ============================================

-- Crear un boton simple
function MC:CreateButton(parent, key, label, x, y, width, func, tooltip)
    local btn = CreateFrame("Button", nil, parent, "UIPanelButtonTemplate")
    btn:SetPoint("TOPLEFT", parent, "TOPLEFT", x, y)
    btn:SetSize(width, 22)
    btn:SetText(label)
    
    btn.key = key
    
    if func then
        btn:SetScript("OnClick", func)
    end
    
    if tooltip then
        btn:SetScript("OnEnter", function(self)
            GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
            GameTooltip:SetText(tooltip, 1, 1, 1, 1, true)
            GameTooltip:Show()
        end)
        btn:SetScript("OnLeave", function() GameTooltip:Hide() end)
    end
    
    return btn
end

--[[
    Registra un módulo para que tenga configuración accesible
    @param moduleId: string - Identificador único del módulo
    @param config: table - Configuración del módulo:
        - name: string - Nombre para mostrar
        - icon: string - Ruta del icono
        - options: table - Lista de opciones configurables
        - onSave: function - Callback al guardar
        - onLoad: function - Callback al cargar
]]
function MC:RegisterModule(moduleId, config)
    -- Support both calling conventions:
    -- 1. RegisterModule("ModuleName", {options...})
    -- 2. RegisterModule({id = "ModuleName", options...})
    if type(moduleId) == "table" then
        -- Second format: single table with id inside
        config = moduleId
        moduleId = config.id
    end
    
    if not moduleId or not config then return end
    
    self.Modules[moduleId] = {
        id = moduleId,
        name = config.name or moduleId,
        icon = config.icon or "Interface\\Icons\\INV_Misc_Gear_01",
        description = config.description or "",
        options = config.options or {},
        onSave = config.onSave,
        onLoad = config.onLoad,
        category = config.category or "general", -- general, raid, pvp, dungeon, utility
    }
    
    -- Si el sistema ya arrancó, cargar configuración inmediatamente
    if self.Initialized and config.onLoad then
        local db = S.db and S.db.profile or {}
        local status, err = pcall(config.onLoad, db)
        if not status and S.Print then
            S:Print("|cFFFF0000Error cargando modulo " .. moduleId .. ": " .. tostring(err))
        end
    end
end

-- ============================================
-- FUNCIONES DE UI
-- ============================================

-- Crear un checkbox para configuración
function MC:CreateCheckbox(parent, key, label, x, y, tooltip, defaultValue)
    local cb = CreateFrame("CheckButton", nil, parent, "UICheckButtonTemplate")
    cb:SetPoint("TOPLEFT", parent, "TOPLEFT", x, y)
    cb:SetSize(24, 24)
    
    cb.label = cb:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    cb.label:SetPoint("LEFT", cb, "RIGHT", 5, 0)
    cb.label:SetText(label)
    
    cb.key = key
    cb.defaultValue = defaultValue or false
    
    if tooltip and type(tooltip) == "string" then
        cb:SetScript("OnEnter", function(self)
            GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
            GameTooltip:SetText(tooltip, 1, 1, 1, 1, true)
            GameTooltip:Show()
        end)
        cb:SetScript("OnLeave", function() GameTooltip:Hide() end)
    end
    
    return cb
end

-- Crear un slider para configuración
function MC:CreateSlider(parent, key, label, x, y, minVal, maxVal, step, tooltip, defaultValue)
    local slider = CreateFrame("Slider", nil, parent, "OptionsSliderTemplate")
    slider:SetPoint("TOPLEFT", parent, "TOPLEFT", x, y)
    slider:SetSize(180, 17)
    slider:SetMinMaxValues(minVal, maxVal)
    slider:SetValueStep(step)
    
    slider.Text = slider:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    slider.Text:SetPoint("BOTTOM", slider, "TOP", 0, 2)
    slider.Text:SetText(label)
    
    slider.Low = slider:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    slider.Low:SetPoint("TOPLEFT", slider, "BOTTOMLEFT", 0, -2)
    slider.Low:SetText(minVal)
    
    slider.High = slider:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    slider.High:SetPoint("TOPRIGHT", slider, "BOTTOMRIGHT", 0, -2)
    slider.High:SetText(maxVal)
    
    slider.Value = slider:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
    slider.Value:SetPoint("TOP", slider, "BOTTOM", 0, -2)
    
    slider:SetScript("OnValueChanged", function(self, value)
        self.Value:SetText(string.format("%.1f", value))
    end)
    
    slider.key = key
    slider.defaultValue = defaultValue or minVal
    
    if tooltip and type(tooltip) == "string" then
        slider:SetScript("OnEnter", function(self)
            GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
            GameTooltip:SetText(tooltip, 1, 1, 1, 1, true)
            GameTooltip:Show()
        end)
        slider:SetScript("OnLeave", function() GameTooltip:Hide() end)
    end
    
    return slider
end

-- Crear un dropdown para configuración
function MC:CreateDropdown(parent, key, label, x, y, options, tooltip, defaultValue)
    local dropdown = CreateFrame("Frame", "SequitoMC_" .. key, parent, "UIDropDownMenuTemplate")
    dropdown:SetPoint("TOPLEFT", parent, "TOPLEFT", x - 15, y)
    
    local labelText = dropdown:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    labelText:SetPoint("BOTTOMLEFT", dropdown, "TOPLEFT", 20, 2)
    labelText:SetText(label)
    
    UIDropDownMenu_SetWidth(dropdown, 150)
    dropdown:SetFrameStrata("FULLSCREEN_DIALOG") -- Ensure dropdown is on top (above DIALOG window)
    UIDropDownMenu_JustifyText(dropdown, "LEFT")
    
    dropdown.options = options
    dropdown.key = key
    dropdown.defaultValue = defaultValue
    
    UIDropDownMenu_Initialize(dropdown, function(self, level)
        for i, opt in ipairs(options) do
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
    
    return dropdown
end

-- Crear un editbox para configuración
function MC:CreateEditBox(parent, key, label, x, y, width, tooltip, defaultValue)
    local container = CreateFrame("Frame", nil, parent)
    container:SetPoint("TOPLEFT", parent, "TOPLEFT", x, y)
    container:SetSize(width + 10, 40)
    
    local labelText = container:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    labelText:SetPoint("TOPLEFT", container, "TOPLEFT", 0, 0)
    labelText:SetText(label)
    
    local editbox = CreateFrame("EditBox", nil, container, "InputBoxTemplate")
    editbox:SetPoint("TOPLEFT", labelText, "BOTTOMLEFT", 5, -2)
    editbox:SetSize(width, 20)
    editbox:SetAutoFocus(false)
    editbox:SetMaxLetters(256)
    
    editbox:SetScript("OnEscapePressed", function(self) self:ClearFocus() end)
    editbox:SetScript("OnEnterPressed", function(self) self:ClearFocus() end)
    
    editbox.key = key
    editbox.defaultValue = defaultValue or ""
    container.editbox = editbox
    
    return container
end

-- ============================================
-- FRAME DE CONFIGURACIÓN DE MÓDULO
-- ============================================

function MC:CreateConfigFrame()
    if self.ConfigFrame then return self.ConfigFrame end
    
    local f = CreateFrame("Frame", "SequitoModuleConfigFrame", UIParent)
    f:SetSize(500, 450)
    f:SetPoint("CENTER", UIParent, "CENTER", 0, 0)
    f:SetMovable(true)
    f:EnableMouse(true)
    f:RegisterForDrag("LeftButton")
    f:SetScript("OnDragStart", f.StartMoving)
    f:SetScript("OnDragStop", f.StopMovingOrSizing)
    f:SetClampedToScreen(true)
    f:SetFrameStrata("DIALOG")
    f:Hide()
    
    -- Fondo
    f.bg = f:CreateTexture(nil, "BACKGROUND")
    f.bg:SetAllPoints()
    f.bg:SetTexture(0.05, 0.05, 0.1, 0.95)
    
    -- Borde
    f.border = CreateFrame("Frame", nil, f)
    f.border:SetAllPoints()
    f.border:SetBackdrop({
        edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
        edgeSize = 16,
        insets = {left = 4, right = 4, top = 4, bottom = 4},
    })
    f.border:SetBackdropBorderColor(0.6, 0.4, 0.8, 1)
    
    -- Título
    f.title = f:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
    f.title:SetPoint("TOP", f, "TOP", 0, -10)
    f.title:SetText("|cff9966ffSequito|r - Configuración de Módulo")
    
    -- Botón cerrar
    f.closeBtn = CreateFrame("Button", nil, f, "UIPanelCloseButton")
    f.closeBtn:SetPoint("TOPRIGHT", f, "TOPRIGHT", -2, -2)
    f.closeBtn:SetScript("OnClick", function() MC:HideConfig() end)
    
    -- Lista de módulos (izquierda)
    f.moduleList = CreateFrame("Frame", nil, f)
    f.moduleList:SetPoint("TOPLEFT", f, "TOPLEFT", 10, -40)
    f.moduleList:SetSize(140, 360)
    f.moduleList:SetBackdrop({
        bgFile = "Interface\\Tooltips\\UI-Tooltip-Background",
        edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
        tile = true, tileSize = 8, edgeSize = 8,
        insets = {left = 2, right = 2, top = 2, bottom = 2}
    })
    f.moduleList:SetBackdropColor(0.1, 0.1, 0.1, 0.8)
    
    -- Scroll para lista de módulos
    f.moduleScroll = CreateFrame("ScrollFrame", "SequitoMCModuleScroll", f.moduleList, "UIPanelScrollFrameTemplate")
    f.moduleScroll:SetPoint("TOPLEFT", f.moduleList, "TOPLEFT", 4, -4)
    f.moduleScroll:SetPoint("BOTTOMRIGHT", f.moduleList, "BOTTOMRIGHT", -24, 4)
    
    f.moduleContent = CreateFrame("Frame", nil, f.moduleScroll)
    f.moduleContent:SetSize(110, 500)
    f.moduleScroll:SetScrollChild(f.moduleContent)
    
    -- Panel de configuración (derecha)
    f.configPanel = CreateFrame("Frame", nil, f)
    f.configPanel:SetPoint("TOPLEFT", f.moduleList, "TOPRIGHT", 10, 0)
    -- Increase bottom inset significantly to 120 to fix ongoing overlap
    f.configPanel:SetPoint("BOTTOMRIGHT", f, "BOTTOMRIGHT", -10, 120)
    f.configPanel:SetBackdrop({
        bgFile = "Interface\\Tooltips\\UI-Tooltip-Background",
        edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
        tile = true, tileSize = 8, edgeSize = 8,
        insets = {left = 2, right = 2, top = 2, bottom = 2}
    })
    f.configPanel:SetBackdropColor(0.1, 0.1, 0.1, 0.8)
    
    -- Scroll para panel de config (Force clipping)
    f.configScroll = CreateFrame("ScrollFrame", "SequitoMCConfigScroll", f.configPanel, "UIPanelScrollFrameTemplate")
    if f.configScroll.SetClipsChildren then
        f.configScroll:SetClipsChildren(true)
    end
    f.configScroll:SetPoint("TOPLEFT", f.configPanel, "TOPLEFT", 4, -4)
    f.configScroll:SetPoint("BOTTOMRIGHT", f.configPanel, "BOTTOMRIGHT", -24, 4)
    
    f.configContent = CreateFrame("Frame", nil, f.configScroll)
    f.configContent:SetSize(300, 600)
    f.configScroll:SetScrollChild(f.configContent)
    
    -- Botones inferiores
    local btnSave = CreateFrame("Button", nil, f, "UIPanelButtonTemplate")
    btnSave:SetSize(100, 25)
    btnSave:SetPoint("BOTTOMRIGHT", f, "BOTTOMRIGHT", -15, 15)
    btnSave:SetText("Guardar")
    btnSave:SetFrameLevel(f.configPanel:GetFrameLevel() + 5) -- Ensure above scroll
    btnSave:SetScript("OnClick", function() MC:SaveCurrentModule() end)
    
    local btnDefaults = CreateFrame("Button", nil, f, "UIPanelButtonTemplate")
    btnDefaults:SetSize(100, 25)
    btnDefaults:SetPoint("RIGHT", btnSave, "LEFT", -10, 0)
    btnDefaults:SetText("Por Defecto")
    btnDefaults:SetFrameLevel(f.configPanel:GetFrameLevel() + 5) -- Ensure above scroll
    btnDefaults:SetScript("OnClick", function() MC:ResetCurrentModule() end)
    
    self.ConfigFrame = f
    return f
end

function MC:PopulateModuleList()
    if not self.ConfigFrame then return end
    
    local content = self.ConfigFrame.moduleContent
    
    -- Limpiar botones existentes
    for _, child in ipairs({content:GetChildren()}) do
        child:Hide()
        child:SetParent(nil)
    end
    
    -- Ordenar módulos por categoría
    local categories = {
        {id = "general", name = "|cffffffffGeneral|r"},
        {id = "raid", name = "|cff00ff00Raid|r"},
        {id = "pvp", name = "|cffff0000PvP|r"},
        {id = "dungeon", name = "|cff00ffffDungeon|r"},
        {id = "utility", name = "|cffffff00Utilidad|r"},
    }
    
    local yOffset = 0
    
    for _, cat in ipairs(categories) do
        local hasModules = false
        for id, mod in pairs(self.Modules) do
            if mod.category == cat.id then
                hasModules = true
                break
            end
        end
        
        if hasModules then
            -- Header de categoría
            local header = content:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
            header:SetPoint("TOPLEFT", content, "TOPLEFT", 5, -yOffset)
            header:SetText(cat.name)
            yOffset = yOffset + 18
            
            -- Módulos de esta categoría
            for id, mod in pairs(self.Modules) do
                if mod.category == cat.id then
                    local btn = CreateFrame("Button", nil, content)
                    btn:SetSize(100, 20)
                    btn:SetPoint("TOPLEFT", content, "TOPLEFT", 10, -yOffset)
                    
                    btn.text = btn:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
                    btn.text:SetPoint("LEFT", btn, "LEFT", 2, 0)
                    btn.text:SetText(mod.name)
                    
                    btn.bg = btn:CreateTexture(nil, "BACKGROUND")
                    btn.bg:SetAllPoints()
                    btn.bg:SetTexture(0.3, 0.3, 0.3, 0)
                    
                    btn:SetScript("OnEnter", function(self)
                        self.bg:SetTexture(0.4, 0.3, 0.6, 0.5)
                    end)
                    btn:SetScript("OnLeave", function(self)
                        if MC.CurrentModule ~= id then
                            self.bg:SetTexture(0.3, 0.3, 0.3, 0)
                        end
                    end)
                    btn:SetScript("OnClick", function()
                        MC:ShowModuleConfig(id)
                    end)
                    
                    btn.moduleId = id
                    yOffset = yOffset + 22
                end
            end
            
            yOffset = yOffset + 5
        end
    end
    
    content:SetHeight(math.max(yOffset, 100))
end

function MC:ShowModuleConfig(moduleId)
    local mod = self.Modules[moduleId]
    if not mod then return end
    
    self.CurrentModule = moduleId
    
    local content = self.ConfigFrame.configContent
    
    -- Limpiar contenido existente (frames)
    for _, child in ipairs({content:GetChildren()}) do
        child:Hide()
        child:SetParent(nil)
    end
    
    -- Limpiar regiones (FontStrings, Textures)
    for _, region in ipairs({content:GetRegions()}) do
        region:Hide()
        if region.SetText then
            region:SetText("")
        end
        if region.SetTexture then
            region:SetTexture(nil)
        end
    end
    
    -- Título del módulo
    local title = content:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
    title:SetPoint("TOPLEFT", content, "TOPLEFT", 10, -10)
    title:SetText("|cff9966ff" .. mod.name .. "|r")
    
    -- Descripción
    if mod.description and mod.description ~= "" then
        local desc = content:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
        desc:SetPoint("TOPLEFT", title, "BOTTOMLEFT", 0, -5)
        desc:SetWidth(280)
        desc:SetJustifyH("LEFT")
        desc:SetText(mod.description)
    end
    
    -- Crear controles para cada opción
    local yOffset = -50
    
    -- Ajustar yOffset si hay descripción
    if mod.description and mod.description ~= "" then
        -- Encontrar el objeto de descripción que acabamos de crear (es el último region)
        local regions = {content:GetRegions()}
        local desc = regions[#regions] 
        if desc and desc.GetStringHeight then
            local height = desc:GetStringHeight()
            yOffset = -45 - height - 10
        end
    end
    self.ConfigFrame.controls = {}
    
    for i, opt in ipairs(mod.options) do
        local control
        
        if opt.type == "checkbox" then
            control = self:CreateCheckbox(content, opt.key, opt.label, 10, yOffset, opt.tooltip, opt.default)
            yOffset = yOffset - 30
        elseif opt.type == "slider" then
            control = self:CreateSlider(content, opt.key, opt.label, 10, yOffset - 15, 
                opt.min or 0, opt.max or 100, opt.step or 1, opt.tooltip, opt.default)
            yOffset = yOffset - 60
        elseif opt.type == "dropdown" then
            control = self:CreateDropdown(content, opt.key, opt.label, 10, yOffset - 10, 
                opt.options, opt.tooltip, opt.default)
            yOffset = yOffset - 55
        elseif opt.type == "editbox" then
            control = self:CreateEditBox(content, opt.key, opt.label, 10, yOffset, 
                opt.width or 150, opt.tooltip, opt.default)
            yOffset = yOffset - 50
        elseif opt.type == "header" then
            local header = content:CreateFontString(nil, "OVERLAY", "GameFontNormal")
            header:SetPoint("TOPLEFT", content, "TOPLEFT", 10, yOffset)
            header:SetText("|cffffcc00" .. opt.label .. "|r")
            yOffset = yOffset - 25
        elseif opt.type == "button" then
            control = self:CreateButton(content, opt.key, opt.label, 10, yOffset, opt.width or 120, opt.func, opt.tooltip)
            yOffset = yOffset - 30
        end
        
        if control then
            table.insert(self.ConfigFrame.controls, control)
        end
    end
    
    content:SetHeight(math.abs(yOffset) + 50)
    
    -- Cargar valores actuales
    self:LoadModuleValues(moduleId)
end

function MC:LoadModuleValues(moduleId)
    local mod = self.Modules[moduleId]
    if not mod or not self.ConfigFrame.controls then return end
    
    local db = S.db and S.db.profile or {}
    
    for _, control in ipairs(self.ConfigFrame.controls) do
        if control.key then
            local dbKey = moduleId .. "_" .. control.key
            local value = db[dbKey]
            
            if value == nil then
                value = control.defaultValue
            end
            
            if control.SetChecked then -- Checkbox
                control:SetChecked(value)
            elseif control.SetValue then -- Slider
                control:SetValue(value or control.defaultValue)
            elseif control.SetSelectedValue then -- Dropdown
                UIDropDownMenu_SetSelectedValue(control, value)
                UIDropDownMenu_JustifyText(control, "LEFT")
                -- Buscar texto
                local found = false
                for _, opt in ipairs(control.options or {}) do
                    if opt.value == value then
                        UIDropDownMenu_SetText(control, opt.text)
                        found = true
                        break
                    end
                end
                if not found then
                    UIDropDownMenu_SetText(control, tostring(value or ""))
                end
            elseif control.editbox then -- EditBox
                control.editbox:SetText(value or "")
            end
        end
    end
    
    -- Callback de carga
    if mod.onLoad then
        mod.onLoad(db)
    end
end

function MC:SaveCurrentModule()
    if not self.CurrentModule or not self.ConfigFrame.controls then return end
    
    local mod = self.Modules[self.CurrentModule]
    if not mod then return end
    
    local db = S.db and S.db.profile or {}
    
    for _, control in ipairs(self.ConfigFrame.controls) do
        if control.key then
            local dbKey = self.CurrentModule .. "_" .. control.key
            local value
            
            if control.GetChecked then -- Checkbox
                value = control:GetChecked()
            elseif control.GetValue then -- Slider
                value = control:GetValue()
            elseif UIDropDownMenu_GetSelectedValue then -- Dropdown
                value = UIDropDownMenu_GetSelectedValue(control)
            elseif control.editbox then -- EditBox
                value = control.editbox:GetText()
            end
            
            db[dbKey] = value
        end
    end
    
    -- Callback de guardado
    if mod.onSave then
        mod.onSave(db)
    end
    
    S:Print("Configuración de " .. mod.name .. " guardada.")
end

function MC:ResetCurrentModule()
    if not self.CurrentModule or not self.ConfigFrame.controls then return end
    
    for _, control in ipairs(self.ConfigFrame.controls) do
        if control.key and control.defaultValue ~= nil then
            if control.SetChecked then
                control:SetChecked(control.defaultValue)
            elseif control.SetValue then
                control:SetValue(control.defaultValue)
            elseif control.editbox then
                control.editbox:SetText(control.defaultValue or "")
            end
        end
    end
    
    S:Print("Valores por defecto restaurados.")
end

function MC:ShowConfig()
    if not self.ConfigFrame then
        self:CreateConfigFrame()
    end
    
    self:PopulateModuleList()
    self.ConfigFrame:Show()
    
    -- Mostrar primer módulo si hay alguno
    for id, _ in pairs(self.Modules) do
        self:ShowModuleConfig(id)
        break
    end
end

function MC:HideConfig()
    if self.ConfigFrame then
        self.ConfigFrame:Hide()
    end
end

function MC:Toggle()
    if self.ConfigFrame and self.ConfigFrame:IsVisible() then
        self:HideConfig()
    else
        self:ShowConfig()
    end
end

function MC:OpenCategory(moduleId)
    if not self.ConfigFrame then
        self:CreateConfigFrame()
    end
    
    self:PopulateModuleList() -- Asegurar que lista esta creada
    self.ConfigFrame:Show()
    
    if self.Modules[moduleId] then
        self:ShowModuleConfig(moduleId)
    else
        -- Fallback: show first
        for id, _ in pairs(self.Modules) do
            self:ShowModuleConfig(id)
            break
        end
    end
end

-- ============================================
-- FUNCIÓN HELPER PARA OBTENER VALOR DE CONFIG
-- ============================================

function MC:GetValue(moduleId, key)
    local db = S.db and S.db.profile or {}
    local dbKey = moduleId .. "_" .. key
    local value = db[dbKey]
    
    -- Si no existe, buscar default en modulo registrado
    if value == nil then
        local mod = self.Modules[moduleId]
        if mod and mod.options then
            for _, opt in ipairs(mod.options) do
                if opt.key == key then
                    return opt.default
                end
            end
        end
    end
    
    -- Fallback de resiliencia: si es 'enabled' y no está explícitamente en la base de datos, siempre es true
    if value == nil and key == "enabled" then
        return true
    end
    
    return value
end

function MC:SetValue(moduleId, key, value)
    local db = S.db and S.db.profile or {}
    local dbKey = moduleId .. "_" .. key
    db[dbKey] = value
end

-- ============================================
-- REGISTRO DE TODOS LOS MÓDULOS
-- ============================================

function MC:RegisterAllModules()
    -- ===== PVP =====
    self:RegisterModule("TrinketTracker", {
        name = "Trinket Tracker",
        category = "pvp",
        description = "Rastrea cuando enemigos usan trinket PvP y muestra cooldown de 2 min.",
        options = {
            {type = "checkbox", key = "enabled", label = "Habilitado", default = true, tooltip = "Activa el rastreo de trinkets PvP"},
            {type = "checkbox", key = "sound", label = "Sonido de alerta", default = true, tooltip = "Reproduce sonido cuando un enemigo usa trinket"},
            {type = "checkbox", key = "announce", label = "Anunciar en chat", default = true, tooltip = "Anuncia en party/raid cuando un enemigo usa trinket"},
            {type = "checkbox", key = "nameplates", label = "Mostrar en nameplates", default = true, tooltip = "Muestra icono de trinket en CD sobre los nameplates"},
        }
    })
    
    self:RegisterModule("CCCoordinator", {
        name = "CC Coordinator",
        category = "pvp",
        description = "Coordina crowd control y rastrea diminishing returns.",
        options = {
            {type = "checkbox", key = "enabled", label = "Habilitado", default = true, tooltip = "Activa el coordinador de CC"},
            {type = "checkbox", key = "drTracking", label = "Rastrear DR", default = true, tooltip = "Muestra diminishing returns de cada objetivo"},
            {type = "checkbox", key = "alerts", label = "Alertas de CC roto", default = true, tooltip = "Alerta cuando alguien rompe un CC"},
            {type = "checkbox", key = "announce", label = "Anunciar en chat", default = false, tooltip = "Anuncia CCs rotos en party/raid"},
        }
    })
    
    self:RegisterModule("HealerTracker", {
        name = "Healer Tracker",
        category = "pvp",
        description = "Monitorea healers enemigos y su mana con cero impacto de rendimiento.",
        options = {
            {type = "checkbox", key = "enabled", label = "Habilitado", default = true, tooltip = "Activa el rastreo de healers"},
            {type = "checkbox", key = "autoDetect", label = "Detección Automática", default = true, tooltip = "Detecta healers automáticamente por sus hechizos"},
            {type = "checkbox", key = "alertLowMana", label = "Alertar Mana Bajo", default = true, tooltip = "Alerta cuando un healer tiene mana bajo"},
            {type = "slider", key = "lowManaThreshold", label = "Umbral de mana bajo (%)", min = 10, max = 50, step = 5, default = 30, tooltip = "Alerta cuando el healer tiene menos de este % de mana"},
            {type = "checkbox", key = "announceToGroup", label = "Anunciar al Grupo", default = false, tooltip = "Anuncia healers con mana bajo al grupo"},
            {type = "checkbox", key = "playSound", label = "Reproducir Sonido", default = true, tooltip = "Reproduce sonido cuando healer tiene mana bajo"},
            {type = "slider", key = "updateInterval", label = "Intervalo Actualización (seg)", min = 0.1, max = 1.0, step = 0.1, default = 0.2, tooltip = "Frecuencia de sondeo de mana"},
        }
    })
    
    self:RegisterModule("FocusFire", {
        name = "Focus Fire",
        category = "pvp",
        description = "Sistema de llamadas de target para el grupo.",
        options = {
            {type = "checkbox", key = "enabled", label = "Habilitado", default = true, tooltip = "Activa el sistema de focus fire"},
            {type = "checkbox", key = "sound", label = "Sonido de alerta", default = true, tooltip = "Reproduce sonido cuando se marca un target"},
            {type = "checkbox", key = "announce", label = "Anunciar en chat", default = true, tooltip = "Anuncia el focus target en party/raid"},
            {type = "checkbox", key = "showFrame", label = "Mostrar barra de HP", default = true, tooltip = "Muestra la barra de vida del focus target"},
        }
    })
    
    -- ===== RAID =====
    self:RegisterModule("RaidAssist", {
        name = "Raid Assist",
        category = "raid",
        description = "Sistema completo de asistencia para raids.",
        options = {
            {type = "checkbox", key = "enabled", label = "Habilitado", default = true, tooltip = "Activa el sistema de Raid Assist"},
            {type = "dropdown", key = "mode", label = "Modo", options = {
                {text = "Farm (menos avisos)", value = "FARM"},
                {text = "Progresión (más ayuda)", value = "PROGRESSION"},
            }, default = "PROGRESSION", tooltip = "Ajusta el nivel de asistencia"},
            {type = "checkbox", key = "interrupts", label = "Coordinador de Interrupciones", default = true, tooltip = "Rastrea y sugiere turnos de interrupción"},
            {type = "checkbox", key = "cooldowns", label = "Compartir Cooldowns", default = true, tooltip = "Sincroniza cooldowns importantes del raid"},
            {type = "checkbox", key = "markers", label = "Marcadores Inteligentes", default = true, tooltip = "Distribuye objetivos entre DPS"},
            {type = "checkbox", key = "pullTimer", label = "Pull Timer", default = true, tooltip = "Countdown sincronizado para pulls"},
        }
    })
    
    self:RegisterModule("WipeAnalyzer", {
        name = "Wipe Analyzer",
        category = "raid",
        description = "Analiza wipes para identificar causas de muerte.",
        options = {
            {type = "checkbox", key = "enabled", label = "Habilitado", default = true, tooltip = "Activa el análisis post-wipe"},
            {type = "checkbox", key = "autoShow", label = "Mostrar automáticamente", default = true, tooltip = "Muestra el análisis al detectar wipe"},
            {type = "checkbox", key = "announce", label = "Anunciar en raid", default = false, tooltip = "Anuncia resumen de wipe en raid chat"},
        }
    })
    
    self:RegisterModule("CooldownMonitor", {
        name = "Cooldown Monitor",
        category = "raid",
        description = "Monitorea cooldowns importantes del raid.",
        options = {
            {type = "checkbox", key = "enabled", label = "Habilitado", default = true, tooltip = "Activa el monitor de cooldowns"},
            {type = "checkbox", key = "timelineMode", label = "Modo Cronograma", default = true, tooltip = "Visualización estilo barra de tiempo suavizada"},
            {type = "checkbox", key = "compact", label = "Modo Compacto", default = false, tooltip = "Usa una visualización más pequeña"},
            {type = "checkbox", key = "classColor", label = "Color por Clase", default = true, tooltip = "Colorear barras por clase en lugar de tipo"},
            {type = "checkbox", key = "alerts", label = "Alertas de CD listos", default = true, tooltip = "Alerta cuando CDs importantes están disponibles"},
            {type = "checkbox", key = "sync", label = "Sincronizar con raid", default = true, tooltip = "Comparte información de CDs con otros Sequito"},
        }
    })
    
    self:RegisterModule("SequitoPlates", {
        name = "Sequito Plates",
        category = "interface",
        description = "Mejoras para Nameplates: CC, Threat y Ejecución.",
        options = {
            {type = "checkbox", key = "enabled", label = "Habilitado", default = true, tooltip = "Activa las mejoras de nameplates"},
            {type = "checkbox", key = "showCC", label = "Mostrar CC", default = true, tooltip = "Muestra iconos de control de masas sobre las placas"},
            {type = "checkbox", key = "showThreat", label = "Indicador de Amenaza", default = true, tooltip = "Cambia el color/brillo si tienes el agro"},
            {type = "slider", key = "scale", label = "Escala de Iconos", min = 0.5, max = 2.0, step = 0.1, default = 1.0, tooltip = "Tamaño de los iconos de CC"},
        }
    })
    
    self:RegisterModule("Assignments", {
        name = "Asignaciones",
        category = "raid",
        description = "Sistema de asignaciones para raid.",
        options = {
            {type = "checkbox", key = "enabled", label = "Habilitado", default = true, tooltip = "Activa el sistema de asignaciones"},
            {type = "checkbox", key = "sync", label = "Sincronizar", default = true, tooltip = "Sincroniza asignaciones con raid"},
            {type = "checkbox", key = "announce", label = "Anunciar cambios", default = true, tooltip = "Anuncia cambios de asignación en raid"},
        }
    })
    
    self:RegisterModule("ReadyChecker", {
        name = "Ready Checker",
        category = "raid",
        description = "Verifica preparación del raid.",
        options = {
            {type = "checkbox", key = "enabled", label = "Habilitado", default = true, tooltip = "Activa el ready checker"},
            {type = "checkbox", key = "flask", label = "Verificar Flask", default = true, tooltip = "Verifica que todos tengan flask"},
            {type = "checkbox", key = "food", label = "Verificar Food", default = true, tooltip = "Verifica que todos tengan food buff"},
        }
    })
    
    -- ===== DUNGEON =====
    self:RegisterModule("PullGuide", {
        name = "Pull Guide",
        category = "dungeon",
        description = "Guía de pulls para dungeons con marcado automático.",
        options = {
            {type = "checkbox", key = "enabled", label = "Habilitado", default = true, tooltip = "Activa la guía de pulls"},
            {type = "checkbox", key = "autoMark", label = "Marcado automático", default = true, tooltip = "Marca automáticamente orden de kill"},
            {type = "checkbox", key = "suggestCC", label = "Sugerir CC", default = true, tooltip = "Sugiere CCs para packs grandes"},
            {type = "checkbox", key = "showFrame", label = "Mostrar panel", default = true, tooltip = "Muestra el panel de pull guide"},
        }
    })
    
    self:RegisterModule("DungeonTimer", {
        name = "Dungeon Timer",
        category = "dungeon",
        description = "Timer y recordatorios para dungeons.",
        options = {
            {type = "checkbox", key = "enabled", label = "Habilitado", default = true, tooltip = "Activa el timer de dungeon"},
            {type = "checkbox", key = "reminders", label = "Recordatorios", default = true, tooltip = "Muestra recordatorios durante el dungeon"},
            {type = "checkbox", key = "showSplits", label = "Mostrar splits", default = true, tooltip = "Muestra tiempos parciales por boss"},
        }
    })
    
    -- ===== UTILITY =====
    self:RegisterModule("DefensiveAlerts", {
        name = "Defensive Alerts",
        category = "utility",
        description = "Alertas de defensivos importantes.",
        options = {
            {type = "checkbox", key = "enabled", label = "Habilitado", default = true, tooltip = "Activa alertas de defensivos"},
            {type = "checkbox", key = "sound", label = "Sonido", default = true, tooltip = "Reproduce sonido con alertas"},
            {type = "checkbox", key = "announce", label = "Anunciar", default = false, tooltip = "Anuncia defensivos usados"},
        }
    })
    
    self:RegisterModule("LootCouncil", {
        name = "Loot Council",
        category = "utility",
        description = "Sistema de loot council para guild.",
        options = {
            {type = "checkbox", key = "enabled", label = "Habilitado", default = true, tooltip = "Activa el sistema de loot council"},
            {type = "checkbox", key = "autoOpen", label = "Abrir automáticamente", default = true, tooltip = "Abre el panel al detectar loot de boss"},
        }
    })
    
    self:RegisterModule("PlayerNotes", {
        name = "Player Notes",
        category = "utility",
        description = "Notas sobre jugadores.",
        options = {
            {type = "checkbox", key = "enabled", label = "Habilitado", default = true, tooltip = "Activa el sistema de notas"},
            {type = "checkbox", key = "share", label = "Compartir notas", default = true, tooltip = "Sincroniza notas con otros officiales"},
        }
    })
    
    self:RegisterModule("EventCalendar", {
        name = "Event Calendar",
        category = "utility",
        description = "Calendario de eventos y raids de hermandad.",
        options = {
            {type = "checkbox", key = "enabled", label = "Habilitado", default = true, tooltip = "Activa el calendario de eventos"},
            {type = "checkbox", key = "reminders", label = "Recordatorios", default = true, tooltip = "Muestra recordatorios de eventos próximos en el chat"},
            {type = "slider", key = "reminderTime", label = "Minutos antes", min = 5, max = 60, step = 5, default = 15, tooltip = "Minutos antes del evento para emitir el recordatorio"},
            {type = "checkbox", key = "soundAlert", label = "Alerta Sonora", default = true, tooltip = "Reproduce un sonido de aviso cuando suena un recordatorio"},
        }
    })
    
    self:RegisterModule("VotingSystem", {
        name = "Voting System",
        category = "utility",
        description = "Sistema democrático de votaciones para raid o grupo.",
        options = {
            {type = "checkbox", key = "enabled", label = "Habilitado", default = true, tooltip = "Activa el sistema de votaciones"},
            {type = "slider", key = "timeout", label = "Tiempo límite (seg)", min = 15, max = 300, step = 15, default = 60, tooltip = "Segundos para votar antes de cerrar la encuesta"},
            {type = "checkbox", key = "announceResults", label = "Anunciar resultados", default = true, tooltip = "Anuncia los resultados finales en el chat de banda o grupo"},
            {type = "checkbox", key = "playSound", label = "Alerta Sonora", default = true, tooltip = "Emite un aviso sonoro al iniciar una votación"},
        }
    })
    
    self:RegisterModule("VersionSync", {
        name = "Version Sync",
        category = "utility",
        description = "Sincroniza versión con otros usuarios.",
        options = {
            {type = "checkbox", key = "enabled", label = "Habilitado", default = true, tooltip = "Activa la sincronización de versión"},
            {type = "checkbox", key = "autoCheck", label = "Verificar automáticamente", default = true, tooltip = "Verifica versión al entrar en raid"},
        }
    })
    
    self:RegisterModule("QuickWhisper", {
        name = "Quick Whisper",
        category = "utility",
        description = "Whispers rápidos a miembros del raid.",
        options = {
            {type = "checkbox", key = "enabled", label = "Habilitado", default = true, tooltip = "Activa quick whisper"},
        }
    })
    
    self:RegisterModule("Logistics", {
        name = "Logistics",
        category = "utility",
        description = "Gestión automática de inventario, reparaciones y fragmentos de alma.",
        icon = "Interface\\Icons\\INV_Misc_Bag_08",
        options = {
            {type = "checkbox", key = "enabled", label = "Habilitado", default = true, tooltip = "Activa el módulo de logística"},
            {type = "checkbox", key = "autoSell", label = "Vender Basura", default = true, tooltip = "Vende automáticamente objetos de calidad gris en los mercaderes"},
            {type = "checkbox", key = "autoRepair", label = "Reparación Automática", default = true, tooltip = "Repara tu equipo automáticamente al abrir un mercader"},
            {type = "checkbox", key = "autoTrade", label = "Auto-Trade", default = false, tooltip = "Entrega automáticamente Piedras de Salud o Agua de Maná a compañeros"},
            {type = "slider", key = "shardLimit", label = "Límite de Soul Shards", min = 10, max = 32, step = 1, default = 28, tooltip = "Cantidad máxima de fragmentos de alma antes de purgar los sobrantes (Brujo)"},
        }
    })
    
    self:RegisterModule("PerformanceStats", {
        name = "Performance Stats",
        category = "utility",
        description = "Estadísticas de rendimiento del raid.",
        options = {
            {type = "checkbox", key = "enabled", label = "Habilitado", default = true, tooltip = "Activa estadísticas de rendimiento"},
            {type = "checkbox", key = "autoTrack", label = "Rastreo automático", default = true, tooltip = "Inicia rastreo al entrar en combate"},
        }
    })
    
    self:RegisterModule("BuildManager", {
        name = "Build Manager",
        category = "utility",
        description = "Gestión de builds y specs.",
        options = {
            {type = "checkbox", key = "enabled", label = "Habilitado", default = true, tooltip = "Activa el gestor de builds"},
        }
    })

    self:RegisterModule("GUI", {
        name = "Interfaz (Esfera)",
        category = "utility",
        description = "Interfaz principal (Esfera y botones)",
        options = {
            {type = "checkbox", key = "enabled", label = "Habilitado", default = true, tooltip = "Activa la esfera principal"},
        },
        onSave = function()
            -- Toggle dinámico sin reload
            local enabled = S.ModuleConfig:GetValue("GUI", "enabled")
            if S.Sphere then
                if enabled then 
                    S.Sphere:Show()
                else 
                    S.Sphere:Hide() 
                end
            elseif enabled and S.GUI then
                -- Si no existe pero se habilitó, intentar crearla
                S.GUI:Initialize()
            end
        end
    })

    -- Internal Modules Registration
    self:RegisterModule("Menu", {
        name = "Menu Contextual",
        category = "utility",
        description = "Menú de clic derecho en la esfera",
        options = { {type = "checkbox", key = "enabled", label = "Habilitado", default = true} }
    })

    self:RegisterModule("Mounts", {
        name = "Montura Inteligente",
        category = "utility",
        description = "Invoca montura (Voladora/Terrestre/Acuática) con un solo botón",
        options = { {type = "checkbox", key = "enabled", label = "Habilitado", default = true} }
    })

    self:RegisterModule("Runes", {
        name = "Visualizador de Runas",
        category = "class",
        description = "Muestra runas de DK (Solo Death Knight)",
        options = { {type = "checkbox", key = "enabled", label = "Habilitado", default = true} }
    })

    self:RegisterModule("Visuals", {
        name = "Efectos Visuales",
        category = "utility",
        icon = "Interface\\Icons\\Spell_Shadow_SoulGem",
        description = "Efectos visuales inmersivos: latido de corazón, brillo de procs y efectos de pantalla completa",
        options = {
            {type = "checkbox", key = "enabled", label = "Habilitar Efectos Visuales", default = true, tooltip = "Activar o desactivar todos los efectos visuales"},
            {type = "checkbox", key = "heartbeatEnabled", label = "Latido de Corazón", default = true, tooltip = "Efecto de latido y pulsación roja cuando la vida está por debajo del 35%"},
            {type = "checkbox", key = "procGlowEnabled", label = "Brillo de Procs", default = true, tooltip = "Resaltar botones satélite cuando hay procs activos"},
            {type = "checkbox", key = "procOverlayEnabled", label = "Overlay de Procs", default = true, tooltip = "Efecto visual inmersivo en pantalla al activarse procs mayores"},
            {type = "checkbox", key = "soulSiphonEnabled", label = "Soul Siphon (Brujo)", default = true, tooltip = "Efecto visual morado y auditivo de absorción de alma al matar a un enemigo (Solo Brujo)"},
            {type = "slider", key = "glowIntensity", label = "Intensidad del Brillo", min = 0.5, max = 2.0, step = 0.1, default = 1.0, tooltip = "Intensidad y opacidad del efecto de brillo en los botones"}
        }
    })

    self:RegisterModule("SpecWatcher", {
        name = "Detector de Talentos",
        category = "utility",
        description = "Actualiza macros al cambiar de talentos (Dual Spec)",
        options = { {type = "checkbox", key = "enabled", label = "Habilitado", default = true} }
    })
    
    self:RegisterModule("MacroGen", {
        name = "Generador de Macros",
        category = "utility",
        description = "Genera macros inteligentes por clase",
        options = { {type = "checkbox", key = "enabled", label = "Habilitado", default = true} }
    })

    self:RegisterModule("MacroSync", {
        name = "Sincronización de Macros",
        category = "raid",
        description = "Permite compartir macros con el grupo",
        options = { {type = "checkbox", key = "enabled", label = "Habilitado", default = true} }
    })

    -- Core System Modules
    self:RegisterModule("RaidSync", {
        name = "Sincronización de Raid",
        category = "raid",
        description = "HiveMind: Sincroniza datos entre usuarios",
        options = { {type = "checkbox", key = "enabled", label = "Habilitado", default = true} }
    })

    self:RegisterModule("RaidIntel", {
        name = "Inteligencia de Raid",
        category = "raid",
        description = "Escanea buffs y alertas estratégicas",
        options = { {type = "checkbox", key = "enabled", label = "Habilitado", default = true} }
    })

    self:RegisterModule("CombatTracker", {
        name = "Rastreador de Combate",
        category = "raid",
        description = "Registra DPS, HPS y muertes",
        options = { {type = "checkbox", key = "enabled", label = "Habilitado", default = true} }
    })

    self:RegisterModule("WipeAnalyzer", {
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

    self:RegisterModule("Logistics", {
        name = "Logística (Venta/Reparación)",
        category = "utility",
        description = "Venta automática de basura y reparación",
        options = { {type = "checkbox", key = "enabled", label = "Habilitado", default = true} }
    })

    self:RegisterModule("PlayerNotes", {
        name = "Notas de Jugador",
        category = "utility",
        icon = "Interface\\Icons\\INV_Misc_Note_01",
        description = "Sistema de notas personales sobre jugadores (tooltips, comandos slash e inspección)",
        options = {
            {type = "checkbox", key = "enabled", label = "Habilitar Notas", default = true, tooltip = "Activa/desactiva el sistema de notas"},
            {type = "checkbox", key = "showInTooltip", label = "Mostrar en Tooltip", default = true, tooltip = "Muestra la nota en el GameTooltip al pasar el cursor sobre el jugador"},
            {type = "checkbox", key = "autoSave", label = "Guardado Automático", default = true, tooltip = "Guarda los cambios automáticamente al cerrar la ventana"},
            {type = "checkbox", key = "showInChatOnTarget", label = "Anunciar en Chat al Seleccionar", default = false, tooltip = "Imprime la nota en la consola de chat cuando seleccionas al jugador como objetivo (fuera de combate)"},
        }
    })

    self:RegisterModule("QuickWhisper", {
        name = "Whispers Rápidos",
        category = "utility",
        icon = "Interface\\Icons\\INV_Letter_15",
        description = "Mensajes rápidos predefinidos con despacho inteligente y gestión de plantillas",
        options = {
            {type = "checkbox", key = "enabled", label = "Habilitar Whispers Rápidos", default = true, tooltip = "Habilitar/deshabilitar módulo de mensajes rápidos"},
            {type = "dropdown", key = "sendMode", label = "Modo de Envío", options = {
                {text = "Inteligente (Target > Grupo)", value = "smart"},
                {text = "Solo Susurro (Objetivo)", value = "whisper"},
                {text = "Solo Grupo (Banda/Grupo)", value = "group"},
            }, default = "smart", tooltip = "Canal prioritario donde se despachan las plantillas"},
            {type = "checkbox", key = "showInChat", label = "Eco en Chat Local", default = true, tooltip = "Muestra confirmación en el chat local al enviar una plantilla"},
            {type = "slider", key = "maxTemplates", label = "Máximo de Plantillas", min = 5, max = 20, step = 1, default = 15, tooltip = "Capacidad máxima de plantillas almacenables en la interfaz"},
        }
    })

    self:RegisterModule("VersionSync", {
        name = "Version Sync",
        category = "utility",
        icon = "Interface\\Icons\\INV_Misc_Gear_08",
        description = "Sincroniza y verifica versiones del addon con otros miembros de banda y hermandad",
        options = {
            {type = "checkbox", key = "enabled", label = "Habilitar Version Sync", default = true, tooltip = "Activa/desactiva la sincronización de versiones"},
            {type = "checkbox", key = "autoCheck", label = "Verificación Automática", default = true, tooltip = "Verifica versiones automáticamente al entrar al juego y cambios de grupo"},
            {type = "checkbox", key = "notifyOutdated", label = "Notificar Nueva Versión", default = true, tooltip = "Notifica cuando un compañero posea una versión más reciente"},
            {type = "slider", key = "checkInterval", label = "Intervalo de Verificación (min)", min = 5, max = 60, step = 5, default = 30, tooltip = "Frecuencia de verificación automática"},
        }
    })

    self:RegisterModule("PetManager", {
        name = "Gestor de Mascotas",
        category = "class",
        description = "Control automático de mascotas",
        options = { {type = "checkbox", key = "enabled", label = "Habilitado", default = true} }
    })

    self:RegisterModule("CCTracker", {
        name = "Rastreador de CC",
        category = "pvp",
        description = "Rastrea duración de control de masas (Polymorph, Banish, Fear, etc.) con barras visuales.",
        options = {
            {type = "checkbox", key = "enabled", label = "Habilitar CC Tracker", default = true, tooltip = "Rastrear duración de hechizos de control"},
            {type = "checkbox", key = "showBars", label = "Mostrar Barras", default = true, tooltip = "Mostrar barras visuales de duración de CC"},
            {type = "checkbox", key = "playSound", label = "Sonido de Alerta", default = true, tooltip = "Reproducir sonido al aplicar o alertar CC"},
            {type = "checkbox", key = "announceBreak", label = "Anunciar CC Roto", default = false, tooltip = "Anunciar en chat de grupo cuando se rompe un CC prematuramente"},
            {type = "slider", key = "warningTime", label = "Tiempo de Advertencia (s)", min = 1, max = 10, step = 1, default = 5, tooltip = "Segundos restantes para alerta visual de fin de CC"},
            {type = "slider", key = "barHeight", label = "Altura de Barras", min = 16, max = 32, step = 2, default = 20, tooltip = "Altura en píxeles de las barras de CC"},
        }
    })
    
    self:RegisterModule("Soulstones", {
        name = "Piedras de Alma",
        category = "class",
        description = "Monitor en tiempo real de piedras de alma activas",
        options = {
            {type = "checkbox", key = "enabled", label = "Habilitar Monitor", default = true},
            {type = "checkbox", key = "alerts", label = "Anunciar Expiraciones en Grupo/Banda", default = true}
        }
    })
    
    self:RegisterModule("RaidPanel", {
        name = "Panel de Banda",
        category = "raid",
        description = "Panel visual HUD con información y selección segura de miembros",
        options = {
            {type = "checkbox", key = "enabled", label = "Habilitar Panel de Banda", default = true},
            {type = "checkbox", key = "autoShow", label = "Mostrar automáticamente en grupo/banda", default = false},
            {type = "checkbox", key = "showHP", label = "Mostrar HP%", default = true},
            {type = "checkbox", key = "showRoles", label = "Mostrar iconos de rol", default = true},
            {type = "slider", key = "scale", label = "Escala del panel", min = 0.5, max = 1.5, step = 0.1, default = 1.0},
        }
    })

    self:RegisterModule("RaidAssist", {
        name = "Asistente de Raid (Core)",
        category = "raid",
        description = "Núcleo del sistema de asistencia",
        options = { {type = "checkbox", key = "enabled", label = "Habilitado", default = true} }
    })
    
    self:RegisterModule("RaidAssistUI", {
        name = "Asistente de Raid (UI)",
        category = "raid",
        description = "Interfaz gráfica del asistente",
        options = { {type = "checkbox", key = "enabled", label = "Habilitado", default = true} }
    })

    self:RegisterModule("ReadyChecker", {
        name = "Ready Check Mejorado",
        category = "raid",
        description = "Verificación pre-pull de buffs, consumibles y preparación",
        options = {
            {type = "checkbox", key = "enabled", label = "Habilitar Ready Check", default = true, tooltip = "Habilitar/deshabilitar módulo de verificación"},
            {type = "checkbox", key = "autoCheck", label = "Check Automático en Pull", default = false, tooltip = "Escanear automáticamente al disparar /readycheck"},
            {type = "checkbox", key = "checkBuffs", label = "Verificar Buffs de Banda", default = true, tooltip = "Verificar entereza, don de lo salvaje, auras y sellos"},
            {type = "checkbox", key = "checkConsumables", label = "Verificar Consumibles", default = true, tooltip = "Verificar frascos, elixires y comida de banda"},
            {type = "checkbox", key = "checkClass", label = "Verificar Requisitos de Clase", default = true, tooltip = "Verificar venenos, piedras de brujo y mascotas"},
            {type = "checkbox", key = "alertSound", label = "Sonido de Alerta", default = true, tooltip = "Reproducir sonido al detectar comprobación de preparación"},
            {type = "checkbox", key = "announceResults", label = "Anunciar Faltantes al Chat", default = true, tooltip = "Emitir mensaje en el canal de banda/grupo"},
        }
    })

    self:RegisterModule("Overlord", {
        name = "The Overlord (HUD)",
        category = "general",
        icon = "Interface\\Icons\\Spell_Shadow_Twilight",
        description = "HUD de recursos (maná, furia, energía, runas, combo points), barra de pet y alertas de procs mayores",
        options = {
            {type = "checkbox", key = "enabled", label = "Habilitar Overlord HUD", default = true, tooltip = "Activa el HUD central de recursos y procs"},
            {type = "checkbox", key = "showResource", label = "Mostrar Barra de Recursos", default = true, tooltip = "Muestra la barra de recurso de clase (maná, furia, runas, combo)"},
            {type = "checkbox", key = "showPetHealth", label = "Mostrar Vida de Mascota", default = true, tooltip = "Muestra la barra de salud de la mascota si está activa"},
            {type = "checkbox", key = "showProcs", label = "Alertas de Procs", default = true, tooltip = "Muestra alertas en pantalla de procs mayores de clase"},
            {type = "slider", key = "opacity", label = "Opacidad del HUD", min = 0.2, max = 1.0, step = 0.1, default = 0.8, tooltip = "Transparencia del HUD de Overlord"}
        }
    })

    self:RegisterModule("DoTTracker", {
        name = "Seguimiento de DoTs (Brujo)",
        category = "class",
        icon = "Interface\\Icons\\Spell_Shadow_AbominationExplosion",
        description = "Monitoreo en tiempo real de DoTs en el objetivo actual para Brujos",
        options = {
            {type = "checkbox", key = "enabled", label = "Habilitar Rastreador de DoTs", default = true, tooltip = "Muestra iconos de DoTs activos en el objetivo con temporizador"}
        }
    })

    self:RegisterModule("Universal", {
        name = "Universal Core",
        category = "general",
        icon = "Interface\\Icons\\INV_Misc_Book_09",
        description = "Motor universal de detección de clase, raza, talentos y rol táctico",
        options = {
            {type = "checkbox", key = "enabled", label = "Habilitar Universal Core", default = true, tooltip = "Activa la sincronización de clase, rol y especificación"}
        }
    })

    self:RegisterModule("SoulEngine", {
        name = "Soul Engine",
        category = "raid",
        icon = "Interface\\Icons\\Spell_Fire_FelFlameRing",
        description = "Motor táctico de cálculo en combate (DPS, HPS y actividad)",
        options = {
            {type = "checkbox", key = "enabled", label = "Habilitar Soul Engine", default = true, tooltip = "Activa el cálculo de rendimiento en combate"}
        }
    })

    self:RegisterModule("Spy", {
        name = "Spy (Vigilancia PvP)",
        category = "pvp",
        icon = "Interface\\Icons\\Ability_Stealth",
        description = "Detección de sigilo y lista de enemigos hostiles cercanos",
        options = {
            {type = "checkbox", key = "enabled", label = "Habilitar Spy", default = true, tooltip = "Activa la detección de enemigos y sigilo en PvP"}
        }
    })

    self:RegisterModule("EventManager", {
        name = "Gestor de Eventos",
        category = "general",
        icon = "Interface\\Icons\\INV_Misc_PocketWatch_01",
        description = "Gestión centralizada de eventos del juego para módulos",
        options = {
            {type = "checkbox", key = "enabled", label = "Habilitar Gestor de Eventos", default = true, tooltip = "Activa el gestor de eventos del núcleo"}
        }
    })

end

-- ============================================
-- INICIALIZACIÓN
-- ============================================

function MC:Initialize()
    self.Initialized = true
    self:RegisterAllModules()
    
    -- Aplicar configuración guardada a todos los módulos
    local db = S.db and S.db.profile or {}
    for id, mod in pairs(self.Modules) do
        if mod.onLoad then
            -- Proteger llamada para evitar errores en un módulo rompiendo todo
            local status, err = pcall(mod.onLoad, db)
            if not status then
                if S.Print then S:Print("|cFFFF0000Error cargando modulo " .. id .. ": " .. tostring(err)) end
            end
        end
    end

    if S.Print then
        S:Print("ModuleConfig cargado: " .. self:GetModuleCount() .. " módulos registrados.")
    end
end

function MC:GetModuleCount()
    local count = 0
    for _ in pairs(self.Modules) do count = count + 1 end
    return count
end

-- Registrar en Sequito
S.ModuleConfig = MC

-- Alias global para registro temprano
function S:RegisterModule(name, data)
    S[name] = data -- Register module instance for Sequito.lua
    MC:RegisterModule(name, data) -- Register config
end
