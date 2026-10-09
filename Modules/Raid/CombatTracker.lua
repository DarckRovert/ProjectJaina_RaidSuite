--[[
    Jaina - CombatTracker.lua
    Seguimiento de Combate en Tiempo Real
    Rastrea DPS, HPS, muertes y estadisticas de combate
]]--

local addonName, Jaina = ...
Jaina.CombatTracker = Jaina.CombatTracker or {}

local CombatTracker = Jaina.CombatTracker

-- Helper para obtener configuración
function CombatTracker:GetOption(key)
    if Jaina.ModuleConfig then
        return Jaina.ModuleConfig:GetValue("CombatTracker", key)
    end
    return true
end

-- Configuracion
local CONFIG = {
    updateInterval = 0.5,
    combatTimeout = 3.0, -- Segundos sin dano para considerar fin de combate
    maxHistory = 10, -- Maximo de combates guardados
}

-- Estado del combate
local combatData = {
    inCombat = false,
    startTime = 0,
    endTime = 0,
    duration = 0,
    
    -- Estadisticas del jugador
    player = {
        damage = 0,
        healing = 0,
        overhealing = 0,
        damageTaken = 0,
        deaths = 0,
        kills = 0,
        interrupts = 0,
        dispels = 0,
    },
    
    -- Estadisticas de la raid
    raid = {
        totalDamage = 0,
        totalHealing = 0,
        deaths = {},
        topDPS = {},
        topHPS = {},
    },
    
    -- Habilidades usadas
    abilities = {},
    
    -- Objetivos danados
    targets = {},
}

-- Historial de combates
local combatHistory = {}

-- Frame de eventos
local eventFrame = nil
local lastUpdate = 0
local lastDamageTime = 0

-- Parsear eventos de combate (Firma correcta 3.3.5a)
local function ParseCombatEvent(timestamp, event, sourceGUID, sourceName, sourceFlags, destGUID, destName, destFlags, ...)
    if not combatData.inCombat then return end
    
    local playerGUID = UnitGUID("player")
    local isPlayer = (sourceGUID == playerGUID)
    local isPlayerTarget = (destGUID == playerGUID)
    
    -- Eventos de dano
    if event == "SWING_DAMAGE" or event == "RANGE_DAMAGE" or event == "SPELL_DAMAGE" or event == "SPELL_PERIODIC_DAMAGE" or event == "DAMAGE_SHIELD" or event == "ENVIRONMENTAL_DAMAGE" then
        local amount, overkill, school, resisted, blocked, absorbed, critical, glancing, crushing
        local spellName -- Para registrar la habilidad de origen

        if event == "SWING_DAMAGE" then
            amount, overkill, school, resisted, blocked, absorbed, critical, glancing, crushing = ...
            spellName = "Melee"
        elseif event == "ENVIRONMENTAL_DAMAGE" then
            local environmentalType
            environmentalType, amount, overkill, school, resisted, blocked, absorbed, critical, glancing, crushing = ...
            spellName = environmentalType -- e.g., "FALLING", "LAVA"
        else
            -- SPELL_DAMAGE, SPELL_PERIODIC_DAMAGE, RANGE_DAMAGE, DAMAGE_SHIELD
            local spellId, sName, spellSchool
            spellId, sName, spellSchool, amount, overkill, school, resisted, blocked, absorbed, critical, glancing, crushing = ...
            spellName = sName
        end
        
        -- Asegurar valor numerico
        amount = amount or 0

        -- Registrar daño realizado (Outgoing)
        if isPlayer and spellName then
            -- Para DAMAGE_SHIELD, source es el Player (reflejando daño)
            -- Para ENVIRONMENTAL_DAMAGE, source es nil o ambiente (no Player)
            
            if not combatData.abilities[spellName] then
                combatData.abilities[spellName] = {damage = 0, hits = 0, crits = 0}
            end
            combatData.abilities[spellName].damage = combatData.abilities[spellName].damage + amount
            combatData.abilities[spellName].hits = combatData.abilities[spellName].hits + 1
            if critical then
                combatData.abilities[spellName].crits = combatData.abilities[spellName].crits + 1
            end
            
            combatData.player.damage = combatData.player.damage + amount
            lastDamageTime = GetTime()
            
            -- Registrar objetivo
            if destName then
                if not combatData.targets[destName] then
                    combatData.targets[destName] = 0
                end
                combatData.targets[destName] = combatData.targets[destName] + amount
            end
        end
        
        -- Registrar daño recibido (Incoming)
        if isPlayerTarget then
            combatData.player.damageTaken = combatData.player.damageTaken + amount
        end
        
        -- Dano total de raid
        if bit.band(sourceFlags, COMBATLOG_OBJECT_AFFILIATION_RAID) > 0 or
           bit.band(sourceFlags, COMBATLOG_OBJECT_AFFILIATION_PARTY) > 0 then
            combatData.raid.totalDamage = combatData.raid.totalDamage + amount
        end
    end
    
    -- Eventos de curacion
    if event == "SPELL_HEAL" or event == "SPELL_PERIODIC_HEAL" then
        local spellId, spellName, spellSchool, amount, overhealing, absorbed, critical = ...
        amount = amount or 0
        overhealing = overhealing or 0
        
        if isPlayer then
            combatData.player.healing = combatData.player.healing + amount
            combatData.player.overhealing = combatData.player.overhealing + overhealing
            
            -- Registrar habilidad de curacion
            if spellName then
                local abilityName = spellName.." (Heal)"
                if not combatData.abilities[abilityName] then
                    combatData.abilities[abilityName] = {healing = 0, hits = 0, crits = 0}
                end
                combatData.abilities[abilityName].healing = (combatData.abilities[abilityName].healing or 0) + amount
                combatData.abilities[abilityName].hits = combatData.abilities[abilityName].hits + 1
                if critical then
                    combatData.abilities[abilityName].crits = combatData.abilities[abilityName].crits + 1
                end
            end
        end
        
        -- Curacion total de raid
        if bit.band(sourceFlags, COMBATLOG_OBJECT_AFFILIATION_RAID) > 0 or
           bit.band(sourceFlags, COMBATLOG_OBJECT_AFFILIATION_PARTY) > 0 then
            combatData.raid.totalHealing = combatData.raid.totalHealing + amount
        end
    end
    
    -- Muertes
    if event == "UNIT_DIED" then
        if isPlayerTarget then
            combatData.player.deaths = combatData.player.deaths + 1
        end
        
        -- Registrar muerte en raid
        if bit.band(destFlags, COMBATLOG_OBJECT_AFFILIATION_RAID) > 0 or
           bit.band(destFlags, COMBATLOG_OBJECT_AFFILIATION_PARTY) > 0 then
            table.insert(combatData.raid.deaths, {
                name = destName,
                time = GetTime() - combatData.startTime,
            })
        end
    end
    
    -- Kills
    if event == "PARTY_KILL" then
        if isPlayer then
            combatData.player.kills = combatData.player.kills + 1
        end
    end
    
    -- Interrupts
    if event == "SPELL_INTERRUPT" then
        if isPlayer then
            combatData.player.interrupts = combatData.player.interrupts + 1
        end
    end
    
    -- Dispels
    if event == "SPELL_DISPEL" or event == "SPELL_STOLEN" then
        if isPlayer then
            combatData.player.dispels = combatData.player.dispels + 1
        end
    end
end

-- Iniciar combate
local function StartCombat()
    if combatData.inCombat then return end
    
    combatData.inCombat = true
    combatData.startTime = GetTime()
    combatData.endTime = 0
    combatData.duration = 0
    
    -- Resetear estadisticas
    combatData.player = {
        damage = 0,
        healing = 0,
        overhealing = 0,
        damageTaken = 0,
        deaths = 0,
        kills = 0,
        interrupts = 0,
        dispels = 0,
    }
    
    combatData.raid = {
        totalDamage = 0,
        totalHealing = 0,
        deaths = {},
        topDPS = {},
        topHPS = {},
    }
    
    combatData.abilities = {}
    combatData.targets = {}
    
    lastDamageTime = GetTime()
    
    Jaina:Print("|cff00ff00Combate iniciado!|r")
end

-- Finalizar combate
local function EndCombat()
    if not combatData.inCombat then return end
    
    combatData.inCombat = false
    combatData.endTime = GetTime()
    combatData.duration = combatData.endTime - combatData.startTime
    
    -- Guardar en historial
    local summary = CombatTracker:GetSummary()
    table.insert(combatHistory, 1, summary)
    
    -- Limitar historial respetando la opción configurada por el usuario (Slider en ModuleConfig)
    local maxHistory = tonumber(CombatTracker:GetOption("maxHistory")) or CONFIG.maxHistory or 10
    while #combatHistory > maxHistory do
        table.remove(combatHistory)
    end
    
    -- Mostrar resumen en chat
    CombatTracker:PrintSummary()
end

-- Obtener DPS actual
function CombatTracker:GetDPS()
    if not combatData.inCombat then
        if combatData.duration > 0 then
            return combatData.player.damage / combatData.duration
        end
        return 0
    end
    
    local elapsed = GetTime() - combatData.startTime
    if elapsed > 0 then
        return combatData.player.damage / elapsed
    end
    return 0
end

-- Obtener HPS actual
function CombatTracker:GetHPS()
    if not combatData.inCombat then
        if combatData.duration > 0 then
            return combatData.player.healing / combatData.duration
        end
        return 0
    end
    
    local elapsed = GetTime() - combatData.startTime
    if elapsed > 0 then
        return combatData.player.healing / elapsed
    end
    return 0
end

-- Obtener resumen del combate
function CombatTracker:GetSummary()
    local duration = combatData.duration
    if combatData.inCombat then
        duration = GetTime() - combatData.startTime
    end
    
    return {
        duration = duration,
        damage = combatData.player.damage,
        healing = combatData.player.healing,
        dps = duration > 0 and (combatData.player.damage / duration) or 0,
        hps = duration > 0 and (combatData.player.healing / duration) or 0,
        damageTaken = combatData.player.damageTaken,
        deaths = combatData.player.deaths,
        kills = combatData.player.kills,
        interrupts = combatData.player.interrupts,
        dispels = combatData.player.dispels,
        raidDamage = combatData.raid.totalDamage,
        raidHealing = combatData.raid.totalHealing,
        raidDeaths = #combatData.raid.deaths,
        topAbility = CombatTracker:GetTopAbility(),
        timestamp = time(),
    }
end

-- Obtener habilidad con mas dano
function CombatTracker:GetTopAbility()
    local topName = nil
    local topDamage = 0
    
    for name, data in pairs(combatData.abilities) do
        local dmg = data.damage or 0
        if dmg > topDamage then
            topDamage = dmg
            topName = name
        end
    end
    
    return topName, topDamage
end

-- Formatear numero grande
local function FormatNumber(num)
    if num >= 1000000 then
        return string.format("%.1fM", num / 1000000)
    elseif num >= 1000 then
        return string.format("%.1fK", num / 1000)
    end
    return tostring(math.floor(num))
end

-- Formatear tiempo
local function FormatTime(seconds)
    local mins = math.floor(seconds / 60)
    local secs = math.floor(seconds % 60)
    return string.format("%d:%02d", mins, secs)
end

-- Imprimir resumen del combate
function CombatTracker:PrintSummary()
    -- Conexión correcta con ModuleConfig (eliminación de dependencia nula a Jaina.db)
    if not self:GetOption("showSummary") then return end
    
    local summary = self:GetSummary()
    if not summary or (summary.duration and summary.duration < 1) then return end
    
    local chatFrame = DEFAULT_CHAT_FRAME or ChatFrame1
    if not chatFrame then return end
    
    chatFrame:AddMessage("|cFFD4AF37[Project Jaina]|r |cFF00CCFFResumen de Combate|r |cFF888888(" .. FormatTime(summary.duration) .. ")|r")
    chatFrame:AddMessage(string.format("  Daño: |cFFFF6600%s|r |cFF888888(%.1f DPS)|r | Recibido: |cFFFF3333%s|r", 
        FormatNumber(summary.damage), summary.dps, FormatNumber(summary.damageTaken)))
    
    if summary.healing > 0 then
        chatFrame:AddMessage(string.format("  Sanación: |cFF00FF00%s|r |cFF888888(%.1f HPS)|r", 
            FormatNumber(summary.healing), summary.hps))
    end
    
    local extras = {}
    if summary.kills > 0 then table.insert(extras, string.format("Bajas: |cFF00FF00%d|r", summary.kills)) end
    if summary.interrupts > 0 then table.insert(extras, string.format("Cortes: |cFF00FFFF%d|r", summary.interrupts)) end
    if summary.dispels > 0 then table.insert(extras, string.format("Disipaciones: |cFFFF00FF%d|r", summary.dispels)) end
    if #extras > 0 then
        chatFrame:AddMessage("  " .. table.concat(extras, " | "))
    end
    
    if summary.topAbility then
        local _, topDmg = self:GetTopAbility()
        chatFrame:AddMessage(string.format("  Habilidad Clave: |cFFFFFF00%s|r |cFF888888(%s)|r", 
            summary.topAbility, FormatNumber(topDmg)))
    end
end

-- Obtener datos en tiempo real para la UI
function CombatTracker:GetRealtimeData()
    return {
        inCombat = combatData.inCombat,
        duration = combatData.inCombat and (GetTime() - combatData.startTime) or combatData.duration,
        dps = self:GetDPS(),
        hps = self:GetHPS(),
        damage = combatData.player.damage,
        healing = combatData.player.healing,
        damageTaken = combatData.player.damageTaken,
    }
end

-- Obtener historial
function CombatTracker:GetHistory()
    return combatHistory
end

-- Limpiar historial
function CombatTracker:ClearHistory()
    combatHistory = {}
    Jaina:Print("Historial de combate limpiado.")
end

-- Reset manual
function CombatTracker:Reset()
    if combatData.inCombat then
        EndCombat()
    end
    
    combatData.player = {
        damage = 0,
        healing = 0,
        overhealing = 0,
        damageTaken = 0,
        deaths = 0,
        kills = 0,
        interrupts = 0,
        dispels = 0,
    }
    
    combatData.abilities = {}
    combatData.targets = {}
    
    Jaina:Print("Estadisticas de combate reseteadas.")
end

function CombatTracker:Initialize()
    if not self:GetOption("enabled") then
        return
    end
    
    -- Crear frame de eventos
    eventFrame = CreateFrame("Frame")
    
    -- Registrar eventos
    eventFrame:RegisterEvent("PLAYER_REGEN_DISABLED") -- Entrar en combate
    eventFrame:RegisterEvent("PLAYER_REGEN_ENABLED")  -- Salir de combate
    
    eventFrame:SetScript("OnEvent", function(self, event, ...)
        if event == "PLAYER_REGEN_DISABLED" then
            StartCombat()
            -- START OPTIMIZATION: Only run OnUpdate during combat
            self:SetScript("OnUpdate", function(self, elapsed)
                lastUpdate = lastUpdate + elapsed
                if lastUpdate >= CONFIG.updateInterval then
                    lastUpdate = 0
                end
            end)
        elseif event == "PLAYER_REGEN_ENABLED" then
            local delayFunc = function()
                EndCombat()
                if eventFrame then eventFrame:SetScript("OnUpdate", nil) end
            end
            
            if C_Timer and C_Timer.After then
                C_Timer.After(0.5, delayFunc)
            else
                delayFunc()
            end
        end
    end)

    if Jaina.CLEU and Jaina.CLEU.Register then
        local subEvents = {
            "SWING_DAMAGE", "RANGE_DAMAGE", "SPELL_DAMAGE", "SPELL_PERIODIC_DAMAGE",
            "DAMAGE_SHIELD", "ENVIRONMENTAL_DAMAGE", "SPELL_HEAL", "SPELL_PERIODIC_HEAL",
            "SPELL_INTERRUPT", "SPELL_DISPEL", "UNIT_DIED"
        }
        for _, subEvent in ipairs(subEvents) do
            Jaina.CLEU:Register(subEvent, function(...)
                ParseCombatEvent(...)
            end)
        end
    else
        eventFrame:RegisterEvent("COMBAT_LOG_EVENT_UNFILTERED")
        eventFrame:HookScript("OnEvent", function(self, event, ...)
            if event == "COMBAT_LOG_EVENT_UNFILTERED" then
                ParseCombatEvent(...)
            end
        end)
    end
    
    Jaina:Print("CombatTracker cargado (Optimizado).")
end

-- Registrar en Jaina
Jaina.CombatTracker = CombatTracker

-- Registrar módulo en ModuleConfig
if Jaina.ModuleConfig then
    Jaina.ModuleConfig:RegisterModule("CombatTracker", {
        name = "Combat Tracker",
        description = "Rastrea DPS, HPS y estadísticas de combate en tiempo real",
        category = "utility",
        icon = "Interface\\Icons\\Ability_DualWield",
        options = {
            {key = "enabled", type = "checkbox", label = "Habilitar Combat Tracker", default = true},
            {key = "showSummary", type = "checkbox", label = "Mostrar resumen al finalizar combate", default = true},
            {key = "maxHistory", type = "slider", label = "Máximo de combates en historial", min = 5, max = 20, step = 1, default = 10},
        }
    })
end

