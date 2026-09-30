--[[
    SEQUITO - Raid Assist UI
    Interface for raid assistance features
]]--

local addonName, S = ...
S.RaidAssistUI = {}
local RAUI = S.RaidAssistUI

-- Helper para obtener configuración
function RAUI:GetOption(key)
    if S.ModuleConfig then
        return S.ModuleConfig:GetValue("RaidAssistUI", key)
    end
    return true
end

function RAUI:Initialize()
    if self.initialized then return end
    if not self:GetOption("enabled") then
        return
    end
    self.initialized = true
    
    self:CreateMainWindow()
    self:CreateLeaderPanel()
    
    -- Register Slash Command
    SLASH_SEQUITORAU1 = "/sra"
    SLASH_SEQUITORAU2 = "/seqassist"
    SlashCmdList["SEQUITORAU"] = function()
        if not self.mainFrame then self:CreateMainWindow() end
        if self.mainFrame:IsShown() then self.mainFrame:Hide() else self.mainFrame:Show() end
    end
    
    -- Auto-show en raid si está habilitado
    if self:GetOption("autoShow") then
        local eventFrame = CreateFrame("Frame")
        eventFrame:RegisterEvent("PLAYER_ENTERING_WORLD")
        eventFrame:RegisterEvent("RAID_ROSTER_UPDATE")
        eventFrame:SetScript("OnEvent", function(self, event)
            if (GetNumRaidMembers() > 0) and RAUI.mainFrame then
                RAUI.mainFrame:Show()
            end
        end)
    end
    
    print("|cFF9900FFSequito RaidAssistUI|r: Online.")
end

-- ============================================
-- MAIN RAID ASSIST WINDOW
-- ============================================

function RAUI:CreateMainWindow()
    local f = CreateFrame("Frame", "SequitoRaidAssistFrame", UIParent)
    f:SetSize(400, 500)
    f:SetPoint("CENTER")
    f:SetBackdrop({
        bgFile = "Interface\\DialogFrame\\UI-DialogBox-Background",
        edgeFile = "Interface\\DialogFrame\\UI-DialogBox-Border",
        tile = true, tileSize = 32, edgeSize = 32,
        insets = {left = 8, right = 8, top = 8, bottom = 8}
    })
    f:SetFrameStrata("HIGH") -- Ensure it's above other windows
    f:SetMovable(true)
    f:EnableMouse(true)
    f:RegisterForDrag("LeftButton")
    f:SetScript("OnDragStart", f.StartMoving)
    f:SetScript("OnDragStop", f.StopMovingOrSizing)
    f:Hide()
    
    -- Title
    f.title = f:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
    f.title:SetPoint("TOP", 0, -15)
    f.title:SetText(S.L["SEQUITO_RAIDASSIST"] or "Sequito Asistente de Raid")
    
    -- Close button
    f.closeBtn = CreateFrame("Button", nil, f, "UIPanelCloseButton")
    f.closeBtn:SetPoint("TOPRIGHT", -5, -5)
    
    -- Store mainFrame BEFORE creating tabs
    self.mainFrame = f
    
    -- Tabs
    self:CreateTabs(f)
end

function RAUI:CreateTabs(parent)
    local tabs = {
        {name = S.L["TAB_STATUS"] or "Estado", content = "CreateStatusTab"},
        {name = S.L["TAB_COOLDOWNS"] or "Cooldowns", content = "CreateCooldownsTab"},
        {name = S.L["TAB_ASSIGNMENTS"] or "Asignaciones", content = "CreateAssignmentsTab"},
        {name = S.L["TAB_STATS"] or "Estadísticas", content = "CreateStatsTab"},
    }
    
    parent.tabs = {}
    parent.tabContents = {}
    
    for i, tabInfo in ipairs(tabs) do
        local tab = CreateFrame("Button", nil, parent)
        tab:SetSize(90, 25)
        tab:SetPoint("TOPLEFT", 10 + (i-1)*95, -40)
        tab:SetNormalTexture("Interface\\PaperDollInfoFrame\\UI-Character-Tab-Enabled")
        tab:SetHighlightTexture("Interface\\PaperDollInfoFrame\\UI-Character-Tab-Highlight")
        
        tab.text = tab:CreateFontString(nil, "OVERLAY", "GameFontNormal")
        tab.text:SetPoint("CENTER")
        tab.text:SetText(tabInfo.name)
        
        tab:SetScript("OnClick", function()
            RAUI:ShowTab(i)
        end)
        
        parent.tabs[i] = tab
        
        -- Create content frame
        local content = CreateFrame("Frame", nil, parent)
        content:SetPoint("TOPLEFT", 10, -70)
        content:SetPoint("BOTTOMRIGHT", -10, 10)
        content:Hide()
        
        if self[tabInfo.content] then
            self[tabInfo.content](self, content)
        end
        
        parent.tabContents[i] = content
    end
    
    self:ShowTab(1)
end

function RAUI:ShowTab(index)
    local f = self.mainFrame
    for i, content in ipairs(f.tabContents) do
        if i == index then
            content:Show()
        else
            content:Hide()
        end
    end
end

-- ============================================
-- STATUS TAB
-- ============================================

function RAUI:CreateStatusTab(parent)
    -- Users with Sequito
    local usersLabel = parent:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
    usersLabel:SetPoint("TOPLEFT", 10, -10)
    usersLabel:SetText(S.L["USERS_WITH_SEQUITO"] or "Usuarios con Sequito:")
    
    local usersList = CreateFrame("ScrollFrame", "SequitoRAUsersScrollFrame", parent, "UIPanelScrollFrameTemplate")
    usersList:SetPoint("TOPLEFT", 10, -35)
    usersList:SetSize(360, 150)
    
    local usersContent = CreateFrame("Frame", nil, usersList)
    usersContent:SetSize(360, 150)
    usersList:SetScrollChild(usersContent)
    
    parent.usersList = usersContent
    
    -- Consumables status
    local consumablesLabel = parent:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
    consumablesLabel:SetPoint("TOPLEFT", 10, -200)
    consumablesLabel:SetText(S.L["CONSUMABLES_STATUS"] or "Estado de Consumibles:")
    
    local consumablesList = CreateFrame("ScrollFrame", "SequitoRAConsumablesScrollFrame", parent, "UIPanelScrollFrameTemplate")
    consumablesList:SetPoint("TOPLEFT", 10, -225)
    consumablesList:SetSize(360, 150)
    
    local consumablesContent = CreateFrame("Frame", nil, consumablesList)
    consumablesContent:SetSize(360, 150)
    consumablesList:SetScrollChild(consumablesContent)
    
    parent.consumablesList = consumablesContent
    
    -- Update button
    local updateBtn = CreateFrame("Button", nil, parent, "UIPanelButtonTemplate")
    updateBtn:SetSize(100, 25)
    updateBtn:SetPoint("BOTTOM", 0, 10)
    updateBtn:SetText(S.L["UPDATE"] or "Actualizar")
    updateBtn:SetScript("OnClick", function()
        RAUI:UpdateStatusTab()
    end)
end

function RAUI:UpdateStatusTab()
    local content = self.mainFrame.tabContents[1]
    if not content then return end
    
    -- Update users list
    local usersList = content.usersList
    usersList:Hide()
    usersList:Show()
    
    local y = 0
    for name, info in pairs(S.RaidAssist.users) do
        local text = usersList:CreateFontString(nil, "OVERLAY", "GameFontNormal")
        text:SetPoint("TOPLEFT", 5, y)
        text:SetText(string.format("%s (v%s)", name, info.version))
        y = y - 20
    end
    
    -- Update consumables
    local consumablesList = content.consumablesList
    consumablesList:Hide()
    consumablesList:Show()
    
    y = 0
    for name, status in pairs(S.RaidAssist.consumables) do
        local flaskIcon = status.flask and "|cFF00FF00✓|r" or "|cFFFF0000X|r"
        local foodIcon = status.food and "|cFF00FF00✓|r" or "|cFFFF0000X|r"
        
        local text = consumablesList:CreateFontString(nil, "OVERLAY", "GameFontNormal")
        text:SetPoint("TOPLEFT", 5, y)
        text:SetText(string.format("%s - Flask:%s Food:%s", name, flaskIcon, foodIcon))
        y = y - 20
    end
end

-- ============================================
-- COOLDOWNS TAB
-- ============================================

function RAUI:CreateCooldownsTab(parent)
    local label = parent:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
    label:SetPoint("TOPLEFT", 10, -10)
    label:SetText(S.L["IMPORTANT_COOLDOWNS"] or "Cooldowns Importantes:")
    
    local scroll = CreateFrame("ScrollFrame", "SequitoRACooldownsScrollFrame", parent, "UIPanelScrollFrameTemplate")
    scroll:SetPoint("TOPLEFT", 10, -35)
    scroll:SetPoint("BOTTOMRIGHT", -30, 40)
    
    local content = CreateFrame("Frame", nil, scroll)
    content:SetSize(360, 400)
    scroll:SetScrollChild(content)
    
    parent.cooldownsList = content
    
    -- Update button
    local updateBtn = CreateFrame("Button", nil, parent, "UIPanelButtonTemplate")
    updateBtn:SetSize(100, 25)
    updateBtn:SetPoint("BOTTOM", 0, 10)
    updateBtn:SetText(S.L["UPDATE"] or "Actualizar")
    updateBtn:SetScript("OnClick", function()
        RAUI:UpdateCooldownsTab()
    end)
end

function RAUI:UpdateCooldownsTab()
    local content = self.mainFrame.tabContents[2]
    if not content or not content.cooldownsList then return end
    
    local list = content.cooldownsList
    list:Hide()
    list:Show()
    
    local y = 0
    for name, cds in pairs(S.RaidAssist.cooldowns) do
        for spellName, info in pairs(cds) do
            -- spellName is already the spell name (not ID) in 3.3.5
            local text = list:CreateFontString(nil, "OVERLAY", "GameFontNormal")
            text:SetPoint("TOPLEFT", 5, y)
            
            local remaining = info.remaining
            local color = remaining > 60 and "|cFFFF0000" or "|cFFFFFF00"
            
            text:SetText(string.format("%s - %s: %s%ds|r", name, spellName, color, remaining))
            y = y - 20
        end
    end
end

-- ============================================
-- ASSIGNMENTS TAB
-- ============================================

function RAUI:CreateAssignmentsTab(parent)
    local label = parent:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
    label:SetPoint("TOPLEFT", 10, -10)
    label:SetText(S.L["RAID_ASSIGNMENTS"] or "Asignaciones de Raid:")
    
    local scroll = CreateFrame("ScrollFrame", "SequitoRAAssignmentsScrollFrame", parent, "UIPanelScrollFrameTemplate")
    scroll:SetPoint("TOPLEFT", 10, -35)
    scroll:SetPoint("BOTTOMRIGHT", -30, 10)
    
    local content = CreateFrame("Frame", nil, scroll)
    content:SetSize(360, 400)
    scroll:SetScrollChild(content)
    
    parent.assignmentsList = content
end

-- ============================================
-- STATS TAB
-- ============================================

function RAUI:CreateStatsTab(parent)
    local wipeLabel = parent:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
    wipeLabel:SetPoint("TOPLEFT", 10, -10)
    wipeLabel:SetText(S.L["SESSION_STATS"] or "Estadísticas de Sesión:")
    
    parent.wipeCount = parent:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    parent.wipeCount:SetPoint("TOPLEFT", 10, -40)
    parent.wipeCount:SetText((S.L["WIPES"] or "Wipes") .. ": 0")
    
    parent.mode = parent:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    parent.mode:SetPoint("TOPLEFT", 10, -60)
    parent.mode:SetText((S.L["MODE"] or "Modo") .. ": FARM")
    
    -- Reset button
    local resetBtn = CreateFrame("Button", nil, parent, "UIPanelButtonTemplate")
    resetBtn:SetSize(150, 25)
    resetBtn:SetPoint("TOPLEFT", 10, -90)
    resetBtn:SetText(S.L["RESET_COUNTER"] or "Reset Contador")
    resetBtn:SetScript("OnClick", function()
        S.RaidAssist:ResetWipeCounter()
        RAUI:UpdateStatsTab()
    end)
    
    -- Mode toggle
    local modeBtn = CreateFrame("Button", nil, parent, "UIPanelButtonTemplate")
    modeBtn:SetSize(150, 25)
    modeBtn:SetPoint("TOPLEFT", 10, -120)
    modeBtn:SetText(S.L["CHANGE_MODE"] or "Cambiar Modo")
    modeBtn:SetScript("OnClick", function()
        local newMode = S.RaidAssist.mode == "FARM" and "PROGRESSION" or "FARM"
        S.RaidAssist:SetMode(newMode)
        RAUI:UpdateStatsTab()
    end)
end

function RAUI:UpdateStatsTab()
    local content = self.mainFrame.tabContents[4]
    if not content then return end
    
    content.wipeCount:SetText((S.L["WIPES"] or "Wipes") .. ": " .. (S.RaidAssist.wipeCount or 0))
    content.mode:SetText((S.L["MODE"] or "Modo") .. ": " .. (S.RaidAssist.mode or "FARM"))
end

-- ============================================
-- LEADER PANEL (Compact)
-- ============================================

function RAUI:CreateLeaderPanel()
    local f = CreateFrame("Frame", "SequitoLeaderPanel", UIParent)
    f:SetSize(200, 150)
    f:SetPoint("TOPRIGHT", -50, -200)
    f:SetBackdrop({
        bgFile = "Interface\\Tooltips\\UI-Tooltip-Background",
        edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
        tile = true, tileSize = 16, edgeSize = 16,
        insets = {left = 4, right = 4, top = 4, bottom = 4}
    })
    f:SetBackdropColor(0, 0, 0, 0.8)
    f:SetFrameStrata("HIGH")
    f:SetMovable(true)
    f:EnableMouse(true)
    f:RegisterForDrag("LeftButton")
    f:SetScript("OnDragStart", f.StartMoving)
    f:SetScript("OnDragStop", f.StopMovingOrSizing)
    f:Hide()
    
    -- Title
    f.title = f:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    f.title:SetPoint("TOP", 0, -10)
    f.title:SetText(S.L["RAID_LEADER"] or "Raid Leader")
    
    -- Pull timer button
    local pullBtn = CreateFrame("Button", nil, f, "UIPanelButtonTemplate")
    pullBtn:SetSize(180, 25)
    pullBtn:SetPoint("TOP", 0, -30)
    pullBtn:SetText(S.L["PULL_TIMER_10S"] or "Pull Timer (10s)")
    pullBtn:SetScript("OnClick", function()
        S.RaidAssist:StartPullTimer(10)
    end)
    
    -- Announce phase button
    local phaseBtn = CreateFrame("Button", nil, f, "UIPanelButtonTemplate")
    phaseBtn:SetSize(180, 25)
    phaseBtn:SetPoint("TOP", 0, -60)
    phaseBtn:SetText(S.L["ANNOUNCE_PHASE_2"] or "Anunciar Fase 2")
    phaseBtn:SetScript("OnClick", function()
        S.RaidAssist:AnnouncePhase("2")
    end)
    
    -- Check consumables button
    local checkBtn = CreateFrame("Button", nil, f, "UIPanelButtonTemplate")
    checkBtn:SetSize(180, 25)
    checkBtn:SetPoint("TOP", 0, -90)
    checkBtn:SetText(S.L["CHECK_CONSUMABLES"] or "Revisar Consumibles")
    checkBtn:SetScript("OnClick", function()
        S.RaidAssist:CheckConsumables()
        local report = S.RaidAssist:GetConsumableReport()
        S:Print(S.L["CONSUMABLES_REPORT"] or "=== Reporte de Consumibles ===")
        S:Print(report)
    end)
    
    -- Open full window button
    local openBtn = CreateFrame("Button", nil, f, "UIPanelButtonTemplate")
    openBtn:SetSize(180, 25)
    openBtn:SetPoint("TOP", 0, -120)
    openBtn:SetText(S.L["OPEN_FULL_PANEL"] or "Abrir Panel Completo")
    openBtn:SetScript("OnClick", function()
        RAUI:Toggle()
    end)
    
    self.leaderPanel = f
end

-- ============================================
-- TOGGLE FUNCTIONS
-- ============================================

function RAUI:Toggle()
    if not self.mainFrame then
        S:Print("RaidAssistUI no está habilitado.")
        return
    end
    
    if self.mainFrame:IsShown() then
        self.mainFrame:Hide()
    else
        self.mainFrame:Show()
        self:UpdateStatusTab()
    end
end

function RAUI:ToggleLeaderPanel()
    if not self.leaderPanel then
        S:Print("RaidAssistUI no está habilitado.")
        return
    end
    
    if self.leaderPanel:IsShown() then
        self.leaderPanel:Hide()
    else
        self.leaderPanel:Show()
    end
end

function RAUI:ShowLeaderPanel()
    if not self.leaderPanel then
        self:CreateLeaderPanel()
    end
    
    -- Check if player is raid leader or assistant
    local numRaid = GetNumRaidMembers()
    local isLeader = false
    
    if numRaid > 0 then
        -- In raid: check if leader or assistant
        isLeader = (UnitIsRaidOfficer("player") or IsRaidLeader())
    else
        -- Not in raid: allow opening for testing
        isLeader = true
    end
    
    if not isLeader then
        S:Print(S.L["NOT_RAID_LEADER"] or "Debes ser líder o asistente de raid")
        return
    end
    
    self.leaderPanel:Show()
end

-- Registrar módulo en ModuleConfig
if S.ModuleConfig then
    S.ModuleConfig:RegisterModule({
        id = "RaidAssistUI",
        name = "Raid Assist UI",
        description = "Interfaz de asistencia para líderes de raid",
        category = "raid",
        icon = "Interface\\Icons\\INV_Misc_GroupLooking",
        options = {
            {
                key = "enabled",
                type = "checkbox",
                name = "Habilitar Raid Assist UI",
                description = "Habilitar/deshabilitar interfaz de asistencia",
                default = true
            },
            {
                key = "autoShow",
                type = "checkbox",
                name = "Auto-Mostrar",
                description = "Mostrar automáticamente al entrar en raid",
                default = false
            },
            {
                key = "showOnlyLeader",
                type = "checkbox",
                name = "Solo Líder/Asistente",
                description = "Mostrar solo si eres líder o asistente",
                default = true
            },
            {
                key = "compactMode",
                type = "checkbox",
                name = "Modo Compacto",
                description = "Usar interfaz compacta",
                default = false
            },
            {
                key = "position",
                type = "dropdown",
                name = "Posición",
                description = "Posición de la ventana",
                values = {"CENTER", "TOP", "BOTTOM", "LEFT", "RIGHT"},
                default = "CENTER"
            }
        }
    })
end
