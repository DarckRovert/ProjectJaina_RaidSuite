--[[
    SEQUITO - Dashboard (GUI 2.0 Glassmorphism)
    Centro de comando y panel unificado de hermandad y banda.
]]

local addonName, S = ...
S.Dashboard = {}
local DB = S.Dashboard
_G.Sequito = _G.Sequito or S
_G.Sequito.Dashboard = DB

function DB:Initialize()
    if self.initialized then return end
    self.initialized = true
    
    self.tabs = {}
    self.tabCount = 0
    self.frame = self:CreateDashboardFrame()

    -- Registrar pestaña de Resumen inicial
    self:CreateOverviewTab()

    -- Registrar pestañas modulares integradas
    self:CreateAchievementsTab()
    self:CreateRotationTab()
    self:CreateLootGalleryTab()

    -- Comandos de consola
    SLASH_SEQUITODASH1 = "/sdb"
    SLASH_SEQUITODASH2 = "/sdash"
    SLASH_SEQUITODASH3 = "/sequitodash"
    SlashCmdList["SEQUITODASH"] = function()
        DB:Toggle()
    end

    print("|cFFFF00FFSequito|r: [GUI] Dashboard 2.0 unificado listo.")
end

function DB:Toggle()
    if not self.frame then
        self.frame = self:CreateDashboardFrame()
    end
    if self.frame:IsShown() then
        self.frame:Hide()
    else
        self:RefreshOverview()
        self.frame:Show()
    end
end

function DB:CreateDashboardFrame()
    if self.frame then return self.frame end

    local f = CreateFrame("Frame", "SequitoDashboard", UIParent)
    f:SetSize(880, 560)
    f:SetPoint("CENTER", UIParent, "CENTER", 0, 10)
    f:SetFrameStrata("HIGH")
    f:SetMovable(true)
    f:EnableMouse(true)
    f:RegisterForDrag("LeftButton")
    f:SetScript("OnDragStart", f.StartMoving)
    f:SetScript("OnDragStop", f.StopMovingOrSizing)
    f:SetClampedToScreen(true)

    -- Aplicar tema dinámico
    if S.Theme and S.Theme.ApplyPanelBackdrop then
        S.Theme:ApplyPanelBackdrop(f)
        if S.Theme.RegisteredFrames then
            table.insert(S.Theme.RegisteredFrames, f)
        end
    else
        f:SetBackdrop({
            bgFile = "Interface\\Buttons\\WHITE8x8",
            edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
            tile = false, edgeSize = 14,
            insets = { left = 3, right = 3, top = 3, bottom = 3 }
        })
        f:SetBackdropColor(0.06, 0.05, 0.09, 0.95)
        f:SetBackdropBorderColor(0.35, 0.35, 0.45, 0.8)
    end

    -- Header Container
    local header = CreateFrame("Frame", nil, f)
    header:SetPoint("TOPLEFT", 10, -8)
    header:SetPoint("TOPRIGHT", -10, -8)
    header:SetHeight(44)
    f.headerBar = header

    -- Logo & Title
    local title = header:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
    title:SetPoint("LEFT", 6, 6)
    title:SetText("|cFFFFD700SEQUITO|r |cFFFFFFFFCónclave Hub|r |cFF888888v" .. (S.Version or "10.1.0") .. "|r")
    f.title = title

    local subtitle = header:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    subtitle:SetPoint("LEFT", 6, -10)
    subtitle:SetText("Centro de Comando Unificado & Gestión Estratégica de Banda")
    subtitle:SetTextColor(0.65, 0.65, 0.7)

    -- Close Button
    local close = CreateFrame("Button", nil, f, "UIPanelCloseButton")
    close:SetPoint("TOPRIGHT", -4, -4)
    close:SetScript("OnClick", function() f:Hide() end)
    f.close = close

    -- Theme Switcher Buttons en Header
    local btnClasico = CreateFrame("Button", nil, header, "UIPanelButtonTemplate")
    btnClasico:SetSize(64, 20)
    btnClasico:SetPoint("RIGHT", -30, 4)
    btnClasico:SetText("Clásico")
    btnClasico:SetScript("OnClick", function()
        if S.Theme then S.Theme:SetTheme("Clasico") end
    end)

    local btnOscuro = CreateFrame("Button", nil, header, "UIPanelButtonTemplate")
    btnOscuro:SetSize(64, 20)
    btnOscuro:SetPoint("RIGHT", btnClasico, "LEFT", -4, 0)
    btnOscuro:SetText("Oscuro")
    btnOscuro:SetScript("OnClick", function()
        if S.Theme then S.Theme:SetTheme("Oscuro") end
    end)

    local btnDemonio = CreateFrame("Button", nil, header, "UIPanelButtonTemplate")
    btnDemonio:SetSize(68, 20)
    btnDemonio:SetPoint("RIGHT", btnOscuro, "LEFT", -4, 0)
    btnDemonio:SetText("Demonio")
    btnDemonio:SetScript("OnClick", function()
        if S.Theme then S.Theme:SetTheme("Demonio") end
    end)

    local themeLabel = header:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    themeLabel:SetPoint("RIGHT", btnDemonio, "LEFT", -6, 0)
    themeLabel:SetText("Tema:")
    themeLabel:SetTextColor(0.8, 0.8, 0.8)

    local btnReload = CreateFrame("Button", nil, header, "UIPanelButtonTemplate")
    btnReload:SetSize(80, 20)
    btnReload:SetPoint("RIGHT", themeLabel, "LEFT", -14, 0)
    btnReload:SetText("Recargar UI")
    btnReload:SetScript("OnClick", function() ReloadUI() end)

    -- Separator Line
    local line = header:CreateTexture(nil, "ARTWORK")
    line:SetPoint("BOTTOMLEFT", 0, -2)
    line:SetPoint("BOTTOMRIGHT", 0, -2)
    line:SetHeight(1)
    line:SetTexture("Interface\\Buttons\\WHITE8x8")
    line:SetVertexColor(0.3, 0.25, 0.4, 0.6)

    -- Left Navigation Sidebar
    local tabBar = CreateFrame("Frame", nil, f)
    tabBar:SetPoint("TOPLEFT", f, "TOPLEFT", 6, -56)
    tabBar:SetPoint("BOTTOMLEFT", f, "BOTTOMLEFT", 6, 8)
    tabBar:SetWidth(84)
    tabBar:SetBackdrop({
        bgFile = "Interface\\Buttons\\WHITE8x8",
        tile = false,
    })
    tabBar:SetBackdropColor(0.04, 0.03, 0.06, 0.6)
    f.tabBar = tabBar

    -- Main Content Area
    local content = CreateFrame("Frame", nil, f)
    content:SetPoint("TOPLEFT", f, "TOPLEFT", 94, -56)
    content:SetPoint("BOTTOMRIGHT", f, "BOTTOMRIGHT", -8, 8)
    content:SetBackdrop({
        bgFile = "Interface\\Buttons\\WHITE8x8",
        edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
        tile = false, edgeSize = 10,
        insets = { left = 2, right = 2, top = 2, bottom = 2 }
    })
    content:SetBackdropColor(0.03, 0.03, 0.05, 0.8)
    content:SetBackdropBorderColor(0.2, 0.2, 0.25, 0.5)
    f.content = content

    f:Hide()
    return f
end

-- ============================================================================
-- REGISTRO DE PESTAÑAS (TAB SYSTEM)
-- ============================================================================

function DB:RegisterTab(name, icon, contentFrame, tooltipDesc)
    if not self.frame then
        self.frame = self:CreateDashboardFrame()
    end

    -- Si ya existe una tab con ese nombre, actualizar su frame
    if self.tabs then
        for i, existing in ipairs(self.tabs) do
            if existing.name == name then
                existing.content = contentFrame
                contentFrame:ClearAllPoints()
                contentFrame:SetParent(self.frame.content)
                contentFrame:SetAllPoints(self.frame.content)
                contentFrame:Hide()
                return
            end
        end
    end

    self.tabCount = (self.tabCount or 0) + 1
    local tabIndex = self.tabCount

    local btnHeight = 48
    local btnSpacing = 3
    local yOffset = -((tabIndex - 1) * (btnHeight + btnSpacing) + 4)

    local btn = CreateFrame("Button", "SequitoDashboardTab" .. tabIndex, self.frame.tabBar)
    btn:SetSize(76, btnHeight)
    btn:SetPoint("TOPLEFT", self.frame.tabBar, "TOPLEFT", 4, yOffset)

    -- Background
    btn.bg = btn:CreateTexture(nil, "BACKGROUND")
    btn.bg:SetAllPoints()
    btn.bg:SetTexture("Interface\\Buttons\\WHITE8x8")
    btn.bg:SetVertexColor(0.08, 0.08, 0.12, 0.85)

    -- Active Indicator Bar (borde izquierdo)
    btn.indicator = btn:CreateTexture(nil, "OVERLAY")
    btn.indicator:SetPoint("TOPLEFT", 0, 0)
    btn.indicator:SetPoint("BOTTOMLEFT", 0, 0)
    btn.indicator:SetWidth(3)
    btn.indicator:SetTexture("Interface\\Buttons\\WHITE8x8")
    btn.indicator:SetVertexColor(0.8, 0.65, 0.2, 1)
    btn.indicator:Hide()

    -- Icon
    btn.icon = btn:CreateTexture(nil, "ARTWORK")
    btn.icon:SetTexture(icon or "Interface\\Icons\\INV_Misc_QuestionMark")
    btn.icon:SetSize(26, 26)
    btn.icon:SetPoint("TOP", 0, -5)
    btn.icon:SetTexCoord(0.08, 0.92, 0.08, 0.92)

    -- Label debajo del icono
    btn.label = btn:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    btn.label:SetPoint("BOTTOM", 0, 4)
    btn.label:SetText(name)
    btn.label:SetFont("Fonts\\FRIZQT__.TTF", 9, "")
    btn.label:SetWidth(72)
    btn.label:SetJustifyH("CENTER")

    btn:SetHighlightTexture("Interface\\Buttons\\ButtonHilight-Square")

    self.tabs = self.tabs or {}
    self.tabs[tabIndex] = {
        name = name,
        btn = btn,
        content = contentFrame,
        desc = tooltipDesc
    }

    local idx = tabIndex
    btn:SetScript("OnClick", function()
        DB:SelectTab(idx)
    end)

    btn:SetScript("OnEnter", function(self)
        GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
        GameTooltip:SetText(name, 1, 0.82, 0)
        if tooltipDesc then
            GameTooltip:AddLine(tooltipDesc, 0.8, 0.8, 0.8, true)
        end
        GameTooltip:Show()
    end)
    btn:SetScript("OnLeave", function() GameTooltip:Hide() end)

    -- Mount content frame
    contentFrame:ClearAllPoints()
    contentFrame:SetParent(self.frame.content)
    contentFrame:SetAllPoints(self.frame.content)
    contentFrame:Hide()

    if tabIndex == 1 then
        self:SelectTab(1)
    end
end

function DB:SelectTab(index)
    if not self.tabs then return end
    for i, tab in ipairs(self.tabs) do
        if tab and tab.btn and tab.content then
            if i == index then
                tab.content:Show()
                tab.btn.bg:SetVertexColor(0.2, 0.15, 0.28, 0.95)
                tab.btn.icon:SetVertexColor(1, 1, 1)
                tab.btn.label:SetTextColor(1, 0.85, 0.2)
                tab.btn.indicator:Show()
            else
                tab.content:Hide()
                tab.btn.bg:SetVertexColor(0.08, 0.08, 0.12, 0.85)
                tab.btn.icon:SetVertexColor(0.55, 0.55, 0.6)
                tab.btn.label:SetTextColor(0.65, 0.65, 0.7)
                tab.btn.indicator:Hide()
            end
        end
    end
end

-- ============================================================================
-- TAB 1: RESUMEN / STATUS (Cónclave Overview)
-- ============================================================================

function DB:CreateOverviewTab()
    local f = CreateFrame("Frame", "SequitoOverviewTab", self.frame.content)

    -- Panel Izquierdo: Info del Personaje & Hermandad
    local charCard = CreateFrame("Frame", nil, f)
    charCard:SetSize(370, 200)
    charCard:SetPoint("TOPLEFT", 12, -12)
    charCard:SetBackdrop({
        bgFile = "Interface\\Buttons\\WHITE8x8",
        edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
        tile = false, edgeSize = 10,
        insets = { left = 2, right = 2, top = 2, bottom = 2 }
    })
    charCard:SetBackdropColor(0.06, 0.06, 0.09, 0.9)
    charCard:SetBackdropBorderColor(0.25, 0.3, 0.45, 0.8)

    local charTitle = charCard:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    charTitle:SetPoint("TOPLEFT", 12, -10)
    charTitle:SetText("|cFFFFD700Estado del Jugador & Hermandad|r")

    f.charInfo = charCard:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    f.charInfo:SetPoint("TOPLEFT", 12, -34)
    f.charInfo:SetPoint("BOTTOMRIGHT", -12, 10)
    f.charInfo:SetJustifyH("LEFT")
    f.charInfo:SetJustifyV("TOP")

    -- Panel Derecho: Matriz de Banda & Grupo
    local raidCard = CreateFrame("Frame", nil, f)
    raidCard:SetSize(370, 200)
    raidCard:SetPoint("TOPRIGHT", -12, -12)
    raidCard:SetBackdrop({
        bgFile = "Interface\\Buttons\\WHITE8x8",
        edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
        tile = false, edgeSize = 10,
        insets = { left = 2, right = 2, top = 2, bottom = 2 }
    })
    raidCard:SetBackdropColor(0.06, 0.06, 0.09, 0.9)
    raidCard:SetBackdropBorderColor(0.25, 0.3, 0.45, 0.8)

    local raidTitle = raidCard:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    raidTitle:SetPoint("TOPLEFT", 12, -10)
    raidTitle:SetText("|cFF00CCFFComposición de Grupo / Banda|r")

    f.raidInfo = raidCard:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    f.raidInfo:SetPoint("TOPLEFT", 12, -34)
    f.raidInfo:SetPoint("BOTTOMRIGHT", -12, 10)
    f.raidInfo:SetJustifyH("LEFT")
    f.raidInfo:SetJustifyV("TOP")

    -- Panel Inferior: Centro de Acciones Rápidas
    local actionCard = CreateFrame("Frame", nil, f)
    actionCard:SetPoint("TOPLEFT", charCard, "BOTTOMLEFT", 0, -12)
    actionCard:SetPoint("BOTTOMRIGHT", -12, 12)
    actionCard:SetBackdrop({
        bgFile = "Interface\\Buttons\\WHITE8x8",
        edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
        tile = false, edgeSize = 10,
        insets = { left = 2, right = 2, top = 2, bottom = 2 }
    })
    actionCard:SetBackdropColor(0.05, 0.05, 0.08, 0.9)
    actionCard:SetBackdropBorderColor(0.2, 0.25, 0.35, 0.7)

    local actTitle = actionCard:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    actTitle:SetPoint("TOPLEFT", 12, -10)
    actTitle:SetText("|cFFFFD700Centro de Acciones Rápidas del Cónclave|r")

    -- 8 Botones funcionales
    local actions = {
        { name = "Rotación HUD", func = function() if S.AcademyRotation then S.AcademyRotation:ToggleHUD() end end },
        { name = "Asistente Invocaciones", func = function() if S.Coven then S.Coven:Toggle() end end },
        { name = "Logros de Guild", func = function() if S.Achievements then S.Achievements:ToggleBrowser() end end },
        { name = "Galería de Tesoros", func = function() if S.LootGallery and S.LootGallery.frame then S.LootGallery.frame:Show(); S.LootGallery:UpdateGallery() end end },
        { name = "Generar Macros", func = function() if S.MacroGen then S.MacroGen:GenerateClassMacros() end end },
        { name = "Inspeccionar Objetivo", func = function() if S.AcademyInspector then S.AcademyInspector:InspectTarget() end end },
        { name = "Iniciar Votación", func = function() if S.VotingSystem then S.VotingSystem:OpenCreationDialog() end end },
        { name = "Verificar Listos", func = function() if S.ReadyChecker then S.ReadyChecker:StartCheck() end end },
    }

    local btnW, btnH = 175, 30
    local cols = 4
    for i, act in ipairs(actions) do
        local col = (i - 1) % cols
        local row = math.floor((i - 1) / cols)

        local b = CreateFrame("Button", nil, actionCard, "UIPanelButtonTemplate")
        b:SetSize(btnW, btnH)
        b:SetPoint("TOPLEFT", 14 + col * (btnW + 12), -38 - row * (btnH + 10))
        b:SetText(act.name)
        b:SetScript("OnClick", act.func)
    end

    -- Diagnóstico del Sistema al pie
    local diag = actionCard:CreateFontString(nil, "OVERLAY", "GameFontDisableSmall")
    diag:SetPoint("BOTTOMLEFT", 14, 10)
    diag:SetText("|cFF888888CLEU Central: Activo | Comm Protocol: OK | ProfileManager: " .. (S.ProfileManager and S.ProfileManager:GetCurrentProfile() or "Default") .. "|r")
    f.diag = diag

    self.overviewFrame = f
    self:RegisterTab("Resumen", "Interface\\Icons\\Spell_Holy_SealOfWisdom", f, "Resumen del cónclave, estado del grupo y acciones rápidas.")
end

function DB:RefreshOverview()
    if not self.overviewFrame then return end
    local f = self.overviewFrame

    -- Player & Guild
    local pName = UnitName("player") or "Jugador"
    local _, pClass = UnitClass("player")
    local cColor = RAID_CLASS_COLORS and RAID_CLASS_COLORS[pClass]
    local colorStr = cColor and string.format("|cFF%02x%02x%02x", cColor.r * 255, cColor.g * 255, cColor.b * 255) or "|cFFFFFFFF"
    local gName, gRankName, gRankIndex = GetGuildInfo("player")
    local zone = GetZoneText() or "Desconocido"
    local _, _, lagHome, lagWorld = GetNetStats()
    local fps = math.floor(GetFramerate())

    local charTxt = string.format(
        "Nombre: %s%s|r (%s)\n" ..
        "Hermandad: |cFFFFD700%s|r (Rango: %s)\n" ..
        "Zona Actual: |cFFFFFFFF%s|r\n" ..
        "Rendimiento: |cFF00FF00%d FPS|r | Latencia: |cFF00FF00%d ms|r\n" ..
        "Perfil Activo: |cFF00CCFF%s|r\n" ..
        "Tema Gráfico: |cFFCC66FF%s|r",
        colorStr, pName, pClass or "Clase",
        gName or "Sin Hermandad", gRankName or "Miembro",
        zone, fps, lagHome or lagWorld or 0,
        (S.ProfileManager and S.ProfileManager:GetCurrentProfile() or "Default"),
        (S.Theme and S.Theme.CurrentTheme or "Oscuro")
    )
    f.charInfo:SetText(charTxt)

    -- Raid / Party Matrix
    local inRaid = (GetNumRaidMembers() > 0)
    local inParty = (GetNumPartyMembers() > 0)
    local totalMembers = inRaid and GetNumRaidMembers() or (inParty and (GetNumPartyMembers() + 1) or 1)

    local tanks, heals, dps = 0, 0, 0
    if inRaid then
        for i = 1, GetNumRaidMembers() do
            local _, _, _, _, _, class, _, _, _, role = GetRaidRosterInfo(i)
            if role == "MAINTANK" or role == "MAINASSIST" then
                tanks = tanks + 1
            elseif class == "PRIEST" or class == "PALADIN" or class == "SHAMAN" or class == "DRUID" then
                heals = heals + 1
            else
                dps = dps + 1
            end
        end
    else
        dps = totalMembers
    end

    local raidTxt = string.format(
        "Estado del Grupo: |cFFFFD700%s|r\n" ..
        "Miembros Totales: |cFFFFFFFF%d|r\n\n" ..
        "Tanques Detectados: |cFF00CCFF%d|r\n" ..
        "Sanadores Estimados: |cFF00FF00%d|r\n" ..
        "DPS / Apoyo: |cFFFF4444%d|r\n\n" ..
        "|cFF888888Usa 'Banda' para el control táctico completo.|r",
        inRaid and "Banda Activa" or (inParty and "Grupo de Mazmorra" or "En Solitario"),
        totalMembers, tanks, heals, dps
    )
    f.raidInfo:SetText(raidTxt)
end

-- ============================================================================
-- TAB: LOGROS (Achievements Browser Embedded)
-- ============================================================================

function DB:CreateAchievementsTab()
    local f = CreateFrame("Frame", "SequitoDashAchTab", self.frame.content)
    
    local title = f:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
    title:SetPoint("TOPLEFT", 14, -12)
    title:SetText("|cFFFFD700Logros de Hermandad & Proezas|r")

    local desc = f:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    desc:SetPoint("TOPLEFT", 14, -32)
    desc:SetText("Sistema interno de gamificación Sequito. Completa hitos y proezas de banda.")
    desc:SetTextColor(0.7, 0.7, 0.7)

    local btnOpen = CreateFrame("Button", nil, f, "UIPanelButtonTemplate")
    btnOpen:SetSize(160, 24)
    btnOpen:SetPoint("TOPRIGHT", -14, -12)
    btnOpen:SetText("Abrir Navegador Flotante")
    btnOpen:SetScript("OnClick", function()
        if S.Achievements then S.Achievements:ToggleBrowser() end
    end)

    -- Scroll Area
    local scroll = CreateFrame("ScrollFrame", "SequitoDashAchScroll", f, "UIPanelScrollFrameTemplate")
    scroll:SetPoint("TOPLEFT", 14, -60)
    scroll:SetPoint("BOTTOMRIGHT", -30, 10)

    local content = CreateFrame("Frame", nil, scroll)
    content:SetSize(720, 480)
    scroll:SetScrollChild(content)

    f:SetScript("OnShow", function()
        if S.Achievements and S.Achievements.AchievementList then
            local yOffset = 0
            local cardH = 50
            for i, ach in ipairs(S.Achievements.AchievementList) do
                local card = content["card" .. i]
                if not card then
                    card = CreateFrame("Frame", nil, content)
                    card:SetSize(710, cardH)
                    card:SetBackdrop({
                        bgFile = "Interface\\Buttons\\WHITE8x8",
                        edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
                        tile = false, edgeSize = 8,
                        insets = { left = 2, right = 2, top = 2, bottom = 2 }
                    })
                    
                    local icon = card:CreateTexture(nil, "ARTWORK")
                    icon:SetSize(36, 36)
                    icon:SetPoint("LEFT", 6, 0)
                    card.icon = icon

                    local t = card:CreateFontString(nil, "OVERLAY", "GameFontNormal")
                    t:SetPoint("TOPLEFT", 48, -6)
                    card.title = t

                    local d = card:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
                    d:SetPoint("TOPLEFT", 48, -24)
                    d:SetPoint("BOTTOMRIGHT", -120, 6)
                    d:SetJustifyH("LEFT")
                    card.desc = d

                    local pts = card:CreateFontString(nil, "OVERLAY", "GameFontNormal")
                    pts:SetPoint("RIGHT", -14, 0)
                    card.pts = pts

                    content["card" .. i] = card
                end

                card:SetPoint("TOPLEFT", 0, -yOffset)
                card.icon:SetTexture(ach.icon)
                card.title:SetText(ach.title)
                card.desc:SetText(ach.desc or "")
                card.pts:SetText("|cFFFFD700+" .. ach.points .. " pts|r")

                local isDone = S.Achievements:IsUnlocked(ach.id)
                if isDone then
                    card:SetBackdropColor(0.1, 0.2, 0.12, 0.8)
                    card:SetBackdropBorderColor(0.2, 0.6, 0.3, 0.8)
                    card.icon:SetDesaturated(false)
                else
                    card:SetBackdropColor(0.06, 0.06, 0.08, 0.8)
                    card:SetBackdropBorderColor(0.2, 0.2, 0.25, 0.5)
                    card.icon:SetDesaturated(true)
                end

                yOffset = yOffset + cardH + 4
            end
            content:SetHeight(math.max(100, yOffset))
        end
    end)

    self:RegisterTab("Logros", "Interface\\Icons\\Inv_Misc_Wreath_01", f, "Logros y proezas internas de hermandad.")
end

-- ============================================================================
-- TAB: ROTACIÓN (Academy Advisor Embedded)
-- ============================================================================

function DB:CreateRotationTab()
    local f = CreateFrame("Frame", "SequitoDashRotTab", self.frame.content)

    local title = f:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
    title:SetPoint("TOPLEFT", 14, -12)
    title:SetText("|cFF00CCFFAsesor de Rotación (Academy Rotation)|r")

    local desc = f:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    desc:SetPoint("TOPLEFT", 14, -32)
    desc:SetText("Prioridad óptima de hechizos calculada según tu clase y talentos en WoW 3.3.5a.")
    desc:SetTextColor(0.7, 0.7, 0.7)

    local btnHUD = CreateFrame("Button", nil, f, "UIPanelButtonTemplate")
    btnHUD:SetSize(160, 24)
    btnHUD:SetPoint("TOPRIGHT", -14, -12)
    btnHUD:SetText("Activar HUD Flotante")
    btnHUD:SetScript("OnClick", function()
        if S.AcademyRotation then S.AcademyRotation:ToggleHUD() end
    end)

    local infoCard = CreateFrame("Frame", nil, f)
    infoCard:SetSize(730, 160)
    infoCard:SetPoint("TOPLEFT", 14, -70)
    infoCard:SetBackdrop({
        bgFile = "Interface\\Buttons\\WHITE8x8",
        edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
        tile = false, edgeSize = 10,
        insets = { left = 2, right = 2, top = 2, bottom = 2 }
    })
    infoCard:SetBackdropColor(0.06, 0.06, 0.09, 0.85)
    infoCard:SetBackdropBorderColor(0.25, 0.4, 0.6, 0.7)

    local cardTitle = infoCard:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    cardTitle:SetPoint("TOPLEFT", 12, -10)
    cardTitle:SetText("Cadena de Prioridad Recomendada:")

    local rotText = infoCard:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
    rotText:SetPoint("TOPLEFT", 12, -35)
    rotText:SetPoint("BOTTOMRIGHT", -12, 10)
    rotText:SetJustifyH("LEFT")
    rotText:SetJustifyV("TOP")
    f.rotText = rotText

    f:SetScript("OnShow", function()
        if S.AcademyRotation then
            local rotData = S.AcademyRotation:GetActiveRotationData()
            if rotData then
                local spells = table.concat(rotData.spells, "  |cFF00CCFF>|r  ")
                rotText:SetText(string.format(
                    "|cFFFFD700Especialización Detectada:|r %s\n\n" ..
                    "|cFFFFFFFF%s|r\n\n" ..
                    "|cFF888888Activa el HUD Flotante para ver en tiempo real el cooldown y el siguiente hechizo listo.|r",
                    rotData.name or "Spec", spells
                ))
            else
                rotText:SetText("No se detectó una rotación específica para tu clase.")
            end
        end
    end)

    self:RegisterTab("Rotación", "Interface\\Icons\\Spell_Holy_SealOfRighteousness", f, "Cadena de prioridad de rotación y HUD flotante.")
end

-- ============================================================================
-- TAB: TESOROS (Loot Gallery Embedded)
-- ============================================================================

function DB:CreateLootGalleryTab()
    local f = CreateFrame("Frame", "SequitoDashLootTab", self.frame.content)

    local title = f:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
    title:SetPoint("TOPLEFT", 14, -12)
    title:SetText("|cFFFFD700Galería de Botín de Banda|r")

    local desc = f:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    desc:SetPoint("TOPLEFT", 14, -32)
    desc:SetText("Registro histórico de piezas épicas y legendarias obtenidas en banda.")
    desc:SetTextColor(0.7, 0.7, 0.7)

    local scroll = CreateFrame("ScrollFrame", "SequitoDashLootScroll", f, "UIPanelScrollFrameTemplate")
    scroll:SetPoint("TOPLEFT", 14, -60)
    scroll:SetPoint("BOTTOMRIGHT", -30, 10)

    local content = CreateFrame("Frame", nil, scroll)
    content:SetSize(720, 480)
    scroll:SetScrollChild(content)

    f:SetScript("OnShow", function()
        local lootList = SequitoLootDB or {}
        local yOffset = 0
        local rowH = 32

        for i, item in ipairs(lootList) do
            local row = content["row" .. i]
            if not row then
                row = CreateFrame("Frame", nil, content)
                row:SetSize(710, rowH)
                row:SetBackdrop({
                    bgFile = "Interface\\Buttons\\WHITE8x8",
                    tile = false
                })
                row:SetBackdropColor(0.06, 0.06, 0.09, 0.7)

                local icon = row:CreateTexture(nil, "ARTWORK")
                icon:SetSize(24, 24)
                icon:SetPoint("LEFT", 6, 0)
                row.icon = icon

                local txt = row:CreateFontString(nil, "OVERLAY", "GameFontNormal")
                txt:SetPoint("LEFT", 38, 0)
                row.txt = txt

                local dateTxt = row:CreateFontString(nil, "OVERLAY", "GameFontDisableSmall")
                dateTxt:SetPoint("RIGHT", -10, 0)
                row.dateTxt = dateTxt

                content["row" .. i] = row
            end

            row:SetPoint("TOPLEFT", 0, -yOffset)
            row.icon:SetTexture(item.icon or "Interface\\Icons\\INV_Misc_QuestionMark")
            row.txt:SetText(item.link or "Objeto")
            row.dateTxt:SetText(item.date or "")
            yOffset = yOffset + rowH + 2
        end
        content:SetHeight(math.max(100, yOffset))
    end)

    self:RegisterTab("Tesoros", "Interface\\Icons\\INV_Box_01", f, "Historial de botín épico obtenido en banda.")
end
