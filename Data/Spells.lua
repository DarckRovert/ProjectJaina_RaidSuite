--[[
    SEQUITO - Spell Data for ALL Classes
    Defining the 4 Satellite Buttons for every class.
]]--

local addonName, S = ...
S.Data = S.Data or {}

-- Format: [1]=TopLeft, [2]=TopRight, [3]=BottomRight, [4]=BottomLeft
-- Using Spell IDs for WotLK 3.3.5a

S.Data.Classes = {
    ["WARRIOR"] = {
        [4] = 34428, -- Victory Rush (Classic leveling/farm)
        [1] = 6673,  -- Battle Shout (Buff)
        [2] = 18499, -- Berserker Rage (Anti-Fear - Very important)
        [3] = 2565,  -- Shield Block (Defense)
    },
    ["ROGUE"] = {
        [4] = 1784,  -- Stealth
        [1] = 2983,  -- Sprint (Mobility)
        [2] = 26669, -- Evasion (Survival)
        [3] = 1766,  -- Kick (Interrupt)
    },
    ["PRIEST"] = {
        [4] = 17,    -- Power Word: Shield
        [1] = 588,   -- Inner Fire
        [2] = 33206, -- Pain Suppression (Disc) or 47788 (Guardian Spirit) - using generic Fade/Dispersion?
        -- Fallback to Fade for universal:
        [2] = 586,   -- Fade (Aggro drop)
        [3] = 1706,  -- Levitate (Flavor/Utility)
    },
    ["HUNTER"] = {
        [4] = 5384,  -- Feign Death (Survival)
        [1] = 781,   -- Disengage (Mobility) - Replaces Trap
        [2] = 34477, -- Misdirection (Utility) - Replaces Sting
        [3] = 136,   -- Mend Pet
    },
    ["DRUID"] = {
        [4] = 1126,  -- Mark of the Wild
        [1] = 29166, -- Innervate (Mana)
        [2] = 22812, -- Barkskin (Defense)
        [3] = 20484, -- Rebirth (Combat Rez - Critical)
    },
    ["SHAMAN"] = {
        [4] = 2825,  -- Bloodlust (Horde) / 32182 Heroism (Alliance) - The main cooldown
        [1] = 546,   -- Water Walking (Flavor)
        [2] = 2645,  -- Ghost Wolf (Mobility)
        [3] = 20608, -- Reincarnation (Self Rez) - Icon visualization only
    },
    ["MAGE"] = {
        [4] = 45438, -- Ice Block
        [1] = 42955, -- Conjure Mana Gem
        [2] = 66,    -- Invisibility (Survival) - Replaces Intellect (is in Menu)
        [3] = 1953,  -- Blink
    },
    ["PALADIN"] = {
        [4] = 642,   -- Divine Shield
        [1] = 48932, -- Divine Plea (Mana)
        [2] = 1044,  -- Hand of Freedom
        [3] = 633,   -- Lay on Hands (Oh S*** Button) - Replaces HoP
    },
    ["WARLOCK"] = {
        [4] = 28176, -- Fel Armor
        [1] = 698,   -- Ritual of Summoning
        [2] = 6201,  -- Create Healthstone
        [3] = 20707, -- Soulstone (Critical Utility) - Replaces Meta
    },
    ["DEATHKNIGHT"] = {
        [4] = 57330, -- Horn of Winter
        [1] = 48792, -- Icebound Fortitude (Defense) - Replaces Presence
        [2] = 49576, -- Death Grip (Positioning) - Replaces Presence
        [3] = 42650, -- Army of the Dead (Cooldown) - Replaces Presence
    },
}
