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
        ["Exterminación"] = "Fuego de alma", -- Decimation
        ["Decimation"] = "Soul Fire",
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
        ["Infusión de Luz"] = "Destello de Luz", -- Infusion of Light
        ["Infusion of Light"] = "Flash of Light",
    },
    ["DRUID"] = {
        ["Eclipse (Lunar)"] = "Fuego estelar",
        ["Eclipse (Solar)"] = "Cólera",
        ["Depredador presto"] = "Toque de sanación", -- Predatory Strikes
    },
    ["SHAMAN"] = {
        ["Arma Vorágine"] = "Descarga de relámpagos", -- Maelstrom Weapon
        ["Maelstrom Weapon"] = "Lightning Bolt",
    },
    ["HUNTER"] = {
        ["Bloquear y cargar"] = "Disparo explosivo", -- Lock and Load
        ["Lock and Load"] = "Explosive Shot",
    },
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
    local intensity = FX:GetOption("glowIntensity") or 1.0
    if type(intensity) ~= "number" then intensity = 1.0 end
    
    -- Buscar botones satélite (1 a 12)
    for i = 1, 12 do
        local btn = _G["SequitoBtn" .. i]
        if btn then
            local typeAttr = btn:GetAttribute("type")
            local spell = btn:GetAttribute("spell")
            if typeAttr == "spell" and spell == spellName then
                if show then
                    if not btn.glow then
                        btn.glow = btn:CreateTexture(nil, "OVERLAY")
                        btn.glow:SetTexture("Interface\\Buttons\\UI-ActionButton-Border")
                        btn.glow:SetBlendMode("ADD")
                        btn.glow:SetAllPoints()
                    end
                    btn.glow:SetVertexColor(1, 1, 0, math.min(1.0, math.max(0.2, intensity)))
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
    for i = 1, 12 do
        local btn = _G["SequitoBtn" .. i]
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
        description = "Efectos visuales inmersivos: latido de corazón, brillo de procs, y efectos de pantalla completa.",
        category = "utility",
        icon = "Interface\\Icons\\Spell_Shadow_SoulGem",
        options = {
            {key = "enabled", type = "checkbox", label = "Habilitar Efectos Visuales", tooltip = "Activar o desactivar todos los efectos visuales", default = true},
            {key = "heartbeatEnabled", type = "checkbox", label = "Latido de Corazón", tooltip = "Efecto de latido y pulsación roja cuando la vida está por debajo del 35%", default = true},
            {key = "procGlowEnabled", type = "checkbox", label = "Brillo de Procs", tooltip = "Resaltar botones satélite cuando hay procs activos", default = true},
            {key = "procOverlayEnabled", type = "checkbox", label = "Overlay de Procs", tooltip = "Efecto visual inmersivo en pantalla al activarse procs mayores", default = true},
            {key = "soulSiphonEnabled", type = "checkbox", label = "Soul Siphon (Brujo)", tooltip = "Efecto visual morado y auditivo de absorción de alma al matar a un enemigo (Solo Brujo)", default = true},
            {key = "glowIntensity", type = "slider", label = "Intensidad del Brillo", tooltip = "Intensidad y opacidad del efecto de brillo en los botones", min = 0.5, max = 2.0, step = 0.1, default = 1.0}
        }
    })
end

-- ===========================================================================
-- SOUL SIPHON (Visual on Kill - Solo Warlock)
-- ===========================================================================
function FX:CheckSoulSiphon(...)
    local timestamp, event, sourceGUID, sourceName, sourceFlags, destGUID, destName, destFlags = ...
    
    if event == "PARTY_KILL" then
        if sourceGUID == UnitGUID("player") then
            local _, class = UnitClass("player")
            if class == "WARLOCK" and self:GetOption("soulSiphonEnabled") then
                FX:TriggerSoulSiphon()
            end
        end
    end
end

function FX:TriggerSoulSiphon()
    -- Audio inmersivo
    PlaySoundFile("Sound\\Spells\\SoulDrain.wav") 
    
    -- Visual Flash morado en pantalla
    local f = FX.FlashFrame
    if not f then
        f = CreateFrame("Frame", "SequitoSiphonFlash", UIParent)
        f:SetAllPoints()
        f:SetFrameStrata("FULLSCREEN_DIALOG")
        f.tex = f:CreateTexture(nil, "BACKGROUND")
        f.tex:SetAllPoints()
        f.tex:SetTexture("Interface\\FullScreenTextures\\LowHealth")
        f.tex:SetVertexColor(0.6, 0.1, 0.85, 0.7) -- Púrpura sombrío
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
-- PROC OVERLAY (Nightfall, Molten Core, Lock and Load, etc.) - WotLK 3.3.5a Engine
-- ===========================================================================
function FX:CheckProcOverlay(unit)
    if unit ~= "player" then return end
    if not self:GetOption("procOverlayEnabled") then 
        if self.OverlayFrame then 
            self.OverlayFrame:Hide()
            self.OverlayFrame:SetScript("OnUpdate", nil)
        end
        return 
    end
    
    local hasNightfall = false
    local hasBacklash = false
    local hasMolten = false
    local hasDecimation = false
    local hasLockAndLoad = false
    local hasHotStreak = false
    local hasBrainFreeze = false
    local hasArtOfWar = false
    
    -- Verificar auras activas
    for i = 1, 40 do
        local name = UnitBuff("player", i)
        if not name then break end
        
        if name == "Shadow Trance" or name == "Trance de las Sombras" then hasNightfall = true end
        if name == "Backlash" or name == "Contragolpe" then hasBacklash = true end
        if name == "Molten Core" or name == "Núcleo de Magma" then hasMolten = true end
        if name == "Decimation" or name == "Exterminación" then hasDecimation = true end
        if name == "Lock and Load" or name == "Bloquear y cargar" then hasLockAndLoad = true end
        if name == "Hot Streak" or name == "Buena racha" then hasHotStreak = true end
        if name == "Brain Freeze" or name == "Congelación cerebral" then hasBrainFreeze = true end
        if name == "The Art of War" or name == "El arte de la guerra" then hasArtOfWar = true end
    end
    
    local active = hasNightfall or hasBacklash or hasMolten or hasDecimation or hasLockAndLoad or hasHotStreak or hasBrainFreeze or hasArtOfWar
    
    if active then
        local f = self:GetOverlayFrame()
        
        -- Prioridad cromática según proc:
        if hasNightfall then
            f.tex:SetVertexColor(1.0, 0.3, 0.9, 0.6) -- Rosa sombra
        elseif hasMolten or hasDecimation or hasHotStreak then
            f.tex:SetVertexColor(1.0, 0.1, 0.0, 0.6) -- Rojo fuego intenso
        elseif hasBacklash or hasLockAndLoad then
            f.tex:SetVertexColor(1.0, 0.55, 0.0, 0.6) -- Naranja explosivo
        elseif hasBrainFreeze then
            f.tex:SetVertexColor(0.2, 0.6, 1.0, 0.6) -- Celeste escarcha
        elseif hasArtOfWar then
            f.tex:SetVertexColor(1.0, 0.85, 0.2, 0.6) -- Dorado sagrado
        end
        
        f:Show()
        -- Oscilador nativo suave (sin AnimationGroup, compatible 100% con 3.3.5a)
        f:SetScript("OnUpdate", function(frame, elapsed)
            local sine = (math.sin(GetTime() * 4.5) + 1) / 2
            local alpha = 0.2 + (sine * 0.45)
            frame:SetAlpha(alpha)
        end)
    else
        if self.OverlayFrame then
            self.OverlayFrame:Hide()
            self.OverlayFrame:SetScript("OnUpdate", nil)
        end
    end
end

function FX:GetOverlayFrame()
    if self.OverlayFrame then return self.OverlayFrame end
    
    local f = CreateFrame("Frame", "SequitoProcOverlay", UIParent)
    f:SetAllPoints()
    f:SetFrameStrata("BACKGROUND")
    f:SetAlpha(0)
    
    f.tex = f:CreateTexture(nil, "BACKGROUND")
    f.tex:SetAllPoints()
    f.tex:SetTexture("Interface\\FullScreenTextures\\LowHealth")
    f.tex:SetBlendMode("ADD")
    f:Hide()
    
    self.OverlayFrame = f
    return f
end

-- ===========================================================================
-- COMANDOS SLASH
-- ===========================================================================
SLASH_SEQUITOVISUALS1 = "/visuals"
SLASH_SEQUITOVISUALS2 = "/fx"
SLASH_SEQUITOVISUALS3 = "/seqvisuals"

SlashCmdList["SEQUITOVISUALS"] = function(msg)
    local cmd = (msg or ""):lower():match("^%s*(%S+)") or ""
    
    if cmd == "test" then
        print("|cFF9966FFSequito Visuals|r: Ejecutando prueba de efectos visuales...")
        FX:TriggerSoulSiphon()
        local f = FX:GetOverlayFrame()
        f.tex:SetVertexColor(1.0, 0.4, 0.9, 0.6)
        f:Show()
        f:SetScript("OnUpdate", function(frame, elapsed)
            local sine = (math.sin(GetTime() * 4.5) + 1) / 2
            local alpha = 0.2 + (sine * 0.45)
            frame:SetAlpha(alpha)
        end)
        
        -- Detener tras 3.5 segundos usando ticker nativo
        local timerFrame = CreateFrame("Frame")
        timerFrame.elapsed = 0
        timerFrame:SetScript("OnUpdate", function(self, elapsed)
            self.elapsed = self.elapsed + elapsed
            if self.elapsed >= 3.5 then
                if FX.OverlayFrame then
                    FX.OverlayFrame:Hide()
                    FX.OverlayFrame:SetScript("OnUpdate", nil)
                end
                self:SetScript("OnUpdate", nil)
            end
        end)
    elseif cmd == "config" or cmd == "options" or cmd == "" then
        if S.ModuleConfig and S.ModuleConfig.ShowModuleConfig then
            S.ModuleConfig:ShowModuleConfig("Visuals")
        else
            print("|cFF9966FFSequito Visuals|r: Módulo activo. Abre la configuración con /seq config.")
        end
    else
        print("|cFF9966FFSequito Visuals|r: Comandos disponibles:")
        print("  |cFFFFD700/visuals|r o |cFFFFD700/fx|r - Abre la configuración visual")
        print("  |cFFFFD700/visuals test|r - Muestra una demostración visual temporal")
    end
end
