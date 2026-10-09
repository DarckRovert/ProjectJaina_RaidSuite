--[[
    Jaina - HealerTracker.lua
    Monitor de Healers Enemigos con Optimización Zero-Heap
    Version: 8.0.0
    Compatibilidad: WotLK 3.3.5a (Build 12340)
]]

local addonName, S = ...
S.HealerTracker = {}
local HT = S.HealerTracker

-- Estado
HT.TrackedHealers = {}  -- {guid = {name, class, mana, maxMana, manaPercent, lastSeen}}
HT.Frame = nil
HT.Rows = {}
HT.IsVisible = false
HT.TimeSinceLastUpdate = 0

-- Clases healer
local HEALER_CLASSES = {
    ["PRIEST"] = true,
    ["PALADIN"] = true,
    ["SHAMAN"] = true,
    ["DRUID"] = true,
}

-- Spells de healing para detección (Todos los rangos comunes WotLK)
local HEALING_SPELLS = {
    -- Priest
    [2050] = "PRIEST", [2054] = "PRIEST", [2060] = "PRIEST", [596] = "PRIEST",
    [139] = "PRIEST", [17] = "PRIEST", [48068] = "PRIEST", [48063] = "PRIEST",
    [48071] = "PRIEST", [48072] = "PRIEST", [33076] = "PRIEST", [34861] = "PRIEST",
    [47788] = "PRIEST", [47540] = "PRIEST", [53007] = "PRIEST",
    
    -- Paladin
    [635] = "PALADIN", [19750] = "PALADIN", [48782] = "PALADIN", [48785] = "PALADIN",
    [53563] = "PALADIN", [20473] = "PALADIN", [31842] = "PALADIN", [53652] = "PALADIN",
    
    -- Shaman
    [331] = "SHAMAN", [8004] = "SHAMAN", [1064] = "SHAMAN", [49273] = "SHAMAN",
    [49276] = "SHAMAN", [55459] = "SHAMAN", [61295] = "SHAMAN", [51886] = "SHAMAN",
    [16190] = "SHAMAN", [51994] = "SHAMAN",
    
    -- Druid
    [774] = "DRUID", [8936] = "DRUID", [5185] = "DRUID", [48441] = "DRUID",
    [48443] = "DRUID", [48378] = "DRUID", [33763] = "DRUID", [18562] = "DRUID",
    [48438] = "DRUID", [17116] = "DRUID",
}

-- Colores por clase
local CLASS_COLORS = {
    ["PRIEST"]  = {r = 1.0, g = 1.0, b = 1.0},
    ["PALADIN"] = {r = 0.96, g = 0.55, b = 0.73},
    ["SHAMAN"]  = {r = 0.0, g = 0.44, b = 0.87},
    ["DRUID"]   = {r = 1.0, g = 0.49, b = 0.04},
}

-- Unidades nativas válidas en WotLK 3.3.5a para sondeo de mana
local SCAN_UNITS = {
    "target", "focus", "mouseover", "targettarget", "focustarget",
    "arena1", "arena2", "arena3", "arena4", "arena5"
}

-- Búfer estático de ordenamiento reutilizable (Zero-Heap Ley IV)
local sortedBuffer = {}
local function CompareMana(a, b)
    return (a.data.manaPercent or 100) < (b.data.manaPercent or 100)
end

function HT:GetOption(key)
    if S.ModuleConfig then
        local val = S.ModuleConfig:GetValue("HealerTracker", key)
        if val ~= nil then return val end
        
        -- Mapeo defensivo de alias cruzados
        if key == "lowManaThreshold" or key == "manaThreshold" then
            val = S.ModuleConfig:GetValue("HealerTracker", "lowManaThreshold")
            if val ~= nil then return val end
            return 30
        elseif key == "announceToGroup" or key == "announce" then
            val = S.ModuleConfig:GetValue("HealerTracker", "announceToGroup")
            if val ~= nil then return val end
            return false
        elseif key == "alertLowMana" or key == "alerts" then
            val = S.ModuleConfig:GetValue("HealerTracker", "alertLowMana")
            if val ~= nil then return val end
            return true
        end
    end
    
    if key == "lowManaThreshold" or key == "manaThreshold" then return 30 end
    if key == "updateInterval" then return 0.2 end
    if key == "announceToGroup" or key == "announce" then return false end
    return true
end

function HT:Initialize()
    if not self:GetOption("enabled") then return end
    if self.initialized then return end
    self.initialized = true
    
    self:CreateFrame()
    self:RegisterEvents()
    
    if S.SmartDefaults then
        S.SmartDefaults:RestorePosition("HealerTracker")
    end
end

function HT:GetGroupChannel()
    local _, instanceType = IsInInstance()
    if instanceType == "pvp" or instanceType == "arena" then
        return "BATTLEGROUND"
    elseif GetNumRaidMembers() > 0 then
        return "RAID"
    elseif GetNumPartyMembers() > 0 then
        return "PARTY"
    end
    return nil
end

function HT:CreateFrame()
    self.Frame = CreateFrame("Frame", "JainaHealerTrackerFrame", UIParent)
    self.Frame:SetSize(220, 180)
    self.Frame:SetPoint("RIGHT", UIParent, "RIGHT", -50, 100)
    self.Frame:SetMovable(true)
    self.Frame:EnableMouse(true)
    self.Frame:RegisterForDrag("LeftButton")
    self.Frame:SetScript("OnDragStart", function(f) f:StartMoving() end)
    self.Frame:SetScript("OnDragStop", function(f)
        f:StopMovingOrSizing()
        if S.SmartDefaults then
            S.SmartDefaults:SavePosition("HealerTracker", f)
        end
    end)
    self.Frame:Hide()
    
    -- Fondo (Ley II: WHITE8X8)
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
    
    -- Pool fijo de 5 ranuras reciclables (Ley IV)
    for i = 1, 5 do
        local row = CreateFrame("Frame", nil, self.Frame)
        row:SetSize(190, 28)
        row:SetPoint("TOPLEFT", self.Frame, "TOPLEFT", 15, -30 - (i-1) * 30)
        
        row.icon = row:CreateTexture(nil, "ARTWORK")
        row.icon:SetSize(22, 22)
        row.icon:SetPoint("LEFT", row, "LEFT", 0, 0)
        row.icon:SetTexture("Interface\\Glues\\CharacterCreate\\UI-CharacterCreate-Classes")
        
        row.name = row:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
        row.name:SetPoint("LEFT", row.icon, "RIGHT", 5, 5)
        row.name:SetWidth(100)
        row.name:SetJustifyH("LEFT")
        row.name:SetText("")
        
        row.manaBar = CreateFrame("StatusBar", nil, row)
        row.manaBar:SetSize(100, 10)
        row.manaBar:SetPoint("BOTTOMLEFT", row.icon, "BOTTOMRIGHT", 5, 0)
        row.manaBar:SetStatusBarTexture("Interface\\TargetingFrame\\UI-StatusBar")
        row.manaBar:SetStatusBarColor(0, 0.5, 1)
        row.manaBar:SetMinMaxValues(0, 100)
        row.manaBar:SetValue(100)
        
        row.manaBar.bg = row.manaBar:CreateTexture(nil, "BACKGROUND")
        row.manaBar.bg:SetAllPoints()
        row.manaBar.bg:SetTexture("Interface\\Buttons\\WHITE8X8")
        row.manaBar.bg:SetVertexColor(0.1, 0.1, 0.3, 0.8)
        
        row.manaText = row.manaBar:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
        row.manaText:SetPoint("RIGHT", row, "RIGHT", 0, 0)
        row.manaText:SetText("")
        
        row:Hide()
        self.Rows[i] = row
    end
    
    -- OnUpdate throttled dinámico
    self.Frame:SetScript("OnUpdate", function(f, elapsed)
        self:OnUpdate(elapsed)
    end)
end

function HT:RegisterEvents()
    local eventFrame = CreateFrame("Frame")
    eventFrame:RegisterEvent("UNIT_MANA")
    eventFrame:RegisterEvent("UNIT_POWER")
    eventFrame:RegisterEvent("PLAYER_TARGET_CHANGED")
    eventFrame:RegisterEvent("PLAYER_FOCUS_CHANGED")
    eventFrame:RegisterEvent("UPDATE_MOUSEOVER_UNIT")
    eventFrame:RegisterEvent("ARENA_OPPONENT_UPDATE")
    eventFrame:RegisterEvent("PLAYER_REGEN_ENABLED")
    
    eventFrame:SetScript("OnEvent", function(f, event, ...)
        if event == "UNIT_MANA" or event == "UNIT_POWER" then
            local unit = ...
            HT:OnUnitPower(unit)
        elseif event == "PLAYER_TARGET_CHANGED" then
            HT:CheckUnitForHealer("target")
        elseif event == "PLAYER_FOCUS_CHANGED" then
            HT:CheckUnitForHealer("focus")
        elseif event == "UPDATE_MOUSEOVER_UNIT" then
            HT:CheckUnitForHealer("mouseover")
        elseif event == "ARENA_OPPONENT_UPDATE" then
            for i = 1, 5 do
                HT:CheckUnitForHealer("arena" .. i)
            end
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
        eventFrame:HookScript("OnEvent", function(f, event, ...)
            if event == "COMBAT_LOG_EVENT_UNFILTERED" then
                HT:OnCombatLog(...)
            end
        end)
    end
end

function HT:OnCombatLog(...)
    local timestamp, event, sourceGUID, sourceName, sourceFlags, destGUID, destName, destFlags, spellId, spellName = ...
    if not sourceGUID or not sourceFlags then return end
    
    if event == "SPELL_HEAL" or event == "SPELL_PERIODIC_HEAL" or event == "SPELL_CAST_SUCCESS" or event == "SPELL_CAST_START" then
        if bit.band(sourceFlags, COMBATLOG_OBJECT_REACTION_HOSTILE) > 0 then
            local healerClass = HEALING_SPELLS[spellId]
            if healerClass then
                self:TrackHealer(sourceGUID, sourceName or "Enemigo", healerClass)
            end
        end
    end
end

function HT:TrackHealer(guid, name, class)
    if not self:GetOption("autoDetect") then return end
    if not guid then return end
    
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

function HT:CheckUnitForHealer(unit)
    if not UnitExists(unit) or not UnitIsEnemy("player", unit) then return end
    
    local _, class = UnitClass(unit)
    if HEALER_CLASSES[class] then
        local guid = UnitGUID(unit)
        local name = UnitName(unit)
        self:TrackHealer(guid, name, class)
        self:OnUnitPower(unit)
    end
end

function HT:OnUnitPower(unit)
    if not UnitExists(unit) or not UnitIsEnemy("player", unit) then return end
    
    local guid = UnitGUID(unit)
    if self.TrackedHealers[guid] then
        local mana = UnitPower(unit, 0)
        local maxMana = UnitPowerMax(unit, 0)
        
        if maxMana and maxMana > 0 then
            local healer = self.TrackedHealers[guid]
            local oldPercent = healer.manaPercent
            
            healer.mana = mana
            healer.maxMana = maxMana
            healer.manaPercent = (mana / maxMana) * 100
            healer.lastSeen = GetTime()
            
            self:CheckManaAlert(healer, oldPercent)
            self:UpdateDisplay()
        end
    end
end

function HT:OnUpdate(elapsed)
    self.TimeSinceLastUpdate = self.TimeSinceLastUpdate + elapsed
    local interval = tonumber(self:GetOption("updateInterval")) or 0.2
    if self.TimeSinceLastUpdate < interval then return end
    self.TimeSinceLastUpdate = 0
    
    -- Sondeo seguro exclusivamente en unidades WotLK 3.3.5a
    for _, unit in ipairs(SCAN_UNITS) do
        if UnitExists(unit) and UnitIsEnemy("player", unit) then
            local guid = UnitGUID(unit)
            if self.TrackedHealers[guid] then
                local mana = UnitPower(unit, 0)
                local maxMana = UnitPowerMax(unit, 0)
                
                if maxMana and maxMana > 0 then
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
    
    if self.Frame and self.Frame:IsShown() then
        self:UpdateDisplay()
    end
end

function HT:CheckManaAlert(healer, oldPercent)
    if not self:GetOption("alertLowMana") then return end
    
    local threshold = tonumber(self:GetOption("lowManaThreshold")) or 30
    local criticalThreshold = threshold / 2
    local newPercent = healer.manaPercent
    oldPercent = oldPercent or 100
    
    -- Alerta de mana crítico
    if newPercent <= criticalThreshold and oldPercent > criticalThreshold then
        if S.Print then
            S:Print(string.format("|cFFFF0000¡%s MANA CRÍTICO!|r (%.0f%%)", healer.name, healer.manaPercent))
        end
        if self:GetOption("playSound") then
            PlaySound("RaidWarning")
        end
        if self:GetOption("announceToGroup") then
            self:AnnounceHealer(healer, "CRITICO")
        end
    -- Alerta de mana bajo
    elseif newPercent <= threshold and oldPercent > threshold then
        if S.Print then
            S:Print(string.format("|cFFFFFF00%s mana bajo|r (%.0f%%)", healer.name, healer.manaPercent))
        end
        if self:GetOption("playSound") then
            PlaySound("RaidWarning")
        end
        if self:GetOption("announceToGroup") then
            self:AnnounceHealer(healer, "BAJO")
        end
    end
end

function HT:AnnounceHealer(healer, status)
    local channel = self:GetGroupChannel()
    if channel then
        SendChatMessage(string.format("[Jaina] Healer %s - Mana %s: %.0f%%", 
            healer.name, status, healer.manaPercent), channel)
    end
end

function HT:UpdateDisplay()
    if not self.Frame or not self.Frame:IsShown() then return end
    
    -- Reciclaje del buffer estático (Cero recolección de basura)
    wipe(sortedBuffer)
    for guid, data in pairs(self.TrackedHealers) do
        table.insert(sortedBuffer, {guid = guid, data = data})
    end
    table.sort(sortedBuffer, CompareMana)
    
    -- Actualizar las 5 filas reciclables
    for i, row in ipairs(self.Rows) do
        if sortedBuffer[i] then
            local healer = sortedBuffer[i].data
            local color = CLASS_COLORS[healer.class] or {r=1, g=1, b=1}
            
            local coords = CLASS_ICON_TCOORDS and CLASS_ICON_TCOORDS[healer.class]
            if coords then
                row.icon:SetTexCoord(unpack(coords))
            end
            
            row.name:SetText(healer.name)
            row.name:SetTextColor(color.r, color.g, color.b)
            
            row.manaBar:SetValue(healer.manaPercent)
            if healer.manaPercent <= 15 then
                row.manaBar:SetStatusBarColor(1, 0, 0)
            elseif healer.manaPercent <= 30 then
                row.manaBar:SetStatusBarColor(1, 0.5, 0)
            elseif healer.manaPercent <= 50 then
                row.manaBar:SetStatusBarColor(1, 1, 0)
            else
                row.manaBar:SetStatusBarColor(0, 0.5, 1)
            end
            
            row.manaText:SetText(string.format("%.0f%%", healer.manaPercent))
            row:Show()
        else
            row:Hide()
        end
    end
end

function HT:Clear()
    wipe(self.TrackedHealers)
    wipe(sortedBuffer)
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
        if S.Print then S:Print("No estás en un grupo.") end
        return
    end
    
    local parts = {}
    for guid, healer in pairs(self.TrackedHealers) do
        table.insert(parts, string.format("%s: %.0f%%", healer.name, healer.manaPercent))
    end
    
    if #parts == 0 then
        SendChatMessage("[Jaina] No hay healers enemigos detectados.", channel)
        return
    end
    
    local msg = "[Jaina] Healers: " .. table.concat(parts, " | ")
    if #msg > 240 then
        msg = msg:sub(1, 237) .. "..."
    end
    SendChatMessage(msg, channel)
end

-- Registro unificado de configuración
if S.ModuleConfig then
    S.ModuleConfig:RegisterModule("HealerTracker", {
        name = "Healer Tracker",
        icon = "Interface\\Icons\\Spell_Holy_FlashHeal",
        description = "Trackea mana de healers enemigos en PvP con cero impacto de rendimiento.",
        category = "pvp",
        options = {
            { type = "checkbox", key = "enabled", label = "Habilitar Healer Tracker", default = true },
            { type = "checkbox", key = "autoDetect", label = "Detección Automática", default = true },
            { type = "checkbox", key = "alertLowMana", label = "Alertar Mana Bajo", default = true },
            { type = "slider", key = "lowManaThreshold", label = "Umbral Mana Bajo (%)", min = 10, max = 50, step = 5, default = 30 },
            { type = "checkbox", key = "announceToGroup", label = "Anunciar al Grupo", default = false },
            { type = "checkbox", key = "playSound", label = "Reproducir Sonido", default = true },
            { type = "slider", key = "updateInterval", label = "Intervalo Actualización (seg)", min = 0.1, max = 1.0, step = 0.1, default = 0.2 },
        },
    })
end

-- Inicialización
if S.RegisterModule then
    S:RegisterModule("HealerTracker", HT)
else
    local initFrame = CreateFrame("Frame")
    initFrame:RegisterEvent("PLAYER_LOGIN")
    initFrame:SetScript("OnEvent", function()
        HT:Initialize()
    end)
end
