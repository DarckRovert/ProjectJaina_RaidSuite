--[[
    Sequito - Spy (PvP Intelligence)
    Detección de sigilo, rastreo de enemigos cercanos y alertas.
    
    Funcionalidades:
    - Detecta enemigos cercanos via Combat Log
    - Alerta visual y sonora al detectar stealth
    - Lista de enemigos recientes con clase y última acción
    - Limpieza automática de datos viejos
]]--

local addonName, S = ...
S.Spy = {}
local SP = S.Spy

-- ============================================
-- CONFIGURACIÓN
-- ============================================
local ENEMY_EXPIRE_TIME = 60    -- Segundos antes de limpiar un enemigo
local STEALTH_COOLDOWN = 10     -- Cooldown entre alertas de stealth (evitar spam)
local MAX_ENEMIES = 20          -- Máximo de enemigos rastreados
local ALERT_DURATION = 4.0      -- Duración de alerta visual (segundos)

-- Habilidades de sigilo conocidas
local STEALTH_SPELLS = {
    -- Rogue
    ["Stealth"]     = true, ["Sigilo"]          = true,
    ["Vanish"]      = true, ["Esfumarse"]       = true,
    -- Druid
    ["Prowl"]       = true, ["Acechar"]         = true,
    -- Mage
    ["Invisibility"] = true, ["Invisibilidad"]  = true,
    -- Night Elf (racial)
    ["Shadowmeld"]  = true, ["Fusión de las Sombras"] = true,
}

-- Habilidades que significan "salió del stealth ahora"
local STEALTH_OPENERS = {
    -- Rogue
    ["Cheap Shot"]       = true, ["Golpe bajo"]           = true,
    ["Garrote"]          = true,
    ["Ambush"]           = true, ["Emboscada"]            = true,
    ["Sap"]              = true, ["Golpe incapacitante"]  = true,
    -- Druid
    ["Pounce"]           = true, ["Abalanzarse"]          = true,
    ["Ravage"]           = true, ["Devastar"]             = true,
    ["Shred"]            = true, ["Triturar"]             = true,
}

-- Colores por clase
local CLASS_COLORS = RAID_CLASS_COLORS or {
    WARRIOR     = {r=0.78, g=0.61, b=0.43},
    PALADIN     = {r=0.96, g=0.55, b=0.73},
    HUNTER      = {r=0.67, g=0.83, b=0.45},
    ROGUE       = {r=1.00, g=0.96, b=0.41},
    PRIEST      = {r=1.00, g=1.00, b=1.00},
    DEATHKNIGHT = {r=0.77, g=0.12, b=0.23},
    SHAMAN      = {r=0.00, g=0.44, b=0.87},
    MAGE        = {r=0.25, g=0.78, b=0.92},
    WARLOCK     = {r=0.53, g=0.53, b=0.93},
    DRUID       = {r=1.00, g=0.49, b=0.04},
}

-- ============================================
-- ESTADO INTERNO
-- ============================================
SP.Enemies = {}         -- { [guid] = { name, class, lastSeen, lastAction, hostile } }
SP.LastStealthAlert = 0  -- Timestamp de última alerta de stealth
SP.AlertFrame = nil
SP.ListFrame = nil

-- ============================================
-- INICIALIZACIÓN
-- ============================================
function SP:Initialize()
    if not self:GetOption("enabled") then return end
    
    self:CreateAlertFrame()
    self:CreateListFrame()
    self:RegisterEvents()
    
    print("|cFF00FFFFSequito|r: [Spy] Protocolo de vigilancia activo.")
end

function SP:GetOption(key)
    if S.ModuleConfig then
        return S.ModuleConfig:GetValue("Spy", key)
    end
    return true
end

-- ============================================
-- FRAMES DE UI
-- ============================================

-- Frame de alerta grande (aparece al detectar stealth)
-- Frame de alerta grande (aparece al detectar stealth)
-- ============================================
-- FRAMES DE UI
-- ============================================

-- Legacy: Frame de alerta eliminado en favor de AlertHub
function SP:CreateAlertFrame()
    -- Deprecated
end

-- Frame de lista de enemigos cercanos
function SP:CreateListFrame()
    local f = CreateFrame("Frame", "SequitoSpyList", UIParent)
    f:SetSize(180, 200)
    f:SetPoint("TOPRIGHT", UIParent, "TOPRIGHT", -20, -200)
    f:SetMovable(true)
    f:EnableMouse(true)
    f:RegisterForDrag("LeftButton")
    f:SetScript("OnDragStart", function(frame) frame:StartMoving() end)
    f:SetScript("OnDragStop", function(frame) 
        frame:StopMovingOrSizing() 
        if S.SmartDefaults then
            S.SmartDefaults:SavePosition("Spy", frame)
        end
    end)
    f:SetScript("OnHide", function(frame)
        if S.SmartDefaults then
            S.SmartDefaults:SavePosition("Spy", frame)
        end
    end)
    f:Hide()
    
    -- Inicializar posición guardada
    if S.SmartDefaults then
        S.SmartDefaults:RestorePosition("Spy")
    end
    
    -- Fondo
    f.bg = f:CreateTexture(nil, "BACKGROUND")
    f.bg:SetAllPoints()
    f.bg:SetTexture(0.05, 0.05, 0.08, 0.85)
    
    -- Borde
    f:SetBackdrop({
        edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
        edgeSize = 12,
    })
    f:SetBackdropBorderColor(0.8, 0.2, 0.2, 0.8)
    
    -- Título
    f.title = f:CreateFontString(nil, "OVERLAY")
    f.title:SetFont("Fonts\\FRIZQT__.TTF", 11, "OUTLINE")
    f.title:SetPoint("TOP", f, "TOP", 0, -6)
    f.title:SetTextColor(1, 0.3, 0.3)
    f.title:SetText("☠ Enemigos Cercanos")
    
    -- Botón cerrar
    f.close = CreateFrame("Button", nil, f, "UIPanelCloseButton")
    f.close:SetSize(20, 20)
    f.close:SetPoint("TOPRIGHT", f, "TOPRIGHT", -2, -2)
    
    -- Rows de enemigos (pre-crear 8)
    f.rows = {}
    for i = 1, 8 do
        local row = CreateFrame("Frame", nil, f)
        row:SetSize(160, 18)
        row:SetPoint("TOPLEFT", f, "TOPLEFT", 10, -20 - (i - 1) * 20)
        
        row.icon = row:CreateTexture(nil, "ARTWORK")
        row.icon:SetSize(14, 14)
        row.icon:SetPoint("LEFT", row, "LEFT", 0, 0)
        
        row.name = row:CreateFontString(nil, "OVERLAY")
        row.name:SetFont("Fonts\\FRIZQT__.TTF", 10, "OUTLINE")
        row.name:SetPoint("LEFT", row.icon, "RIGHT", 4, 0)
        row.name:SetJustifyH("LEFT")
        row.name:SetWidth(100)
        
        row.time = row:CreateFontString(nil, "OVERLAY")
        row.time:SetFont("Fonts\\FRIZQT__.TTF", 9, "OUTLINE")
        row.time:SetPoint("RIGHT", row, "RIGHT", 0, 0)
        row.time:SetTextColor(0.6, 0.6, 0.6)
        
        row:Hide()
        f.rows[i] = row
    end
    
    -- Texto de "sin enemigos"
    f.emptyText = f:CreateFontString(nil, "OVERLAY")
    f.emptyText:SetFont("Fonts\\FRIZQT__.TTF", 10, "OUTLINE")
    f.emptyText:SetPoint("CENTER", f, "CENTER", 0, -10)
    f.emptyText:SetTextColor(0.5, 0.5, 0.5)
    f.emptyText:SetText("Sin enemigos detectados")
    
    -- Actualizar cada 2 segundos
    f:SetScript("OnUpdate", function(frame, elapsed)
        frame.timer = (frame.timer or 0) + elapsed
        if frame.timer >= 2 then
            frame.timer = 0
            SP:UpdateList()
        end
    end)
    
    self.ListFrame = f
    self.frame = f -- Alias para SmartDefaults
end

-- ============================================
-- EVENTOS
-- ============================================
function SP:RegisterEvents()
    local f = CreateFrame("Frame")
    f:RegisterEvent("COMBAT_LOG_EVENT_UNFILTERED")
    f:RegisterEvent("UPDATE_MOUSEOVER_UNIT")
    f:RegisterEvent("PLAYER_TARGET_CHANGED")
    
    f:SetScript("OnEvent", function(self, event, ...)
        if event == "COMBAT_LOG_EVENT_UNFILTERED" then
            SP:OnCombatLog(...)
        elseif event == "UPDATE_MOUSEOVER_UNIT" then
            SP:CheckMouseover()
        elseif event == "PLAYER_TARGET_CHANGED" then
            SP:CheckTarget()
        end
    end)
end

-- ============================================
-- DETECCIÓN DE ENEMIGOS
-- ============================================

function SP:OnCombatLog(timestamp, subEvent, sourceGUID, sourceName, sourceFlags, destGUID, destName, destFlags, spellId, spellName)
    if not sourceName and not destName then return end
    
    -- Detectar si la fuente es un jugador enemigo
    if sourceGUID and sourceName and self:IsEnemyPlayer(sourceFlags) then
        local class = self:GetClassFromGUID(sourceGUID)
        
        -- Sanear nombre de acción (evitar números de SWING_DAMAGE)
        local action = spellName
        if subEvent:find("SWING") then
            action = "Melee"
        elseif subEvent:find("ENVIRONMENTAL") then
            action = "Environment"
        end
        
        self:TrackEnemy(sourceGUID, sourceName, class, action or subEvent)
        
        -- Detectar opener de stealth (el rogue/druid acaba de salir del stealth)
        if STEALTH_OPENERS[spellName] then
            self:OnStealthDetected(sourceName, class, spellName)
        end
    end
    
    -- Detectar si alguien entró en stealth
    if subEvent == "SPELL_AURA_APPLIED" and destGUID and destName then
        if self:IsEnemyPlayer(destFlags) and STEALTH_SPELLS[spellName] then
            local class = self:GetClassFromGUID(destGUID)
            self:TrackEnemy(destGUID, destName, class, "→ " .. (spellName or "Stealth"))
            self:OnStealthDetected(destName, class, spellName)
        end
    end
    
    -- Detectar enemigos como objetivo de habilidades aliadas
    if destGUID and destName and self:IsEnemyPlayer(destFlags) then
        local class = self:GetClassFromGUID(destGUID)
        self:TrackEnemy(destGUID, destName, class, nil) -- no actualizar acción
    end
end

-- Verificar si un bitfield de flags indica jugador enemigo
function SP:IsEnemyPlayer(flags)
    if not flags then return false end
    -- COMBATLOG_OBJECT_TYPE_PLAYER = 0x400
    -- COMBATLOG_OBJECT_REACTION_HOSTILE = 0x40
    local isPlayer = bit.band(flags, 0x400) > 0
    local isHostile = bit.band(flags, 0x40) > 0
    return isPlayer and isHostile
end

-- Intentar obtener clase desde GUID (formato: 0xTTTTCCNNNNNNNNNN)
function SP:GetClassFromGUID(guid)
    if not guid then return nil end
    
    -- Intentar obtener info del cache del cliente
    local _, classFilename = GetPlayerInfoByGUID(guid)
    if classFilename and classFilename ~= "" then
        return classFilename
    end
    
    return nil
end

-- Añadir/actualizar enemigo en la lista
function SP:TrackEnemy(guid, name, class, action)
    if not guid or not name then return end
    
    -- Intentar obtener clase si no la tenemos
    if not class and UnitExists("target") and UnitGUID("target") == guid then
        local _, c = UnitClass("target")
        class = c
    end
    
    local existing = self.Enemies[guid]
    if existing then
        existing.lastSeen = GetTime()
        if action then existing.lastAction = action end
        if class then existing.class = class end
    else
        -- Limpiar si hay demasiados
        self:CleanupEnemies()
        
        self.Enemies[guid] = {
            name = name,
            class = class,
            lastSeen = GetTime(),
            lastAction = action or "Detected",
        }
    end
    
    -- Mostrar lista si hay enemigos
    if self.ListFrame and not self.ListFrame:IsShown() then
        self.ListFrame:Show()
    end
end

-- ============================================
-- ALERTAS DE STEALTH
-- ============================================
-- ============================================
-- ALERTAS DE STEALTH
-- ============================================
function SP:OnStealthDetected(name, class, spellName)
    if not self:GetOption("stealthAlert") then return end
    
    local now = GetTime()
    if (now - self.LastStealthAlert) < STEALTH_COOLDOWN then return end
    self.LastStealthAlert = now
    
    -- Icono según clase
    local icon = "Interface\\Icons\\Ability_Rogue_Stealth"
    if class == "ROGUE" then
        icon = "Interface\\Icons\\Ability_Rogue_Stealth"
    elseif class == "DRUID" then
        icon = "Interface\\Icons\\Ability_Druid_Prowl"
    elseif class == "MAGE" then
        icon = "Interface\\Icons\\Ability_Mage_Invisibility"
    end
    
    -- Alerta visual via AlertHub
    local displayName = name or "Desconocido"
    local msg = "¡SIGILO DETECTADO!\n" .. displayName .. " (" .. (spellName or "Stealth") .. ")"
    
    -- Usar color de clase para el override
    local classColor = CLASS_COLORS[class] or {1, 0.3, 0.3}
    local colorOverride = {classColor[1], classColor[2], classColor[3]}
    -- O forzar rojo puro para máxima alerta? AlertHub CRITICAL ya es rojo.
    -- Pero Spy usa texto rojo y subtexto clase.
    -- AlertHub tiene un solo texto grande. 
    -- Mejor usar ROJO ALERTA.
    
    S:ShowAlert(msg, "CRITICAL", icon) -- CRITICAL flashes screen and allows sound override if config
    
    -- Print
    print("|cFFFF3333[Spy]|r ¡" .. (name or "Enemigo") .. " detectado en sigilo! (" .. (spellName or "Stealth") .. ")")
end

-- ============================================
-- ACTUALIZACIÓN DE LISTA
-- ============================================
function SP:UpdateList()
    if not self.ListFrame then return end
    
    -- Limpiar enemigos viejos
    self:CleanupEnemies()
    
    -- Convertir a lista ordenada (más reciente primero)
    local sorted = {}
    for guid, data in pairs(self.Enemies) do
        table.insert(sorted, { guid = guid, data = data })
    end
    table.sort(sorted, function(a, b)
        return a.data.lastSeen > b.data.lastSeen
    end)
    
    -- Actualizar rows
    local now = GetTime()
    local hasEnemies = false
    
    for i = 1, 8 do
        local row = self.ListFrame.rows[i]
        if sorted[i] then
            hasEnemies = true
            local enemy = sorted[i].data
            local elapsed = math.floor(now - enemy.lastSeen)
            local classColor = CLASS_COLORS[enemy.class] or {0.8, 0.8, 0.8}
            
            -- Icono de clase
            if enemy.class then
                row.icon:SetTexture("Interface\\Glues\\CharacterCreate\\UI-CharacterCreate-Classes")
                local coords = CLASS_ICON_TCOORDS and CLASS_ICON_TCOORDS[enemy.class]
                if coords then
                    row.icon:SetTexCoord(unpack(coords))
                else
                    row.icon:SetTexCoord(0, 0.25, 0, 0.25) -- Default
                end
            else
                row.icon:SetTexture("Interface\\Icons\\INV_Misc_QuestionMark")
                row.icon:SetTexCoord(0, 1, 0, 1)
            end
            
            -- Nombre coloreado
            row.name:SetText(enemy.name)
            row.name:SetTextColor(classColor[1], classColor[2], classColor[3])
            
            -- Tiempo
            if elapsed < 5 then
                row.time:SetText("ahora")
                row.time:SetTextColor(1, 0.3, 0.3)
            elseif elapsed < 60 then
                row.time:SetText(elapsed .. "s")
                row.time:SetTextColor(0.6, 0.6, 0.6)
            else
                row.time:SetText(">1m")
                row.time:SetTextColor(0.4, 0.4, 0.4)
            end
            
            row:Show()
        else
            row:Hide()
        end
    end
    
    -- Mostrar/ocultar texto vacío
    if self.ListFrame.emptyText then
        if hasEnemies then
            self.ListFrame.emptyText:Hide()
        else
            self.ListFrame.emptyText:Show()
        end
    end
    
    -- Ocultar lista si no hay enemigos
    if not hasEnemies and self.ListFrame:IsShown() then
        self.ListFrame:Hide()
    end
end

-- ============================================
-- DETECCIÓN POR MOUSEOVER/TARGET
-- ============================================
function SP:CheckMouseover()
    if not UnitExists("mouseover") then return end
    if not UnitIsPlayer("mouseover") then return end
    if not UnitIsEnemy("player", "mouseover") then return end
    
    local guid = UnitGUID("mouseover")
    local name = UnitName("mouseover")
    local _, class = UnitClass("mouseover")
    
    self:TrackEnemy(guid, name, class, "Mouseover")
end

function SP:CheckTarget()
    if not UnitExists("target") then return end
    if not UnitIsPlayer("target") then return end
    if not UnitIsEnemy("player", "target") then return end
    
    local guid = UnitGUID("target")
    local name = UnitName("target")
    local _, class = UnitClass("target")
    
    self:TrackEnemy(guid, name, class, "Targeted")
    
    -- Actualizar clase de enemigos existentes que teníamos sin clase
    if guid and class and self.Enemies[guid] then
        self.Enemies[guid].class = class
    end
end

-- ============================================
-- LIMPIEZA
-- ============================================
function SP:CleanupEnemies(force)
    if force then
        self.Enemies = {}
        if self.ListFrame and self.ListFrame:IsShown() then
            self:UpdateList()
        end
        return
    end

    local now = GetTime()
    local count = 0
    
    for guid, data in pairs(self.Enemies) do
        if (now - data.lastSeen) > ENEMY_EXPIRE_TIME then
            self.Enemies[guid] = nil
        else
            count = count + 1
        end
    end
    
    -- Si hay demasiados, eliminar los más viejos
    if count > MAX_ENEMIES then
        local sorted = {}
        for guid, data in pairs(self.Enemies) do
            table.insert(sorted, { guid = guid, time = data.lastSeen })
        end
        table.sort(sorted, function(a, b) return a.time < b.time end)
        
        local toRemove = count - MAX_ENEMIES
        for i = 1, toRemove do
            self.Enemies[sorted[i].guid] = nil
        end
    end
end

-- ============================================
-- API PÚBLICA
-- ============================================

-- Obtener número de enemigos cercanos
function SP:GetEnemyCount()
    local count = 0
    local now = GetTime()
    for _, data in pairs(self.Enemies) do
        if (now - data.lastSeen) <= ENEMY_EXPIRE_TIME then
            count = count + 1
        end
    end
    return count
end

-- Obtener lista de enemigos
function SP:GetEnemies()
    return self.Enemies
end

-- Toggle la lista manualmente
function SP:Toggle()
    if self.ListFrame then
        if self.ListFrame:IsShown() then
            self.ListFrame:Hide()
        else
            self:UpdateList()
            self.ListFrame:Show()
        end
    end
end

-- ============================================
-- REGISTRO DE MÓDULO
-- ============================================
if S.ModuleConfig then
    S.ModuleConfig:RegisterModule("Spy", {
        name = "Spy (PvP)",
        description = "Alertas de sigilo y detección de enemigos.",
        category = "pvp",
        icon = "Interface\\Icons\\Ability_Rogue_Stealth",
        options = {
            {key = "enabled", type = "checkbox", label = "Habilitar Spy", default = true},
            {key = "stealthAlert", type = "checkbox", label = "Alerta de Sigilo", default = true},
            {key = "soundAlert", type = "checkbox", label = "Sonido de Alerta", default = true},
        }
    })
end
