--[[
    Jaina - Void Whispers (Audio FX)
    Modulo v11.0: Feedback auditivo inmersivo.
]]

local addonName, S = ...
S.Audio = {}
local Audio = S.Audio

-- Config
local EXECUTE_SOUND = "Sound\\Events\\TimeStop.wav" -- Heartbeat-like booming sound
local PROC_SOUND = "Sound\\Spells\\PVPFlagTaken.wav" -- Impact sound

-- Procs to watch (SpellName -> True)
local WATCHED_PROCS = {
    ["Art of War"] = true,
    ["The Art of War"] = true,
    ["El arte de la guerra"] = true,
    ["Hot Streak"] = true,
    ["Buena racha"] = true,
    ["Molten Core"] = true,
    ["Núcleo de Magma"] = true,
    ["Eclipse (Solar)"] = true,
    ["Eclipse (Lunar)"] = true,
    ["Killing Machine"] = true,
    ["Máquina de matar"] = true,
    ["Shadow Trance"] = true,
    ["Trance de las Sombras"] = true,
    ["Decimation"] = true,
    ["Diezmar"] = true,
}

function Audio:Initialize()
    if S.db and S.db.profile and S.db.profile.AudioFX == false then return end
    
    self.Frame = CreateFrame("Frame")
    self.Frame:RegisterEvent("UNIT_HEALTH")
    self.Frame:RegisterEvent("COMBAT_LOG_EVENT_UNFILTERED")
    self.Frame:RegisterEvent("PLAYER_REGEN_DISABLED")
    self.Frame:RegisterEvent("PLAYER_REGEN_ENABLED")
    
    self.Frame:SetScript("OnEvent", function(self, event, ...)
        if event == "UNIT_HEALTH" then
            Audio:CheckExecute(...)
        elseif event == "COMBAT_LOG_EVENT_UNFILTERED" then
            Audio:CheckProcs(...)
        elseif event == "PLAYER_REGEN_DISABLED" then
            Audio.InCombat = true
        elseif event == "PLAYER_REGEN_ENABLED" then
            Audio.InCombat = false
        end
    end)
    
    print("|cFF9900FFJaina Audio|r: Void Whispers listening.")
end

-- ============================================================================
-- EXECUTE PHASE (Heartbeat)
-- ============================================================================

function Audio:CheckExecute(unit)
    if unit ~= "target" then return end
    if not self.InCombat then return end
    if UnitIsDead("target") then return end
    
    local hp = UnitHealth("target")
    local max = UnitHealthMax("target")
    local pct = (hp / max) * 100
    
    -- Execute Range < 25% (Standard) or < 35% (Some classes)
    if pct <= 25 then
        local now = GetTime()
        if not self.lastHeartbeat or (now - self.lastHeartbeat > 2.0) then
            PlaySoundFile(EXECUTE_SOUND)
            self.lastHeartbeat = now
        end
    end
end

-- ============================================================================
-- PROC IMPACT (Critical Buffs)
-- ============================================================================

function Audio:CheckProcs(timestamp, event, sourceGUID, sourceName, sourceFlags, destGUID, destName, destFlags, spellId, spellName)
    if event == "SPELL_AURA_APPLIED" then
        if destGUID == UnitGUID("player") and WATCHED_PROCS[spellName] then
            PlaySoundFile(PROC_SOUND)
        end
    end
end
