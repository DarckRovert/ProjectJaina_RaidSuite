--[[
    SEQUITO - Data Module
    Contiene tablas de datos estaticos para la interfaz y utilidades.
]]--

local addonName, S = ...
S.Data = S.Data or {}
S.Data.Classes = {}

-- Utility Buttons (Satellites) Config
-- Spells to show around the sphere (Clockwise from top-right: 45, -45, -135, 135)
-- Each slot now contains an ARRAY of spell options, ordered by priority (highest rank first).
-- The addon will automatically select the FIRST spell the player has learned.

-- WARLOCK
S.Data.Classes["WARLOCK"] = {
    [1] = {47864, 47871, 23822, 11730, 5699, 6201}, -- Create Healthstone (Ranks 8-1)
    [2] = {47884, 47882, 20762, 20761, 20760, 20758, 693}, -- Create Soulstone (Ranks 7-1)
    [3] = {47891, 28610, 11740, 11739, 6229}, -- Shadow Ward (Ranks 4-1)
    [4] = 5697,  -- Unending Breath (Aliento inagotable) - Placeholder (Swapped for pet in GUI)
}

-- Mapeo de habilidades de mascota para reemplazar botones
S.Data.PetSpells = {
    ["Imp"] = 47982, -- Fire Shield (Escudo de Fuego) - O Blood Pact (Pasiva)
    ["Diablillo"] = 47982,
    
    ["Voidwalker"] = 47985, -- Sacrifice (Sacrificio) - Critico
    ["Abisario"] = 47985,
    
    ["Succubus"] = 6358, -- Seduction (Seduccion) - Critico
    ["Sucubo"] = 6358,
    
    ["Felhunter"] = 19647, -- Spell Lock (Bloqueo de hechizo) - Critico
    ["Manafago"] = 19647,
    
    ["Felguard"] = 30198, -- Intercept (Interceptar) - Utility
    ["Guardia Apocaliptico"] = 30198,
}


-- MAGE
S.Data.Classes["MAGE"] = {
    [1] = {43039, 43038, 33405, 27134, 13033, 11426, 7301}, -- Ice Barrier (Ranks 7-1)
    [2] = {43012, 43010, 27128, 10225, 8458, 543}, -- Fire Ward (Ranks 6-1)
    [3] = {43015, 43012, 32796, 27134, 6143, 5676}, -- Frost Ward (Ranks 6-1)
    [4] = {43046, 43024, 27125, 22783, 7302, 6117}, -- Molten/Mage Armor (Ranks 6-1)
}

-- PRIEST
S.Data.Classes["PRIEST"] = {
    [1] = {48066, 48065, 25218, 25217, 10901, 10900, 10899, 6066, 6065, 3747, 600, 17}, -- Power Word: Shield (Ranks 12-1)
    [2] = 6346,  -- Fear Ward (No ranks)
    [3] = {48168, 48167, 25312, 10952, 10951, 7128, 602, 588, 1006, 1245}, -- Inner Fire (Ranks 10-1)
    [4] = {48073, 48072, 27841, 27681, 25312, 14819, 14818, 14752}, -- Divine Spirit (Ranks 8-1)
}

-- DRUID
S.Data.Classes["DRUID"] = {
    [1] = {48468, 27013, 24977, 24976, 24975, 9758, 5570}, -- Insect Swarm (Ranks 7-1)
    [2] = {53307, 26992, 9910, 9756, 8914, 1075, 782, 467}, -- Thorns (Ranks 8-1)
    [3] = {48469, 48470, 26990, 9885, 9884, 8907, 5234, 6756, 5232, 1126}, -- Mark of the Wild (Ranks 10-1)
    [4] = 22812, -- Barkskin (No ranks)
}

-- PALADIN
S.Data.Classes["PALADIN"] = {
    [1] = {498, 5573}, -- Divine Protection (Ranks 2-1)
    [2] = {642, 1020}, -- Divine Shield (Ranks 2-1)
    [3] = {10278, 5599, 1022}, -- Hand of Protection (Ranks 3-1)
    [4] = 1044,  -- Hand of Freedom (No ranks)
}

-- SHAMAN
S.Data.Classes["SHAMAN"] = {
    [1] = {49281, 49280, 25472, 25469, 10432, 10431, 8134, 945, 8788, 325, 324}, -- Lightning Shield (Ranks 11-1)
    [2] = {52127, 52129, 52131, 52134, 52136, 52138, 24398, 33736}, -- Water Shield (Ranks 8-1)
    [3] = {49284, 49283, 32594, 974}, -- Earth Shield (Ranks 4-1)
    [4] = {546, 547}, -- Water Walking (Ranks 2-1)
}

-- HUNTER
S.Data.Classes["HUNTER"] = {
    [1] = 19263, -- Deterrence (No ranks)
    [2] = 5384,  -- Feign Death (No ranks)
    [3] = 3045,  -- Rapid Fire (No ranks)
    [4] = {34074, 27068, 25296, 14327, 14326, 14325, 14324, 13165}, -- Aspect of the Viper/Hawk (Ranks 8-1)
}

-- ROGUE
S.Data.Classes["ROGUE"] = {
    [1] = {26669, 5277}, -- Evasion (Ranks 2-1)
    [2] = 31224, -- Cloak of Shadows (No ranks)
    [3] = {11305, 8696, 2983}, -- Sprint (Ranks 3-1)
    [4] = 14185, -- Preparation (No ranks)
}

-- WARRIOR
S.Data.Classes["WARRIOR"] = {
    [1] = 871,   -- Shield Wall (No ranks)
    [2] = 1719,  -- Recklessness (No ranks)
    [3] = 46924, -- Bladestorm (No ranks)
    [4] = 23920, -- Spell Reflection (No ranks)
}

-- DEATHKNIGHT
S.Data.Classes["DEATHKNIGHT"] = {
    [1] = {48707, 48792, 47528}, -- Anti-Magic Shell / Icebound Fortitude / Mind Freeze
    [2] = {49028, 47568, 49016}, -- Dancing Rune Weapon / Empower Rune Weapon / Hysteria
    [3] = {49222, 55233, 49039}, -- Bone Shield / Vampiric Blood / Lichborne
    [4] = {49576, 47541, 45529}, -- Death Grip / Death Coil / Blood Tap
}
