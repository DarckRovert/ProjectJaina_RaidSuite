--[[
    Jaina - Soul Engine (Matemáticas Avanzadas)
    Motor de predicción para Time-To-Die (TTD) y Snapshots de daño.
    
    TTD usa regresión lineal sobre historial de HP reciente.
    Snapshot captura stats del jugador para comparación.
]]--

local addonName, S = ...
S.SoulEngine = {}
local SE = S.SoulEngine

-- ============================================
-- CONFIGURACIÓN
-- ============================================
local TTD_HISTORY_SIZE = 20      -- Muestras de HP a guardar
local TTD_SAMPLE_INTERVAL = 0.3  -- Segundos entre muestras
local TTD_MAX_VALUE = 999        -- Máximo TTD reportado
local SNAPSHOT_INTERVAL = 1.0    -- Intervalo de actualización de snapshot

-- ============================================
-- ESTADO INTERNO
-- ============================================
SE.HealthHistory = {}      -- { [guid] = { {time, hp}, {time, hp}, ... } }
SE.CachedTTD = {}          -- { [guid] = seconds }
SE.LastSnapshot = nil       -- Último snapshot de stats
SE.SampleTimer = 0
SE.SnapshotTimer = 0
SE.InCombat = false

-- ============================================
-- INICIALIZACIÓN
-- ============================================
function SE:Initialize()
    if not self:GetOption("enabled") then return end
    
    self:RegisterEvents()
    
    -- print("|cFF00FFFFJaina|r: [SoulEngine] Motor matemático iniciado.")
end

function SE:GetOption(key)
    if S.ModuleConfig then
        local val = S.ModuleConfig:GetValue("SoulEngine", key)
        if val ~= nil then return val end
    end
    return true
end

-- ============================================
-- EVENTOS
-- ============================================
function SE:RegisterEvents()
    local f = CreateFrame("Frame")
    f:RegisterEvent("PLAYER_REGEN_DISABLED")
    f:RegisterEvent("PLAYER_REGEN_ENABLED")
    
    f:SetScript("OnEvent", function(self, event)
        if event == "PLAYER_REGEN_DISABLED" then
            SE.InCombat = true
            SE:StartTracking()
        elseif event == "PLAYER_REGEN_ENABLED" then
            SE.InCombat = false
            SE:StopTracking()
        end
    end)
    
    self.EventFrame = f
end

-- ============================================
-- TRACKING LOOP (OnUpdate durante combate)
-- ============================================
function SE:StartTracking()
    -- Limpiar historial al entrar en combate
    self.HealthHistory = {}
    self.CachedTTD = {}
    
    self.EventFrame:SetScript("OnUpdate", function(frame, elapsed)
        SE.SampleTimer = SE.SampleTimer + elapsed
        SE.SnapshotTimer = SE.SnapshotTimer + elapsed
        
        -- Muestrear HP del target
        if SE.SampleTimer >= TTD_SAMPLE_INTERVAL then
            SE.SampleTimer = 0
            SE:SampleHealth("target")
        end
        
        -- Actualizar snapshot de stats
        if SE.SnapshotTimer >= SNAPSHOT_INTERVAL then
            SE.SnapshotTimer = 0
            if SE:GetOption("snapshotEnabled") then
                SE:UpdateSnapshot()
            end
        end
    end)
end

function SE:StopTracking()
    if self.EventFrame then
        self.EventFrame:SetScript("OnUpdate", nil)
    end
    self.SampleTimer = 0
    self.SnapshotTimer = 0
end

-- ============================================
-- TTD: TIME TO DIE
-- ============================================

-- Muestrear HP de una unidad
function SE:SampleHealth(unit)
    if not self:GetOption("ttdEnabled") then return end
    if not UnitExists(unit) then return end
    if UnitIsDead(unit) then return end
    if not UnitCanAttack("player", unit) then return end
    
    local guid = UnitGUID(unit)
    if not guid then return end
    
    local hp = UnitHealth(unit)
    local maxHp = UnitHealthMax(unit)
    if maxHp == 0 then return end
    
    local now = GetTime()
    
    -- Inicializar historial para esta unidad
    if not self.HealthHistory[guid] then
        self.HealthHistory[guid] = {}
    end
    
    local history = self.HealthHistory[guid]
    
    -- Añadir muestra
    table.insert(history, { time = now, hp = hp })
    
    -- Limitar tamaño del historial (FIFO)
    while #history > TTD_HISTORY_SIZE do
        table.remove(history, 1)
    end
    
    -- Calcular TTD con regresión lineal
    self.CachedTTD[guid] = self:CalculateTTD(history)
end

-- Regresión lineal para predecir Time-To-Die
-- Calcula la pendiente de HP/segundo y extrapola hasta HP=0
function SE:CalculateTTD(history)
    local n = #history
    if n < 3 then return TTD_MAX_VALUE end -- Necesitamos mínimo 3 muestras
    
    -- Variables para regresión: y = a + bx
    -- x = tiempo, y = HP
    local sumX, sumY, sumXY, sumX2 = 0, 0, 0, 0
    local baseTime = history[1].time -- Normalizar tiempo para evitar overflow
    
    for i = 1, n do
        local x = history[i].time - baseTime
        local y = history[i].hp
        sumX = sumX + x
        sumY = sumY + y
        sumXY = sumXY + (x * y)
        sumX2 = sumX2 + (x * x)
    end
    
    local denominator = (n * sumX2) - (sumX * sumX)
    if denominator == 0 then return TTD_MAX_VALUE end
    
    -- Pendiente (HP por segundo)
    local slope = ((n * sumXY) - (sumX * sumY)) / denominator
    
    -- Si la pendiente es >= 0, el target NO está perdiendo HP
    if slope >= 0 then return TTD_MAX_VALUE end
    
    -- Intercepto
    local intercept = (sumY - slope * sumX) / n
    
    -- HP actual (última muestra)
    local currentHP = history[n].hp
    local currentTime = history[n].time - baseTime
    
    -- Tiempo hasta HP = 0: resolver 0 = intercept + slope * t
    -- t = -intercept / slope
    -- TTD = t - currentTime
    local timeToZero = -intercept / slope
    local ttd = timeToZero - currentTime
    
    -- Clamp
    if ttd < 0 then ttd = 0 end
    if ttd > TTD_MAX_VALUE then ttd = TTD_MAX_VALUE end
    
    return math.floor(ttd)
end

-- API Pública: Obtener TTD para una unidad
function SE:GetTTD(unit)
    if not unit then unit = "target" end
    if not UnitExists(unit) then return TTD_MAX_VALUE end
    if UnitIsDead(unit) then return 0 end
    
    local guid = UnitGUID(unit)
    if guid and self.CachedTTD[guid] then
        return self.CachedTTD[guid]
    end
    
    return TTD_MAX_VALUE
end

-- API Pública: Obtener TTD formateado como string
function SE:GetTTDString(unit)
    local ttd = self:GetTTD(unit)
    if ttd >= TTD_MAX_VALUE then return "∞" end
    if ttd == 0 then return "DEAD" end
    
    if ttd >= 60 then
        return string.format("%d:%02d", math.floor(ttd / 60), ttd % 60)
    end
    return string.format("%ds", ttd)
end

-- ============================================
-- SNAPSHOT: ESTADÍSTICAS DEL JUGADOR
-- ============================================

function SE:UpdateSnapshot()
    local _, class = UnitClass("player")
    
    local snapshot = {
        timestamp = GetTime(),
        class = class,
        -- Stats de combate
        spellPower = GetSpellBonusDamage(2) or 0,  -- Shadow school (2) como referencia
        healPower = GetSpellBonusHealing() or 0,
        attackPower = UnitAttackPower("player") or 0,
        -- Ratings
        crit = GetCritChance() or 0,
        spellCrit = GetSpellCritChance(2) or 0,  -- Shadow school
        -- Haste
        haste = GetCombatRatingBonus(20) or 0,  -- CR_HASTE_MELEE = 20
        spellHaste = GetCombatRatingBonus(20) or 0,
        -- Defensivos
        armor = select(2, UnitArmor("player")) or 0,
        dodge = GetDodgeChance() or 0,
        parry = GetParryChance() or 0,
        block = GetBlockChance() or 0,
        -- Recursos
        health = UnitHealth("player"),
        maxHealth = UnitHealthMax("player"),
        mana = UnitPower("player", 0),
        maxMana = UnitPowerMax("player", 0),
    }
    
    -- Calcular stats derivados
    if snapshot.maxHealth > 0 then
        snapshot.healthPct = math.floor((snapshot.health / snapshot.maxHealth) * 100)
    else
        snapshot.healthPct = 100
    end
    
    if snapshot.maxMana > 0 then
        snapshot.manaPct = math.floor((snapshot.mana / snapshot.maxMana) * 100)
    else
        snapshot.manaPct = 100
    end
    
    -- Elegir stat principal según clase
    if class == "WARRIOR" or class == "ROGUE" or class == "DEATHKNIGHT" then
        snapshot.mainStat = snapshot.attackPower
        snapshot.mainStatName = "Attack Power"
    elseif class == "HUNTER" then
        snapshot.mainStat = UnitRangedAttackPower("player") or 0
        snapshot.mainStatName = "Ranged AP"
    else
        snapshot.mainStat = snapshot.spellPower
        snapshot.mainStatName = "Spell Power"
    end
    
    self.LastSnapshot = snapshot
end

-- API Pública: Obtener snapshot actual
function SE:GetSnapshot()
    if self.LastSnapshot then
        return self.LastSnapshot
    end
    -- Fallback si no hay snapshot aún
    self:UpdateSnapshot()
    return self.LastSnapshot or { spellPower = 0, haste = 0, crit = 0 }
end

-- API Pública: Obtener stat específico del snapshot
function SE:GetStat(statName)
    local snap = self:GetSnapshot()
    return snap[statName] or 0
end

-- API Pública: Comparar snapshot actual con uno guardado
function SE:CompareSnapshot(oldSnapshot)
    if not oldSnapshot or not self.LastSnapshot then return nil end
    
    local diff = {}
    for key, newVal in pairs(self.LastSnapshot) do
        if type(newVal) == "number" and oldSnapshot[key] then
            local change = newVal - oldSnapshot[key]
            if change ~= 0 then
                diff[key] = { old = oldSnapshot[key], new = newVal, change = change }
            end
        end
    end
    return diff
end

-- ============================================
-- UTILIDADES
-- ============================================

-- Limpiar historial de unidades que ya no existen
function SE:CleanupHistory()
    local now = GetTime()
    for guid, history in pairs(self.HealthHistory) do
        if #history > 0 then
            local lastSample = history[#history]
            -- Si no hemos muestreado en >10s, limpiar
            if (now - lastSample.time) > 10 then
                self.HealthHistory[guid] = nil
                self.CachedTTD[guid] = nil
            end
        end
    end
end

-- ============================================
-- REGISTRO DE MÓDULO
-- ============================================
if S.ModuleConfig then
    S.ModuleConfig:RegisterModule("SoulEngine", {
        name = "Soul Engine",
        description = "Motor matemático para predicción de muerte (TTD) y rastreo de estadísticas (Snapshot).",
        category = "core",
        icon = "Interface\\Icons\\Spell_Shadow_SoulGem",
        options = {
            {key = "enabled", type = "checkbox", label = "Habilitar Soul Engine", default = true},
            {key = "ttdEnabled", type = "checkbox", label = "Rastrear Time-To-Die", default = true},
            {key = "snapshotEnabled", type = "checkbox", label = "Rastrear Snapshots", default = true}
        }
    })
end
