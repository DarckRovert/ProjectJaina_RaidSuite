--[[
    Sequito - AlertHub.lua
    Sistema Centralizado de Alertas (Visual & Audio)
    Version: 10.2.0
]]

local addonName, S = ...
S.AlertHub = {}
local AH = S.AlertHub

AH.Frame = nil
AH.Queue = {}

-- Tipos de Alerta
AH.Types = {
    INFO     = {color = {1, 1, 0},      sound = nil,          duration = 3},
    WARNING  = {color = {1, 0.5, 0},    sound = "RaidWarning", duration = 4},
    CRITICAL = {color = {1, 0, 0},      sound = "RaidWarning", duration = 5, flash = true},
    SUCCESS  = {color = {0, 1, 0},      sound = "ReadyCheck",  duration = 3},
}

function AH:Initialize()
    self:CreateFrame()
end

function AH:CreateFrame()
    if self.Frame then return end

    local f = CreateFrame("Frame", "SequitoAlertFrame", UIParent)
    f:SetSize(400, 100)
    f:SetPoint("TOP", UIParent, "TOP", 0, -200)

    -- Texto Principal
    f.text = f:CreateFontString(nil, "OVERLAY", "GameFontNormalHuge")
    f.text:SetPoint("CENTER", f, "CENTER", 0, 0)
    f.text:SetShadowOffset(2, -2)

    -- Icono
    f.icon = f:CreateTexture(nil, "OVERLAY")
    f.icon:SetSize(48, 48)
    f.icon:SetPoint("RIGHT", f.text, "LEFT", -10, 0)

    -- Motor de animación 3.3.5a nativo (sin AnimationGroup):
    -- fade-in 0.2s → hold N segundos → fade-out 0.5s → hide
    -- La duración del hold se configura en AH:Show() via f.holdDuration
    f.phase = 0
    f.phaseTimer = 0
    f.holdDuration = 3

    self.Frame = f

    -- Movilidad
    f:SetMovable(true)
    f:EnableMouse(true)
    f:RegisterForDrag("LeftButton")
    f:SetScript("OnDragStart", function(self) self:StartMoving() end)
    f:SetScript("OnDragStop", function(self)
        self:StopMovingOrSizing()
        if S.SmartDefaults then
            S.SmartDefaults:SavePosition("AlertHub", self)
        end
    end)

    -- Restaurar posición
    if S.SmartDefaults then
        if not S.SmartDefaults:RestorePosition("AlertHub") then
            f:SetPoint("TOP", UIParent, "TOP", 0, -200)
        end
    else
        f:SetPoint("TOP", UIParent, "TOP", 0, -200)
    end

    f:Hide()
end

function AH:Show(msg, type, icon, colorOverride)
    if not self.Frame then self:Initialize() end

    local config = self.Types[type] or self.Types.INFO

    -- Visual
    self.Frame.text:SetText(msg)

    if colorOverride then
        self.Frame.text:SetTextColor(unpack(colorOverride))
    else
        self.Frame.text:SetTextColor(unpack(config.color))
    end

    if icon then
        self.Frame.icon:SetTexture(icon)
        self.Frame.icon:Show()
    else
        self.Frame.icon:Hide()
    end

    -- Audio
    if config.sound then
        PlaySound(config.sound)
    end

    -- Screen Flash (para CRITICAL)
    if config.flash then
        self:FlashScreen()
    end

    -- Lanzar motor de animación fade-in → hold → fade-out
    local f = self.Frame
    f.phase = 0
    f.phaseTimer = 0
    f.holdDuration = config.duration or 3
    f:Show()
    f:SetAlpha(0)

    f:SetScript("OnUpdate", function(frame, elapsed)
        frame.phaseTimer = frame.phaseTimer + elapsed
        if frame.phase == 0 then
            -- Fase 0: fade-in (0.2s)
            local a = math.min(1.0, frame.phaseTimer / 0.2)
            frame:SetAlpha(a)
            if frame.phaseTimer >= 0.2 then
                frame.phase = 1
                frame.phaseTimer = 0
            end
        elseif frame.phase == 1 then
            -- Fase 1: hold (holdDuration segundos)
            frame:SetAlpha(1.0)
            if frame.phaseTimer >= frame.holdDuration then
                frame.phase = 2
                frame.phaseTimer = 0
            end
        elseif frame.phase == 2 then
            -- Fase 2: fade-out (0.5s)
            local a = math.max(0.0, 1.0 - (frame.phaseTimer / 0.5))
            frame:SetAlpha(a)
            if frame.phaseTimer >= 0.5 then
                frame:Hide()
                frame:SetScript("OnUpdate", nil)
            end
        end
    end)
end

function AH:FlashScreen()
    if not self.FlashFrame then
        self.FlashFrame = CreateFrame("Frame", "SequitoFlash", UIParent)
        self.FlashFrame:SetFrameStrata("BACKGROUND")
        self.FlashFrame:SetAllPoints()
        self.FlashFrame.t = self.FlashFrame:CreateTexture(nil, "BACKGROUND")
        self.FlashFrame.t:SetAllPoints()
        -- SetTexture(r,g,b,a) se traduce automáticamente por el polyfill de Constants.lua
        self.FlashFrame.t:SetTexture(1, 0, 0, 0.3)
        self.FlashFrame:Hide()
    end

    -- Fade-out simple: mostrar y desvanecer en 0.8s
    local ff = self.FlashFrame
    ff:Show()
    ff:SetAlpha(1)
    ff.elapsed = 0
    ff:SetScript("OnUpdate", function(self, elapsed)
        self.elapsed = self.elapsed + elapsed
        local a = math.max(0.0, 1.0 - (self.elapsed / 0.8))
        self:SetAlpha(a)
        if self.elapsed >= 0.8 then
            self:Hide()
            self:SetScript("OnUpdate", nil)
        end
    end)
end

-- Init
local f = CreateFrame("Frame")
f:RegisterEvent("PLAYER_LOGIN")
f:SetScript("OnEvent", function() AH:Initialize() end)
