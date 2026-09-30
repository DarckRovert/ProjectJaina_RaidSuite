--[[
    Sequito - RaidPanel.lua
    Panel Visual de Raid con información de todos los miembros
    Muestra clase, spec, rol, HP, mana y estado de cada jugador
]]--

local addonName, Sequito = ...
Sequito.RaidPanel = Sequito.RaidPanel or {}

local RaidPanel = Sequito.RaidPanel
local Universal = Sequito.Universal
local RaidSync = Sequito.RaidSync

-- Helper para obtener configuración
function RaidPanel:GetOption(key)
    if Sequito.ModuleConfig then
        return Sequito.ModuleConfig:GetValue("RaidPanel", key)
    end
    return true
end

-- Configuración del panel
local PANEL_CONFIG = {
    width = 320,
    height = 450,
    rowHeight = 18,
    maxRows = 40,
    headerHeight = 25,
    padding = 5,
    updateInterval = 1.0, -- Actualizar cada segundo
}

-- Colores de clase (RGBA)
local CLASS_COLORS = {
    ["WARRIOR"] = {0.78, 0.61, 0.43, 1},
    ["PALADIN"] = {0.96, 0.55, 0.73, 1},
    ["HUNTER"] = {0.67, 0.83, 0.45, 1},
    ["ROGUE"] = {1.00, 0.96, 0.41, 1},
    ["PRIEST"] = {1.00, 1.00, 1.00, 1},
    ["DEATHKNIGHT"] = {0.77, 0.12, 0.23, 1},
    ["SHAMAN"] = {0.00, 0.44, 0.87, 1},
    ["MAGE"] = {0.41, 0.80, 0.94, 1},
    ["WARLOCK"] = {0.58, 0.51, 0.79, 1},
    ["DRUID"] = {1.00, 0.49, 0.04, 1},
}

-- Iconos de rol
local ROLE_ICONS = {
    ["TANK"] = "Interface\\LFGFrame\\UI-LFG-ICON-PORTRAITROLES",
    ["HEALER"] = "Interface\\LFGFrame\\UI-LFG-ICON-PORTRAITROLES",
    ["DPS"] = "Interface\\LFGFrame\\UI-LFG-ICON-PORTRAITROLES",
}

local ROLE_TEXCOORDS = {
    ["TANK"] = {0, 0.25, 0.25, 0.5},
    ["HEALER"] = {0.25, 0.5, 0, 0.25},
    ["DPS"] = {0.25, 0.5, 0.25, 0.5},
}

-- Variables del panel
local mainFrame = nil
local memberRows = {}
local isVisible = false
local lastUpdate = 0

-- [INITIALIZE REMOVED: Duplicate found later in file]

-- Crear el frame principal del panel
local function CreateMainFrame()
    if mainFrame then return mainFrame end
    
    -- Frame principal
    mainFrame = CreateFrame("Frame", "SequitoRaidPanel", UIParent)
    mainFrame:SetSize(PANEL_CONFIG.width, PANEL_CONFIG.height)
    mainFrame:SetPoint("RIGHT", UIParent, "RIGHT", -20, 0)
    mainFrame:SetMovable(true)
    mainFrame:EnableMouse(true)
    mainFrame:RegisterForDrag("LeftButton")
    mainFrame:SetScript("OnDragStart", mainFrame.StartMoving)
    mainFrame:SetScript("OnDragStop", mainFrame.StopMovingOrSizing)
    mainFrame:SetClampedToScreen(true)
    mainFrame:Hide()
    
    -- Fondo
    mainFrame.bg = mainFrame:CreateTexture(nil, "BACKGROUND")
    mainFrame.bg:SetAllPoints()
    mainFrame.bg:SetTexture("Interface\\Buttons\\WHITE8X8")
    mainFrame.bg:SetVertexColor(0.05, 0.05, 0.1, 0.9)
    
    -- Borde
    mainFrame.border = CreateFrame("Frame", nil, mainFrame)
    mainFrame.border:SetAllPoints()
    mainFrame.border:SetBackdrop({
        edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
        edgeSize = 16,
        insets = {left = 4, right = 4, top = 4, bottom = 4},
    })
    mainFrame.border:SetBackdropBorderColor(0.3, 0.3, 0.3, 1) -- Darker border
    
    -- Título
    mainFrame.title = mainFrame:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
    mainFrame.title:SetPoint("TOP", mainFrame, "TOP", 0, -8)
    mainFrame.title:SetText("|cff9966ffSequito|r - Raid Panel")
    
    -- Botón de cerrar
    mainFrame.closeBtn = CreateFrame("Button", nil, mainFrame, "UIPanelCloseButton")
    mainFrame.closeBtn:SetPoint("TOPRIGHT", mainFrame, "TOPRIGHT", -2, -2)
    mainFrame.closeBtn:SetScript("OnClick", function()
        RaidPanel:Hide()
    end)
    
    -- Header con columnas
    mainFrame.header = CreateFrame("Frame", nil, mainFrame)
    mainFrame.header:SetSize(PANEL_CONFIG.width - 20, PANEL_CONFIG.headerHeight)
    mainFrame.header:SetPoint("TOPLEFT", mainFrame, "TOPLEFT", 10, -30)
    
    -- Columnas del header (Responsive config)
    local columns = {
        {key = "index",  text = "#",      width = 25, align = "LEFT"},
        {key = "role",   text = "Rol",    width = 30, align = "CENTER"},
        {key = "class",  text = "Clase",  width = 60, align = "LEFT"},
        {key = "name",   text = "Nombre", width = 0,  align = "LEFT", isDynamic = true}, -- 0 = Fill
        {key = "hp",     text = "HP%",    width = 50, align = "RIGHT"},
        {key = "status", text = "Estado", width = 60, align = "CENTER"},
    }
    mainFrame.columns = columns
    
    local function UpdateLayout()
        local totalWidth = mainFrame:GetWidth()
        -- Safety check for width
        if not totalWidth or totalWidth < 100 then totalWidth = PANEL_CONFIG.width end
        
        local effectiveWidth = totalWidth - 40 
        
        -- Header Background strip
        if not mainFrame.headerBg then
            mainFrame.headerBg = mainFrame.header:CreateTexture(nil, "BACKGROUND")
            mainFrame.headerBg:SetAllPoints()
            mainFrame.headerBg:SetTexture("Interface\\Buttons\\WHITE8X8")
            mainFrame.headerBg:SetVertexColor(0.1, 0.1, 0.1, 0.5)
        end
        mainFrame.header:SetWidth(effectiveWidth)
        
        -- Calculate dynamic width
        local fixedWidth = 0
        for _, col in ipairs(columns) do
            if not col.isDynamic then fixedWidth = fixedWidth + col.width end
        end
        
        -- Ensure dynamic width is never missing or zero
        local dynamicWidth = math.max(60, effectiveWidth - fixedWidth)
        
        -- Position Headers
        local currentX = 5 -- Add Padding
        if not mainFrame.headerTexts then mainFrame.headerTexts = {} end
        
        for i, col in ipairs(columns) do
            local t = mainFrame.headerTexts[i]
            if not t then
                t = mainFrame.header:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
                t:SetTextColor(0.8, 0.8, 0.2, 1)
                mainFrame.headerTexts[i] = t
            end
            
            local w = col.isDynamic and dynamicWidth or col.width
            col.currentWidth = w -- Store for rows
            
            t:ClearAllPoints()
            t:SetPoint("LEFT", mainFrame.header, "LEFT", currentX, 0)
            t:SetWidth(w)
            t:SetText(col.text)
            t:SetJustifyH(col.align)
            
            currentX = currentX + w
        end
        
        -- Update ScrollFrame size
        mainFrame.scrollFrame:SetSize(totalWidth - 30, mainFrame:GetHeight() - 60)
        mainFrame.separator:SetWidth(totalWidth - 20)
        mainFrame.content:SetWidth(totalWidth - 30)
    end
    mainFrame.UpdateLayout = UpdateLayout
    
    mainFrame:SetScript("OnShow", function() UpdateLayout() end)
    mainFrame:SetScript("OnSizeChanged", function() UpdateLayout() end)
    
    -- Línea separadora
    mainFrame.separator = mainFrame:CreateTexture(nil, "ARTWORK")
    mainFrame.separator:SetSize(PANEL_CONFIG.width - 20, 1)
    mainFrame.separator:SetPoint("TOPLEFT", mainFrame.header, "BOTTOMLEFT", 0, -2)
    mainFrame.separator:SetTexture("Interface\\Buttons\\WHITE8X8")
    mainFrame.separator:SetVertexColor(0.5, 0.5, 0.5, 0.5)
    
    -- ScrollFrame para la lista de miembros
    mainFrame.scrollFrame = CreateFrame("ScrollFrame", "SequitoRaidPanelScroll", mainFrame, "UIPanelScrollFrameTemplate")
    mainFrame.scrollFrame:SetPoint("TOPLEFT", mainFrame.separator, "BOTTOMLEFT", 0, -5)
    mainFrame.scrollFrame:SetPoint("BOTTOMRIGHT", mainFrame, "BOTTOMRIGHT", -25, 25) -- Leave space for Footer and ScrollBar
    
    -- Content frame dentro del scroll
    mainFrame.content = CreateFrame("Frame", nil, mainFrame.scrollFrame)
    mainFrame.content:SetSize(PANEL_CONFIG.width - 30, PANEL_CONFIG.maxRows * PANEL_CONFIG.rowHeight)
    mainFrame.scrollFrame:SetScrollChild(mainFrame.content)
    
    -- Crear filas para miembros
    for i = 1, PANEL_CONFIG.maxRows do
        local row = CreateMemberRow(mainFrame.content, i)
        row:SetPoint("TOPLEFT", mainFrame.content, "TOPLEFT", 0, -((i-1) * PANEL_CONFIG.rowHeight))
        memberRows[i] = row
    end
    
    -- Footer con estadísticas
    mainFrame.footer = mainFrame:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    mainFrame.footer:SetPoint("BOTTOM", mainFrame, "BOTTOM", 0, 8)
    mainFrame.footer:SetText("Total: 0 | Tanks: 0 | Healers: 0 | DPS: 0")
    mainFrame.footer:SetTextColor(0.7, 0.7, 0.7, 1)
    
    -- Script de actualización
    mainFrame:SetScript("OnUpdate", function(self, elapsed)
        lastUpdate = lastUpdate + elapsed
        if lastUpdate >= PANEL_CONFIG.updateInterval then
            lastUpdate = 0
            RaidPanel:UpdateMembers()
        end
    end)
    
    return mainFrame
end

-- ===========================================================================
-- HELPER VISUAL
-- ===========================================================================
function UpdateRowLayout(row, columns)
    local currentX = 5
    row:SetWidth(row:GetParent():GetWidth())
    
    -- Safe Widths
    local w1 = (columns[1] and columns[1].currentWidth) or 20
    local w2 = (columns[2] and columns[2].currentWidth) or 20
    local w3 = (columns[3] and columns[3].currentWidth) or 40
    local w4 = (columns[4] and columns[4].currentWidth) or 100
    local w5 = (columns[5] and columns[5].currentWidth) or 50
    local w6 = (columns[6] and columns[6].currentWidth) or 60
    
    -- # Index
    row.indexText:SetPoint("LEFT", row, "LEFT", currentX, 0)
    row.indexText:SetWidth(w1)
    currentX = currentX + w1
    
    -- Role
    row.roleIcon:ClearAllPoints()
    row.roleIcon:SetPoint("CENTER", row, "LEFT", currentX + (w2/2), 0)
    currentX = currentX + w2
    
    -- Class
    row.classText:SetPoint("LEFT", row, "LEFT", currentX, 0)
    row.classText:SetWidth(w3)
    currentX = currentX + w3
    
    -- Name
    row.nameText:SetPoint("LEFT", row, "LEFT", currentX, 0)
    row.nameText:SetWidth(w4)
    currentX = currentX + w4
    
    -- HP
    row.hpText:SetPoint("LEFT", row, "LEFT", currentX, 0)
    row.hpText:SetWidth(w5)
    currentX = currentX + w5
    
    -- Status
    row.statusText:SetPoint("LEFT", row, "LEFT", currentX, 0)
    row.statusText:SetWidth(w6)
end

-- ===========================================================================
-- LOGICA DE MIEMBROS
-- ===========================================================================
function CreateMemberRow(parent, index)
    local row = CreateFrame("Button", "SequitoRaidRow"..index, parent, "SecureUnitButtonTemplate")
    row:SetSize(PANEL_CONFIG.width - 30, PANEL_CONFIG.rowHeight)
    row:EnableMouse(true)
    
    -- Health Bar (Replacing plain background)
    row.hpBar = CreateFrame("StatusBar", nil, row)
    row.hpBar:SetAllPoints()
    -- Use specific trustworthy texture or solid color
    row.hpBar:SetStatusBarTexture("Interface\\Buttons\\WHITE8x8")
    row.hpBar:SetFrameLevel(row:GetFrameLevel() + 1)
    
    -- Background for Bar
    row.bg = row.hpBar:CreateTexture(nil, "BACKGROUND")
    row.bg:SetAllPoints()
    row.bg:SetTexture("Interface\\Buttons\\WHITE8X8")
    row.bg:SetVertexColor(0, 0, 0, 0.8) -- Darker background

    -- Highlight logic
    row:SetScript("OnEnter", function(self) 
        self.hpBar:SetAlpha(1) 
        if self.nameText then self.nameText:SetTextColor(1, 1, 0) end
    end)
    row:SetScript("OnLeave", function(self) 
        self.hpBar:SetAlpha(0.9)
        if self.nameText then 
            -- Restore class color (we need to store it somewhere, or just reset to white for simplicity now)
            -- Ideally we'd re-run color logic, but white is distinct enough.
            self.nameText:SetTextColor(1, 1, 1) 
        end
    end)
    
    row:RegisterForClicks("AnyUp")
    row:SetAttribute("type", "target")
    
    -- Use GameFontNormalSmall for rows with outline for readability over bar
    local font, size, flags = GameFontNormalSmall:GetFont()
    local outlineFont = "Fonts\\FRIZQT__.TTF" -- Default but explicit
    
    row.indexText = row:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    row.indexText:SetFont(font, size, "OUTLINE")
    row.indexText:SetJustifyH("RIGHT")
    row.indexText:SetTextColor(0.7, 0.7, 0.7)
    
    row.nameText = row:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    row.nameText:SetFont(font, size, "OUTLINE")
    row.nameText:SetJustifyH("LEFT")
    row.nameText:SetTextColor(1, 1, 1)
    
    row.classText = row:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    row.classText:SetFont(font, size, "OUTLINE")
    row.classText:SetJustifyH("LEFT")
    row.classText:SetTextColor(0.8, 0.8, 0.8)
    
    row.roleIcon = row:CreateTexture(nil, "OVERLAY")
    row.roleIcon:SetSize(14, 14)
    
    row.hpText = row:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    row.hpText:SetFont(font, size, "OUTLINE")
    row.hpText:SetJustifyH("RIGHT")
    
    row.statusText = row:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    row.statusText:SetFont(font, size, "OUTLINE")
    row.statusText:SetHeight(PANEL_CONFIG.rowHeight)
    row.statusText:SetJustifyH("CENTER")
    -- row.statusText:SetJustifyV("MIDDLE")
    
    row:Hide()
    return row
end

local function GetMemberInfo(unit)
    if not UnitExists(unit) then return nil end
    local name = UnitName(unit)
    local _, classToken = UnitClass(unit)
    local hp = UnitHealth(unit)
    local hpMax = UnitHealthMax(unit)
    local hpPercent = (hpMax and hpMax > 0) and math.floor((hp / hpMax) * 100) or 0
    local isDead = UnitIsDead(unit) or UnitIsGhost(unit)
    local isOnline = UnitIsConnected(unit)
    
    -- ROLE LOGIC:
    -- 1. Try RaidSync data (Most accurate, transmitted by players)
    -- 2. Fallback to "DPS"
    local role = "DPS"
    
    if Sequito.RaidSync and Sequito.RaidSync.RaidData and Sequito.RaidSync.RaidData[name] then
        role = Sequito.RaidSync.RaidData[name].role or "DPS"
    elseif UnitIsUnit(unit, "player") and Universal and Universal.GetPlayerRole then
        role = Universal:GetPlayerRole() 
    end
    
    local status = "OK"
    local statusColor = {0.2, 1, 0.2, 1}
    if not isOnline then status = "OFF"; statusColor = {0.5, 0.5, 0.5, 1}
    elseif isDead then status = "DEAD"; statusColor = {1, 0.2, 0.2, 1}
    elseif hpPercent < 30 then status = "LOW"; statusColor = {1, 0.5, 0.2, 1} end
    
    return { unit = unit, name = name, class = classToken or "WARRIOR", hp = hpPercent, status = status, statusColor = statusColor, role = role }
end

function RaidPanel:UpdateMembers()
    if not mainFrame or not mainFrame:IsVisible() then return end
    if mainFrame.UpdateLayout then mainFrame:UpdateLayout() end 
    local columns = mainFrame.columns
    
    local members = {}
    local numMembers = 0
    local tankCount, healerCount, dpsCount = 0, 0, 0
    
    local inRaid = (GetNumRaidMembers() > 0)
    local inParty = GetNumPartyMembers() > 0
    
    -- Gather Logic
    if inRaid then
        for i = 1, 40 do
            local unit = "raid"..i
            local info = GetMemberInfo(unit)
            if info then
                numMembers = numMembers + 1
                info.index = numMembers
                table.insert(members, info)
                if info.role == "TANK" then tankCount = tankCount + 1
                elseif info.role == "HEALER" then healerCount = healerCount + 1
                else dpsCount = dpsCount + 1 end
            end
        end
    elseif inParty then
        local pInfo = GetMemberInfo("player"); if pInfo then 
            pInfo.index=1; table.insert(members, pInfo); numMembers=1 
            local r=pInfo.role; if r=="TANK" then tankCount=1 elseif r=="HEALER" then healerCount=1 else dpsCount=1 end
        end
        for i=1,4 do
            local info = GetMemberInfo("party"..i)
            if info then 
                numMembers=numMembers+1; info.index=numMembers; table.insert(members, info) 
               local r=info.role; if r=="TANK" then tankCount=tankCount+1 elseif r=="HEALER" then healerCount=healerCount+1 else dpsCount=dpsCount+1 end
            end
        end
    else
        local pInfo = GetMemberInfo("player"); if pInfo then 
            pInfo.index=1; table.insert(members, pInfo); numMembers=1; dpsCount=1
        end
    end
    
    -- Sort (Simplificado por Clase)
    table.sort(members, function(a, b) return a.class < b.class end)
    
    -- Populate
    for i = 1, PANEL_CONFIG.maxRows do
        local row = memberRows[i]
        local member = members[i]
        
        if member then
            -- Configurar fila
            row.unit = member.unit
            if not InCombatLockdown() then
                row:SetAttribute("unit", member.unit)
            end
            
            -- Debug Prints REMOVED
            
            -- Setup Colors logic (Class Colors for Bar)
            local r, g, b = 0.5, 0.5, 0.5
            if member.class then
                local c = CLASS_COLORS[member.class]
                if c then r,g,b = c[1], c[2], c[3] end -- Changed to index access if table is {r,g,b,a}
            end
            
            -- Bar Update
            row.hpBar:SetMinMaxValues(0, 100)
            row.hpBar:SetValue(member.hp or 100)
            
            if member.status == "DEAD" or member.status == "OFF" then
                row.hpBar:SetStatusBarColor(0.2, 0.2, 0.2, 0.8) -- Grey for dead/offline
                if row.nameText then row.nameText:SetTextColor(0.5, 0.5, 0.5) end
            else
                row.hpBar:SetStatusBarColor(r, g, b, 0.8) -- Class Color Bar
                if row.nameText then row.nameText:SetTextColor(1, 1, 1) end -- Name White
            end

            -- Update Texts
            if row.nameText then row.nameText:SetText(member.name) end
            if row.indexText then row.indexText:SetText(i) end
            if row.classText then row.classText:SetText(member.class); row.classText:SetTextColor(r,g,b) end -- Class Text Colored
            if row.hpText then row.hpText:SetText(member.hp .. "%"); row.hpText:SetTextColor(1, 1, 1) end
            if row.statusText then row.statusText:SetText(member.status or "OK"); 
                -- Color status text
                local sc = member.statusColor
                if sc then row.statusText:SetTextColor(unpack(sc)) end
            end
            if row.roleIcon then
                 row.roleIcon:SetTexture("Interface\\LFGFrame\\UI-LFG-ICON-PORTRAITROLES")
                 local coords = ROLE_TEXCOORDS[member.role] or ROLE_TEXCOORDS["DPS"]
                 row.roleIcon:SetTexCoord(unpack(coords))
            end

            -- Refresh Layout
            UpdateRowLayout(row, mainFrame.columns)
            
            row:Show()
            -- Removed SetFrameLevel forcing to rely on natural hierarchy
        else
            row:Hide()
        end
    end
    
    -- Actualizar footer
    mainFrame.footer:SetText(string.format(
        "Total: %d | Tanks: %d | Healers: %d | DPS: %d",
        numMembers, tankCount, healerCount, dpsCount
    ))
end
    


-- Mostrar el panel
function RaidPanel:Show()
    if not Sequito.db.profile.ShowRaidPanel then return end

    if not mainFrame then
        CreateMainFrame()
    end
    
    -- Apply Scale
    local scale = Sequito.db.profile.RaidPanelScale or 1.0
    mainFrame:SetScale(scale)
    
    mainFrame:Show()
    isVisible = true
    self:UpdateMembers()
    Sequito:Print("Raid Panel abierto.")
end

-- Ocultar el panel
function RaidPanel:Hide()
    if mainFrame then
        mainFrame:Hide()
    end
    isVisible = false
end

-- Toggle del panel
function RaidPanel:Toggle()
    if isVisible then
        self:Hide()
    else
        self:Show()
    end
end

-- Verificar si está visible
function RaidPanel:IsVisible()
    return isVisible
end

-- Inicialización

-- Helper para obtener configuración
function RaidPanel:GetOption(key)
    if Sequito.ModuleConfig then
        return Sequito.ModuleConfig:GetValue("RaidPanel", key)
    end
    return true
end

-- ===========================================================================
-- INICIALIZACIÓN
-- ===========================================================================
function RaidPanel:Initialize()
    if self.initialized then return end
    if not self:GetOption("enabled") then 
        print("|cFFFF9900Sequito|r: [RaidPanel] Deshabilitado por configuración.")
        return 
    end
    self.initialized = true
    
    self.frame = CreateMainFrame()
    
    -- Register with Dashboard
    if Sequito.Dashboard and Sequito.Dashboard.RegisterTab then
        print("|cFF00FFFFSequito|r: [RaidPanel] Registrando tab en Dashboard...")
        
        -- Ajustar visuales para modo Dashboard (eliminar decoraciones redundantes)
        self.frame:SetMovable(false)
        self.frame:SetScript("OnDragStart", nil)
        self.frame:SetScript("OnDragStop", nil)
        
        self.frame:SetBackdrop(nil) -- Quitar borde/fondo del frame principal
        if self.frame.bg then self.frame.bg:Hide() end
        if self.frame.border then self.frame.border:Hide() end
        if self.frame.closeBtn then self.frame.closeBtn:Hide() end
        if self.frame.title then self.frame.title:Hide() end
        
        -- Reposicionar header - Asegurar que sea visible
        if self.frame.header then
            self.frame.header:ClearAllPoints()
            self.frame.header:SetPoint("TOPLEFT", self.frame, "TOPLEFT", 10, -10)
            self.frame.header:SetParent(self.frame) 
            self.frame.header:Show()
        end
        
        Sequito.Dashboard:RegisterTab("Raid Panel", "Interface\\Icons\\INV_Misc_GroupLooking", self.frame)
        print("|cFF00FF00Sequito|r: [RaidPanel] Tab registrado y estilizado!")
    else
        print("|cFFFF0000Sequito ERROR:|r Dashboard no disponible para RaidPanel")
        self.frame:Hide()
    end

    self:RegisterEvents()
    self:CreateSlashCommands()
    
    print("|cFFFF00FFSequito|r: [RaidPanel] Panel visual iniciado.")
end

function RaidPanel:CreateSlashCommands()
    SLASH_SEQUITORP1 = "/srp"
    SLASH_SEQUITORP2 = "/seqpanel"
    SlashCmdList["SEQUITORP"] = function()
        if Sequito.Dashboard then
             Sequito.Dashboard:Toggle()
        else
            self:Toggle()
        end
    end
end

-- Eventos para AutoShow (moved from old Initialize)
function RaidPanel:RegisterEvents()
    local f = CreateFrame("Frame")
    f:RegisterEvent("RAID_ROSTER_UPDATE")
    f:RegisterEvent("PLAYER_ENTERING_WORLD")
    f:SetScript("OnEvent", function(self, event)
        if Sequito.db.profile.ShowRaidPanel and Sequito.db.profile.RaidPanelAuto and (GetNumRaidMembers() > 0) then
            if not RaidPanel:IsVisible() then
                 RaidPanel:Show()
            end
        end
    end)
    
    -- Check initial state
    if Sequito.db.profile.ShowRaidPanel and Sequito.db.profile.RaidPanelAuto and (GetNumRaidMembers() > 0) then
         self:Show()
    end
end

-- Registrar en Sequito
Sequito.RaidPanel = RaidPanel

-- Registrar módulo en ModuleConfig
if Sequito.ModuleConfig then
    Sequito.ModuleConfig:RegisterModule("RaidPanel", {
        name = "Raid Panel",
        description = "Panel visual de raid con información de todos los miembros",
        category = "raid",
        icon = "Interface\\\\Icons\\\\INV_Misc_GroupLooking",
        options = {
            {key = "enabled", type = "checkbox", label = "Habilitar Raid Panel", default = true},
            {key = "autoShow", type = "checkbox", label = "Mostrar automáticamente en raid", default = false},
            {key = "showHP", type = "checkbox", label = "Mostrar HP%", default = true},
            {key = "showRoles", type = "checkbox", label = "Mostrar iconos de rol", default = true},
            {key = "scale", type = "slider", label = "Escala del panel", min = 0.5, max = 1.5, step = 0.1, default = 1.0},
        }
    })
end

