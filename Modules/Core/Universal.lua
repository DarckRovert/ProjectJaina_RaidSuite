--[[
    SEQUITO - Universal Class System
    Detección de clase/raza y configuración universal.
    Inspirado en NecrosisUniversal.lua
]]--

local addonName, S = ...
S.Universal = {}

-- ===========================================================================
-- RAZAS Y HABILIDADES RACIALES
-- ===========================================================================
S.Universal.Races = {
    -- Alianza
    ["Human"]     = { SpellID = 59752, Icon = "Spell_Shadow_Charm" },           -- Every Man for Himself
    ["Dwarf"]     = { SpellID = 20594, Icon = "Spell_Shadow_UnholyStrength" },  -- Stoneform
    ["NightElf"]  = { SpellID = 58984, Icon = "Ability_Ambush" },               -- Shadowmeld
    ["Gnome"]     = { SpellID = 20589, Icon = "Spell_Nature_Polymorph" },       -- Escape Artist
    ["Draenei"]   = { SpellID = 59542, Icon = "Spell_Holy_FlashHeal" },         -- Gift of the Naaru
    
    -- Horda
    ["Orc"]       = { SpellID = 20572, Icon = "Racial_Orc_BerserkerStrength" }, -- Blood Fury
    ["Scourge"]   = { SpellID = 7744,  Icon = "Spell_Shadow_RaiseDead" },       -- Will of the Forsaken
    ["Tauren"]    = { SpellID = 20549, Icon = "Ability_WarStomp" },             -- War Stomp
    ["Troll"]     = { SpellID = 26297, Icon = "Racial_Troll_Berserk" },         -- Berserking
    ["BloodElf"]  = { SpellID = 28730, Icon = "Spell_Shadow_Teleport" },        -- Arcane Torrent
}

-- ===========================================================================
-- DETECCIÓN DE CLASE Y SPEC
-- ===========================================================================
function S.Universal:GetPlayerInfo()
    local _, class = UnitClass("player")
    local _, race = UnitRace("player")
    local spec = self:GetSpec()
    local role = self:GetRole(class, spec)
    
    return {
        class = class,
        race = race,
        spec = spec,
        role = role,
        name = UnitName("player"),
        level = UnitLevel("player")
    }
end

function S.Universal:GetSpec()
    local group = GetActiveTalentGroup and GetActiveTalentGroup() or 1
    local c1, c2, c3 = 0, 0, 0
    
    if group then
        _, _, c1 = GetTalentTabInfo(1, false, false, group)
        _, _, c2 = GetTalentTabInfo(2, false, false, group)
        _, _, c3 = GetTalentTabInfo(3, false, false, group)
    else
        _, _, c1 = GetTalentTabInfo(1)
        _, _, c2 = GetTalentTabInfo(2)
        _, _, c3 = GetTalentTabInfo(3)
    end
    
    local maxPoints = math.max(c1 or 0, c2 or 0, c3 or 0)
    if maxPoints == c1 then return 1 end
    if maxPoints == c2 then return 2 end
    if maxPoints == c3 then return 3 end
    return 1
end

function S.Universal:GetRole(class, spec)
    local roles = {
        ["WARRIOR"]     = { [1] = "DPS", [2] = "DPS", [3] = "TANK" },
        ["PALADIN"]     = { [1] = "HEALER", [2] = "TANK", [3] = "DPS" },
        ["HUNTER"]      = { [1] = "DPS", [2] = "DPS", [3] = "DPS" },
        ["ROGUE"]       = { [1] = "DPS", [2] = "DPS", [3] = "DPS" },
        ["PRIEST"]      = { [1] = "HEALER", [2] = "HEALER", [3] = "DPS" },
        ["DEATHKNIGHT"] = { [1] = "TANK", [2] = "DPS", [3] = "DPS" },
        ["SHAMAN"]      = { [1] = "DPS", [2] = "DPS", [3] = "HEALER" },
        ["MAGE"]        = { [1] = "DPS", [2] = "DPS", [3] = "DPS" },
        ["WARLOCK"]     = { [1] = "DPS", [2] = "DPS", [3] = "DPS" },
        ["DRUID"]       = { [1] = "DPS", [2] = "DPS", [3] = "HEALER" },
    }
    
    if roles[class] and roles[class][spec] then
        return roles[class][spec]
    end
    return "DPS"
end

function S.Universal:GetRacialSpell()
    local _, race = UnitRace("player")
    if self.Races[race] then
        local spellName = GetSpellInfo(self.Races[race].SpellID)
        return spellName, self.Races[race].Icon, self.Races[race].SpellID
    end
    return nil, nil, nil
end

-- ===========================================================================
-- COLORES DE CLASE
-- ===========================================================================
function S.Universal:GetClassColor(class)
    local colors = RAID_CLASS_COLORS[class]
    if colors then
        return colors.r, colors.g, colors.b
    end
    return 1, 1, 1
end

-- ===========================================================================
-- CONTADOR DE RECURSOS POR CLASE
-- ===========================================================================
function S.Universal:GetResourceCount()
    local _, class = UnitClass("player")
    local count = 0
    
    -- Recursos dinámicos de combate
    if class == "ROGUE" or (class == "DRUID" and GetShapeshiftForm() == 3) then
        local cp = GetComboPoints("player", "target")
        if cp > 0 then return cp, "COMBO" end
    end
    
    if class == "DEATHKNIGHT" then
        -- Runic Power
        local rp = UnitPower("player", 6) -- SPELL_POWER_RUNIC_POWER
        return math.floor(rp / 10), "RUNIC"
    end
    
    -- Recursos de inventario (reagentes)
    local reagents = {
        ["MAGE"]    = { id = 17020, name = "Arcane Powder" },
        ["PRIEST"]  = { id = 17029, name = "Sacred Candle" },
        ["DRUID"]   = { id = 17034, name = "Maple Seed" },
        ["SHAMAN"]  = { id = 17030, name = "Ankh" },
        ["PALADIN"] = { id = 21177, name = "Symbol of Kings" },
        ["ROGUE"]   = { id = 3775,  name = "Flash Powder" },
    }
    
    if class == "HUNTER" then
        local ammoSlot = GetInventorySlotInfo("AmmoSlot")
        local ammoID = GetInventoryItemID("player", ammoSlot)
        if ammoID then
            count = GetItemCount(ammoID)
            return count, "AMMO"
        else
            return 0, "AMMO"
        end
    end
    
    if reagents[class] then
        count = GetItemCount(reagents[class].id)
        return count, "REAGENT"
    end
    
    -- Warlock: Soul Shards
    if class == "WARLOCK" then
        return GetItemCount(6265), "SHARD"
    end
    
    -- Default: Espacios libres en bolsas
    for i = 0, 4 do
        count = count + GetContainerNumFreeSlots(i)
    end
    return count, "BAGSPACE"
end

-- ===========================================================================
-- INICIALIZACIÓN
-- ===========================================================================

-- Helper para obtener configuración
function S.Universal:GetOption(key)
    if S.ModuleConfig then
        local val = S.ModuleConfig:GetValue("Universal", key)
        if val ~= nil then return val end
    end
    return true
end

function S.Universal:Initialize()
    if not self:GetOption("enabled") then
        return
    end
    
    local info = self:GetPlayerInfo()
    
    S.PlayerInfo = info
    S.PlayerClass = info.class
    S.PlayerRace = info.race
    S.PlayerSpec = info.spec
    S.PlayerRole = info.role
    
    -- Aplicar color de clase a la esfera
    if S.Sphere then
        local r, g, b = self:GetClassColor(info.class)
        local tex = S.Sphere:GetNormalTexture()
        if tex then
            tex:SetVertexColor(r, g, b)
        end
    end
    
    local r, g, b = self:GetClassColor(info.class)
    -- Silent init
end

-- Evento para detectar cambio de spec
local specFrame = CreateFrame("Frame")
specFrame:RegisterEvent("ACTIVE_TALENT_GROUP_CHANGED")
specFrame:RegisterEvent("PLAYER_TALENT_UPDATE")
specFrame:SetScript("OnEvent", function(self, event)
    if S.Universal then
        S.Universal:Initialize()
    end
end)

-- Registrar módulo en ModuleConfig
if S.ModuleConfig then
    S.ModuleConfig:RegisterModule("Universal", {
        name = "Universal",
        description = "Sistema universal de detección de clase/raza y configuración",
        category = "utility",
        icon = "Interface\\Icons\\INV_Misc_QuestionMark",
        options = {
            {key = "enabled", type = "checkbox", label = "Habilitar Universal", default = true},
            {key = "showClassColor", type = "checkbox", label = "Aplicar color de clase a la esfera", default = true},
            {key = "trackResources", type = "checkbox", label = "Trackear recursos de clase", default = true},
        }
    })
end

