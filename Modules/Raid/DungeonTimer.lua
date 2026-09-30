--[[
    Sequito - DungeonTimer.lua
    Timer de Heroic/Daily Dungeons
    Version: 7.3.0
    
    Funcionalidades:
    - Mostrar tiempo restante para reset de heroicas
    - Recordar qué dungeons ya hiciste hoy
    - Tooltip en la esfera con info
    - Tracking de lockouts
]]

local addonName, S = ...
S.DungeonTimer = {}
local DT = S.DungeonTimer

-- Estado
DT.Frame = nil
DT.CompletedDungeons = {}
DT.DailyReset = 0
DT.IsVisible = false

-- Lista de Heroicas de WotLK
local HEROIC_DUNGEONS = {
    -- Northrend Dungeons
    {id = 574, name = "Utgarde Keep", abbrev = "UK"},
    {id = 575, name = "Utgarde Pinnacle", abbrev = "UP"},
    {id = 576, name = "The Nexus", abbrev = "Nex"},
    {id = 578, name = "The Oculus", abbrev = "Ocu"},
    {id = 595, name = "The Culling of Stratholme", abbrev = "CoS"},
    {id = 599, name = "Halls of Stone", abbrev = "HoS"},
    {id = 600, name = "Drak'Tharon Keep", abbrev = "DTK"},
    {id = 601, name = "Azjol-Nerub", abbrev = "AN"},
    {id = 602, name = "Halls of Lightning", abbrev = "HoL"},
    {id = 604, name = "Gundrak", abbrev = "Gun"},
    {id = 608, name = "The Violet Hold", abbrev = "VH"},
    {id = 619, name = "Ahn'kahet: The Old Kingdom", abbrev = "OK"},
    {id = 632, name = "The Forge of Souls", abbrev = "FoS"},
    {id = 650, name = "Trial of the Champion", abbrev = "ToC5"},
    {id = 658, name = "Pit of Saron", abbrev = "PoS"},
    {id = 668, name = "Halls of Reflection", abbrev = "HoR"},
}

-- Dailies especiales
local DAILY_DUNGEONS = {
    {name = "Random Heroic", abbrev = "RH", questId = 24790},
    {name = "Random Normal", abbrev = "RN", questId = 24788},
}

-- Helper para obtener configuración
function DT:GetOption(key)
    if S.ModuleConfig then
        return S.ModuleConfig:GetValue("DungeonTimer", key)
    end
    return true
end

function DT:Initialize()
    if self.initialized then return end
    if not self:GetOption("enabled") then
        return
    end
    self.initialized = true
    
    self:CreateFrame()
    self:RegisterEvents()
    self:LoadSavedData()
    self:CalculateResetTime()
end

function DT:CreateFrame()
    self.Frame = CreateFrame("Frame", "SequitoDungeonTimerFrame", UIParent)
    self.Frame:SetSize(280, 350)
    self.Frame:SetPoint("CENTER", UIParent, "CENTER", 0, 0)
    self.Frame:SetFrameStrata("HIGH")
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
    self.Frame.bg:SetVertexColor(0, 0, 0, 0.9)
    
    -- Borde
    self.Frame.border = CreateFrame("Frame", nil, self.Frame)
    self.Frame.border:SetAllPoints()
    self.Frame.border:SetBackdrop({
        edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
        edgeSize = 14,
    })
    self.Frame.border:SetBackdropBorderColor(0.4, 0.6, 0.8, 1)
    
    -- Título
    self.Frame.title = self.Frame:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
    self.Frame.title:SetPoint("TOP", self.Frame, "TOP", 0, -10)
    self.Frame.title:SetText("|cFF6699FFDungeon Timer|r")
    
    -- Botón cerrar
    self.Frame.closeBtn = CreateFrame("Button", nil, self.Frame, "UIPanelCloseButton")
    self.Frame.closeBtn:SetPoint("TOPRIGHT", self.Frame, "TOPRIGHT", -2, -2)
    self.Frame.closeBtn:SetScript("OnClick", function() self.Frame:Hide() end)
    
    -- Timer de reset
    self.Frame.resetTimer = self.Frame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    self.Frame.resetTimer:SetPoint("TOPLEFT", self.Frame, "TOPLEFT", 15, -35)
    self.Frame.resetTimer:SetText("|cFFFFFF00Reset en:|r Calculando...")
    
    -- Daily status
    self.Frame.dailyStatus = self.Frame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    self.Frame.dailyStatus:SetPoint("TOPLEFT", self.Frame.resetTimer, "BOTTOMLEFT", 0, -5)
    self.Frame.dailyStatus:SetText("")
    
    -- Separador
    self.Frame.sep = self.Frame:CreateTexture(nil, "ARTWORK")
    self.Frame.sep:SetSize(250, 1)
    self.Frame.sep:SetPoint("TOPLEFT", self.Frame.dailyStatus, "BOTTOMLEFT", 0, -10)
    self.Frame.sep:SetTexture("Interface\\Buttons\\WHITE8X8")
    self.Frame.sep:SetVertexColor(0.5, 0.5, 0.5, 0.5)
    
    -- Header de dungeons
    self.Frame.dungeonHeader = self.Frame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    self.Frame.dungeonHeader:SetPoint("TOPLEFT", self.Frame.sep, "BOTTOMLEFT", 0, -10)
    self.Frame.dungeonHeader:SetText("|cFF00FFFFHeroicas Completadas:|r")
    
    -- Lista de dungeons (scroll frame)
    self.Frame.scrollFrame = CreateFrame("ScrollFrame", "SequitoDTListScroll", self.Frame, "UIPanelScrollFrameTemplate")
    self.Frame.scrollFrame:SetSize(240, 200)
    self.Frame.scrollFrame:SetPoint("TOPLEFT", self.Frame.dungeonHeader, "BOTTOMLEFT", 0, -5)
    
    self.Frame.scrollChild = CreateFrame("Frame", nil, self.Frame.scrollFrame)
    self.Frame.scrollChild:SetSize(240, 400)
    self.Frame.scrollFrame:SetScrollChild(self.Frame.scrollChild)
    
    -- Crear filas de dungeons
    self.Frame.dungeonRows = {}
    for i, dungeon in ipairs(HEROIC_DUNGEONS) do
        local row = CreateFrame("Frame", nil, self.Frame.scrollChild)
        row:SetSize(230, 18)
        row:SetPoint("TOPLEFT", self.Frame.scrollChild, "TOPLEFT", 0, -(i-1) * 20)
        
        -- Checkbox
        row.check = row:CreateTexture(nil, "ARTWORK")
        row.check:SetSize(14, 14)
        row.check:SetPoint("LEFT", row, "LEFT", 0, 0)
        row.check:SetTexture("Interface\\Buttons\\UI-CheckBox-Check")
        row.check:Hide()
        
        -- Nombre
        row.name = row:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
        row.name:SetPoint("LEFT", row.check, "RIGHT", 5, 0)
        row.name:SetText(dungeon.abbrev .. " - " .. dungeon.name)
        row.name:SetTextColor(0.7, 0.7, 0.7)
        
        row.dungeonId = dungeon.id
        self.Frame.dungeonRows[i] = row
    end
    
    -- Botón de reset manual
    local resetBtn = CreateFrame("Button", nil, self.Frame)
    resetBtn:SetSize(100, 24)
    resetBtn:SetPoint("BOTTOM", self.Frame, "BOTTOM", 0, 15)
    
    resetBtn.bg = resetBtn:CreateTexture(nil, "BACKGROUND")
    resetBtn.bg:SetAllPoints()
    resetBtn.bg:SetTexture("Interface\\Buttons\\WHITE8X8")
    resetBtn.bg:SetVertexColor(0.3, 0.3, 0.5, 0.8)
    
    resetBtn.text = resetBtn:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    resetBtn.text:SetPoint("CENTER")
    resetBtn.text:SetText("Resetear Lista")
    
    resetBtn:SetHighlightTexture("Interface\\Buttons\\UI-Listbox-Highlight")
    resetBtn:SetScript("OnClick", function() DT:ResetCompleted() end)
    
    self.Frame.resetBtn = resetBtn
    
    -- OnUpdate para timer
    self.Frame:SetScript("OnUpdate", function(frame, elapsed)
        self:OnUpdate(elapsed)
    end)
    
    self.updateTimer = 0
end

function DT:RegisterEvents()
    local eventFrame = CreateFrame("Frame")
    eventFrame:RegisterEvent("PLAYER_ENTERING_WORLD")
    eventFrame:RegisterEvent("LFG_COMPLETION_REWARD")
    eventFrame:RegisterEvent("ZONE_CHANGED_NEW_AREA")
    
    eventFrame:SetScript("OnEvent", function(self, event, ...)
        if event == "PLAYER_ENTERING_WORLD" then
            DT:CheckDailyReset()
            DT:UpdateDisplay()
        elseif event == "LFG_COMPLETION_REWARD" then
            DT:OnDungeonComplete()
        elseif event == "ZONE_CHANGED_NEW_AREA" then
            DT:CheckCurrentDungeon()
        end
    end)
    
    -- Detección real de bosses en 3.3.5a vía CLEU Dispatcher
    if S.CLEU and S.CLEU.Register then
        S.CLEU:Register("UNIT_DIED", function(...)
            local _, _, _, _, _, destGUID, destName = ...
            if destGUID and destName then
                local unitType = tonumber(destGUID:sub(5, 5), 16)
                if unitType == 3 or unitType == 5 then -- Creature/Vehicle
                    local _, instanceType, difficultyID = GetInstanceInfo()
                    if instanceType == "party" or instanceType == "raid" then
                        DT:OnBossKill(destName)
                    end
                end
            end
        end)
    end
end

function DT:LoadSavedData()
    if SequitoDB and SequitoDB.DungeonTimer then
        self.CompletedDungeons = SequitoDB.DungeonTimer.completed or {}
        self.DailyReset = SequitoDB.DungeonTimer.dailyReset or 0
    end
end

function DT:SaveData()
    if not SequitoDB then SequitoDB = {} end
    if not SequitoDB.DungeonTimer then SequitoDB.DungeonTimer = {} end
    
    SequitoDB.DungeonTimer.completed = self.CompletedDungeons
    SequitoDB.DungeonTimer.dailyReset = self.DailyReset
end

function DT:CalculateResetTime()
    local serverTime = (GetServerTime and GetServerTime()) or time()
    local resetSec = GetQuestResetTime and GetQuestResetTime()
    if resetSec and resetSec > 0 then
        self.DailyReset = serverTime + resetSec
        return
    end

    -- El reset diario es a las 3:00 AM hora del servidor (fallback aproximado)
    -- En WotLK privados puede variar
    local resetHour = 3 -- 3 AM
    
    -- Calcular próximo reset
    local date = date("*t", serverTime)
    local todayReset = time({
        year = date.year,
        month = date.month,
        day = date.day,
        hour = resetHour,
        min = 0,
        sec = 0
    })
    
    if serverTime >= todayReset then
        -- El reset de hoy ya pasó, calcular el de mañana
        self.DailyReset = todayReset + 86400 -- +24 horas
    else
        self.DailyReset = todayReset
    end
end

function DT:CheckDailyReset()
    local serverTime = GetServerTime()
    
    if serverTime >= self.DailyReset then
        -- Reset ocurrió, limpiar dungeons completados
        wipe(self.CompletedDungeons)
        self:CalculateResetTime()
        self:SaveData()
        
        -- Notificar si está habilitado
        if self:GetOption("notifyOnReset") and S.Print then
            S:Print("|cFF00FF00¡Reset diario! Lista de heroicas limpiada.|r")
        end
    end
end

function DT:OnUpdate(elapsed)
    self.updateTimer = self.updateTimer + elapsed
    if self.updateTimer < 1 then return end
    self.updateTimer = 0
    
    self:UpdateResetTimer()
end

function DT:UpdateResetTimer()
    local serverTime = GetServerTime()
    local timeLeft = self.DailyReset - serverTime
    
    if timeLeft <= 0 then
        self:CheckDailyReset()
        return
    end
    
    local hours = math.floor(timeLeft / 3600)
    local mins = math.floor((timeLeft % 3600) / 60)
    local secs = timeLeft % 60
    
    self.Frame.resetTimer:SetText(string.format(
        "|cFFFFFF00Reset en:|r |cFFFFFFFF%02d:%02d:%02d|r",
        hours, mins, secs
    ))
end

function DT:OnDungeonComplete()
    local instanceName = GetInstanceInfo()
    self:MarkDungeonComplete(instanceName)
end

function DT:OnBossKill(bossName)
    -- Verificar si tracking está habilitado
    if not self:GetOption("trackLockouts") then
        return
    end
    
    -- Verificar si estamos en una heroica
    local name, instanceType, difficultyID = GetInstanceInfo()
    if difficultyID == 2 then -- Heroic 5-man
        -- Marcar como completada después del último boss
        -- (simplificado: marcamos en cualquier boss kill)
    end
end

function DT:CheckCurrentDungeon()
    local name, instanceType, difficultyID, difficultyName, 
          maxPlayers, dynamicDifficulty, isDynamic, instanceID = GetInstanceInfo()
    
    if instanceType == "party" and difficultyID == 2 then
        -- Estamos en una heroica
        if S.Print then
            S:Print(string.format("|cFF6699FF[Dungeon]|r Entrando a: %s (Heroica)", name))
        end
    end
end

function DT:MarkDungeonComplete(dungeonName)
    -- Buscar el dungeon por nombre
    for _, dungeon in ipairs(HEROIC_DUNGEONS) do
        if dungeon.name == dungeonName or string.find(dungeonName, dungeon.abbrev) then
            self.CompletedDungeons[dungeon.id] = {
                name = dungeon.name,
                time = GetServerTime(),
            }
            self:SaveData()
            self:UpdateDisplay()
            
            self.lastRunCompleted = true
            if S.EcosystemBridge and S.EcosystemBridge.NotifyDungeonComplete then
                S.EcosystemBridge:NotifyDungeonComplete()
            end

            if S.Print then
                S:Print(string.format("|cFF00FF00✓|r %s completada.", dungeon.name))
            end
            return
        end
    end
end

function DT:MarkComplete(dungeonId)
    for _, dungeon in ipairs(HEROIC_DUNGEONS) do
        if dungeon.id == dungeonId then
            self.CompletedDungeons[dungeon.id] = {
                name = dungeon.name,
                time = GetServerTime(),
            }
            self:SaveData()
            self:UpdateDisplay()
            
            if S.Print then
                S:Print(string.format("|cFF00FF00✓|r %s marcada como completada.", dungeon.name))
            end
            return
        end
    end
end

function DT:MarkIncomplete(dungeonId)
    if self.CompletedDungeons[dungeonId] then
        local name = self.CompletedDungeons[dungeonId].name
        self.CompletedDungeons[dungeonId] = nil
        self:SaveData()
        self:UpdateDisplay()
        
        if S.Print then
            S:Print(string.format("|cFFFF6600✗|r %s desmarcada.", name))
        end
    end
end

function DT:ResetCompleted()
    wipe(self.CompletedDungeons)
    self:SaveData()
    self:UpdateDisplay()
    
    if S.Print then
        S:Print("Lista de heroicas reseteada.")
    end
end

function DT:UpdateDisplay()
    if not self.Frame:IsShown() then return end
    
    -- Actualizar filas de dungeons
    for i, row in ipairs(self.Frame.dungeonRows) do
        local dungeon = HEROIC_DUNGEONS[i]
        if dungeon then
            if self.CompletedDungeons[dungeon.id] then
                row.check:Show()
                row.name:SetTextColor(0.3, 0.8, 0.3)
            else
                row.check:Hide()
                row.name:SetTextColor(0.7, 0.7, 0.7)
            end
        end
    end
    
    -- Actualizar contador
    local completed = 0
    for _ in pairs(self.CompletedDungeons) do
        completed = completed + 1
    end
    
    self.Frame.dailyStatus:SetText(string.format(
        "|cFF00FFFFCompletadas:|r %d / %d",
        completed, #HEROIC_DUNGEONS
    ))
end

function DT:GetCompletedCount()
    local count = 0
    for _ in pairs(self.CompletedDungeons) do
        count = count + 1
    end
    return count, #HEROIC_DUNGEONS
end

function DT:GetTimeToReset()
    local serverTime = GetServerTime()
    return math.max(0, self.DailyReset - serverTime)
end

function DT:GetTimeToResetFormatted()
    local timeLeft = self:GetTimeToReset()
    local hours = math.floor(timeLeft / 3600)
    local mins = math.floor((timeLeft % 3600) / 60)
    return string.format("%dh %dm", hours, mins)
end

function DT:Toggle()
    if not self.Frame then return end
    if self.Frame:IsShown() then
        self.Frame:Hide()
    else
        self.Frame:Show()
        self:UpdateDisplay()
        self:UpdateResetTimer()
    end
end

function DT:PrintStatus()
    local completed, total = self:GetCompletedCount()
    local resetTime = self:GetTimeToResetFormatted()
    
    if S.Print then
        S:Print(string.format("|cFF6699FF[Dungeon Timer]|r Completadas: %d/%d | Reset en: %s",
            completed, total, resetTime))
    end
    
    -- Listar completadas
    for id, data in pairs(self.CompletedDungeons) do
        if S.Print then
            S:Print(string.format("  |cFF00FF00✓|r %s", data.name))
        end
    end
end

-- Tooltip para la esfera
function DT:GetTooltipText()
    local completed, total = self:GetCompletedCount()
    local resetTime = self:GetTimeToResetFormatted()
    
    return string.format("Heroicas: %d/%d\nReset: %s", completed, total, resetTime)
end

-- Registrar configuración en ModuleConfig
if S.ModuleConfig then
    S.ModuleConfig:RegisterModule("DungeonTimer", {
        name = "Dungeon Timer",
        icon = "Interface\\Icons\\INV_Misc_PocketWatch_01",
        description = "Trackea lockouts de dungeons y tiempo para reset diario",
        category = "dungeon",
        options = {
            {
                type = "checkbox",
                key = "enabled",
                label = "Habilitar Dungeon Timer",
                tooltip = "Activa/desactiva el tracker de dungeons",
                default = true,
            },
            {
                type = "checkbox",
                key = "showReminders",
                label = "Mostrar Recordatorios",
                tooltip = "Muestra recordatorios de dungeons disponibles",
                default = true,
            },
            {
                type = "checkbox",
                key = "trackLockouts",
                label = "Trackear Lockouts",
                tooltip = "Registra qué dungeons ya completaste",
                default = true,
            },
            {
                type = "checkbox",
                key = "showInTooltip",
                label = "Mostrar en Tooltip",
                tooltip = "Muestra info de dungeons en el tooltip de la esfera",
                default = true,
            },
            {
                type = "checkbox",
                key = "notifyOnReset",
                label = "Notificar en Reset",
                tooltip = "Notifica cuando se resetean los lockouts diarios",
                default = true,
            },
            {
                type = "slider",
                key = "reminderTime",
                label = "Tiempo Recordatorio (min)",
                tooltip = "Cuánto tiempo antes del reset mostrar recordatorio",
                min = 15,
                max = 120,
                step = 15,
                default = 60,
            },
        },
    })
end

-- Inicializar
if S.RegisterModule then
    S:RegisterModule("DungeonTimer", DT)
else
    local initFrame = CreateFrame("Frame")
    initFrame:RegisterEvent("PLAYER_LOGIN")
    initFrame:SetScript("OnEvent", function()
        DT:Initialize()
    end)
end
