--[[
    SEQUITO - Theme System
    Sistema centralizado de colores y estilos para toda la interfaz.
    Soporta 3 temas predefinidos: Demonio, Oscuro, Clásico.
]]--

local addonName, S = ...
S.Theme = {}
local T = S.Theme

-- ============================================
-- TEMAS PREDEFINIDOS
-- ============================================

T.Presets = {
    -- Demonio: Morado intenso + fuego naranja (default Jaina)
    ["Demonio"] = {
        primary     = {0.60, 0.20, 0.80, 1.0},  -- Morado
        secondary   = {0.40, 0.10, 0.60, 1.0},  -- Morado oscuro
        accent      = {1.00, 0.50, 0.00, 1.0},  -- Naranja fuego
        background  = {0.05, 0.02, 0.08, 0.90}, -- Negro-morado
        border      = {0.60, 0.20, 0.80, 1.0},  -- Morado
        text        = {1.00, 0.85, 1.00, 1.0},  -- Blanco-lila
        textDim     = {0.70, 0.50, 0.80, 1.0},  -- Lila tenue
        success     = {0.20, 1.00, 0.40, 1.0},  -- Verde
        danger      = {1.00, 0.20, 0.20, 1.0},  -- Rojo
        warning     = {1.00, 0.80, 0.00, 1.0},  -- Amarillo
        glow        = {0.80, 0.40, 1.00, 0.60}, -- Glow morado
        headerText  = "|cFF9932CC",               -- Color code para headers
        accentText  = "|cFFFF8000",               -- Color code para acentos
    },
    -- Oscuro: Gris metalico + cyan neón
    ["Oscuro"] = {
        primary     = {0.10, 0.70, 0.80, 1.0},  -- Cyan
        secondary   = {0.08, 0.50, 0.60, 1.0},  -- Cyan oscuro
        accent      = {0.00, 1.00, 1.00, 1.0},  -- Cyan brillante
        background  = {0.06, 0.06, 0.08, 0.92}, -- Gris muy oscuro
        border      = {0.15, 0.60, 0.70, 1.0},  -- Cyan medio
        text        = {0.90, 0.95, 1.00, 1.0},  -- Blanco-azul
        textDim     = {0.50, 0.60, 0.70, 1.0},  -- Gris-azul
        success     = {0.20, 1.00, 0.60, 1.0},  -- Verde menta
        danger      = {1.00, 0.30, 0.30, 1.0},  -- Rojo claro
        warning     = {1.00, 0.90, 0.30, 1.0},  -- Amarillo cálido
        glow        = {0.00, 0.80, 1.00, 0.50}, -- Glow cyan
        headerText  = "|cFF00CCDD",
        accentText  = "|cFF00FFFF",
    },
    -- Clásico: Dorado + rojo sangre (estilo WoW vanilla)
    ["Clasico"] = {
        primary     = {0.80, 0.60, 0.00, 1.0},  -- Dorado
        secondary   = {0.60, 0.40, 0.00, 1.0},  -- Dorado oscuro
        accent      = {0.80, 0.10, 0.10, 1.0},  -- Rojo sangre
        background  = {0.08, 0.05, 0.02, 0.90}, -- Marrón oscuro
        border      = {0.70, 0.55, 0.10, 1.0},  -- Dorado border
        text        = {1.00, 0.95, 0.80, 1.0},  -- Crema
        textDim     = {0.70, 0.60, 0.40, 1.0},  -- Marrón claro
        success     = {0.30, 0.90, 0.30, 1.0},  -- Verde
        danger      = {0.90, 0.10, 0.10, 1.0},  -- Rojo oscuro
        warning     = {1.00, 0.70, 0.00, 1.0},  -- Naranja
        glow        = {1.00, 0.80, 0.20, 0.50}, -- Glow dorado
        headerText  = "|cFFDAA520",
        accentText  = "|cFFCC1111",
    },
}

-- Alias con tilde para compatibilidad
T.Presets["Clásico"] = T.Presets["Clasico"]

-- Tema activo (se carga desde SavedVariables o default)
T.ActiveTheme = "Demonio"

-- ============================================
-- API PÚBLICA
-- ============================================

-- Obtener un color del tema activo
-- Retorna r, g, b, a (unpacked) para uso directo en WoW API
function T:GetColor(token)
    local theme = self.Presets[self.ActiveTheme] or self.Presets["Demonio"]
    local color = theme[token]
    if color then
        return color[1], color[2], color[3], color[4] or 1.0
    end
    return 1, 1, 1, 1 -- Fallback blanco
end

-- Obtener color como tabla {r, g, b, a}
function T:GetColorTable(token)
    local theme = self.Presets[self.ActiveTheme] or self.Presets["Demonio"]
    return theme[token] or {1, 1, 1, 1}
end

-- Obtener color code para texto (|cFF...)
function T:GetTextColor(token)
    local theme = self.Presets[self.ActiveTheme] or self.Presets["Demonio"]
    if token == "header" then return theme.headerText or "|cFFFFFFFF" end
    if token == "accent" then return theme.accentText or "|cFFFFFF00" end
    -- Generar color code desde RGBA
    local color = theme[token]
    if color then
        return string.format("|cFF%02X%02X%02X", color[1]*255, color[2]*255, color[3]*255)
    end
    return "|cFFFFFFFF"
end

-- Cambiar tema
function T:SetTheme(themeName)
    if self.Presets[themeName] then
        self.ActiveTheme = themeName
        if S.db and S.db.profile then
            S.db.profile.theme = themeName
            S.db.profile.Theme_theme = themeName -- Sync for ModuleConfig
        end
        if S.Callbacks and S.Callbacks.Fire then
            S.Callbacks:Fire("THEME_CHANGED", themeName)
        end
        if S.SendMessage then
            S:SendMessage("THEME_CHANGED", themeName)
        end
        self:RefreshAllFrames()
    end
end

-- Obtener nombre del tema activo
function T:GetThemeName()
    return self.ActiveTheme
end

-- Obtener lista de temas disponibles
function T:GetThemeList()
    local list = {}
    for name, _ in pairs(self.Presets) do
        table.insert(list, name)
    end
    table.sort(list)
    return list
end

-- Inicializar: cargar tema desde SavedVariables
function T:Initialize()
    if S.db and S.db.profile then
        -- Prefer Theme_theme (ModuleConfig) or theme (Direct/Menu)
        local saved = S.db.profile.Theme_theme or S.db.profile.theme
        
        if saved and self.Presets[saved] then
            self.ActiveTheme = saved
        end
    end
    
    -- Registrar en ModuleConfig (Ahora seguro porque ModuleConfig ya cargó)
    if S.ModuleConfig then
        S.ModuleConfig:RegisterModule("Theme", {
            name = "Sistema de Temas",
            description = "Cambia los colores de toda la interfaz de Jaina.",
            category = "interface",
            icon = "Interface\\Icons\\INV_Misc_Gem_Variety2",
            options = {
                {
                    key = "theme",
                    type = "dropdown",
                    label = "Tema de Color",
                    tooltip = "Elige el esquema de colores del addon",
                    options = {
                        {text = "Demonio (Morado/Naranja)", value = "Demonio"},
                        {text = "Oscuro (Cyan/Gris)", value = "Oscuro"},
                        {text = "Clásico (Dorado/Rojo)", value = "Clasico"},
                    },
                    default = "Demonio",
                    -- Callback cuando cambia opción en panel
                    onSave = function()
                        local newTheme = S.db.profile.Theme_theme
                        if newTheme then
                            T:SetTheme(newTheme)
                        end
                    end
                },
            }
        })
    end
end

-- Obtener nombre del tema activo
function T:GetThemeName()
    return self.ActiveTheme
end

-- Obtener lista de temas disponibles
function T:GetThemeList()
    local list = {}
    for name, _ in pairs(self.Presets) do
        table.insert(list, name)
    end
    table.sort(list)
    return list
end

-- Inicializar: cargar tema desde SavedVariables
function T:Initialize()
    if S.db and S.db.profile and S.db.profile.theme then
        if self.Presets[S.db.profile.theme] then
            self.ActiveTheme = S.db.profile.theme
        end
    end
end

-- Registro de frames para actualización reactiva en vivo
T.RegisteredFrames = {}

function T:RegisterFrame(frame, refreshCallback)
    if not frame then return end
    table.insert(self.RegisteredFrames, { frame = frame, callback = refreshCallback })
end

function T:RefreshAllFrames()
    for _, entry in ipairs(self.RegisteredFrames) do
        if entry.callback then
            pcall(entry.callback, self.ActiveTheme)
        elseif entry.frame and entry.frame.SetBackdropBorderColor then
            entry.frame:SetBackdropBorderColor(self:GetColor("border"))
        end
    end
end

-- Aplicar tema a un frame con fondo + borde
function T:StyleFrame(frame)
    if not frame then return end
    
    if frame.bg then
        frame.bg:SetTexture(self:GetColor("background"))
    end
    
    if frame.SetBackdropBorderColor then
        frame:SetBackdropBorderColor(self:GetColor("border"))
    end
end

-- Crear un panel estilizado moderno tipo Glassmorphism
function T:ApplyPanelBackdrop(frame, isChild)
    if not frame then return end
    
    frame:SetBackdrop({
        bgFile = "Interface\\ChatFrame\\ChatFrameBackground",
        edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
        tile = true, tileSize = 16, edgeSize = isChild and 12 or 16,
        insets = { left = 3, right = 3, top = 3, bottom = 3 }
    })
    
    local r, g, b, a = self:GetColor("background")
    if isChild then
        frame:SetBackdropColor(r * 0.7, g * 0.7, b * 0.7, math.min(1, a + 0.05))
    else
        frame:SetBackdropColor(r, g, b, a)
    end
    
    frame:SetBackdropBorderColor(self:GetColor("border"))
end

-- Estilizar botón con diseño moderno y hover reactivo
function T:ApplyButtonTheme(btn, isPrimary)
    if not btn then return end
    
    btn:SetBackdrop({
        bgFile = "Interface\\ChatFrame\\ChatFrameBackground",
        edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
        tile = true, tileSize = 12, edgeSize = 10,
        insets = { left = 2, right = 2, top = 2, bottom = 2 }
    })
    
    local pr, pg, pb = self:GetColor(isPrimary and "primary" or "secondary")
    local br, bg, bb = self:GetColor("border")
    btn:SetBackdropColor(pr * 0.3, pg * 0.3, pb * 0.3, 0.85)
    btn:SetBackdropBorderColor(br, bg, bb, 0.9)
    
    local font = btn:GetFontString()
    if font then
        font:SetTextColor(self:GetColor("text"))
    end
    
    btn:HookScript("OnEnter", function(self)
        self:SetBackdropColor(pr * 0.6, pg * 0.6, pb * 0.6, 1.0)
        self:SetBackdropBorderColor(T:GetColor("accent"))
    end)
    btn:HookScript("OnLeave", function(self)
        self:SetBackdropColor(pr * 0.3, pg * 0.3, pb * 0.3, 0.85)
        self:SetBackdropBorderColor(T:GetColor("border"))
    end)
end

-- Aplicar estilo zebra interactivo a filas de tablas/listas
function T:ApplyZebraRow(row, index)
    if not row then return end
    
    if not row.zebraBg then
        row.zebraBg = row:CreateTexture(nil, "BACKGROUND")
        row.zebraBg:SetAllPoints()
    end
    
    local isEven = (index % 2 == 0)
    if isEven then
        row.zebraBg:SetTexture(1, 1, 1, 0.04)
    else
        row.zebraBg:SetTexture(0, 0, 0, 0.15)
    end
    row.zebraBg:Show()
    
    row:EnableMouse(true)
    row:HookScript("OnEnter", function(self)
        self.zebraBg:SetTexture(T:GetColor("accent"))
        self.zebraBg:SetAlpha(0.18)
    end)
    row:HookScript("OnLeave", function(self)
        if isEven then
            self.zebraBg:SetTexture(1, 1, 1, 0.04)
        else
            self.zebraBg:SetTexture(0, 0, 0, 0.15)
        end
        self.zebraBg:SetAlpha(1.0)
    end)
end

-- Crear un fondo temático para un frame
function T:ApplyBackground(frame)
    if not frame then return end
    
    local bg = frame:CreateTexture(nil, "BACKGROUND")
    bg:SetAllPoints()
    bg:SetTexture(self:GetColor("background"))
    frame.bg = bg
    return bg
end

-- Crear un borde temático
function T:ApplyBorder(frame)
    if not frame then return end
    
    local border = CreateFrame("Frame", nil, frame)
    border:SetAllPoints()
    border:SetBackdrop({
        edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
        edgeSize = 14,
    })
    border:SetBackdropBorderColor(self:GetColor("border"))
    frame.border = border
    return border
end


