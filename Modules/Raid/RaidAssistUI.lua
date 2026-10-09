--[[
    SEQUITO - Raid Assist UI
    Interface for raid assistance features
    Optimizado: Zero Heap FontString Pooling & Live Assignments
]]--

local addonName, S = ...
S.RaidAssistUI = {}
local RAUI = S.RaidAssistUI

-- Pools de reciclaje para evitar fugas de memoria y superposición de texto
local usersPool = {}
local consumablesPool = {}
local cooldownsPool = {}
local assignmentsPool = {}

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
        self:Toggle()
    end
    
    -- Auto-show en raid si está habilitado
    if self:GetOption("autoShow") then
        local eventFrame = CreateFrame("Frame")
        eventFrame:RegisterEvent("PLAYER_ENTERING_WORLD")
        eventFrame:RegisterEvent("RAID_ROSTER_UPDATE")
        eventFrame:SetScript("OnEvent", function()
            if (GetNumRaidMembers() > 0) and RAUI.mainFrame then
                local onlyLeader = RAUI:GetOption("showOnlyLeader")
                local isLeader = (IsRaidLeader and IsRaidLeader()) or (IsRaidOfficer and IsRaidOfficer())
                if not onlyLeader or isLeader then
                    RAUI.mainFrame:Show()
                    RAUI:UpdateCurrentTab()
                end
            end
        end)
    end
    
    if S.Print then
        S:Print("|cFF9900FFRaidAssistUI|r: Online.")
    end
end

-- ============================================
-- MAIN RAID ASSIST WINDOW
-- ============================================

function RAUI:CreateMainWindow()
    local f = CreateFrame("Frame", "JainaRaidAssistFrame", UIParent)
    f:SetSize(420, 520)
    f:SetPoint("CENTER")
    
    if S.Theme and S.Theme.ApplyPanelBackdrop then
        S.Theme:ApplyPanelBackdrop(f)
    else
        f:SetBackdrop({
            bgFile = "Interface\\DialogFrame\\UI-DialogBox-Background",
            edgeFile = "Interface\\DialogFrame\\UI-DialogBox-Border",
            tile = true, tileSize = 16, edgeSize = 16,
            insets = {left = 4, right = 4, top = 4, bottom = 4}
        })
    end
    
    f:SetFrameStrata("HIGH")
    f:SetMovable(true)
    f:EnableMouse(true)
    f:RegisterForDrag("LeftButton")
    f:SetScript("OnDragStart", f.StartMoving)
    f:SetScript("OnDragStop", function(self)
        self:StopMovingOrSizing()
        if S.SmartDefaults then
            S.SmartDefaults:SavePosition("RaidAssistUI", self)
        end
    end)
    f:Hide()
    
    -- Title
    f.title = f:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
    f.title:SetPoint("TOP", 0, -12)
    f.title:SetText(S.L["SEQUITO_RAIDASSIST"] or "Asistente de Banda")
    
    -- Close button
    f.closeBtn = CreateFrame("Button", nil, f, "UIPanelCloseButton")
    f.closeBtn:SetPoint("TOPRIGHT", -5, -5)
    f.closeBtn:SetScript("OnClick", function() f:Hide() end)
    
    self.mainFrame = f
    self.frame = f -- Exposición canónica para SmartDefaults
    
    if S.SmartDefaults then
        S.SmartDefaults:RestorePosition("RaidAssistUI")
    end
    
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
        tab:SetSize(95, 25)
        tab:SetPoint("TOPLEFT", 10 + (i-1)*98, -40)
        tab:SetNormalTexture("Interface\\PaperDollInfoFrame\\UI-Character-Tab-Enabled")
        tab:SetHighlightTexture("Interface\\PaperDollInfoFrame\\UI-Character-Tab-Highlight")
        
        tab.text = tab:CreateFontString(nil, "OVERLAY", "GameFontNormal")
        tab.text:SetPoint("CENTER")
        tab.text:SetText(tabInfo.name)
        
        tab:SetScript("OnClick", function()
            RAUI:ShowTab(i)
        end)
        
        parent.tabs[i] = tab
        
        -- Content frame
        local content = CreateFrame("Frame", nil, parent)
        content:SetPoint("TOPLEFT", 10, -70)
        content:SetPoint("BOTTOMRIGHT", -10, 10)
        content:Hide()
        
        if self[tabInfo.content] then
            self[tabInfo.content](self, content)
        end
        
        parent.tabContents[i] = content
    end
    
    self.currentTab = 1
    self:ShowTab(1)
end

function RAUI:ShowTab(index)
    local f = self.mainFrame
    if not f or not f.tabContents then return end
    
    self.currentTab = index
    for i, content in ipairs(f.tabContents) do
        if i == index then
            content:Show()
            if i == 1 then
                self:UpdateStatusTab()
            elseif i == 2 then
                self:UpdateCooldownsTab()
            elseif i == 3 then
                self:UpdateAssignmentsTab()
            elseif i == 4 then
                self:UpdateStatsTab()
            end
        else
            content:Hide()
        end
    end
end

function RAUI:UpdateCurrentTab()
    if self.mainFrame and self.mainFrame:IsShown() and self.currentTab then
        self:ShowTab(self.currentTab)
    end
end

-- ============================================
-- STATUS TAB (Reciclado en memoria)
-- ============================================

function RAUI:CreateStatusTab(parent)
    local usersLabel = parent:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
    usersLabel:SetPoint("TOPLEFT", 10, -10)
    usersLabel:SetText(S.L["USERS_WITH_SEQUITO"] or "Usuarios con el Addon:")
    
    local usersList = CreateFrame("ScrollFrame", "JainaRAUsersScrollFrame", parent, "UIPanelScrollFrameTemplate")
    usersList:SetPoint("TOPLEFT", 10, -35)
    usersList:SetSize(370, 140)
    
    local usersContent = CreateFrame("Frame", nil, usersList)
    usersContent:SetSize(370, 140)
    usersList:SetScrollChild(usersContent)
    parent.usersList = usersContent
    
    local consumablesLabel = parent:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
    consumablesLabel:SetPoint("TOPLEFT", 10, -185)
    consumablesLabel:SetText(S.L["CONSUMABLES_STATUS"] or "Estado de Consumibles:")
    
    local consumablesList = CreateFrame("ScrollFrame", "JainaRAConsumablesScrollFrame", parent, "UIPanelScrollFrameTemplate")
    consumablesList:SetPoint("TOPLEFT", 10, -210)
    consumablesList:SetSize(370, 170)
    
    local consumablesContent = CreateFrame("Frame", nil, consumablesList)
    consumablesContent:SetSize(370, 170)
    consumablesList:SetScrollChild(consumablesContent)
    parent.consumablesList = consumablesContent
    
    local updateBtn = CreateFrame("Button", nil, parent, "UIPanelButtonTemplate")
    updateBtn:SetSize(120, 24)
    updateBtn:SetPoint("BOTTOM", 0, 10)
    updateBtn:SetText(S.L["UPDATE"] or "Actualizar")
    updateBtn:SetScript("OnClick", function()
        RAUI:UpdateStatusTab()
    end)
end

function RAUI:UpdateStatusTab()
    local content = self.mainFrame and self.mainFrame.tabContents and self.mainFrame.tabContents[1]
    if not content or not S.RaidAssist then return end
    
    -- 1. Actualizar Usuarios
    for _, fs in ipairs(usersPool) do fs:Hide() end
    local uIdx = 1
    local y = 0
    
    if S.RaidAssist.users then
        for name, info in pairs(S.RaidAssist.users) do
            local fs = usersPool[uIdx]
            if not fs then
                fs = content.usersList:CreateFontString(nil, "OVERLAY", "GameFontNormal")
                usersPool[uIdx] = fs
            end
            fs:ClearAllPoints()
            fs:SetPoint("TOPLEFT", 5, -y)
            fs:SetText(string.format("|cFF00FF00%s|r (v%s)", name, info.version or "1.0"))
            fs:Show()
            y = y + 18
            uIdx = uIdx + 1
        end
    end
    if uIdx == 1 then
        local fs = usersPool[1] or content.usersList:CreateFontString(nil, "OVERLAY", "GameFontDisable")
        usersPool[1] = fs
        fs:ClearAllPoints()
        fs:SetPoint("TOPLEFT", 5, 0)
        fs:SetText("No se detectaron otros miembros con el addon.")
        fs:Show()
        y = 18
    end
    content.usersList:SetHeight(math.max(140, y))
    
    -- 2. Actualizar Consumibles
    for _, fs in ipairs(consumablesPool) do fs:Hide() end
    local cIdx = 1
    y = 0
    
    if S.RaidAssist.consumables then
        for name, status in pairs(S.RaidAssist.consumables) do
            local fs = consumablesPool[cIdx]
            if not fs then
                fs = content.consumablesList:CreateFontString(nil, "OVERLAY", "GameFontNormal")
                consumablesPool[cIdx] = fs
            end
            local flaskText = status.flask and "|cFF00FF00Frasco OK|r" or "|cFFFF3333Sin Frasco|r"
            local foodText  = status.food and "|cFF00FF00Comida OK|r" or "|cFFFF3333Sin Comida|r"
            fs:ClearAllPoints()
            fs:SetPoint("TOPLEFT", 5, -y)
            fs:SetText(string.format("%s: %s | %s", name, flaskText, foodText))
            fs:Show()
            y = y + 18
            cIdx = cIdx + 1
        end
    end
    if cIdx == 1 then
        local fs = consumablesPool[1] or content.consumablesList:CreateFontString(nil, "OVERLAY", "GameFontDisable")
        consumablesPool[1] = fs
        fs:ClearAllPoints()
        fs:SetPoint("TOPLEFT", 5, 0)
        fs:SetText("Pulsa 'Revisar Consumibles' en el panel de líder.")
        fs:Show()
        y = 18
    end
    content.consumablesList:SetHeight(math.max(170, y))
end

-- ============================================
-- COOLDOWNS TAB (Reciclado en memoria)
-- ============================================

function RAUI:CreateCooldownsTab(parent)
    local label = parent:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
    label:SetPoint("TOPLEFT", 10, -10)
    label:SetText(S.L["IMPORTANT_COOLDOWNS"] or "Cooldowns de Banda:")
    
    local scroll = CreateFrame("ScrollFrame", "JainaRACooldownsScrollFrame", parent, "UIPanelScrollFrameTemplate")
    scroll:SetPoint("TOPLEFT", 10, -35)
    scroll:SetPoint("BOTTOMRIGHT", -30, 45)
    
    local content = CreateFrame("Frame", nil, scroll)
    content:SetSize(370, 360)
    scroll:SetScrollChild(content)
    parent.cooldownsList = content
    
    local updateBtn = CreateFrame("Button", nil, parent, "UIPanelButtonTemplate")
    updateBtn:SetSize(120, 24)
    updateBtn:SetPoint("BOTTOM", 0, 10)
    updateBtn:SetText(S.L["UPDATE"] or "Actualizar")
    updateBtn:SetScript("OnClick", function()
        RAUI:UpdateCooldownsTab()
    end)
end

function RAUI:UpdateCooldownsTab()
    local content = self.mainFrame and self.mainFrame.tabContents and self.mainFrame.tabContents[2]
    if not content or not content.cooldownsList or not S.RaidAssist then return end
    
    for _, fs in ipairs(cooldownsPool) do fs:Hide() end
    local cdIdx = 1
    local y = 0
    
    if S.RaidAssist.cooldowns then
        for name, cds in pairs(S.RaidAssist.cooldowns) do
            for spellName, info in pairs(cds) do
                local fs = cooldownsPool[cdIdx]
                if not fs then
                    fs = content.cooldownsList:CreateFontString(nil, "OVERLAY", "GameFontNormal")
                    cooldownsPool[cdIdx] = fs
                end
                local remaining = info.remaining or 0
                local color = remaining > 60 and "|cFFFF4444" or "|cFFFFFF00"
                fs:ClearAllPoints()
                fs:SetPoint("TOPLEFT", 5, -y)
                fs:SetText(string.format("%s - |cFFFFD100%s|r: %s%ds|r", name, spellName, color, remaining))
                fs:Show()
                y = y + 18
                cdIdx = cdIdx + 1
            end
        end
    end
    
    if cdIdx == 1 then
        local fs = cooldownsPool[1] or content.cooldownsList:CreateFontString(nil, "OVERLAY", "GameFontDisable")
        cooldownsPool[1] = fs
        fs:ClearAllPoints()
        fs:SetPoint("TOPLEFT", 5, 0)
        fs:SetText("No hay cooldowns compartidos activos en este momento.")
        fs:Show()
        y = 18
    end
    content.cooldownsList:SetHeight(math.max(360, y))
end

-- ============================================
-- ASSIGNMENTS TAB (Funcionalidad Real Conectada)
-- ============================================

function RAUI:CreateAssignmentsTab(parent)
    local label = parent:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
    label:SetPoint("TOPLEFT", 10, -10)
    label:SetText(S.L["RAID_ASSIGNMENTS"] or "Asignaciones de Banda:")
    
    local scroll = CreateFrame("ScrollFrame", "JainaRAAssignmentsScrollFrame", parent, "UIPanelScrollFrameTemplate")
    scroll:SetPoint("TOPLEFT", 10, -35)
    scroll:SetPoint("BOTTOMRIGHT", -30, 45)
    
    local content = CreateFrame("Frame", nil, scroll)
    content:SetSize(370, 360)
    scroll:SetScrollChild(content)
    parent.assignmentsList = content
    
    local updateBtn = CreateFrame("Button", nil, parent, "UIPanelButtonTemplate")
    updateBtn:SetSize(120, 24)
    updateBtn:SetPoint("BOTTOM", 0, 10)
    updateBtn:SetText(S.L["UPDATE"] or "Actualizar")
    updateBtn:SetScript("OnClick", function()
        RAUI:UpdateAssignmentsTab()
    end)
end

function RAUI:UpdateAssignmentsTab()
    local content = self.mainFrame and self.mainFrame.tabContents and self.mainFrame.tabContents[3]
    if not content or not content.assignmentsList then return end
    
    for _, fs in ipairs(assignmentsPool) do fs:Hide() end
    local aIdx = 1
    local y = 0
    
    -- 1. Asignaciones de RaidAssist (ROLE_ASSIGN)
    if S.RaidAssist and S.RaidAssist.assignments then
        for player, assign in pairs(S.RaidAssist.assignments) do
            local fs = assignmentsPool[aIdx]
            if not fs then
                fs = content.assignmentsList:CreateFontString(nil, "OVERLAY", "GameFontNormal")
                assignmentsPool[aIdx] = fs
            end
            fs:ClearAllPoints()
            fs:SetPoint("TOPLEFT", 5, -y)
            fs:SetText(string.format("|cFF66BBFF[Rol]|r %s: |cFFFFFFFF%s|r", player, tostring(assign)))
            fs:Show()
            y = y + 18
            aIdx = aIdx + 1
        end
    end
    
    -- 2. Asignaciones avanzadas del módulo Assignments (Tanques / Corte / Marcas)
    if S.Assignments and S.Assignments.Current then
        local cur = S.Assignments.Current
        if cur.tanks and next(cur.tanks) then
            for target, tank in pairs(cur.tanks) do
                local fs = assignmentsPool[aIdx]
                if not fs then
                    fs = content.assignmentsList:CreateFontString(nil, "OVERLAY", "GameFontNormal")
                    assignmentsPool[aIdx] = fs
                end
                fs:ClearAllPoints()
                fs:SetPoint("TOPLEFT", 5, -y)
                fs:SetText(string.format("|cFFFFA500[Tanque]|r %s -> Objetivo: %s", tank, target))
                fs:Show()
                y = y + 18
                aIdx = aIdx + 1
            end
        end
        if cur.interrupts and next(cur.interrupts) then
            for target, rot in pairs(cur.interrupts) do
                local fs = assignmentsPool[aIdx]
                if not fs then
                    fs = content.assignmentsList:CreateFontString(nil, "OVERLAY", "GameFontNormal")
                    assignmentsPool[aIdx] = fs
                end
                local rotStr = type(rot) == "table" and table.concat(rot, ", ") or tostring(rot)
                fs:ClearAllPoints()
                fs:SetPoint("TOPLEFT", 5, -y)
                fs:SetText(string.format("|cFFFF4444[Corte]|r %s: %s", target, rotStr))
                fs:Show()
                y = y + 18
                aIdx = aIdx + 1
            end
        end
    end
    
    if aIdx == 1 then
        local fs = assignmentsPool[1] or content.assignmentsList:CreateFontString(nil, "OVERLAY", "GameFontDisable")
        assignmentsPool[1] = fs
        fs:ClearAllPoints()
        fs:SetPoint("TOPLEFT", 5, 0)
        fs:SetText("No hay asignaciones de banda configuradas.")
        fs:Show()
        y = 18
    end
    content.assignmentsList:SetHeight(math.max(360, y))
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
    parent.mode:SetPoint("TOPLEFT", 10, -65)
    parent.mode:SetText((S.L["MODE"] or "Modo") .. ": FARM")
    
    local resetBtn = CreateFrame("Button", nil, parent, "UIPanelButtonTemplate")
    resetBtn:SetSize(160, 24)
    resetBtn:SetPoint("TOPLEFT", 10, -100)
    resetBtn:SetText(S.L["RESET_COUNTER"] or "Reset Contador Wipes")
    resetBtn:SetScript("OnClick", function()
        if S.RaidAssist then
            S.RaidAssist:ResetWipeCounter()
        end
        RAUI:UpdateStatsTab()
    end)
    
    local modeBtn = CreateFrame("Button", nil, parent, "UIPanelButtonTemplate")
    modeBtn:SetSize(160, 24)
    modeBtn:SetPoint("TOPLEFT", 10, -130)
    modeBtn:SetText(S.L["CHANGE_MODE"] or "Alternar Progreso/Farm")
    modeBtn:SetScript("OnClick", function()
        if S.RaidAssist then
            local newMode = S.RaidAssist.mode == "FARM" and "PROGRESSION" or "FARM"
            S.RaidAssist:SetMode(newMode)
        end
        RAUI:UpdateStatsTab()
    end)
end

function RAUI:UpdateStatsTab()
    local content = self.mainFrame and self.mainFrame.tabContents and self.mainFrame.tabContents[4]
    if not content or not S.RaidAssist then return end
    
    content.wipeCount:SetText((S.L["WIPES"] or "Wipes") .. ": " .. (S.RaidAssist.wipeCount or 0))
    content.mode:SetText((S.L["MODE"] or "Modo") .. ": " .. (S.RaidAssist.mode or "FARM"))
end

-- ============================================
-- LEADER PANEL (Compact)
-- ============================================

function RAUI:CreateLeaderPanel()
    local f = CreateFrame("Frame", "JainaLeaderPanel", UIParent)
    f:SetSize(200, 150)
    f:SetPoint("TOPRIGHT", -50, -200)
    
    if S.Theme and S.Theme.ApplyPanelBackdrop then
        S.Theme:ApplyPanelBackdrop(f)
    else
        f:SetBackdrop({
            bgFile = "Interface\\Tooltips\\UI-Tooltip-Background",
            edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
            tile = true, tileSize = 16, edgeSize = 16,
            insets = {left = 4, right = 4, top = 4, bottom = 4}
        })
        f:SetBackdropColor(0, 0, 0, 0.8)
    end
    
    f:SetFrameStrata("HIGH")
    f:SetMovable(true)
    f:EnableMouse(true)
    f:RegisterForDrag("LeftButton")
    f:SetScript("OnDragStart", f.StartMoving)
    f:SetScript("OnDragStop", function(self)
        self:StopMovingOrSizing()
        if S.SmartDefaults then
            S.SmartDefaults:SavePosition("LeaderPanel", self)
        end
    end)
    f:Hide()
    
    f.title = f:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    f.title:SetPoint("TOP", 0, -10)
    f.title:SetText(S.L["RAID_LEADER"] or "Líder de Banda")
    
    local pullBtn = CreateFrame("Button", nil, f, "UIPanelButtonTemplate")
    pullBtn:SetSize(180, 24)
    pullBtn:SetPoint("TOP", 0, -30)
    pullBtn:SetText(S.L["PULL_TIMER_10S"] or "Pull Timer (10s)")
    pullBtn:SetScript("OnClick", function()
        if S.RaidAssist then S.RaidAssist:StartPullTimer(10) end
    end)
    
    local phaseBtn = CreateFrame("Button", nil, f, "UIPanelButtonTemplate")
    phaseBtn:SetSize(180, 24)
    phaseBtn:SetPoint("TOP", 0, -58)
    phaseBtn:SetText(S.L["ANNOUNCE_PHASE_2"] or "Anunciar Fase 2")
    phaseBtn:SetScript("OnClick", function()
        if S.RaidAssist then S.RaidAssist:AnnouncePhase("2") end
    end)
    
    local checkBtn = CreateFrame("Button", nil, f, "UIPanelButtonTemplate")
    checkBtn:SetSize(180, 24)
    checkBtn:SetPoint("TOP", 0, -86)
    checkBtn:SetText(S.L["CHECK_CONSUMABLES"] or "Revisar Consumibles")
    checkBtn:SetScript("OnClick", function()
        if S.RaidAssist then
            S.RaidAssist:CheckConsumables()
            local report = S.RaidAssist:GetConsumableReport()
            S:Print(S.L["CONSUMABLES_REPORT"] or "=== Reporte de Consumibles ===")
            S:Print(report)
            RAUI:UpdateStatusTab()
        end
    end)
    
    local openBtn = CreateFrame("Button", nil, f, "UIPanelButtonTemplate")
    openBtn:SetSize(180, 24)
    openBtn:SetPoint("TOP", 0, -114)
    openBtn:SetText(S.L["OPEN_FULL_PANEL"] or "Abrir Panel Completo")
    openBtn:SetScript("OnClick", function()
        RAUI:Toggle()
    end)
    
    self.leaderPanel = f
end

function RAUI:Toggle()
    if not self.mainFrame then
        self:CreateMainWindow()
    end
    
    if self.mainFrame:IsShown() then
        self.mainFrame:Hide()
    else
        self.mainFrame:Show()
        self:UpdateCurrentTab()
    end
end

function RAUI:ToggleLeaderPanel()
    if not self.leaderPanel then
        self:CreateLeaderPanel()
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
    
    local numRaid = GetNumRaidMembers()
    local isLeader = false
    
    if numRaid > 0 then
        isLeader = (IsRaidLeader and IsRaidLeader()) or (IsRaidOfficer and IsRaidOfficer())
    elseif GetNumPartyMembers() > 0 then
        isLeader = IsPartyLeader and IsPartyLeader()
    else
        isLeader = true
    end
    
    if not isLeader then
        S:Print(S.L["NOT_RAID_LEADER"] or "Debes ser líder o asistente de raid")
        return
    end
    
    self.leaderPanel:Show()
end

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
            }
        }
    })
end
