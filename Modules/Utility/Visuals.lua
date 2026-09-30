--[[
    SEQUITO - Visual FX
    Efectos inmersivos (Latido, Procs, Soul Siphon).
]]--

local addonName, S = ...
S.Visuals = {}
local FX = S.Visuals

-- Config
FX.HeartbeatEnabled = true
FX.ProcGlowEnabled = true

-- Procs importantes por clase (Buff Name -> Spell Name on Button)
FX.Procs = {
    ["WARLOCK"] = {
        ["Trance de las Sombras"] = "Descarga de las Sombras", -- Nightfall
        ["Shadow Trance"] = "Shadow Bolt",
        ["Contragolpe"] = "Incinerar", -- Backlash
        ["Backlash"] = "Incinerate",
        ["Núcleo de Magma"] = "Incinerar", -- Molten Core (Demo)
        ["Molten Core"] = "Incinerate",
    },
    ["MAGE"] = {
        ["Buena racha"] = "Piroexplosión", -- Hot Streak
        ["Hot Streak"] = "Pyroblast",
        ["Congelación cerebral"] = "Descarga de Pirofrío", -- Brain Freeze
        ["Brain Freeze"] = "Frostfire Bolt",
        ["Dedos de Escarcha"] = "Lanza de hielo", -- Fingers of Frost
        ["Fingers of Frost"] = "Ice Lance",
        ["Barrera de hielo"] = "Barrera de hielo", -- Para saber si está activa
    },
    ["PALADIN"] = {
        ["El arte de la guerra"] = "Exorcismo", -- Art of War
        ["The Art of War"] = "Exorcism",
    },
    ["DRUID"] = {
        ["Eclipse (Lunar)"] = "Fuego estelar",
        ["Eclipse (Solar)"] = "Cólera",
        ["Depredador presto"] = "Toque de sanación", -- Predatory Strikes
    },
    ["SHAMAN"] = {
        ["Arma Vorágine"] = "Descarga de relámpagos", -- Maelstrom Weapon (5 stacks usually, but simple check here)
        ["Maelstrom Weapon"] = "Lightning Bolt",
    },
    -- Add more as needed
}

-- Helper para obtener configuración
function FX:GetOption(key)
    if S.ModuleConfig then
        return S.ModuleConfig:GetValue("Visuals", key)
    end
    return true
end

function FX:Initialize()
    if self.initialized then return end
    if not self:GetOption("enabled") then
        return
    end
    self.initialized = true
    
    if S.CLEU and S.CLEU.Register then
        S.CLEU:Register("PARTY_KILL", function(...)
            FX:CheckSoulSiphon(...)
        end)
    end
    
    self.Frame = CreateFrame("Frame")
    self.Frame:RegisterEvent("UNIT_HEALTH")
    self.Frame:RegisterEvent("UNIT_AURA")
    self.Frame:RegisterEvent("PLAYER_REGEN_ENABLED")
    self.Frame:RegisterEvent("PLAYER_REGEN_DISABLED")
    if not (S.CLEU and S.CLEU.Register) then
        self.Frame:RegisterEvent("COMBAT_LOG_EVENT_UNFILTERED")
    end
    
    self.Frame:SetScript("OnEvent", function(self, event, ...)
        if event == "UNIT_HEALTH" then
            FX:CheckHeartbeat(...)
        elseif event == "UNIT_AURA" then
            FX:CheckProcs(...)
            FX:CheckProcOverlay(...)
        elseif event == "COMBAT_LOG_EVENT_UNFILTERED" then
            FX:CheckSoulSiphon(...)
        end
    end)
    
    -- Heartbeat Animation Loop
    self.Frame:SetScript("OnUpdate", function(self, elapsed)
        FX:OnUpdate(elapsed)
    end)
    

end

-- ===========================================================================
-- HEARTBEAT (Latido en HP Baja)
-- ===========================================================================
function FX:CheckHeartbeat(unit)
    if unit ~= "player" then return end
    -- La logica real ocurre en OnUpdate para suavidad
end

function FX:OnUpdate(elapsed)
    if not self:GetOption("heartbeatEnabled") then return end
    
    self.throttle = (self.throttle or 0) + elapsed
    if self.throttle < 0.04 then return end
    self.throttle = 0
    
    local sphere = S.Sphere
    if not sphere then return end
    
    local hp = UnitHealth("player")
    local max = UnitHealthMax("player")
    local pct = (max and max > 0) and ((hp / max) * 100) or 100
    
    if pct <= 35 and not UnitIsDeadOrGhost("player") then
        self.isPulsing = true
        -- Pulsar Rojo
        local speed = 5
        if pct < 20 then speed = 10 end -- Más rápido si es crítico
        
        local sine = math.sin(GetTime() * speed)
        local others = (sine + 1) / 2 -- Oscila entre 0 y 1
        
        local tex = sphere:GetNormalTexture()
        if tex then
            tex:SetVertexColor(1, others, others)
        end
    elseif self.isPulsing then
        -- Restaurar color normal solo una vez al salir del estado crítico
        self.isPulsing = false
        local tex = sphere:GetNormalTexture()
        if tex then
            tex:SetVertexColor(1, 1, 1)
        end
    end
end

-- ===========================================================================
-- PROC WATCHER (Brillo en Botones)
-- ===========================================================================
function FX:CheckProcs(unit)
    if unit ~= "player" then return end
    if not self:GetOption("procGlowEnabled") then return end
    
    local _, class = UnitClass("player")
    local map = self.Procs[class]
    if not map then return end
    
    self:ClearAllGlows()
    for i=1, 40 do
        local name = UnitBuff("player", i)
        if not name then break end
        local targetSpell = map[name]
        if targetSpell then
            self:GlowButtonForSpell(targetSpell, true)
        end
    end
end

function FX:GlowButtonForSpell(spellName, show)
    -- Buscar si algún botón satélite tiene ese hechizo
    for i=1, 4 do
        local btn = _G["SequitoBtn"..i]
        if btn then
            local type = btn:GetAttribute("type")
            local spell = btn:GetAttribute("spell")
            if type == "spell" and spell == spellName then
                if show then
                    if not btn.glow then
                        btn.glow = btn:CreateTexture(nil, "OVERLAY")
                        btn.glow:SetTexture("Interface\\Buttons\\UI-ActionButton-Border")
                        btn.glow:SetBlendMode("ADD")
                        btn.glow:SetVertexColor(1, 1, 0) -- Amarillo
                        btn.glow:SetAllPoints()
                    end
                    btn.glow:Show()
                    UIFrameFlash(btn.glow, 0.5, 0.5, 5, true, 0, 0)
                else
                    if btn.glow then 
                        btn.glow:Hide()
                        UIFrameFlashStop(btn.glow)
                    end
                end
            end
        end
    end
end

function FX:ClearAllGlows()
    for i=1, 4 do
        local btn = _G["SequitoBtn"..i]
        if btn and btn.glow then
            btn.glow:Hide()
            UIFrameFlashStop(btn.glow)
        end
    end
end

-- Registrar módulo en ModuleConfig
if S.ModuleConfig then
    S.ModuleConfig:RegisterModule({
        id = "Visuals",
        name = "Efectos Visuales",
        description = "Efectos visuales inmersivos: latido de corazón, brillo de procs, y efectos especiales.",
        category = "utility",
        icon = "Interface\\\\Icons\\\\Spell_Shadow_SoulGem",
        options = {
            {key = "enabled", type = "checkbox", name = "Habilitar Efectos Visuales", description = "Activar todos los efectos visuales", default = true},
            {key = "heartbeatEnabled", type = "checkbox", name = "Latido de Corazón", description = "Efecto de latido cuando la vida está baja", default = true},
            {key = "procGlowEnabled", type = "checkbox", name = "Brillo de Procs", description = "Resaltar habilidades cuando hay procs activos", default = true},
            {key = "procOverlayEnabled", type = "checkbox", name = "Overlay de Procs", description = "Efecto visual en pantalla (Nightfall/Backlash) [Estilo Necrosis]", default = true},
            {key = "soulSiphonEnabled", type = "checkbox", name = "Soul Siphon", description = "Efecto visual de absorción de alma (Warlock)", default = true},
            {key = "glowIntensity", type = "slider", name = "Intensidad del Brillo", description = "Intensidad del efecto de brillo en procs", min = 0.5, max = 2.0, step = 0.1, default = 1.0}
        }
    })
end

-- ===========================================================================
-- SOUL SIPHON (Visual on Kill)
-- ===========================================================================
function FX:CheckSoulSiphon(...)
    local timestamp, event, sourceGUID, sourceName, sourceFlags, destGUID, destName, destFlags = ...
    
    if event == "PARTY_KILL" then
        if sourceGUID == UnitGUID("player") then
            if self:GetOption("soulSiphonEnabled") then
                FX:TriggerSoulSiphon()
            end
        end
    end
end

function FX:TriggerSoulSiphon()
    -- Sound
    PlaySoundFile("Sound\\Spells\\SoulDrain.wav") 
    
    -- Visual Flash (Purple)
    local f = FX.FlashFrame
    if not f then
        f = CreateFrame("Frame", "SequitoSiphonFlash", UIParent)
        f:SetAllPoints()
        f:SetFrameStrata("FULLSCREEN_DIALOG")
        f.tex = f:CreateTexture(nil, "BACKGROUND")
        f.tex:SetAllPoints()
        f.tex:SetTexture("Interface\\FullScreenTextures\\LowHealth") -- Generic texture, tint purple
        f.tex:SetVertexColor(0.6, 0.1, 0.85, 0.7) -- Purple tint
        f.tex:SetBlendMode("ADD")
        f:Hide()
        FX.FlashFrame = f
    end
    
    f:Show()
    f:SetAlpha(0.7)
    f.timer = 0
    f:SetScript("OnUpdate", function(self, elapsed)
        self.timer = self.timer + elapsed
        if self.timer >= 0.7 then
            self:Hide()
            self:SetScript("OnUpdate", nil)
        else
            local alpha = (1 - (self.timer / 0.7)) * 0.7
            self:SetAlpha(math.max(0, alpha))
        end
    end)
end

-- ===========================================================================
-- PROC OVERLAY (Nightfall / Backlash Graphics)
-- ===========================================================================
function FX:CheckProcOverlay(unit)
    if unit ~= "player" then return end
    if not self:GetOption("procOverlayEnabled") then 
        if self.OverlayFrame then self.OverlayFrame:Hide() end
        return 
    end
    
    local hasNightfall = false
    local hasBacklash = false
    local hasMolten = false
    local hasDecimation = false
    
    -- Check buffs
    for i=1, 40 do
        local name = UnitBuff("player", i)
        if not name then break end
        
        if name == "Shadow Trance" or name == "Trance de las Sombras" then hasNightfall = true end
        if name == "Backlash" or name == "Contragolpe" then hasBacklash = true end
        if name == "Molten Core" or name == "Núcleo de Magma" then hasMolten = true end
        if name == "Decimation" or name == "Exterminación" then hasDecimation = true end
    end
    
    local active = hasNightfall or hasBacklash or hasMolten or hasDecimation
    
    if active then
        local f = self:GetOverlayFrame()
        f:Show()
        
        -- Priority: Nightfall (Pink) > Molten/Decimation (Red) > Backlash (Orange)
        if hasNightfall then
            f.tex:SetVertexColor(1, 0.4, 1, 0.6) -- Pink
        elseif hasMolten or hasDecimation then
            f.tex:SetVertexColor(1, 0, 0, 0.6) -- Red
        elseif hasBacklash then
            f.tex:SetVertexColor(1, 0.5, 0, 0.6) -- Orange
        end
        
        -- Pulse animation if not playing
        if not f.anim:IsPlaying() then f.anim:Play() end
    else
        if self.OverlayFrame then
            self.OverlayFrame:Hide()
            self.OverlayFrame.anim:Stop()
        end
    end
end

function FX:GetOverlayFrame()
    if self.OverlayFrame then return self.OverlayFrame end
    
    local f = CreateFrame("Frame", "SequitoProcOverlay", UIParent)
    f:SetAllPoints()
    f:SetFrameStrata("BACKGROUND") -- Behind UI but over world
    f:SetAlpha(0)
    
    f.tex = f:CreateTexture(nil, "BACKGROUND")
    f.tex:SetAllPoints()
    f.tex:SetTexture("Interface\\FullScreenTextures\\LowHealth") -- Best generic overlay
    f.tex:SetBlendMode("ADD")
    
    -- Pulse Animation
    local ag = f:CreateAnimationGroup()
    local a1 = ag:CreateAnimation("Alpha")
    a1:SetChange(1) 
    a1:SetDuration(0.5) 
    a1:SetOrder(1) 
    a1:SetSmoothing("IN_OUT")
    local a2 = ag:CreateAnimation("Alpha")
    a2:SetChange(-1) 
    a2:SetDuration(0.5) 
    a2:SetOrder(2) 
    a2:SetSmoothing("IN_OUT")
    ag:SetLooping("BOUNCE")
    
    f.anim = ag
    self.OverlayFrame = f
    return f
end
