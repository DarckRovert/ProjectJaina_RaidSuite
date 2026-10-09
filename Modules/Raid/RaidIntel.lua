--[[
    SEQUITO - Raid Intelligence
    Escaneo de buffs, alertas estratégicas y datos en tiempo real.
    Inspirado en NecrosisWarlord.lua
]]--

local addonName, S = ...
S.RaidIntel = {}

-- ===========================================================================
-- BUFFS ESENCIALES A VERIFICAR
-- ===========================================================================
S.RaidIntel.EssentialBuffs = {
    -- Nombre en español y en inglés para compatibilidad
    Kings = { "Bendición de reyes", "Blessing of Kings", "Bendición de santuario", "Blessing of Sanctuary" },
    Fortitude = { "Entereza", "Fortitude", "Palabra de poder: entereza", "Power Word: Fortitude" },
    Wild = { "Don de lo Salvaje", "Gift of the Wild", "Marca de lo Salvaje", "Mark of the Wild" },
    Intellect = { "Intelecto Arcano", "Arcane Intellect", "Brillantez Arcana", "Arcane Brilliance" },
    Spirit = { "Espíritu divino", "Divine Spirit", "Plegaria de espíritu", "Prayer of Spirit" },
    Food = { "Bien alimentado", "Well Fed" },
}

-- ===========================================================================
-- ESCANEO DE BUFFS
-- ===========================================================================
function S.RaidIntel:ScanBuffs()
    local missing = {
        Kings = {},
        Fortitude = {},
        Wild = {},
        Intellect = {},
        Spirit = {},
        Food = {},
    }
    
    local numRaid = GetNumRaidMembers()
    local numParty = GetNumPartyMembers()
    
    local units = {}
    
    if numRaid > 0 then
        for i = 1, numRaid do
            table.insert(units, "raid" .. i)
        end
    elseif numParty > 0 then
        table.insert(units, "player")
        for i = 1, numParty do
            table.insert(units, "party" .. i)
        end
    else
        table.insert(units, "player")
    end
    
    for _, unit in ipairs(units) do
        if UnitExists(unit) and UnitIsConnected(unit) and not UnitIsDeadOrGhost(unit) then
            local name = UnitName(unit)
            
            for buffType, buffNames in pairs(self.EssentialBuffs) do
                if not self:HasAnyBuff(unit, buffNames) then
                    table.insert(missing[buffType], name)
                end
            end
        end
    end
    
    return missing
end

function S.RaidIntel:HasAnyBuff(unit, buffNames)
    for i = 1, 40 do
        local name = UnitBuff(unit, i)
        if not name then break end
        
        for _, buffName in ipairs(buffNames) do
            if name:lower():find(buffName:lower()) then
                return true
            end
        end
    end
    return false
end

function S.RaidIntel:PrintBuffReport()
    -- Verificar si escaneo de buffs está habilitado
    if not self:GetOption("scanBuffs") then
        return
    end
    
    local missing = self:ScanBuffs()
    local allGood = true
    
    print("|cFFFF00FF=== Jaina: Reporte de Buffs ===")
    
    local buffLabels = {
        Kings = "Reyes/Santuario",
        Fortitude = "Entereza",
        Wild = "Marca/Don Salvaje",
        Intellect = "Intelecto",
        Spirit = "Espíritu",
        Food = "Comida",
    }
    
    for buffType, players in pairs(missing) do
        if #players > 0 then
            allGood = false
            print(string.format("|cFFFF0000Falta %s:|r %s", 
                buffLabels[buffType] or buffType, 
                table.concat(players, ", ")))
        end
    end
    
    if allGood then
        print("|cFF00FF00¡Todos los buffs están aplicados! LISTOS PARA COMBATE.|r")
    end
end

-- ===========================================================================
-- COOLDOWNS IMPORTANTES DE RAID
-- ===========================================================================
S.RaidIntel.ImportantCDs = {
    -- Bloodlust/Heroism
    [2825]  = { name = "Bloodlust", type = "BURST" },
    [32182] = { name = "Heroism", type = "BURST" },
    
    -- Battle Rez
    [20484] = { name = "Rebirth", type = "BREZ" },
    [20707] = { name = "Soulstone", type = "BREZ" },
    
    -- Raid CDs
    [64901] = { name = "Hymn of Hope", type = "MANA_CD" },
    [31821] = { name = "Aura Mastery", type = "RAID_CD" },
    [16190] = { name = "Mana Tide Totem", type = "MANA_CD" },
    
    -- Tank CDs
    [871]   = { name = "Shield Wall", type = "TANK_CD" },
    [12975] = { name = "Last Stand", type = "TANK_CD" },
    [48792] = { name = "Icebound Fortitude", type = "TANK_CD" },
    [498]   = { name = "Divine Protection", type = "TANK_CD" },
    [61336] = { name = "Survival Instincts", type = "TANK_CD" },
}

-- ===========================================================================
-- ALERTAS DE COMBATE
-- ===========================================================================
S.RaidIntel.CombatAlerts = {}

function S.RaidIntel:RegisterCombatEvents()
    if S.CLEU and S.CLEU.Register then
        S.CLEU:Register("SPELL_CAST_SUCCESS", function(...)
            S.RaidIntel:OnCombatLog(...)
        end)
    else
        local frame = CreateFrame("Frame")
        frame:RegisterEvent("COMBAT_LOG_EVENT_UNFILTERED")
        frame:SetScript("OnEvent", function(self, event, ...)
            S.RaidIntel:OnCombatLog(...)
        end)
    end
end

function S.RaidIntel:OnCombatLog(...)
    -- WoW 3.3.5a CLEU signature: timestamp, event, sourceGUID, sourceName, sourceFlags, destGUID, destName, destFlags, spellID, spellName, ...
    local timestamp, eventType, sourceGUID, sourceName, sourceFlags, destGUID, destName, destFlags, spellID, spellName = ...
    
    -- Detectar uso de CDs importantes
    if eventType == "SPELL_CAST_SUCCESS" then
        local cdInfo = self.ImportantCDs[spellID]
        if cdInfo then
            self:OnImportantCD(sourceName, cdInfo)
        end
    end
end

function S.RaidIntel:OnImportantCD(caster, cdInfo)
    local msg = string.format("%s usó %s", caster or "Alguien", cdInfo.name)
    local color = {r=1, g=1, b=0} -- Default Yellow
    
    if cdInfo.type == "BURST" then
        msg = "★ " .. string.upper(cdInfo.name) .. " !! (" .. caster .. ")"
        color = {r=1, g=0.2, b=0.2} -- Red
        PlaySound("RaidWarning")
    elseif cdInfo.type == "BREZ" then
        color = {r=0.2, g=1, b=0.2} -- Green
    elseif cdInfo.type == "TANK_CD" then
        color = {r=0.5, g=0.5, b=1} -- Blue
    end
    
    -- Print to chat as log
    print("|cFFFFD700[Jaina]|r " .. msg)
    
    -- Show on Screen (Big Text)
    if RaidWarningFrame then
        RaidNotice_AddMessage(RaidWarningFrame, msg, color)
    else
        UIErrorsFrame:AddMessage(msg, color.r, color.g, color.b, 1.0, UIERRORS_HOLD_TIME)
    end
end

-- ===========================================================================
-- UTILIDADES
-- ===========================================================================
function S.RaidIntel:GetClassCount()
    local counts = {}
    local numRaid = GetNumRaidMembers()
    local numParty = GetNumPartyMembers()
    
    if numRaid > 0 then
        for i = 1, numRaid do
            local _, _, _, _, _, fileName = GetRaidRosterInfo(i)
            if fileName then
                counts[fileName] = (counts[fileName] or 0) + 1
            end
        end
    elseif numParty > 0 then
        local _, playerClass = UnitClass("player")
        if playerClass then counts[playerClass] = (counts[playerClass] or 0) + 1 end
        for i = 1, numParty do
            local _, partyClass = UnitClass("party" .. i)
            if partyClass then
                counts[partyClass] = (counts[partyClass] or 0) + 1
            end
        end
    else
        local _, playerClass = UnitClass("player")
        if playerClass then counts[playerClass] = (counts[playerClass] or 0) + 1 end
    end
    
    return counts
end

function S.RaidIntel:PrintClassCount()
    local counts = self:GetClassCount()
    
    print("|cFFFF00FF=== Jaina: Clases en Raid ===")
    
    for class, count in pairs(counts) do
        local r, g, b = S.Universal:GetClassColor(class)
        print(string.format("|cFF%02x%02x%02x%s: %d|r", r*255, g*255, b*255, class, count))
    end
end

-- ===========================================================================
-- INICIALIZACIÓN
-- ===========================================================================

-- Helper para obtener configuración
function S.RaidIntel:GetOption(key)
    if S.ModuleConfig then
        return S.ModuleConfig:GetValue("RaidIntel", key)
    end
    return true
end

function S.RaidIntel:Initialize()
    if not self:GetOption("enabled") then
        return
    end
    
    self:RegisterCombatEvents()
    print("|cFFFF00FFJaina|r: [RaidIntel] Sistema de inteligencia iniciado.")
end

-- Registrar módulo en ModuleConfig
if S.ModuleConfig then
    S.ModuleConfig:RegisterModule("RaidIntel", {
        name = "Raid Intel",
        description = "Escaneo de buffs, alertas estratégicas y datos en tiempo real",
        category = "raid",
        icon = "Interface\\Icons\\Spell_Holy_MindVision",
        options = {
            {key = "enabled", type = "checkbox", label = "Habilitar Raid Intel", default = true},
            {key = "scanBuffs", type = "checkbox", label = "Escanear buffs de raid", default = true},
            {key = "trackCooldowns", type = "checkbox", label = "Trackear cooldowns importantes", default = true},
            {key = "announceAlerts", type = "checkbox", label = "Anunciar alertas tácticas", default = true},
        }
    })
end

