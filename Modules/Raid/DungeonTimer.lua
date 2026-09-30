--[[
    Sequito - DungeonTimer.lua
    Timer de Heroic/Daily Dungeons y Lockouts
    Version: 8.0.0 (Bilingual & Ecosystem Sync Edition)
    Compatibilidad: WotLK 3.3.5a (Build 12340) | Español (esES/esMX) & Inglés (enUS)
]]

local addonName, S = ...
S.DungeonTimer = {}
local DT = S.DungeonTimer

-- Estado
DT.Frame = nil
DT.CompletedDungeons = {}
DT.DailyReset = 0
DT.IsVisible = false
DT.lastRunCompleted = false

-- Función utilitaria para normalizar texto (sin tildes, minúsculas)
local function CleanString(str)
    if not str then return "" end
    local s = str:lower()
    s = s:gsub("á", "a"):gsub("é", "e"):gsub("í", "i"):gsub("ó", "o"):gsub("ú", "u"):gsub("ñ", "n")
    return s
end

-- Catálogo Maestro de Heroicas de WotLK (Soporte Bilingüe y Claves de Búsqueda)
local HEROIC_DUNGEONS = {
    { id = 574, name = "Fortaleza de Utgarde",      nameEn = "Utgarde Keep",              abbrev = "UK",   keys = {"utgarde keep", "fortaleza de utgarde"} },
    { id = 575, name = "Pináculo de Utgarde",       nameEn = "Utgarde Pinnacle",          abbrev = "UP",   keys = {"utgarde pinnacle", "pinaculo de utgarde"} },
    { id = 576, name = "El Nexo",                  nameEn = "The Nexus",                 abbrev = "Nex",  keys = {"the nexus", "el nexo", "nexo"} },
    { id = 578, name = "El Oculus",                nameEn = "The Oculus",                abbrev = "Ocu",  keys = {"the oculus", "el oculus", "oculus"} },
    { id = 595, name = "La Matanza de Stratholme", nameEn = "The Culling of Stratholme", abbrev = "CoS",  keys = {"the culling of stratholme", "matanza de stratholme", "stratholme"} },
    { id = 599, name = "Cámaras de Piedra",        nameEn = "Halls of Stone",            abbrev = "HoS",  keys = {"halls of stone", "camaras de piedra"} },
    { id = 600, name = "Fortaleza de Drak'Tharon", nameEn = "Drak'Tharon Keep",          abbrev = "DTK",  keys = {"drak'tharon keep", "draktharon keep", "fortaleza de drak'tharon", "drak'tharon"} },
    { id = 601, name = "Azjol-Nerub",              nameEn = "Azjol-Nerub",               abbrev = "AN",   keys = {"azjol-nerub", "azjol nerub"} },
    { id = 602, name = "Cámaras de Relámpagos",    nameEn = "Halls of Lightning",        abbrev = "HoL",  keys = {"halls of lightning", "camaras de relampagos"} },
    { id = 604, name = "Gundrak",                  nameEn = "Gundrak",                   abbrev = "Gun",  keys = {"gundrak"} },
    { id = 608, name = "El Bastión Violeta",       nameEn = "The Violet Hold",           abbrev = "VH",   keys = {"the violet hold", "violet hold", "bastion violeta", "el bastion violeta"} },
    { id = 619, name = "Ahn'kahet: El Antiguo Reino", nameEn = "Ahn'kahet: The Old Kingdom", abbrev = "OK", keys = {"ahn'kahet", "the old kingdom", "antiguo reino"} },
    { id = 632, name = "La Forja de Almas",        nameEn = "The Forge of Souls",        abbrev = "FoS",  keys = {"the forge of souls", "forge of souls", "forja de almas", "la forja de almas"} },
    { id = 650, name = "Prueba del Campeón",       nameEn = "Trial of the Champion",     abbrev = "ToC5", keys = {"trial of the champion", "prueba del campeon"} },
    { id = 658, name = "Foso de Saron",            nameEn = "Pit of Saron",              abbrev = "PoS",  keys = {"pit of saron", "foso de saron"} },
    { id = 668, name = "Cámaras de Reflexión",     nameEn = "Halls of Reflection",       abbrev = "HoR",  keys = {"halls of reflection", "camaras de reflexion"} },
}

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
    self:SyncWithSavedInstances()
end

function DT:CreateFrame()
    local f = CreateFrame("Frame", "SequitoDungeonTimerFrame", UIParent)
    f:SetSize(300, 370)
    f:SetPoint("CENTER", UIParent, "CENTER", 0, 0)
    f:SetFrameStrata("HIGH")
    f:SetMovable(true)
    f:EnableMouse(true)
    f:RegisterForDrag("LeftButton")
    f:SetScript("OnDragStart", function(frame) frame:StartMoving() end)
    f:SetScript("OnDragStop", function(frame)
        frame:StopMovingOrSizing()
        if S.SmartDefaults then
            S.SmartDefaults:SavePosition("DungeonTimer", frame)
        end
    end)
    f:Hide()
    
    -- Fondo con respaldo unificado
    if S.Theme and S.Theme.ApplyPanelBackdrop then
        S.Theme:ApplyPanelBackdrop(f)
    else
        f.bg = f:CreateTexture(nil, "BACKGROUND")
        f.bg:SetAllPoints()
        f.bg:SetTexture("Interface\\Buttons\\WHITE8X8")
        f.bg:SetVertexColor(0, 0, 0, 0.9)
        
        f.border = CreateFrame("Frame", nil, f)
        f.border:SetAllPoints()
        f.border:SetBackdrop({
            edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
            edgeSize = 14,
        })
        f.border:SetBackdropBorderColor(0.4, 0.6, 0.8, 1)
    end
    
    -- Título
    f.title = f:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
    f.title:SetPoint("TOP", f, "TOP", 0, -10)
    f.title:SetText("|cFF6699FFHeroicas Diarias|r")
    
    -- Botón cerrar
    f.closeBtn = CreateFrame("Button", nil, f, "UIPanelCloseButton")
    f.closeBtn:SetPoint("TOPRIGHT", f, "TOPRIGHT", -2, -2)
    f.closeBtn:SetScript("OnClick", function() f:Hide() end)
    
    -- Timer de reset
    f.resetTimer = f:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    f.resetTimer:SetPoint("TOPLEFT", f, "TOPLEFT", 15, -35)
    f.resetTimer:SetText("|cFFFFFF00Reset en:|r Calculando...")
    
    -- Daily status
    f.dailyStatus = f:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    f.dailyStatus:SetPoint("TOPLEFT", f.resetTimer, "BOTTOMLEFT", 0, -5)
    f.dailyStatus:SetText("")
    
    -- Separador
    f.sep = f:CreateTexture(nil, "ARTWORK")
    f.sep:SetSize(270, 1)
    f.sep:SetPoint("TOPLEFT", f.dailyStatus, "BOTTOMLEFT", 0, -8)
    f.sep:SetTexture("Interface\\Buttons\\WHITE8X8")
    f.sep:SetVertexColor(0.5, 0.5, 0.5, 0.5)
    
    -- Header de dungeons
    f.dungeonHeader = f:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    f.dungeonHeader:SetPoint("TOPLEFT", f.sep, "BOTTOMLEFT", 0, -8)
    f.dungeonHeader:SetText("|cFF00FFFFHeroicas Completadas Hoy:|r")
    
    -- Lista de dungeons (scroll frame)
    f.scrollFrame = CreateFrame("ScrollFrame", "SequitoDTListScroll", f, "UIPanelScrollFrameTemplate")
    f.scrollFrame:SetSize(255, 210)
    f.scrollFrame:SetPoint("TOPLEFT", f.dungeonHeader, "BOTTOMLEFT", 0, -5)
    
    f.scrollChild = CreateFrame("Frame", nil, f.scrollFrame)
    f.scrollChild:SetSize(255, 360)
    f.scrollFrame:SetScrollChild(f.scrollChild)
    
    -- Crear filas de dungeons
    f.dungeonRows = {}
    for i, dungeon in ipairs(HEROIC_DUNGEONS) do
        local row = CreateFrame("Frame", nil, f.scrollChild)
        row:SetSize(250, 18)
        row:SetPoint("TOPLEFT", f.scrollChild, "TOPLEFT", 0, -(i-1) * 21)
        
        -- Checkbox
        row.check = row:CreateTexture(nil, "ARTWORK")
        row.check:SetSize(14, 14)
        row.check:SetPoint("LEFT", row, "LEFT", 0, 0)
        row.check:SetTexture("Interface\\Buttons\\UI-CheckBox-Check")
        row.check:Hide()
        
        -- Nombre
        row.name = row:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
        row.name:SetPoint("LEFT", row.check, "RIGHT", 5, 0)
        row.name:SetText(string.format("[%s] %s", dungeon.abbrev, dungeon.name))
        row.name:SetTextColor(0.7, 0.7, 0.7)
        
        row.dungeonId = dungeon.id
        f.dungeonRows[i] = row
    end
    
    -- Botón de sincronizar con servidor
    local syncBtn = CreateFrame("Button", nil, f, "UIPanelButtonTemplate")
    syncBtn:SetSize(120, 22)
    syncBtn:SetPoint("BOTTOMLEFT", f, "BOTTOMLEFT", 15, 12)
    syncBtn:SetText("Sincronizar")
    syncBtn:SetScript("OnClick", function()
        DT:SyncWithSavedInstances()
        if S.Print then S:Print("Sincronizado con bloqueos del servidor.") end
    end)
    
    -- Botón de reset manual
    local resetBtn = CreateFrame("Button", nil, f, "UIPanelButtonTemplate")
    resetBtn:SetSize(120, 22)
    resetBtn:SetPoint("BOTTOMRIGHT", f, "BOTTOMRIGHT", -15, 12)
    resetBtn:SetText("Resetear Lista")
    resetBtn:SetScript("OnClick", function() DT:ResetCompleted() end)
    
    f.syncBtn = syncBtn
    f.resetBtn = resetBtn
    
    f:SetScript("OnUpdate", function(_, elapsed)
        DT:OnUpdate(elapsed)
    end)
    
    self.Frame = f
    self.frame = f -- Conexión para SmartDefaults
    self.updateTimer = 0
    
    if S.SmartDefaults then
        S.SmartDefaults:RestorePosition("DungeonTimer")
    end
end

function DT:RegisterEvents()
    local eventFrame = CreateFrame("Frame")
    eventFrame:RegisterEvent("PLAYER_ENTERING_WORLD")
    eventFrame:RegisterEvent("LFG_COMPLETION_REWARD")
    eventFrame:RegisterEvent("ZONE_CHANGED_NEW_AREA")
    eventFrame:RegisterEvent("UPDATE_INSTANCE_INFO")
    
    eventFrame:SetScript("OnEvent", function(_, event)
        if event == "PLAYER_ENTERING_WORLD" then
            DT:CheckDailyReset()
            DT:SyncWithSavedInstances()
            DT:UpdateDisplay()
        elseif event == "LFG_COMPLETION_REWARD" then
            DT:OnDungeonComplete()
        elseif event == "ZONE_CHANGED_NEW_AREA" then
            DT:CheckCurrentDungeon()
        elseif event == "UPDATE_INSTANCE_INFO" then
            DT:SyncWithSavedInstances()
        end
    end)
    
    if S.CLEU and S.CLEU.Register then
        S.CLEU:Register("UNIT_DIED", function(...)
            local _, _, _, _, _, destGUID, destName = ...
            if destGUID and destName then
                local unitType = tonumber(destGUID:sub(5, 5), 16)
                if unitType == 3 or unitType == 5 then
                    local _, instanceType, difficultyID = GetInstanceInfo()
                    if instanceType == "party" and difficultyID == 2 then
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
    SequitoDB = SequitoDB or {}
    SequitoDB.DungeonTimer = SequitoDB.DungeonTimer or {}
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

    local dateT = date("*t", serverTime)
    local todayReset = time({
        year = dateT.year,
        month = dateT.month,
        day = dateT.day,
        hour = 4, -- 04:00 AM hora oficial de reinicio del Reino Andino
        min = 0,
        sec = 0
    })
    
    if serverTime >= todayReset then
        self.DailyReset = todayReset + 86400
    else
        self.DailyReset = todayReset
    end
end

function DT:CheckDailyReset()
    local serverTime = (GetServerTime and GetServerTime()) or time()
    
    if self.DailyReset > 0 and serverTime >= self.DailyReset then
        wipe(self.CompletedDungeons)
        self:CalculateResetTime()
        self:SaveData()
        self:UpdateDisplay()
        
        if self:GetOption("notifyOnReset") and S.Print then
            S:Print("|cFF00FF00¡Reset diario completado! Lista de heroicas limpiada.|r")
        end
    end
end

function DT:SyncWithSavedInstances()
    RequestRaidInfo()
    local count = GetNumSavedInstances()
    if not count or count == 0 then return end
    
    local anyAdded = false
    local sTime = (GetServerTime and GetServerTime()) or time()

    for i = 1, count do
        local name, _, reset, difficulty, locked, _, _, isRaid = GetSavedInstanceInfo(i)
        if difficulty == 2 and not isRaid and locked then
            local matched = self:MarkDungeonComplete(name, true)
            if matched then anyAdded = true end
            if reset and reset > 0 then
                local candidate = sTime + reset
                if self.DailyReset == 0 or candidate < self.DailyReset then
                    self.DailyReset = candidate
                end
            end
        end
    end
    
    if anyAdded then
        self:SaveData()
        self:UpdateDisplay()
    end
end

function DT:OnUpdate(elapsed)
    self.updateTimer = (self.updateTimer or 0) + elapsed
    if self.updateTimer < 1 then return end
    self.updateTimer = 0
    
    self:UpdateResetTimer()
end

function DT:UpdateResetTimer()
    if not self.Frame or not self.Frame:IsShown() then return end
    
    local serverTime = (GetServerTime and GetServerTime()) or time()
    local timeLeft = self.DailyReset - serverTime
    
    if timeLeft <= 0 then
        self:CheckDailyReset()
        return
    end
    
    local hours = math.floor(timeLeft / 3600)
    local mins  = math.floor((timeLeft % 3600) / 60)
    local secs  = timeLeft % 60
    
    self.Frame.resetTimer:SetText(string.format(
        "|cFFFFFF00Reset en:|r |cFFFFFFFF%02d:%02d:%02d|r",
        hours, mins, secs
    ))
end

function DT:OnDungeonComplete()
    local instanceName = GetInstanceInfo()
    self:MarkDungeonComplete(instanceName, false)
end

function DT:OnBossKill(bossName)
    if not self:GetOption("trackLockouts") then return end
    local name, instanceType, difficultyID = GetInstanceInfo()
    if instanceType == "party" and difficultyID == 2 then
        self:MarkDungeonComplete(name, false)
    end
end

function DT:CheckCurrentDungeon()
    local name, instanceType, difficultyID = GetInstanceInfo()
    if instanceType == "party" and difficultyID == 2 then
        if S.Print then
            S:Print(string.format("|cFF6699FF[Dungeon]|r Entrando a: %s (Heroica)", name))
        end
    end
end

function DT:MarkDungeonComplete(rawName, silent)
    if not rawName or rawName == "" then return false end
    local clean = CleanString(rawName)
    
    for _, dungeon in ipairs(HEROIC_DUNGEONS) do
        local matched = false
        if CleanString(dungeon.name) == clean or CleanString(dungeon.nameEn) == clean then
            matched = true
        else
            for _, key in ipairs(dungeon.keys) do
                if clean:find(key, 1, true) then
                    matched = true
                    break
                end
            end
        end
        
        if matched then
            local isNew = (self.CompletedDungeons[dungeon.id] == nil)
            self.CompletedDungeons[dungeon.id] = {
                name = dungeon.name,
                time = (GetServerTime and GetServerTime()) or time(),
            }
            self.lastRunCompleted = true
            
            -- Notificar al EcosystemBridge para alimentar el BattlePass
            if S.EcosystemBridge and S.EcosystemBridge.NotifyDungeonComplete then
                S.EcosystemBridge:NotifyDungeonComplete()
            end
            
            if isNew and not silent then
                self:SaveData()
                self:UpdateDisplay()
                if S.Print then
                    S:Print(string.format("|cFF00FF00[Dungeon]|r ¡%s completada!", dungeon.name))
                end
            end
            return true
        end
    end
    return false
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
    if not self.Frame or not self.Frame:IsShown() then return end
    
    for i, row in ipairs(self.Frame.dungeonRows) do
        local dungeon = HEROIC_DUNGEONS[i]
        if dungeon then
            if self.CompletedDungeons[dungeon.id] then
                row.check:Show()
                row.name:SetTextColor(0.3, 0.9, 0.3)
            else
                row.check:Hide()
                row.name:SetTextColor(0.65, 0.65, 0.65)
            end
        end
    end
    
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
    local serverTime = (GetServerTime and GetServerTime()) or time()
    return math.max(0, self.DailyReset - serverTime)
end

function DT:GetTimeToResetFormatted()
    local timeLeft = self:GetTimeToReset()
    local hours = math.floor(timeLeft / 3600)
    local mins  = math.floor((timeLeft % 3600) / 60)
    return string.format("%dh %dm", hours, mins)
end

function DT:Toggle()
    if not self.Frame then
        self:CreateFrame()
    end
    if self.Frame:IsShown() then
        self.Frame:Hide()
    else
        self.Frame:Show()
        self:SyncWithSavedInstances()
        self:UpdateDisplay()
        self:UpdateResetTimer()
    end
end

function DT:GetTooltipText()
    local completed, total = self:GetCompletedCount()
    local resetTime = self:GetTimeToResetFormatted()
    return string.format("Heroicas: %d/%d\nReset: %s", completed, total, resetTime)
end

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
                key = "trackLockouts",
                label = "Trackear Lockouts",
                tooltip = "Registra qué dungeons ya completaste",
                default = true,
            },
            {
                type = "checkbox",
                key = "notifyOnReset",
                label = "Notificar en Reset",
                tooltip = "Notifica cuando se resetean los lockouts diarios",
                default = true,
            },
        },
    })
end

if S.RegisterModule then
    S:RegisterModule("DungeonTimer", DT)
else
    local initFrame = CreateFrame("Frame")
    initFrame:RegisterEvent("PLAYER_LOGIN")
    initFrame:SetScript("OnEvent", function()
        DT:Initialize()
    end)
end
