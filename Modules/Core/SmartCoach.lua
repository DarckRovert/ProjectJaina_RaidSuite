--[[
    SEQUITO - Smart Coach (v10.0)
    Inteligencia Activa: Sugerencias en tiempo real.
]]

local addonName, S = ...
S.Coach = {}
local SC = S.Coach

function SC:Initialize()
    self.frame = self:CreateHintFrame()
    self:RegisterEvents()
    self.lastHint = 0
    print("|cFFFF00FFJaina|r: [Coach] Entrenador inteligente activo.")
end

function SC:RegisterEvents()
    local f = CreateFrame("Frame")
    f:RegisterEvent("PLAYER_REGEN_DISABLED")
    f:RegisterEvent("PLAYER_REGEN_ENABLED")
    f:RegisterEvent("UNIT_AURA")
    f:RegisterEvent("UNIT_HEALTH")
    f:RegisterEvent("UNIT_MANA")
    
    f:SetScript("OnEvent", function(self, event, unit)
        if event == "PLAYER_REGEN_DISABLED" then
            SC.InCombat = true
            SC:StartAnalysis()
        elseif event == "PLAYER_REGEN_ENABLED" then
            SC.InCombat = false
            SC:StopAnalysis()
            SC.frame:Hide()
        end
    end)
    
    self.eventFrame = f
end

-- ===========================================================================
-- ANALYSIS LOOP (Low frequency: 1s)
-- ===========================================================================
function SC:StartAnalysis()
    self.eventFrame:SetScript("OnUpdate", function(self, elapsed)
        self.timer = (self.timer or 0) + elapsed
        if self.timer > 1.0 then
             SC:AnalyzeSituation()
             self.timer = 0
        end
    end)
end

function SC:StopAnalysis()
    self.eventFrame:SetScript("OnUpdate", nil)
end

function SC:AnalyzeSituation()
    if not self.InCombat then return end
    
    -- Prevent spam: 5s cooldown on hints
    if (GetTime() - self.lastHint) < 5 then return end
    
    local hint = nil
    local type = "DANGER"
    
    -- 1. Check Self Buffs (Simplified)
    local class = select(2, UnitClass("player"))
    if class == "PRIEST" and not self:HasBuff("Inner Fire") then
        hint = "¡Falta Fuego Interno!"
        type = "BUFF"
    elseif class == "MAGE" and not self:HasBuff("Molten Armor") and not self:HasBuff("Ice Armor") then
        hint = "¡Falta Armadura!"
        type = "BUFF"
    end
    
    -- 2. Check Mana
    local mana = UnitPower("player", 0)
    local maxMana = UnitPowerMax("player", 0)
    if not hint and maxMana > 0 and (mana / maxMana) < 0.10 then
        -- Generic mana hint (could be class specific: Innervate, Divine Plea)
        hint = "Mana Crítico (<10%)"
        type = "MANA"
    end
    
    -- 3. Check Health
    local hp = UnitHealth("player")
    local maxHp = UnitHealthMax("player")
    if not hint and (hp / maxHp) < 0.20 then
        hint = "¡Salud Baja! Usa Defensivos"
        type = "DANGER"
    end
    
    if hint then
        self:ShowHint(hint, type)
        self.lastHint = GetTime()
    else
        self.frame:Hide()
    end
end

function SC:HasBuff(name)
    return UnitAura("player", name) ~= nil
end

-- ===========================================================================
-- UI: HINT FRAME (Heads Up Display)
-- ===========================================================================
function SC:CreateHintFrame()
    local f = CreateFrame("Frame", "JainaCoachFrame", UIParent)
    f:SetSize(300, 50)
    f:SetPoint("CENTER", 0, 150) -- Above character
    f:Hide()
    
    f.text = f:CreateFontString(nil, "OVERLAY", "GameFontNormalHuge")
    f.text:SetPoint("CENTER")
    f.text:SetTextColor(1, 0.8, 0, 1) -- Golden
    
    -- Icon
    f.icon = f:CreateTexture(nil, "ARTWORK")
    f.icon:SetSize(32, 32)
    f.icon:SetPoint("RIGHT", f.text, "LEFT", -10, 0)
    f.icon:SetTexture("Interface\\Icons\\Inv_Misc_QuestionMark")
    
    -- Flash Animation
    f.anim = f:CreateAnimationGroup()
    local a1 = f.anim:CreateAnimation("Alpha")
    a1:SetChange(-1)
    a1:SetDuration(0.5)
    a1:SetOrder(1)
    a1:SetSmoothing("OUT")
    local a2 = f.anim:CreateAnimation("Alpha")
    a2:SetChange(1)
    a2:SetDuration(0.5)
    a2:SetOrder(2)
    a2:SetSmoothing("IN")
    f.anim:SetLooping("REPEAT")
    
    return f
end

-- ===========================================================================
-- SOUND SYSTEM (TTS Simulation)
-- ===========================================================================
SC.Sounds = {
    ["DANGER"] = "Sound\\Creature\\HoodWolf\\HoodWolfAttack1.wav", -- Generic Danger
    ["MANA"]   = "Sound\\Interface\\RaidWarning.wav",               -- Mana Low
    ["BUFF"]   = "Sound\\Interface\\iTellMessage.wav",              -- Missing Buff
    ["KILL"]   = "Sound\\Creature\\Peon\\PeonBuildingComplete1.wav" -- Positive
}

function SC:PlayVoice(type)
    local sound = self.Sounds[type] or "Sound\\Interface\\RaidWarning.wav"
    PlaySoundFile(sound)
end

function SC:ShowHint(text, type)
    self.frame.text:SetText(text)
    self.frame:Show()
    self.frame.anim:Play()
    
    -- Audio Feedback
    self:PlayVoice(type or "DANGER")
    
    -- Print to chat as backup
    print("|cFFFF00FF[Coach]|r: " .. text)
end

-- Registrar
if S.ModuleConfig then
    S.ModuleConfig:RegisterModule("SmartCoach", {
        name = "Smart Coach",
        description = "Asistente inteligente de combate",
        category = "general",
        icon = "Interface\\Icons\\Inv_Misc_Head_Dragon_01",
        options = {}
    })
end
