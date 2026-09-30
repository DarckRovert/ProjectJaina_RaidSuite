--[[
    SEQUITO - Runes Module
    Visualización de Runas para Caballeros de la Muerte.
]]--

local addonName, S = ...
S.Runes = {}
local R = S.Runes

R.RuneMapping = {
    [1] = "Blood",
    [2] = "Blood",
    [3] = "Unholy",
    [4] = "Unholy",
    [5] = "Frost",
    [6] = "Frost",
}

-- Helper para obtener configuración
function R:GetOption(key)
    if S.ModuleConfig then
        return S.ModuleConfig:GetValue("Runes", key)
    end
    return true
end

function R:Initialize()
    if not self:GetOption("enabled") then
        return
    end
    
    local _, class = UnitClass("player")
    if class ~= "DEATHKNIGHT" then return end
    
    self:CreateRunes()
    self:RegisterEvents()
    
    -- Visibility Check
    if not S.db.profile.ShowRunes then
        self:Hide()
    end
end

function R:Hide()
    if self.RuneFrames then
        for _, f in pairs(self.RuneFrames) do f:Hide() end
    end
end

function R:Show()
    if self.RuneFrames and S.db.profile.ShowRunes then
        for _, f in pairs(self.RuneFrames) do f:Show() end
    end
end

function R:CreateRunes()
    self.RuneFrames = {}
    
    -- Configuración visual
    local radius = 55 -- Un poco más lejos que los satélites (40)
    -- Posiciones circulares arriba de la esfera
    -- Angulos: 60, 80, 100, 120, 140, 160 (Arco superior)
    local angles = {30, 60, 90, 120, 150, 180} -- Arco amplio superior
    
    for i=1, 6 do
        local f = CreateFrame("Frame", "SequitoRune"..i, S.Sphere)
        f:SetSize(16, 16)
        
        -- Posición Polar
        local rad = math.rad(angles[i])
        local x = math.cos(rad) * radius
        local y = math.sin(rad) * radius
        f:SetPoint("CENTER", S.Sphere, "CENTER", x, y)
        
        -- Textura (Fondo)
        f.bg = f:CreateTexture(nil, "BACKGROUND")
        f.bg:SetAllPoints()
        f.bg:SetTexture("Interface\\Icons\\Spell_Shadow_Rune") 
        f.bg:SetDesaturated(true)
        f.bg:SetVertexColor(0.5, 0.5, 0.5)
        
        -- Cooldown (Fill)
        f.cd = CreateFrame("Cooldown", "SequitoRuneCD"..i, f, "CooldownFrameTemplate")
        f.cd:SetAllPoints()
        f.cd:SetReverse(true) -- Se llena cuando está lista? No, CD standard.
        
        -- Icono de tipo (Overlay)
        f.icon = f:CreateTexture(nil, "ARTWORK")
        f.icon:SetAllPoints()
        f.icon:SetTexture("Interface\\PlayerFrame\\UI-PlayerFrame-Deathknight-Blood")
        f.icon:SetAlpha(0.8)
        
        self.RuneFrames[i] = f
    end
    
    self:UpdateAllRunes()
end

function R:RegisterEvents()
    local f = CreateFrame("Frame")
    f:RegisterEvent("RUNE_POWER_UPDATE")
    f:RegisterEvent("RUNE_TYPE_UPDATE")
    f:SetScript("OnEvent", function(self, event, runeID)
        if runeID then
            R:UpdateRune(runeID)
        else
            R:UpdateAllRunes()
        end
    end)
end

function R:UpdateAllRunes()
    for i=1, 6 do
        self:UpdateRune(i)
    end
end

function R:UpdateRune(id)
    if not self.RuneFrames[id] then return end
    local f = self.RuneFrames[id]
    
    local start, duration, ready = GetRuneCooldown(id)
    local runeType = GetRuneType(id)
    
    -- Iconos por tipo (WotLK IDs: 1=Blood, 2=Unholy, 3=Frost, 4=Death)
    local textures = {
        [1] = "Interface\\PlayerFrame\\UI-PlayerFrame-Deathknight-Blood",
        [2] = "Interface\\PlayerFrame\\UI-PlayerFrame-Deathknight-Unholy",
        [3] = "Interface\\PlayerFrame\\UI-PlayerFrame-Deathknight-Frost",
        [4] = "Interface\\PlayerFrame\\UI-PlayerFrame-Deathknight-Death",
    }
    
    if textures[runeType] then
        f.icon:SetTexture(textures[runeType])
    end
    
    if ready then
        f.cd:Hide()
        f.icon:SetAlpha(1.0)
        f.icon:SetDesaturated(false)
    else
        f.cd:Show()
        f.cd:SetCooldown(start, duration)
        f.icon:SetAlpha(0.5)
        f.icon:SetDesaturated(true)
    end
end

-- Registrar módulo en ModuleConfig
if S.ModuleConfig then
    S.ModuleConfig:RegisterModule({
        id = "Runes",
        name = "Visualizador de Runas",
        description = "Visualización de runas para Death Knights",
        category = "class",
        icon = "Interface\\Icons\\Spell_Deathknight_RuneTap",
        options = {
            {key = "enabled", type = "checkbox", label = "Habilitar Runas", tooltip = "Habilitar/deshabilitar visualización de runas", default = true},
            {key = "showCooldowns", type = "checkbox", label = "Mostrar Cooldowns", tooltip = "Mostrar cooldowns de recarga en las runas", default = true},
            {key = "runeSize", type = "slider", label = "Tamaño de Runas", tooltip = "Tamaño de los iconos de runas en píxeles", min = 20, max = 60, step = 5, default = 32},
            {key = "showNumbers", type = "checkbox", label = "Mostrar Números", tooltip = "Mostrar temporizadores numéricos de cooldown", default = true}
        }
    })
end
