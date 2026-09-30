--[[
    Sequito - PerformanceStats Module
    Estadísticas de Rendimiento
    Version: 10.2.0
]]

local addonName, S = ...
S.PerformanceStats = {}
local PS = S.PerformanceStats

SequitoStatsDB = SequitoStatsDB or {}

local currentCombat = nil

-- Helper para obtener configuración
function PS:GetOption(key)
    if S.ModuleConfig then
        return S.ModuleConfig:GetValue("PerformanceStats", key)
    end
    return true
end

function PS:Initialize()
    if self.initialized then return end
    if not self:GetOption("enabled") then
        return
    end
    self.initialized = true
    
    self.frame = self:CreateFrame()
    self:RegisterEvents()
end

function PS:CreateFrame()
    local f = CreateFrame("Frame", "SequitoPerformanceStatsFrame", UIParent)
    self.frame = f
    f:SetSize(400, 350)
    f:SetPoint("CENTER")
    if S.Theme and S.Theme.ApplyPanelBackdrop then
        S.Theme:ApplyPanelBackdrop(f)
    else
        f:SetBackdrop({bgFile = "Interface\\DialogFrame\\UI-DialogBox-Background", edgeFile = "Interface\\DialogFrame\\UI-DialogBox-Border", edgeSize = 16, insets = {left = 4, right = 4, top = 4, bottom = 4}})
    end
    f:SetMovable(true)
    f:EnableMouse(true)
    f:RegisterForDrag("LeftButton")
    f:SetScript("OnDragStart", f.StartMoving)
    f:SetScript("OnDragStop", function(self)
        self:StopMovingOrSizing()
        if S.SmartDefaults then
            S.SmartDefaults:SavePosition("PerformanceStats", self)
        end
    end)
    f:Hide()
    
    f.title = f:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
    f.title:SetPoint("TOP", 0, -10)
    f.title:SetText("Estadísticas de Rendimiento")
    
    f.scroll = CreateFrame("ScrollFrame", "SequitoPSStatsScroll", f, "UIPanelScrollFrameTemplate")
    f.scroll:SetPoint("TOPLEFT", 10, -40)
    f.scroll:SetPoint("BOTTOMRIGHT", -30, 40)
    
    f.content = CreateFrame("Frame", nil, f.scroll)
    f.content:SetSize(360, 500)
    f.scroll:SetScrollChild(f.content)
    
    f.close = CreateFrame("Button", nil, f, "UIPanelCloseButton")
    f.close:SetPoint("TOPRIGHT", -5, -5)
    f.close:SetScript("OnClick", function() f:Hide() end)
    
    if S.SmartDefaults then
        S.SmartDefaults:RestorePosition("PerformanceStats")
    end
    
    return f
end

function PS:RegisterEvents()
    local events = CreateFrame("Frame")
    events:RegisterEvent("PLAYER_REGEN_DISABLED")
    events:RegisterEvent("PLAYER_REGEN_ENABLED")
    
    if S.CLEU and S.CLEU.Register then
        local function onCLEU(...)
            PS:ProcessCombatLog(...)
        end
        S.CLEU:Register("SWING_DAMAGE", onCLEU)
        S.CLEU:Register("RANGE_DAMAGE", onCLEU)
        S.CLEU:Register("SPELL_DAMAGE", onCLEU)
        S.CLEU:Register("SPELL_PERIODIC_DAMAGE", onCLEU)
        S.CLEU:Register("DAMAGE_SHIELD", onCLEU)
        S.CLEU:Register("SPELL_HEAL", onCLEU)
        S.CLEU:Register("SPELL_PERIODIC_HEAL", onCLEU)
    else
        events:RegisterEvent("COMBAT_LOG_EVENT_UNFILTERED")
    end
    
    events:SetScript("OnEvent", function(_, event, ...)
        if event == "PLAYER_REGEN_DISABLED" then
            PS:StartCombat()
        elseif event == "PLAYER_REGEN_ENABLED" then
            PS:EndCombat()
        elseif event == "COMBAT_LOG_EVENT_UNFILTERED" then
            PS:ProcessCombatLog(...)
        end
    end)
end

function PS:StartCombat()
    -- Verificar si tracking está habilitado
    if not self:GetOption("autoTrack") then
        return
    end
    
    currentCombat = {
        startTime = GetTime(),
        damage = 0,
        healing = 0,
        target = UnitName("target") or "Unknown"
    }
end

function PS:EndCombat()
    if currentCombat then
        local duration = GetTime() - currentCombat.startTime
        if duration > 3 and (currentCombat.damage > 0 or currentCombat.healing > 0) then
            local dps = currentCombat.damage / duration
            local hps = currentCombat.healing / duration
            
            local record = {
                target = currentCombat.target,
                duration = duration,
                dps = dps,
                hps = hps,
                date = date("%Y-%m-%d %H:%M")
            }
            
            table.insert(SequitoStatsDB, record)
            local maxRecords = tonumber(self:GetOption("maxRecords")) or 50
            while #SequitoStatsDB > maxRecords do
                table.remove(SequitoStatsDB, 1)
            end
        end
        currentCombat = nil
    end
end

function PS:ProcessCombatLog(...)
    if not currentCombat then
        if self:GetOption("autoTrack") then
            self:StartCombat()
        else
            return
        end
    end
    
    -- WoW 3.3.5a CLEU signature: timestamp, event, sourceGUID, sourceName, sourceFlags, destGUID, destName, destFlags, ...
    local timestamp, event, sourceGUID, sourceName, sourceFlags, destGUID, destName, destFlags = ...
    local playerGUID = UnitGUID("player")
    local petGUID = UnitGUID("pet")
    
    if sourceGUID == playerGUID or (petGUID and sourceGUID == petGUID) then
        if event == "SWING_DAMAGE" then
            local amount = select(9, ...) or 0
            currentCombat.damage = currentCombat.damage + (tonumber(amount) or 0)
            if currentCombat.target == "Unknown" and destName and destName ~= UnitName("player") and destName ~= UnitName("pet") then
                currentCombat.target = destName
            end
        elseif event == "SPELL_DAMAGE" or event == "SPELL_PERIODIC_DAMAGE" or event == "RANGE_DAMAGE" or event == "DAMAGE_SHIELD" then
            local amount = select(12, ...) or 0
            currentCombat.damage = currentCombat.damage + (tonumber(amount) or 0)
            if currentCombat.target == "Unknown" and destName and destName ~= UnitName("player") and destName ~= UnitName("pet") then
                currentCombat.target = destName
            end
        elseif event == "SPELL_HEAL" or event == "SPELL_PERIODIC_HEAL" then
            local amount = select(12, ...) or 0
            local overheal = select(13, ...) or 0
            local effectiveHeal = math.max(0, (tonumber(amount) or 0) - (tonumber(overheal) or 0))
            currentCombat.healing = currentCombat.healing + effectiveHeal
        end
    end
end

function PS:ClearStats()
    wipe(SequitoStatsDB)
    if self.statLines then
        for _, fs in ipairs(self.statLines) do
            fs:Hide()
        end
    end
    if S.Print then
        S:Print("Estadísticas de rendimiento reiniciadas.")
    end
end

function PS:CompareRaids()
    if S.Print then
        S:Print("Comparación de combate: registros totales guardados = " .. #SequitoStatsDB)
    end
    self:ShowStats()
end

function PS:ShowStats()
    if not self.frame then return end
    self.statLines = self.statLines or {}
    for _, fs in ipairs(self.statLines) do
        fs:Hide()
    end
    
    if #SequitoStatsDB == 0 then
        if not self.emptyText then
            self.emptyText = self.frame.content:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
            self.emptyText:SetPoint("TOP", 0, -40)
            self.emptyText:SetText("No hay registros de combate aún.\nEntra en combate para medir tu DPS y HPS.")
        end
        self.emptyText:Show()
        self.frame:Show()
        return
    elseif self.emptyText then
        self.emptyText:Hide()
    end
    
    local yOffset = 0
    local lineIdx = 1
    local maxDisplay = tonumber(self:GetOption("maxRecords")) or 50
    for i = #SequitoStatsDB, math.max(1, #SequitoStatsDB - maxDisplay + 1), -1 do
        local record = SequitoStatsDB[i]
        local text = self.statLines[lineIdx]
        if not text then
            text = self.frame.content:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
            self.statLines[lineIdx] = text
        end
        text:ClearAllPoints()
        text:SetPoint("TOPLEFT", 5, -yOffset)
        text:SetText(string.format("%s - %s: %.1f DPS, %.1f HPS (%.0fs)", 
            record.date or "-", record.target or "Unknown", record.dps or 0, record.hps or 0, record.duration or 0))
        text:Show()
        yOffset = yOffset + 15
        lineIdx = lineIdx + 1
    end
    for j = lineIdx, #self.statLines do
        self.statLines[j]:Hide()
    end
    if self.frame and self.frame.content then
        self.frame.content:SetHeight(math.max(yOffset + 20, 270))
    end
    self.frame:Show()
end

function PS:Toggle()
    if not self.frame then return end
    if self.frame:IsShown() then self.frame:Hide() else self:ShowStats() end
end

function PS:SlashCommand(msg)
    self:Toggle()
end

-- Registrar módulo en ModuleConfig
if S.ModuleConfig then
    S.ModuleConfig:RegisterModule({
        id = "PerformanceStats",
        name = "Estadísticas de Rendimiento",
        description = "Trackeo de DPS/HPS y estadísticas de combate",
        category = "utility",
        icon = "Interface\\Icons\\INV_Misc_PocketWatch_01",
        options = {
            {
                key = "enabled",
                type = "checkbox",
                name = "Habilitar Stats",
                description = "Habilitar/deshabilitar tracking de estadísticas",
                default = true
            },
            {
                key = "autoTrack",
                type = "checkbox",
                name = "Auto-Track",
                description = "Trackear automáticamente en combate",
                default = true
            },
            {
                key = "showInTooltip",
                type = "checkbox",
                name = "Mostrar en Tooltip",
                description = "Mostrar estadísticas en tooltip de jugadores",
                default = false
            },
            {
                key = "trackBosses",
                type = "checkbox",
                name = "Solo Bosses",
                description = "Trackear solo combates contra bosses",
                default = true
            },
            {
                key = "maxRecords",
                type = "slider",
                name = "Máximo de Registros",
                description = "Número máximo de registros a guardar",
                min = 10,
                max = 100,
                step = 10,
                default = 50
            }
        }
    })
end

SLASH_PERFORMANCESTATS1 = "/ps"
SLASH_PERFORMANCESTATS2 = "/stats"
SlashCmdList["PERFORMANCESTATS"] = function(msg)
    PS:SlashCommand(msg)
end
