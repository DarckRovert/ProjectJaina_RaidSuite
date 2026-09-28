--[[
    SEQUITO - DoT Tracker (Necrosis Style)
    Rastrea tus DoTs en el objetivo actual con iconos y temporizadores.
]]--

local addonName, S = ...
S.DoTTracker = {}
local DT = S.DoTTracker

-- Configuración de Spells a rastrear (Por prioridad)
DT.Spells = {
    -- Affli / Destro Core
    { id = 172, name = "Corruption", icon = "Spell_Shadow_AbominationExplosion" }, -- Corrupción
    { id = 348, name = "Immolate", icon = "Spell_Fire_Immolation" }, -- Inmolar
    { id = 30108, name = "Unstable Affliction", icon = "Spell_Shadow_UnstableAffliction_3" }, -- Aflicción inestable
    { id = 980, name = "Curse of Agony", icon = "Spell_Shadow_CurseOfSargeras" }, -- Agonía
    { id = 603, name = "Curse of Doom", icon = "Spell_Shadow_AuraOfDarkness" }, -- Apocalipsis
    { id = 1490, name = "Curse of the Elements", icon = "Spell_Shadow_ChillTouch" }, -- Elementos
    { id = 702, name = "Curse of Weakness", icon = "Spell_Shadow_CurseOfMannoroth" }, -- Debilidad
    { id = 1714, name = "Curse of Tongues", icon = "Spell_Shadow_CurseOfTounges" }, -- Lenguas
    { id = 48181, name = "Haunt", icon = "Ability_Warlock_Haunt" }, -- Poseer
    { id = 27243, name = "Seed of Corruption", icon = "Spell_Shadow_SeedOfDestruction" }, -- Semilla
}

-- Mapeo de nombres localizados (se llenará en Initialize)
DT.SpellMap = {}

-- Helper para obtener configuración
function DT:GetOption(key)
    if S.ModuleConfig then
        return S.ModuleConfig:GetValue("DoTTracker", key)
    end
    return true
end

function DT:Initialize()
    if not self:GetOption("enabled") then
        return
    end
    
    local _, class = UnitClass("player")
    if class ~= "WARLOCK" then return end

    self:BuildSpellMap()
    self:CreateAnchor()
    self:CreateIcons()
    self:RegisterEvents()
    
    print("|cFF9900FFSequito DoT Tracker|r: Online.")
end

function DT:BuildSpellMap()
    for _, data in ipairs(self.Spells) do
        local name, _, icon = GetSpellInfo(data.id)
        if name then
            self.SpellMap[name] = { id = data.id, icon = icon }
        end
    end
end

function DT:CreateAnchor()
    local f = CreateFrame("Frame", "SequitoDoTAnchor", UIParent)
    f:SetSize(200, 40)
    -- Posicion por defecto: Arriba de la esfera (o donde el usuario quiera)
    f:SetPoint("CENTER", UIParent, "CENTER", 0, -200)
    f:SetMovable(true)
    f:EnableMouse(true)
    f:RegisterForDrag("LeftButton")
    
    f.bg = f:CreateTexture(nil, "BACKGROUND")
    f.bg:SetAllPoints()
    f.bg:SetTexture(0, 0, 0, 0.3)
    f.bg:Hide()
    
    f.text = f:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    f.text:SetPoint("CENTER")
    f.text:SetText("Sequito DoT Tracker")
    f.text:Hide()
    
    f:SetScript("OnDragStart", function(self) if not S.db.profile.Locked then self:StartMoving() end end)
    f:SetScript("OnDragStop", function(self)
        self:StopMovingOrSizing()
        -- Save pos logic if needed
    end)
    
    -- Manejo de bloqueo
    f:SetScript("OnEnter", function(self)
        if not S.db.profile.Locked then
            self.bg:Show()
            self.text:Show()
        end
    end)
    f:SetScript("OnLeave", function(self) 
        self.bg:Hide()
        self.text:Hide()
    end)
    
    self.Anchor = f
end

function DT:CreateIcons()
    self.Icons = {}
    
    -- Crear un icono por cada spell trackeado
    local prev = nil
    
    for i, data in ipairs(self.Spells) do
        local name, _, icon = GetSpellInfo(data.id)
        icon = icon or data.icon -- Fallback
        
        local btn = CreateFrame("Frame", "SequitoDoTIcon"..i, self.Anchor)
        btn:SetSize(30, 30)
        
        if prev then
            btn:SetPoint("LEFT", prev, "RIGHT", 5, 0)
        else
            btn:SetPoint("LEFT", self.Anchor, "LEFT", 0, 0)
        end
        
        btn.icon = btn:CreateTexture(nil, "ARTWORK")
        btn.icon:SetAllPoints()
        btn.icon:SetTexture(icon)
        btn.icon:SetDesaturated(true) -- Gris si no activo
        btn.icon:SetAlpha(0.5)
        
        btn.cd = CreateFrame("Cooldown", "SequitoDoTCD"..i, btn, "CooldownFrameTemplate")
        btn.cd:SetAllPoints()
        btn.cd:Hide()
        
        btn.text = btn:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
        btn.text:SetPoint("BOTTOM", 0, -10)
        btn.text:SetText("")
        
        btn.spellName = name
        btn:Show()
        
        self.Icons[i] = btn
        prev = btn
    end
    
    self.Anchor:SetWidth(#self.Spells * 35)
end

function DT:RegisterEvents()
    local f = CreateFrame("Frame")
    f:RegisterEvent("PLAYER_TARGET_CHANGED")
    f:RegisterEvent("UNIT_AURA")
    
    f:SetScript("OnEvent", function(self, event, ...)
        local unit = ...
        if event == "PLAYER_TARGET_CHANGED" then
            DT:UpdateAll()
        elseif event == "UNIT_AURA" then
            if unit == "target" then
                DT:UpdateAll()
            end
        end
    end)
end

function DT:UpdateAll()
    if not UnitExists("target") then
        self:ResetIcons()
        return
    end
    
    for i, btn in ipairs(self.Icons) do
        self:CheckAura(btn)
    end
end

function DT:CheckAura(btn)
    if not btn.spellName then return end
    
    local name, _, _, count, _, duration, expirationTime, unitCaster = UnitDebuff("target", btn.spellName)
    
    -- Check if it is cast by player
    if name and unitCaster == "player" then
        btn.icon:SetDesaturated(false)
        btn.icon:SetAlpha(1.0)
        
        if duration and duration > 0 then
            btn.cd:Show()
            btn.cd:SetCooldown(expirationTime - duration, duration)
            
            -- Countdown text if wanted
            -- Use OnUpdate for text or simple CD frame
        else
            btn.cd:Hide()
        end
    else
        btn.icon:SetDesaturated(true)
        btn.icon:SetAlpha(0.4)
        btn.cd:Hide()
    end
end

function DT:ResetIcons()
    for _, btn in ipairs(self.Icons) do
        btn.icon:SetDesaturated(true)
        btn.icon:SetAlpha(0.4)
        btn.cd:Hide()
    end
end

-- Config
if S.ModuleConfig then
    S.ModuleConfig:RegisterModule("DoTTracker", {
        name = "DoT Tracker",
        description = "Barra de Iconos para rastrear DoTs en el objetivo.",
        category = "class",
        icon = "Interface\\Icons\\Spell_Shadow_AbominationExplosion",
        options = {
            {key = "enabled", type = "checkbox", label = "Habilitar DoT Tracker", default = true}
        }
    })
end
