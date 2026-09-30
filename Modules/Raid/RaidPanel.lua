--[[
    SEQUITO - RaidPanel.lua
    Panel Visual de Raid con información en tiempo real de todos los miembros.
    Optimizado: Zero-Heap Buffer, InCombatLockdown Safe, SmartDefaults & ModuleConfig.
    Compatible con WotLK 3.3.5a (Build 12340)
]]--

local addonName, Sequito = ...
Sequito.RaidPanel = Sequito.RaidPanel or {}
local RaidPanel = Sequito.RaidPanel
local Universal = Sequito.Universal

-- Configuración del panel
local PANEL_CONFIG = {
    width = 330,
    height = 460,
    rowHeight = 18,
    maxRows = 40,
    headerHeight = 22,
    updateInterval = 1.0,
}

-- Colores de clase estándar (RGBA)
local CLASS_COLORS = {
    ["WARRIOR"]     = {0.78, 0.61, 0.43, 1},
    ["PALADIN"]     = {0.96, 0.55, 0.73, 1},
    ["HUNTER"]      = {0.67, 0.83, 0.45, 1},
    ["ROGUE"]       = {1.00, 0.96, 0.41, 1},
    ["PRIEST"]      = {1.00, 1.00, 1.00, 1},
    ["DEATHKNIGHT"] = {0.77, 0.12, 0.23, 1},
    ["SHAMAN"]      = {0.00, 0.44, 0.87, 1},
    ["MAGE"]        = {0.41, 0.80, 0.94, 1},
    ["WARLOCK"]     = {0.58, 0.51, 0.79, 1},
    ["DRUID"]       = {1.00, 0.49, 0.04, 1},
}

local ROLE_TEXCOORDS = {
    ["TANK"]   = {0, 0.25, 0.25, 0.5},
    ["HEALER"] = {0.25, 0.5, 0, 0.25},
    ["DPS"]    = {0.25, 0.5, 0.25, 0.5},
}

local COLUMNS = {
    {key = "index",  text = "#",      width = 22, align = "LEFT"},
    {key = "role",   text = "Rol",    width = 24, align = "CENTER"},
    {key = "class",  text = "Clase",  width = 54, align = "LEFT"},
    {key = "name",   text = "Nombre", width = 110, align = "LEFT", isDynamic = true},
    {key = "hp",     text = "HP%",    width = 46, align = "RIGHT"},
    {key = "status", text = "Estado", width = 50, align = "CENTER"},
}

-- Buffers estáticos (Zero Heap Thrashing)
local staticMemberPool = {}
for i = 1, 40 do
    staticMemberPool[i] = {
        unit = "",
        name = "",
        class = "WARRIOR",
        hp = 100,
        status = "OK",
        role = "DPS",
        index = i,
        r = 0.5, g = 0.5, b = 0.5,
    }
end
local staticMembersList = {}

-- Variables locales del panel
local mainFrame = nil
local memberRows = {}
local isVisible = false
local lastUpdate = 0
local pendingRosterUpdate = false

-- Helper para obtener configuración
function RaidPanel:GetOption(key)
    if Sequito.ModuleConfig then
        local val = Sequito.ModuleConfig:GetValue("RaidPanel", key)
        if val ~= nil then return val end
    end
    if Sequito.db and Sequito.db.profile then
        if key == "autoShow" and Sequito.db.profile.RaidPanelAuto ~= nil then return Sequito.db.profile.RaidPanelAuto end
        if key == "scale" and Sequito.db.profile.RaidPanelScale ~= nil then return Sequito.db.profile.RaidPanelScale end
        if key == "showHP" and Sequito.db.profile.RaidPanelHP ~= nil then return Sequito.db.profile.RaidPanelHP end
        if key == "showRoles" and Sequito.db.profile.RaidPanelRoles ~= nil then return Sequito.db.profile.RaidPanelRoles end
    end
    if key == "enabled" or key == "showHP" or key == "showRoles" then return true end
    if key == "scale" then return 1.0 end
    return false
end

-- Layout estático de fila (solo se invoca una vez o al redimensionar)
local function LayoutRowColumns(row, dynamicNameWidth)
    local currentX = 4
    local wIndex  = 22
    local wRole   = 24
    local wClass  = 54
    local wName   = dynamicNameWidth or 110
    local wHP     = 46
    local wStatus = 50

    row.indexText:ClearAllPoints()
    row.indexText:SetPoint("LEFT", row, "LEFT", currentX, 0)
    row.indexText:SetWidth(wIndex)
    currentX = currentX + wIndex

    row.roleIcon:ClearAllPoints()
    row.roleIcon:SetPoint("CENTER", row, "LEFT", currentX + (wRole / 2), 0)
    currentX = currentX + wRole

    row.classText:ClearAllPoints()
    row.classText:SetPoint("LEFT", row, "LEFT", currentX, 0)
    row.classText:SetWidth(wClass)
    currentX = currentX + wClass

    row.nameText:ClearAllPoints()
    row.nameText:SetPoint("LEFT", row, "LEFT", currentX, 0)
    row.nameText:SetWidth(wName)
    currentX = currentX + wName

    row.hpText:ClearAllPoints()
    row.hpText:SetPoint("LEFT", row, "LEFT", currentX, 0)
    row.hpText:SetWidth(wHP)
    currentX = currentX + wHP

    row.statusText:ClearAllPoints()
    row.statusText:SetPoint("LEFT", row, "LEFT", currentX, 0)
    row.statusText:SetWidth(wStatus)
end

-- Creación de cada fila segura
local function CreateMemberRow(parent, index)
    local row = CreateFrame("Button", "SequitoRaidRow" .. index, parent, "SecureUnitButtonTemplate")
    row:SetSize(PANEL_CONFIG.width - 24, PANEL_CONFIG.rowHeight)
    row:EnableMouse(true)
    row:RegisterForClicks("AnyUp")
    row:SetAttribute("type", "target")

    -- Barra de salud
    row.hpBar = CreateFrame("StatusBar", nil, row)
    row.hpBar:SetAllPoints()
    row.hpBar:SetStatusBarTexture("Interface\\Buttons\\WHITE8X8")
    row.hpBar:SetFrameLevel(row:GetFrameLevel() + 1)

    -- Fondo de barra
    row.bg = row.hpBar:CreateTexture(nil, "BACKGROUND")
    row.bg:SetAllPoints()
    row.bg:SetTexture("Interface\\Buttons\\WHITE8X8")
    row.bg:SetVertexColor(0.04, 0.04, 0.06, 0.85)

    -- Textos sobre la barra
    row.indexText = row.hpBar:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    row.indexText:SetJustifyH("RIGHT")
    row.indexText:SetTextColor(0.7, 0.7, 0.7, 1)

    row.roleIcon = row.hpBar:CreateTexture(nil, "OVERLAY")
    row.roleIcon:SetSize(13, 13)
    row.roleIcon:SetTexture("Interface\\LFGFrame\\UI-LFG-ICON-PORTRAITROLES")

    row.classText = row.hpBar:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    row.classText:SetJustifyH("LEFT")

    row.nameText = row.hpBar:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    row.nameText:SetJustifyH("LEFT")
    row.nameText:SetTextColor(1, 1, 1, 1)

    row.hpText = row.hpBar:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    row.hpText:SetJustifyH("RIGHT")

    row.statusText = row.hpBar:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    row.statusText:SetJustifyH("CENTER")

    -- Posicionar columnas de inmediato (cero SetPoint en OnUpdate)
    LayoutRowColumns(row, 110)

    -- Resaltado hover
    row:SetScript("OnEnter", function(self)
        self.hpBar:SetAlpha(1.0)
        self.nameText:SetTextColor(1, 0.82, 0)
    end)
    row:SetScript("OnLeave", function(self)
        self.hpBar:SetAlpha(0.9)
        self.nameText:SetTextColor(1, 1, 1)
    end)

    row:Hide()
    return row
end

-- Creación del frame principal HUD
local function CreateMainFrame()
    if mainFrame then return mainFrame end

    mainFrame = CreateFrame("Frame", "SequitoRaidPanel", UIParent)
    mainFrame:SetSize(PANEL_CONFIG.width, PANEL_CONFIG.height)
    mainFrame:SetPoint("RIGHT", UIParent, "RIGHT", -20, 0)
    mainFrame:SetMovable(true)
    mainFrame:EnableMouse(true)
    mainFrame:RegisterForDrag("LeftButton")
    mainFrame:SetClampedToScreen(true)
    mainFrame:SetFrameStrata("MEDIUM")

    mainFrame:SetScript("OnDragStart", function(self)
        self:StartMoving()
    end)
    mainFrame:SetScript("OnDragStop", function(self)
        self:StopMovingOrSizing()
        if Sequito.SmartDefaults then
            Sequito.SmartDefaults:SavePosition("RaidPanel", self)
        end
    end)

    -- Fondo y Borde (3.3.5a Glassmorphism)
    mainFrame:SetBackdrop({
        bgFile   = "Interface\\Buttons\\WHITE8X8",
        edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
        tile     = false,
        edgeSize = 14,
        insets   = { left = 3, right = 3, top = 3, bottom = 3 }
    })
    mainFrame:SetBackdropColor(0.05, 0.05, 0.08, 0.92)
    mainFrame:SetBackdropBorderColor(0.3, 0.25, 0.45, 0.8)

    -- Título
    mainFrame.title = mainFrame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    mainFrame.title:SetPoint("TOPLEFT", mainFrame, "TOPLEFT", 10, -8)
    mainFrame.title:SetText("|cFFFFD700Sequito|r - Panel de Banda")

    -- Botón de cerrar
    mainFrame.closeBtn = CreateFrame("Button", nil, mainFrame, "UIPanelCloseButton")
    mainFrame.closeBtn:SetPoint("TOPRIGHT", mainFrame, "TOPRIGHT", -2, -2)
    mainFrame.closeBtn:SetScript("OnClick", function()
        RaidPanel:Hide()
    end)

    -- Header con columnas
    mainFrame.header = CreateFrame("Frame", nil, mainFrame)
    mainFrame.header:SetSize(PANEL_CONFIG.width - 20, PANEL_CONFIG.headerHeight)
    mainFrame.header:SetPoint("TOPLEFT", mainFrame, "TOPLEFT", 10, -28)

    mainFrame.headerBg = mainFrame.header:CreateTexture(nil, "BACKGROUND")
    mainFrame.headerBg:SetAllPoints()
    mainFrame.headerBg:SetTexture("Interface\\Buttons\\WHITE8X8")
    mainFrame.headerBg:SetVertexColor(0.1, 0.08, 0.15, 0.6)

    mainFrame.headerTexts = {}
    local currentX = 4
    for i, col in ipairs(COLUMNS) do
        local t = mainFrame.header:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
        t:SetPoint("LEFT", mainFrame.header, "LEFT", currentX, 0)
        t:SetWidth(col.width)
        t:SetText(col.text)
        t:SetJustifyH(col.align)
        t:SetTextColor(0.9, 0.75, 0.3, 1)
        mainFrame.headerTexts[i] = t
        currentX = currentX + col.width
    end

    -- Separador
    mainFrame.separator = mainFrame:CreateTexture(nil, "ARTWORK")
    mainFrame.separator:SetSize(PANEL_CONFIG.width - 20, 1)
    mainFrame.separator:SetPoint("TOPLEFT", mainFrame.header, "BOTTOMLEFT", 0, -2)
    mainFrame.separator:SetTexture("Interface\\Buttons\\WHITE8X8")
    mainFrame.separator:SetVertexColor(0.3, 0.25, 0.4, 0.6)

    -- ScrollFrame para la lista de miembros
    mainFrame.scrollFrame = CreateFrame("ScrollFrame", "SequitoRaidPanelScroll", mainFrame, "UIPanelScrollFrameTemplate")
    mainFrame.scrollFrame:SetPoint("TOPLEFT", mainFrame.separator, "BOTTOMLEFT", 0, -4)
    mainFrame.scrollFrame:SetPoint("BOTTOMRIGHT", mainFrame, "BOTTOMRIGHT", -24, 24)

    mainFrame.content = CreateFrame("Frame", nil, mainFrame.scrollFrame)
    mainFrame.content:SetSize(PANEL_CONFIG.width - 24, PANEL_CONFIG.maxRows * PANEL_CONFIG.rowHeight)
    mainFrame.scrollFrame:SetScrollChild(mainFrame.content)

    -- Crear 40 filas una sola vez
    for i = 1, PANEL_CONFIG.maxRows do
        local row = CreateMemberRow(mainFrame.content, i)
        row:SetPoint("TOPLEFT", mainFrame.content, "TOPLEFT", 0, -((i - 1) * PANEL_CONFIG.rowHeight))
        memberRows[i] = row
    end

    -- Footer con estadísticas
    mainFrame.footer = mainFrame:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    mainFrame.footer:SetPoint("BOTTOMLEFT", mainFrame, "BOTTOMLEFT", 10, 8)
    mainFrame.footer:SetPoint("BOTTOMRIGHT", mainFrame, "BOTTOMRIGHT", -10, 8)
    mainFrame.footer:SetJustifyH("CENTER")
    mainFrame.footer:SetText("Total: 0 | Tanques: 0 | Sanadores: 0 | DPS: 0")

    -- Ticker OnUpdate throttled a updateInterval
    mainFrame:SetScript("OnUpdate", function(self, elapsed)
        lastUpdate = lastUpdate + elapsed
        if lastUpdate >= PANEL_CONFIG.updateInterval then
            lastUpdate = 0
            RaidPanel:UpdateMembers()
        end
    end)

    -- Redimensionamiento responsive (solo si cambia de tamaño)
    mainFrame:SetScript("OnSizeChanged", function(self, width, height)
        if not width or width < 150 then return end
        local fixedWidth = 22 + 24 + 54 + 46 + 50 + 8
        local dynamicW = math.max(60, width - fixedWidth - 24)
        if mainFrame.headerTexts and mainFrame.headerTexts[4] then
            mainFrame.headerTexts[4]:SetWidth(dynamicW)
        end
        for i = 1, PANEL_CONFIG.maxRows do
            if memberRows[i] then
                memberRows[i]:SetWidth(width - 24)
                LayoutRowColumns(memberRows[i], dynamicW)
            end
        end
    end)

    -- Restaurar posición con SmartDefaults
    if Sequito.SmartDefaults then
        Sequito.SmartDefaults:RestorePosition("RaidPanel", mainFrame)
    end

    mainFrame:Hide()
    return mainFrame
end

-- Llenado de datos sin crear tablas en heap
local function PopulateMemberData(data, unit)
    if not UnitExists(unit) then return false end
    data.unit = unit
    data.name = UnitName(unit) or "Desconocido"
    local _, classToken = UnitClass(unit)
    data.class = classToken or "WARRIOR"

    local hp = UnitHealth(unit)
    local hpMax = UnitHealthMax(unit)
    data.hp = (hpMax and hpMax > 0) and math.floor((hp / hpMax) * 100) or 0
    data.isDead = UnitIsDead(unit) or UnitIsGhost(unit)
    data.isOnline = UnitIsConnected(unit)

    local role = "DPS"
    if Sequito.RaidSync and Sequito.RaidSync.RaidData and Sequito.RaidSync.RaidData[data.name] then
        role = Sequito.RaidSync.RaidData[data.name].role or "DPS"
    elseif UnitIsUnit(unit, "player") and Universal and Universal.GetPlayerRole then
        role = Universal:GetPlayerRole()
    end
    data.role = role

    if not data.isOnline then
        data.status = "OFF"
    elseif data.isDead then
        data.status = "DEAD"
    elseif data.hp < 30 then
        data.status = "LOW"
    else
        data.status = "OK"
    end

    local c = CLASS_COLORS[data.class]
    if c then
        data.r, data.g, data.b = c[1], c[2], c[3]
    else
        data.r, data.g, data.b = 0.5, 0.5, 0.5
    end
    return true
end

-- Comparador estático para table.sort
local function CompareByClass(a, b)
    if a.class ~= b.class then
        return a.class < b.class
    end
    return a.name < b.name
end

-- Actualización periódica y segura
function RaidPanel:UpdateMembers(forceFullRefresh)
    if not mainFrame or not mainFrame:IsVisible() then return end
    if not self:GetOption("enabled") then return end

    local inCombat = InCombatLockdown()
    local showHP = self:GetOption("showHP")
    local showRoles = self:GetOption("showRoles")

    -- Si estamos en combate y no es refresco forzado fuera de combate:
    -- NO alterar atributos seguros ni visibilidad de widgets protegidos
    if inCombat and not forceFullRefresh then
        for i = 1, PANEL_CONFIG.maxRows do
            local row = memberRows[i]
            if row and row.activeUnit and UnitExists(row.activeUnit) then
                local u = row.activeUnit
                local hp = UnitHealth(u)
                local hpMax = UnitHealthMax(u)
                local pct = (hpMax and hpMax > 0) and math.floor((hp / hpMax) * 100) or 0
                local dead = UnitIsDead(u) or UnitIsGhost(u)
                local online = UnitIsConnected(u)

                row.hpBar:SetValue(pct)
                if not online then
                    row.statusText:SetText("OFF")
                    row.statusText:SetTextColor(0.5, 0.5, 0.5, 1)
                    row.hpBar:SetStatusBarColor(0.2, 0.2, 0.2, 0.8)
                elseif dead then
                    row.statusText:SetText("DEAD")
                    row.statusText:SetTextColor(1, 0.2, 0.2, 1)
                    row.hpBar:SetStatusBarColor(0.2, 0.2, 0.2, 0.8)
                else
                    if pct < 30 then
                        row.statusText:SetText("LOW")
                        row.statusText:SetTextColor(1, 0.5, 0.2, 1)
                    else
                        row.statusText:SetText("OK")
                        row.statusText:SetTextColor(0.2, 1, 0.2, 1)
                    end
                    local c = CLASS_COLORS[row.unitClass or "WARRIOR"] or {0.5, 0.5, 0.5}
                    row.hpBar:SetStatusBarColor(c[1], c[2], c[3], 0.85)
                end

                if showHP then
                    row.hpText:SetText(pct .. "%")
                    row.hpText:Show()
                else
                    row.hpText:Hide()
                end
            end
        end
        return
    end

    -- FUERA DE COMBATE: Recolección y Reordenamiento Seguro
    for k in pairs(staticMembersList) do staticMembersList[k] = nil end
    local numMembers = 0
    local tankCount, healerCount, dpsCount = 0, 0, 0

    local inRaid = (GetNumRaidMembers() > 0)
    local inParty = (GetNumPartyMembers() > 0)

    if inRaid then
        local count = math.min(40, GetNumRaidMembers())
        for i = 1, count do
            local unit = "raid" .. i
            local data = staticMemberPool[numMembers + 1]
            if data and PopulateMemberData(data, unit) then
                numMembers = numMembers + 1
                staticMembersList[numMembers] = data
                if data.role == "TANK" then tankCount = tankCount + 1
                elseif data.role == "HEALER" then healerCount = healerCount + 1
                else dpsCount = dpsCount + 1 end
            end
        end
    elseif inParty then
        local pData = staticMemberPool[1]
        if PopulateMemberData(pData, "player") then
            numMembers = 1
            staticMembersList[1] = pData
            if pData.role == "TANK" then tankCount = 1
            elseif pData.role == "HEALER" then healerCount = 1
            else dpsCount = 1 end
        end
        local partyCount = GetNumPartyMembers()
        for i = 1, partyCount do
            local unit = "party" .. i
            local data = staticMemberPool[numMembers + 1]
            if data and PopulateMemberData(data, unit) then
                numMembers = numMembers + 1
                staticMembersList[numMembers] = data
                if data.role == "TANK" then tankCount = tankCount + 1
                elseif data.role == "HEALER" then healerCount = healerCount + 1
                else dpsCount = dpsCount + 1 end
            end
        end
    else
        local pData = staticMemberPool[1]
        if PopulateMemberData(pData, "player") then
            numMembers = 1
            staticMembersList[1] = pData
            dpsCount = 1
        end
    end

    -- Ordenar por clase (seguro fuera de combate)
    table.sort(staticMembersList, CompareByClass)

    -- Aplicar a las filas
    for i = 1, PANEL_CONFIG.maxRows do
        local row = memberRows[i]
        local member = staticMembersList[i]

        if member then
            row.activeUnit = member.unit
            row.unitClass = member.class

            -- Configurar atributos seguros
            if not inCombat then
                row:SetAttribute("unit", member.unit)
            end

            -- Barra de salud y colores
            row.hpBar:SetMinMaxValues(0, 100)
            row.hpBar:SetValue(member.hp)

            if member.status == "DEAD" or member.status == "OFF" then
                row.hpBar:SetStatusBarColor(0.2, 0.2, 0.2, 0.8)
                row.nameText:SetTextColor(0.5, 0.5, 0.5, 1)
            else
                row.hpBar:SetStatusBarColor(member.r, member.g, member.b, 0.85)
                row.nameText:SetTextColor(1, 1, 1, 1)
            end

            -- Textos
            row.nameText:SetText(member.name)
            row.indexText:SetText(i)
            row.classText:SetText(member.class)
            row.classText:SetTextColor(member.r, member.g, member.b, 1)

            if showHP then
                row.hpText:SetText(member.hp .. "%")
                row.hpText:Show()
            else
                row.hpText:Hide()
            end

            row.statusText:SetText(member.status)
            if member.status == "OK" then
                row.statusText:SetTextColor(0.2, 1, 0.2, 1)
            elseif member.status == "LOW" then
                row.statusText:SetTextColor(1, 0.5, 0.2, 1)
            elseif member.status == "DEAD" then
                row.statusText:SetTextColor(1, 0.2, 0.2, 1)
            else
                row.statusText:SetTextColor(0.5, 0.5, 0.5, 1)
            end

            -- Icono de rol
            if showRoles then
                local coords = ROLE_TEXCOORDS[member.role] or ROLE_TEXCOORDS["DPS"]
                row.roleIcon:SetTexCoord(unpack(coords))
                row.roleIcon:Show()
            else
                row.roleIcon:Hide()
            end

            if not inCombat then
                row:Show()
            end
        else
            row.activeUnit = nil
            if not inCombat then
                row:Hide()
            end
        end
    end

    -- Footer
    mainFrame.footer:SetText(string.format(
        "Total: %d | Tanques: %d | Sanadores: %d | DPS: %d",
        numMembers, tankCount, healerCount, dpsCount
    ))
end

-- Mostrar el panel
function RaidPanel:Show()
    if not self:GetOption("enabled") then return end
    if not mainFrame then CreateMainFrame() end

    local scale = self:GetOption("scale") or 1.0
    mainFrame:SetScale(scale)
    mainFrame:Show()
    isVisible = true

    self:UpdateMembers(true)
    if Sequito.Print then
        Sequito:Print("Panel de Banda visible. Usa |cFFFFD700/srp|r para ocultar.")
    end
end

-- Ocultar el panel
function RaidPanel:Hide()
    if mainFrame then
        mainFrame:Hide()
    end
    isVisible = false
end

-- Toggle
function RaidPanel:Toggle()
    if isVisible and mainFrame and mainFrame:IsShown() then
        self:Hide()
    else
        self:Show()
    end
end

function RaidPanel:IsVisible()
    return isVisible and mainFrame and mainFrame:IsShown()
end

-- Inicialización
function RaidPanel:Initialize()
    if self.initialized then return end
    if not self:GetOption("enabled") then return end
    self.initialized = true

    self.frame = CreateMainFrame()
    self:RegisterEvents()
    self:CreateSlashCommands()

    if Sequito.Print then
        Sequito:Print("[RaidPanel] Panel visual de banda iniciado.")
    end
end

function RaidPanel:CreateSlashCommands()
    SLASH_SEQUITORP1 = "/srp"
    SLASH_SEQUITORP2 = "/seqpanel"
    SlashCmdList["SEQUITORP"] = function()
        RaidPanel:Toggle()
    end
end

function RaidPanel:RegisterEvents()
    local f = CreateFrame("Frame")
    f:RegisterEvent("RAID_ROSTER_UPDATE")
    f:RegisterEvent("PARTY_MEMBERS_CHANGED")
    f:RegisterEvent("PLAYER_ENTERING_WORLD")
    f:RegisterEvent("PLAYER_REGEN_DISABLED")
    f:RegisterEvent("PLAYER_REGEN_ENABLED")

    f:SetScript("OnEvent", function(self, event)
        if event == "PLAYER_REGEN_DISABLED" then
            -- Entrando en combate: nada pendiente
            pendingRosterUpdate = false
        elseif event == "PLAYER_REGEN_ENABLED" then
            -- Al salir de combate, si hubo cambios en la raid, refrescar completo de inmediato
            if pendingRosterUpdate then
                pendingRosterUpdate = false
                RaidPanel:UpdateMembers(true)
            end
        elseif event == "RAID_ROSTER_UPDATE" or event == "PARTY_MEMBERS_CHANGED" or event == "PLAYER_ENTERING_WORLD" then
            if InCombatLockdown() then
                pendingRosterUpdate = true
            else
                if RaidPanel:GetOption("autoShow") and (GetNumRaidMembers() > 0 or GetNumPartyMembers() > 0) then
                    if not RaidPanel:IsVisible() then
                        RaidPanel:Show()
                    end
                end
                if RaidPanel:IsVisible() then
                    RaidPanel:UpdateMembers(true)
                end
            end
        end
    end)
end

-- Registrar en Sequito
Sequito.RaidPanel = RaidPanel

-- Registrar módulo en ModuleConfig
if Sequito.ModuleConfig then
    Sequito.ModuleConfig:RegisterModule("RaidPanel", {
        name = "Panel de Banda",
        description = "Panel visual HUD con información y selección segura de miembros",
        category = "raid",
        icon = "Interface\\Icons\\INV_Misc_GroupLooking",
        options = {
            {key = "enabled", type = "checkbox", label = "Habilitar Panel de Banda", default = true},
            {key = "autoShow", type = "checkbox", label = "Mostrar automáticamente en grupo/banda", default = false},
            {key = "showHP", type = "checkbox", label = "Mostrar HP%", default = true},
            {key = "showRoles", type = "checkbox", label = "Mostrar iconos de rol", default = true},
            {key = "scale", type = "slider", label = "Escala del panel", min = 0.5, max = 1.5, step = 0.1, default = 1.0},
        }
    })
end
