--[[
    SEQUITO - Performance Auditor
    Auditor de rendimiento y "FailBot".
    Rastrea muertes, cortes y dispels para reporte post-combate.
    Parte del sistema "Academy Mode" (v9.0)
]]

local addonName, S = ...
S.Performance = {}
local SP = S.Performance

SP.Data = {
    Interrupts = {},
    Dispels = {},
    Deaths = {}
}

-- ===========================================================================
-- CONFIGURACIÓN
-- ===========================================================================
function SP:Initialize()
    self:RegisterEvents()
    print("|cFFFF00FFSequito|r: [Academy] Auditor de rendimiento activo.")
end

function SP:RegisterEvents()
    local f = CreateFrame("Frame")
    f:RegisterEvent("PLAYER_REGEN_DISABLED") -- Combat Start
    f:RegisterEvent("PLAYER_REGEN_ENABLED")  -- Combat End
    
    f:SetScript("OnEvent", function(self, event, ...)
        if event == "PLAYER_REGEN_DISABLED" then
            SP:ResetData()
        elseif event == "PLAYER_REGEN_ENABLED" then
            if SP.InCombat then
                SP:Report()
                SP.InCombat = false
            end
        end
    end)

    if S.CLEU and S.CLEU.Register then
        local function onCLEU(...)
            SP.InCombat = true
            SP:OnCombatLog(...)
        end
        S.CLEU:Register("SPELL_INTERRUPT", onCLEU)
        S.CLEU:Register("SPELL_DISPEL", onCLEU)
        S.CLEU:Register("UNIT_DIED", onCLEU)
    else
        f:RegisterEvent("COMBAT_LOG_EVENT_UNFILTERED")
        f:HookScript("OnEvent", function(self, event, ...)
            if event == "COMBAT_LOG_EVENT_UNFILTERED" then
                SP.InCombat = true
                SP:OnCombatLog(...)
            end
        end)
    end
end

function SP:ResetData()
    self.Data = { Interrupts = {}, Dispels = {}, Deaths = {} }
    self.InCombat = true
end

-- ===========================================================================
-- COMBAT LOG LOGIC
-- ===========================================================================
function SP:OnCombatLog(...)
    -- WoW 3.3.5a CLEU signature: timestamp, event, sourceGUID, sourceName, sourceFlags, destGUID, destName, destFlags, spellID, spellName, spellSchool, extraSpellID, extraSpellName, extraSchool, auraType
    local timestamp, eventType, sourceGUID, sourceName, sourceFlags, destGUID, destName, destFlags, spellID, spellName, spellSchool, extraSpellID, extraSpellName, extraSchool, auraType = ...

    if eventType == "SPELL_INTERRUPT" then
        if sourceName then
            self.Data.Interrupts[sourceName] = (self.Data.Interrupts[sourceName] or 0) + 1
        end
    elseif eventType == "SPELL_DISPEL" then
        if sourceName then
            self.Data.Dispels[sourceName] = (self.Data.Dispels[sourceName] or 0) + 1
        end
    elseif eventType == "UNIT_DIED" then
        if destName and (UnitInRaid(destName) or UnitInParty(destName) or destName == UnitName("player")) then
            table.insert(self.Data.Deaths, { name = destName, time = date("%H:%M:%S") })
        end
    end
end

-- ===========================================================================
-- REPORTING
-- ===========================================================================
function SP:Report()
    -- Solo reportar si hay datos significativos y es el líder/oficial quien lo tiene activo
    -- (Para evitar spam si todos lo tienen). Por ahora, print local.
    
    print("|cFFFF00FF=== Sequito: Auditoría de Combate ===|r")
    
    -- Top Interrupts
    local maxInt = 0
    local topIntName = nil
    for name, count in pairs(self.Data.Interrupts) do
        if count > maxInt then maxInt = count; topIntName = name end
    end
    if topIntName then
        print(string.format((S.L["MVP_INTERRUPT"] or "MVP") .. ": |cFF00FF00%s (%d)|r", topIntName, maxInt))
    else
        print(S.L["NO_INTERRUPTS"] or "Nadie cortó.")
    end
    
    -- Deaths
    if #self.Data.Deaths > 0 then
        print(string.format("%s: %d", (S.L["DEATHS"] or "Muertes"), #self.Data.Deaths))
        -- List first 3 deaths
        for i=1, math.min(3, #self.Data.Deaths) do
            print(string.format("   - %s (%s)", self.Data.Deaths[i].name, self.Data.Deaths[i].time))
        end
    else
        print(S.L["NO_DEATHS"] or "Sin muertes.")
    end
    
    -- Logro 'Salvador del Wipe' (Gamification hook)
    if S.Achievements and #self.Data.Deaths == 0 then
        -- S.Achievements:Unlock(X) -- Si existiera logro de 'Flawless Victory'
    end
end

-- Registrar en ModuleConfig
if S.ModuleConfig then
    S.ModuleConfig:RegisterModule("PerformanceAuditor", {
        name = "Performance Auditor",
        description = "Reporte de cortes, dispels y muertes tras el combate",
        category = "raid",
        icon = "Interface\\Icons\\Spell_Holy_Fanaticism",
        options = {}
    })
end
