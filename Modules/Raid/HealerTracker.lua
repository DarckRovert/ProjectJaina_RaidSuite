--[[
    Sequito - HealerTracker.lua
    Monitor de Healers Enemigos
    Version: 7.3.0
    
    Funcionalidades:
    - Trackear mana de healers enemigos
    - Alertar cuando healer enemigo está bajo de mana
    - UI con barra de mana visible para healers marcados
    - Detectar healers automáticamente por clase/spec
]]

local addonName, S = ...
S.HealerTracker = {}
local HT = S.HealerTracker

-- Estado
HT.TrackedHealers = {}  -- {guid = {name, class, mana, maxMana, lastSeen}}
HT.Frame = nil
HT.Rows = {}
HT.IsVisible = false
HT.UpdateInterval = 0.2
HT.TimeSinceLastUpdate = 0

-- Clases que pueden ser healers
local HEALER_CLASSES = {
    ["PRIEST"] = true,
    ["PALADIN"] = true,
    ["SHAMAN"] = true,
    ["DRUID"] = true,
}

-- Spells de healing para detectar healers
local HEALING_SPELLS = {
    -- Priest
    [2050] = "PRIEST",   -- Lesser Heal
    [2054] = "PRIEST",   -- Heal
    [2060] = "PRIEST",   -- Greater Heal
    [596] = "PRIEST",    -- Prayer of Healing
    [139] = "PRIEST",    -- Renew
    [17] = "PRIEST",     -- Power Word: Shield
    [48068] = "PRIEST",  -- Renew (Rank 14)
    [48063] = "PRIEST",  -- Greater Heal (Rank 9)
    [48071] = "PRIEST",  -- Flash Heal (Rank 11)
    [48072] = "PRIEST",  -- Prayer of Healing (Rank 7)
    [33076] = "PRIEST",  -- Prayer of Mending
    [34861] = "PRIEST",  -- Circle of Healing
    [47788] = "PRIEST",  -- Guardian Spirit
    [47540] = "PRIEST",  -- Penance
    
    -- Paladin
    [635] = "PALADIN",   -- Holy Light
    [19750] = "PALADIN", -- Flash of Light
    [48782] = "PALADIN", -- Holy Light (Rank 13)
    [48785] = "PALADIN", -- Flash of Light (Rank 9)
    [53563] = "PALADIN", -- Beacon of Light
    [20473] = "PALADIN", -- Holy Shock
    [31842] = "PALADIN", -- Divine Illumination
    
    -- Shaman
    [331] = "SHAMAN",    -- Healing Wave
    [8004] = "SHAMAN",   -- Lesser Healing Wave
    [1064] = "SHAMAN",   -- Chain Heal
    [49273] = "SHAMAN",  -- Healing Wave (Rank 14)
    [49276] = "SHAMAN",  -- Lesser Healing Wave (Rank 9)
    [55459] = "SHAMAN",  -- Chain Heal (Rank 7)
    [61295] = "SHAMAN",  -- Riptide
    [51886] = "SHAMAN",  -- Cleanse Spirit
    [16190] = "SHAMAN",  -- Mana Tide Totem
    
    -- Druid
    [774] = "DRUID",     -- Rejuvenation
    [8936] = "DRUID",    -- Regrowth
    [5185] = "DRUID",    -- Healing Touch
    [48441] = "DRUID",   -- Rejuvenation (Rank 15)
    [48443] = "DRUID",   -- Regrowth (Rank 12)
    [48378] = "DRUID",   -- Healing Touch (Rank 15)
    [33763] = "DRUID",   -- Lifebloom
    [18562] = "DRUID",   -- Swiftmend
    [48438] = "DRUID",   -- Wild Growth
    [17116] = "DRUID",   -- Nature's Swiftness
}

-- Colores por clase
local CLASS_COLORS = {
    ["PRIEST"] = {r = 1.0, g = 1.0, b = 1.0},
    ["PALADIN"] = {r = 0.96, g = 0.55, b = 0.73},
    ["SHAMAN"] = {r = 0.0, g = 0.44, b = 0.87},
    ["DRUID"] = {r = 1.0, g = 0.49, b = 0.04},
}

-- Umbral de mana bajo
local LOW_MANA_THRESHOLD = 0.30  -- 30%
local CRITICAL_MANA_THRESHOLD = 0.15  -- 15%

-- Helper para obtener configuración
function HT:GetOption(key)
    if S.ModuleConfig then
        return S.ModuleConfig:GetValue("HealerTracker", key)
    end
    -- Defaults
    if key == "manaThreshold" then return 30 end
    return true
end

function HT:Initialize()
    if not self:GetOption("enabled") then
        return
    end
    if self.initialized then return end
    self.initialized = true
    
    self:CreateFrame()
    self:RegisterEvents()
end

function HT:GetGroupChannel()
    if IsInInstance then
        local inInstance, instanceType = IsInInstance()
        if inInstance and instanceType == "pvp" then
            return "BATTLEGROUND"
        end
    end
    if GetNumRaidMembers() > 0 then
        return "RAID"
    elseif GetNumPartyMembers() > 0 then
        return "PARTY"
    end
    return nil
end

function HT:CreateFrame()
    self.Frame = CreateFrame("Frame", "SequitoHealerTrackerFrame", UIParent)
    self.Frame:SetSize(220, 180)
    self.Frame:SetPoint("RIGHT", UIParent, "RIGHT", -50, 100)
    self.Frame:SetMovable(true)
    self.Frame:EnableMouse(true)
    self.Frame:RegisterForDrag("LeftButton")
    self.Frame:SetScript("OnDragStart", function(f) f:StartMoving() end)
    self.Frame:SetScript("OnDragStop", function(f) f:StopMovingOrSizing() end)
    self.Frame:Hide()
    
    -- Fondo
    self.Frame.bg = self.Frame:CreateTexture(nil, "BACKGROUND")
    self.Frame.bg:SetAllPoints()
    self.Frame.bg:SetTexture("Interface\\Buttons\\WHITE8X8")
    self.Frame.bg:SetVertexColor(0, 0, 0, 0.85)
    
    -- Borde
    self.Frame.border = CreateFrame("Frame", nil, self.Frame)
    self.Frame.border:SetAllPoints()
    self.Frame.border:SetBackdrop({
        edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
        edgeSize = 14,
    })
    self.Frame.border:SetBackdropBorderColor(0.2, 0.6, 1.0, 1)
    
    -- Título
    self.Frame.title = self.Frame:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
    self.Frame.title:SetPoint("TOP", self.Frame, "TOP", 0, -10)
    self.Frame.title:SetText("|cFF00AAFFHealers Enemigos|r")
    
    -- Botón cerrar
    self.Frame.closeBtn = CreateFrame("Button", nil, self.Frame, "UIPanelCloseButton")
    self.Frame.closeBtn:SetPoint("TOPRIGHT", self.Frame, "TOPRIGHT", -2, -2)
    self.Frame.closeBtn:SetScript("OnClick", function() self.Frame:Hide() end)
    
    -- Crear filas para healers
    for i = 1, 5 do
        local row = CreateFrame("Frame", nil, self.Frame)
        row:SetSize(190, 28)
        row:SetPoint("TOPLEFT", self.Frame, "TOPLEFT", 15, -30 - (i-1) * 30)
        
        -- Icono de clase
        row.icon = row:CreateTexture(nil, "ARTWORK")
        row.icon:SetSize(22, 22)
        row.icon:SetPoint("LEFT", row, "LEFT", 0, 0)
        row.icon:SetTexture("Interface\\Glues\\CharacterCreate\\UI-CharacterCreate-Classes")
        
        -- Nombre
        row.name = row:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
        row.name:SetPoint("LEFT", row.icon, "RIGHT", 5, 5)
        row.name:SetWidth(100)
        row.name:SetJustifyH("LEFT")
        row.name:SetText("")
        
        -- Barra de mana
        row.manaBar = CreateFrame("StatusBar", nil, row)
        row.manaBar:SetSize(100, 10)
        row.manaBar:SetPoint("BOTTOMLEFT", row.icon, "BOTTOMRIGHT", 5, 0)
        row.manaBar:SetStatusBarTexture("Interface\\TargetingFrame\\UI-StatusBar")
        row.manaBar:SetStatusBarColor(0, 0.5, 1)
        row.manaBar:SetMinMaxValues(0, 100)
        row.manaBar:SetValue(100)
        
        -- Fondo de barra
        row.manaBar.bg = row.manaBar:CreateTexture(nil, "BACKGROUND")
        row.manaBar.bg:SetAllPoints()
        row.manaBar.bg:SetTexture("Interface\\Buttons\\WHITE8X8")
        row.manaBar.bg:SetVertexColor(0.1, 0.1, 0.3, 0.8)
        
        -- Texto de mana
        row.manaText = row.manaBar:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
        row.manaText:SetPoint("RIGHT", row, "RIGHT", 0, 0)
        row.manaText:SetText("")
        
        row:Hide()
        self.Rows[i] = row
    end
    
    -- OnUpdate
    self.Frame:SetScript("OnUpdate", function(frame, elapsed)
        self:OnUpdate(elapsed)
    end)
end

function HT:RegisterEvents()
    local eventFrame = CreateFrame("Frame")
    eventFrame:RegisterEvent("UNIT_MANA")
    eventFrame:RegisterEvent("PLAYER_TARGET_CHANGED")
    eventFrame:RegisterEvent("PLAYER_FOCUS_CHANGED")
    eventFrame:RegisterEvent("UPDATE_MOUSEOVER_UNIT")
    eventFrame:RegisterEvent("PLAYER_REGEN_ENABLED")
    
    eventFrame:SetScript("OnEvent", function(self, event, ...)
        if event == "UNIT_MANA" then
            local unit = ...
            HT:OnUnitPower(unit)
        elseif event == "PLAYER_TARGET_CHANGED" then
            HT:OnNameplateAdded("target")
        elseif event == "PLAYER_FOCUS_CHANGED" then
            HT:OnNameplateAdded("focus")
        elseif event == "UPDATE_MOUSEOVER_UNIT" then
            HT:OnNameplateAdded("mouseover")
        elseif event == "PLAYER_REGEN_ENABLED" then
            -- Limpieza o mantenimiento opcional fuera de combate
        end
    end)

    if S.CLEU and S.CLEU.Register then
        local function onHeal(...)
            HT:OnCombatLog(...)
        end
        S.CLEU:Register("SPELL_HEAL", onHeal)
        S.CLEU:Register("SPELL_PERIODIC_HEAL", onHeal)
        S.CLEU:Register("SPELL_CAST_START", onHeal)
        S.CLEU:Register("SPELL_CAST_SUCCESS", onHeal)
    else
        eventFrame:RegisterEvent("COMBAT_LOG_EVENT_UNFILTERED")
        eventFrame:HookScript("OnEvent", function(self, event, ...)
            if event == "COMBAT_LOG_EVENT_UNFILTERED" then
                HT:OnCombatLog(...)
            end
        end)
    end
end

function HT:OnCombatLog(...)
    local timestamp, event, sourceGUID, sourceName, sourceFlags, destGUID, destName, destFlags, spellId, spellName = ...
    
    -- Detectar healing de enemigos
    if event == "SPELL_HEAL" or event == "SPELL_PERIODIC_HEAL" then
        -- Verificar si es enemigo
        if bit.band(sourceFlags, COMBATLOG_OBJECT_REACTION_HOSTILE) > 0 then
            local healerClass = HEALING_SPELLS[spellId]
            if healerClass then
                self:TrackHealer(sourceGUID, sourceName, healerClass)
            end
        end
    -- Detectar casts de healing
    elseif event == "SPELL_CAST_SUCCESS" or event == "SPELL_CAST_START" then
        if bit.band(sourceFlags, COMBATLOG_OBJECT_REACTION_HOSTILE) > 0 then
            local healerClass = HEALING_SPELLS[spellId]
            if healerClass then
                self:TrackHealer(sourceGUID, sourceName, healerClass)
            end
        end
    end
end

function HT:TrackHealer(guid, name, class)
    -- Verificar si auto-detect está habilitado
    if not self:GetOption("autoDetect") then return end
    
    if not self.TrackedHealers[guid] then
        self.TrackedHealers[guid] = {
            name = name,
            class = class,
            mana = 100,
            maxMana = 100,
            manaPercent = 100,
            lastSeen = GetTime(),
        }
        
        if S.Print then
            local color = CLASS_COLORS[class] or {r=1, g=1, b=1}
            S:Print(string.format("|cFF00AAFF[Healer Detectado]|r |cFF%02x%02x%02x%s|r (%s)", 
                color.r * 255, color.g * 255, color.b * 255, name, class))
        end
        
        self:UpdateDisplay()
    else
        self.TrackedHealers[guid].lastSeen = GetTime()
    end
end

function HT:OnUnitPower(unit)
    if not UnitExists(unit) then return end
    if not UnitIsEnemy("player", unit) then return end
    
    local guid = UnitGUID(unit)
    if self.TrackedHealers[guid] then
        local mana = UnitPower(unit, 0)  -- 0 = MANA
        local maxMana = UnitPowerMax(unit, 0)
        
        if maxMana > 0 then
            local healer = self.TrackedHealers[guid]
            local oldPercent = healer.manaPercent
            
            healer.mana = mana
            healer.maxMana = maxMana
            healer.manaPercent = (mana / maxMana) * 100
            healer.lastSeen = GetTime()
            
            -- Alertar si bajó de umbral
            self:CheckManaAlert(healer, oldPercent)
            self:UpdateDisplay()
        end
    end
end

function HT:OnNameplateAdded(unit)
    if not UnitExists(unit) then return end
    if not UnitIsEnemy("player", unit) then return end
    
    local guid = UnitGUID(unit)
    local _, class = UnitClass(unit)
    
    if HEALER_CLASSES[class] then
        local name = UnitName(unit)
        self:TrackHealer(guid, name, class)
        
        -- Actualizar mana
        local mana = UnitPower(unit, 0)
        local maxMana = UnitPowerMax(unit, 0)
        
        if maxMana > 0 and self.TrackedHealers[guid] then
            self.TrackedHealers[guid].mana = mana
            self.TrackedHealers[guid].maxMana = maxMana
            self.TrackedHealers[guid].manaPercent = (mana / maxMana) * 100
            self:UpdateDisplay()
        end
    end
end

function HT:OnNameplateRemoved(unit)
    -- No eliminamos, solo dejamos de actualizar
end

function HT:OnUpdate(elapsed)
    self.TimeSinceLastUpdate = self.TimeSinceLastUpdate + elapsed
    if self.TimeSinceLastUpdate < self.UpdateInterval then return end
    self.TimeSinceLastUpdate = 0
    
    -- Actualizar mana de healers visibles
    for i = 1, 40 do
        local unit = "nameplate" .. i
        if UnitExists(unit) and UnitIsEnemy("player", unit) then
            local guid = UnitGUID(unit)
            if self.TrackedHealers[guid] then
                local mana = UnitPower(unit, 0)
                local maxMana = UnitPowerMax(unit, 0)
                
                if maxMana > 0 then
                    local healer = self.TrackedHealers[guid]
                    local oldPercent = healer.manaPercent
                    
                    healer.mana = mana
                    healer.maxMana = maxMana
                    healer.manaPercent = (mana / maxMana) * 100
                    healer.lastSeen = GetTime()
                    
                    self:CheckManaAlert(healer, oldPercent)
                end
            end
        end
    end
    
    -- También verificar target y focus
    for _, unit in ipairs({"target", "focus"}) do
        if UnitExists(unit) and UnitIsEnemy("player", unit) then
            local guid = UnitGUID(unit)
            if self.TrackedHealers[guid] then
                local mana = UnitPower(unit, 0)
                local maxMana = UnitPowerMax(unit, 0)
                
                if maxMana > 0 then
                    local healer = self.TrackedHealers[guid]
                    healer.mana = mana
                    healer.maxMana = maxMana
                    healer.manaPercent = (mana / maxMana) * 100
                    healer.lastSeen = GetTime()
                end
            end
        end
    end
    
    if self.Frame:IsShown() then
        self:UpdateDisplay()
    end
end

function HT:CheckManaAlert(healer, oldPercent)
    -- Verificar si alertas están habilitadas
    if not self:GetOption("alertLowMana") then return end
    
    local threshold = self:GetOption("manaThreshold")
    if not self:GetOption("alerts") then return end
    
    local newPercent = healer.manaPercent
    oldPercent = oldPercent or 100
    
    local threshold = self:GetOption("manaThreshold") or 30
    local criticalThreshold = threshold / 2  -- La mitad del umbral es crítico
    
    -- Alerta de mana crítico
    if newPercent <= criticalThreshold and oldPercent > criticalThreshold then
        if S.Print then
            S:Print(string.format("|cFFFF0000¡%s MANA CRÍTICO!|r (%.0f%%)", healer.name, healer.manaPercent))
        end
        -- Sonido si está habilitado
        if self:GetOption("playSound") then
            PlaySound("RaidWarning")
        end
        
        -- Anunciar al grupo si está habilitado
        if self:GetOption("announce") then
            self:AnnounceHealer(healer, "CRITICO")
        end
    -- Alerta de mana bajo
    elseif newPercent <= threshold and oldPercent > threshold then
        if S.Print then
            S:Print(string.format("|cFFFFFF00%s mana bajo|r (%.0f%%)", healer.name, healer.manaPercent))
        end
    end
end

function HT:AnnounceHealer(healer, status)
    local channel = self:GetGroupChannel()
    
    if channel then
        SendChatMessage(string.format("[Sequito] Healer %s - Mana %s: %.0f%%", 
            healer.name, status, healer.manaPercent), channel)
    end
end

function HT:UpdateDisplay()
    -- Ordenar healers por mana (menor primero)
    local sorted = {}
    for guid, data in pairs(self.TrackedHealers) do
        table.insert(sorted, {guid = guid, data = data})
    end
    table.sort(sorted, function(a, b)
        return a.data.manaPercent < b.data.manaPercent
    end)
    
    -- Actualizar filas
    for i, row in ipairs(self.Rows) do
        if sorted[i] then
            local healer = sorted[i].data
            local color = CLASS_COLORS[healer.class] or {r=1, g=1, b=1}
            
            -- Icono de clase
            local coords = CLASS_ICON_TCOORDS[healer.class]
            if coords then
                row.icon:SetTexCoord(unpack(coords))
            end
            
            -- Nombre con color de clase
            row.name:SetText(healer.name)
            row.name:SetTextColor(color.r, color.g, color.b)
            
            -- Barra de mana
            row.manaBar:SetValue(healer.manaPercent)
            
            -- Color de barra según mana
            if healer.manaPercent <= 15 then
                row.manaBar:SetStatusBarColor(1, 0, 0)  -- Rojo
            elseif healer.manaPercent <= 30 then
                row.manaBar:SetStatusBarColor(1, 0.5, 0)  -- Naranja
            elseif healer.manaPercent <= 50 then
                row.manaBar:SetStatusBarColor(1, 1, 0)  -- Amarillo
            else
                row.manaBar:SetStatusBarColor(0, 0.5, 1)  -- Azul
            end
            
            -- Texto de mana
            row.manaText:SetText(string.format("%.0f%%", healer.manaPercent))
            
            row:Show()
        else
            row:Hide()
        end
    end
end

function HT:Clear()
    wipe(self.TrackedHealers)
    self:UpdateDisplay()
    if S.Print then
        S:Print("Tracker de healers limpiado.")
    end
end

function HT:Toggle()
    if not self.Frame then return end
    if self.Frame:IsShown() then
        self.Frame:Hide()
    else
        self.Frame:Show()
        self:UpdateDisplay()
    end
end

function HT:AnnounceAll()
    local channel = self:GetGroupChannel()
    
    if not channel then
        if S.Print then
            S:Print("No estás en un grupo.")
        end
        return
    end
    
    local parts = {}
    for guid, healer in pairs(self.TrackedHealers) do
        table.insert(parts, string.format("%s: %.0f%%", healer.name, healer.manaPercent))
    end
    
    if #parts == 0 then
        SendChatMessage("[Sequito] No hay healers enemigos detectados.", channel)
        return
    end
    
    local msg = "[Sequito] Healers: " .. table.concat(parts, " | ")
    if #msg > 240 then
        msg = msg:sub(1, 237) .. "..."
    end
    SendChatMessage(msg, channel)
end

function HT:GetHealerCount()
    local count = 0
    for _ in pairs(self.TrackedHealers) do
        count = count + 1
    end
    return count
end

function HT:GetLowestManaHealer()
    local lowest = nil
    local lowestMana = 101
    
    for guid, healer in pairs(self.TrackedHealers) do
        if healer.manaPercent < lowestMana then
            lowestMana = healer.manaPercent
            lowest = healer
        end
    end
    
    return lowest
end

-- Registrar configuración en ModuleConfig
if S.ModuleConfig then
    S.ModuleConfig:RegisterModule("HealerTracker", {
        name = "Healer Tracker",
        icon = "Interface\\Icons\\Spell_Holy_FlashHeal",
        description = "Trackea mana de healers enemigos en PvP",
        category = "pvp",
        options = {
            {
                type = "checkbox",
                key = "enabled",
                label = "Habilitar Healer Tracker",
                tooltip = "Activa/desactiva el tracker de healers",
                default = true,
            },
            {
                type = "checkbox",
                key = "autoDetect",
                label = "Detección Automática",
                tooltip = "Detecta healers automáticamente por sus hechizos",
                default = true,
            },
            {
                type = "checkbox",
                key = "alertLowMana",
                label = "Alertar Mana Bajo",
                tooltip = "Alerta cuando un healer tiene mana bajo",
                default = true,
            },
            {
                type = "slider",
                key = "lowManaThreshold",
                label = "Umbral Mana Bajo (%)",
                tooltip = "Porcentaje de mana para considerar 'bajo'",
                min = 10,
                max = 50,
                step = 5,
                default = 30,
            },
            {
                type = "checkbox",
                key = "announceToGroup",
                label = "Anunciar al Grupo",
                tooltip = "Anuncia healers con mana bajo al grupo",
                default = false,
            },
            {
                type = "checkbox",
                key = "playSound",
                label = "Reproducir Sonido",
                tooltip = "Reproduce sonido cuando healer tiene mana bajo",
                default = true,
            },
            {
                type = "slider",
                key = "updateInterval",
                label = "Intervalo Actualización (seg)",
                tooltip = "Frecuencia de actualización del tracker",
                min = 0.1,
                max = 1.0,
                step = 0.1,
                default = 0.2,
            },
        },
    })
end

-- Inicializar
if S.RegisterModule then
    S:RegisterModule("HealerTracker", HT)
else
    local initFrame = CreateFrame("Frame")
    initFrame:RegisterEvent("PLAYER_LOGIN")
    initFrame:SetScript("OnEvent", function()
        HT:Initialize()
    end)
end
