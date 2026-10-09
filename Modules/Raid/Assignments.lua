--[[
    Jaina - Assignments.lua
    Sistema de Asignaciones Automáticas para Raids
    Version: 7.2.0
]]

local addonName, S = ...
S.Assignments = {}
local AS = S.Assignments
local L = S.L or {}

-- Tipos de asignaciones
AS.Types = {
    INTERRUPTS = "interrupts",
    TANKS = "tanks",
    HEALERS = "healers",
    COOLDOWNS = "cooldowns",
    MARKS = "marks",
}

-- Asignaciones actuales
AS.Current = {
    interrupts = {},  -- {target = "Boss", rotation = {"Player1", "Player2", "Player3"}}
    tanks = {},       -- {target = "Add1", tank = "Player1"}
    healers = {},     -- {target = "Tank1", healer = "Player1"}
    cooldowns = {},   -- {phase = 1, spell = "Divine Sacrifice", player = "Player1"}
    marks = {},       -- {skull = "Player1", cross = "Player2"}
}

-- Clases con interrupt
local InterruptClasses = {
    ROGUE = {spellId = 1766, name = "Kick", cd = 10},
    WARRIOR = {spellId = 6552, name = "Pummel", cd = 10},
    DEATHKNIGHT = {spellId = 47528, name = "Mind Freeze", cd = 10},
    SHAMAN = {spellId = 57994, name = "Wind Shear", cd = 6},
    MAGE = {spellId = 2139, name = "Counterspell", cd = 24},
    HUNTER = {spellId = 34490, name = "Silencing Shot", cd = 20},
    PRIEST = {spellId = 15487, name = "Silence", cd = 45}, -- Shadow only
    WARLOCK = {spellId = 19647, name = "Spell Lock", cd = 24}, -- Felhunter
}

-- Clases tank
local TankSpecs = {
    WARRIOR = "Protection",
    PALADIN = "Protection",
    DEATHKNIGHT = "Blood", -- or Frost tank
    DRUID = "Feral",
}

AS.Frame = nil
AS.IsVisible = false

-- Helper para obtener configuración
function AS:GetOption(key)
    if S.ModuleConfig then
        return S.ModuleConfig:GetValue("Assignments", key)
    end
    return true
end

function AS:GetAssignmentsData()
    local profile = (S.db and S.db.profile) or (Jaina and Jaina.db and Jaina.db.profile)
    if not profile then
        if not JainaDB then JainaDB = {} end
        if not JainaDB.profiles then JainaDB.profiles = {} end
        local key = UnitName("player") .. " - " .. (GetRealmName() or "Realm")
        local pName = (JainaDB.profileKeys and JainaDB.profileKeys[key]) or "Default"
        if not JainaDB.profiles[pName] then JainaDB.profiles[pName] = {} end
        profile = JainaDB.profiles[pName]
    end

    -- Migración resiliente desde JainaDB.profile legado si existía
    if JainaDB and JainaDB.profile and JainaDB.profile.AssignmentsData and not profile.AssignmentsData then
        profile.AssignmentsData = JainaDB.profile.AssignmentsData
        JainaDB.profile.AssignmentsData = nil
    end

    if not profile.AssignmentsData then
        profile.AssignmentsData = {
            interrupts = {}, 
            tanks = "",
            healers = "",
            cooldowns = "",
            marks = ""
        }
    end

    return profile.AssignmentsData
end

function AS:Initialize()
    if not self:GetOption("enabled") then
        return
    end
    
    -- Vincular al perfil activo del sistema central
    self.Current = self:GetAssignmentsData()
    
    -- Migración de seguridad (Tablas -> Strings)
    if type(self.Current.tanks) == "table" then self.Current.tanks = "" end
    if type(self.Current.healers) == "table" then self.Current.healers = "" end
    if type(self.Current.cooldowns) == "table" then self.Current.cooldowns = "" end
    if type(self.Current.marks) == "table" then self.Current.marks = "" end
    
    self:CreateFrame()
    self:RegisterComm()
    
    -- Escuchar cambios dinámicos de perfil de Jaina
    if S.RegisterMessage then
        S:RegisterMessage("SEQUITO_PROFILE_CHANGED", function()
            AS.Current = AS:GetAssignmentsData()
            AS:UpdateInterruptersDisplay()
            if AS.editBoxes then
                for key, edit in pairs(AS.editBoxes) do
                    local val = AS.Current[key]
                    if not val or val == "" then
                        edit:SetText(L["NOTE_PLACEHOLDER"] or "...")
                    else
                        edit:SetText(val)
                    end
                end
            end
        end)
    end
    
    if S.ModuleConfig then
        S.ModuleConfig:RegisterModule("Assignments", {
            name = L["ASSIGNMENTS_PANEL"],
            description = "Raids Assignments & Rotations",
            icon = "Interface\\Icons\\INV_Misc_Book_09",
            category = "raid",
            options = {
                {key = "enabled", type = "checkbox", label = L["CFG_ENABLED"], default = true},
                {key = "announce", type = "checkbox", label = L["CFG_ANNOUNCE"], default = true},
            }
        })
    end
end

-- ============================================================================
-- RESOLUCIÓN CONTEXTUAL DE CANAL DE RED Y CHAT (WotLK 3.3.5a)
-- ============================================================================
function AS:GetGroupChannel()
    if IsInInstance then
        local inInstance, instanceType = IsInInstance()
        if inInstance and instanceType == "pvp" then
            return "BATTLEGROUND"
        end
    end
    if GetNumRaidMembers and GetNumRaidMembers() > 0 then
        return "RAID"
    elseif GetNumPartyMembers and GetNumPartyMembers() > 0 then
        return "PARTY"
    end
    return nil
end

function AS:SendChat(msg)
    local channel = self:GetGroupChannel()
    if channel then
        SendChatMessage(msg, channel)
    else
        local f = DEFAULT_CHAT_FRAME or ChatFrame1
        if f and f.AddMessage then
            f:AddMessage(msg)
        end
    end
end

function AS:CreateFrame()
    if self.Frame then return end
    
    local f = CreateFrame("Frame", "JainaAssignments", UIParent)
    f:SetSize(460, 420)
    f:SetPoint("CENTER", UIParent, "CENTER", 0, 0)
    
    -- Fondo elegante
    local bg = f:CreateTexture(nil, "BACKGROUND")
    bg:SetAllPoints()
    bg:SetTexture("Interface\\Buttons\\WHITE8X8")
    bg:SetVertexColor(0, 0, 0, 0.85)
    f.bg = bg
    
    -- Borde fino
    local border = CreateFrame("Frame", nil, f)
    border:SetAllPoints()
    border:SetBackdrop({
        edgeFile = "Interface\\Buttons\\WHITE8x8",
        edgeSize = 1,
    })
    border:SetBackdropBorderColor(0.8, 0.5, 0, 1) -- Borde naranja/dorado
    
    -- Header Strip
    local headerBg = f:CreateTexture(nil, "ARTWORK")
    headerBg:SetPoint("TOPLEFT", f, "TOPLEFT", 0, 0)
    headerBg:SetPoint("BOTTOMRIGHT", f, "TOPRIGHT", 0, -24)
    headerBg:SetTexture("Interface\\Buttons\\WHITE8X8")
    headerBg:SetVertexColor(0.3, 0.2, 0.05, 1) -- Header naranja oscuro
    
    f:EnableMouse(true)
    f:SetMovable(true)
    f:RegisterForDrag("LeftButton")
    f:SetScript("OnDragStart", f.StartMoving)
    f:SetScript("OnDragStop", f.StopMovingOrSizing)
    f:SetClampedToScreen(true)
    f:Hide()
    
    -- Título
    local title = f:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    title:SetPoint("LEFT", headerBg, "LEFT", 10, 0)
    title:SetText("|cffff9900" .. L["ASSIGNMENTS_PANEL"] .. "|r")
    f.title = title
    
    -- Botón cerrar
    local closeBtn = CreateFrame("Button", nil, f, "UIPanelCloseButton")
    closeBtn:SetPoint("TOPRIGHT", f, "TOPRIGHT", -2, -2)
    closeBtn:SetScript("OnClick", function() AS:Toggle() end)
    
    -- Tabs
    local tabs = {"Interrupts", "Tanks", "Healers", "CDs", "Marks"}
    local tabFrames = {}
    f.tabs = {}
    f.tabContents = {}
    
    for i, tabName in ipairs(tabs) do
        local tab = CreateFrame("Button", nil, f, "UIPanelButtonTemplate")
        tab:SetSize(70, 22)
        tab:SetPoint("TOPLEFT", f, "TOPLEFT", 10 + (i-1) * 75, -35)
        tab:SetText(tabName)
        tab:SetScript("OnClick", function()
            AS:ShowTab(tabName:lower())
        end)
        f.tabs[tabName:lower()] = tab
        
        -- Contenido del tab
        local content = CreateFrame("Frame", nil, f)
        content:SetPoint("TOPLEFT", f, "TOPLEFT", 10, -65)
        content:SetPoint("BOTTOMRIGHT", f, "BOTTOMRIGHT", -10, 40)
        content:Hide()
        f.tabContents[tabName:lower()] = content
    end
    
    -- Crear contenido de cada tab
    self:CreateInterruptsTab(f.tabContents["interrupts"])
    self:CreateTanksTab(f.tabContents["tanks"])
    self:CreateHealersTab(f.tabContents["healers"])
    self:CreateCooldownsTab(f.tabContents["cds"])
    self:CreateMarksTab(f.tabContents["marks"])
    
    -- Botones inferiores
    local syncBtn = CreateFrame("Button", nil, f, "UIPanelButtonTemplate")
    syncBtn:SetSize(100, 24)
    syncBtn:SetPoint("BOTTOMLEFT", f, "BOTTOMLEFT", 10, 10)
    syncBtn:SetText(L["SYNC"])
    syncBtn:SetScript("OnClick", function() AS:SyncToRaid() end)
    
    local clearBtn = CreateFrame("Button", nil, f, "UIPanelButtonTemplate")
    clearBtn:SetSize(100, 24)
    clearBtn:SetPoint("BOTTOMRIGHT", f, "BOTTOMRIGHT", -10, 10)
    clearBtn:SetText(L["CLEAR"])
    clearBtn:SetScript("OnClick", function() AS:ClearAll() end)
    
    local announceBtn = CreateFrame("Button", nil, f, "UIPanelButtonTemplate")
    announceBtn:SetSize(100, 24)
    announceBtn:SetPoint("BOTTOM", f, "BOTTOM", 0, 10)
    announceBtn:SetText(L["ANNOUNCE"])
    announceBtn:SetScript("OnClick", function() AS:AnnounceAll() end)
    
    self.Frame = f
    self:ShowTab("interrupts")
end

function AS:CreateInterruptsTab(parent)
    -- Panel Izquierdo: Disponibles
    local availFrame = CreateFrame("Frame", nil, parent)
    availFrame:SetSize(180, 240)
    availFrame:SetPoint("TOPLEFT", parent, "TOPLEFT", 10, -10)
    availFrame:SetBackdrop({
        bgFile = "Interface\\Tooltips\\UI-Tooltip-Background",
        edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
        tile = true, tileSize = 16, edgeSize = 16,
        insets = {left = 4, right = 4, top = 4, bottom = 4}
    })
    availFrame:SetBackdropColor(0, 0, 0, 0.4)
    availFrame:SetBackdropBorderColor(0.4, 0.4, 0.4, 0.6)
    
    local availTitle = availFrame:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    availTitle:SetPoint("TOP", 0, -8)
    availTitle:SetText(L["AVAILABLE"])
    
    parent.availText = availFrame:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    parent.availText:SetPoint("TOPLEFT", 10, -30)
    parent.availText:SetPoint("BOTTOMRIGHT", -10, 10)
    parent.availText:SetJustifyH("LEFT")
    -- parent.availText:SetJustifyV("TOP") -- Removed for 3.3.5 compatibility
    
    -- Panel Derecho: Rotación
    local rotFrame = CreateFrame("Frame", nil, parent)
    rotFrame:SetSize(220, 240)
    rotFrame:SetPoint("TOPRIGHT", parent, "TOPRIGHT", -10, -10)
    rotFrame:SetBackdrop({
        bgFile = "Interface\\Tooltips\\UI-Tooltip-Background",
        edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
        tile = true, tileSize = 16, edgeSize = 16,
        insets = {left = 4, right = 4, top = 4, bottom = 4}
    })
    rotFrame:SetBackdropColor(0, 0, 0, 0.6)
    rotFrame:SetBackdropBorderColor(1, 0.8, 0, 0.6)
    parent.rotationFrame = rotFrame
    
    local rotTitle = rotFrame:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
    rotTitle:SetPoint("TOP", 0, -8)
    rotTitle:SetText(L["ACTIVE_ROTATION"])
    
    -- Botón auto-asignar (Centrado abajo)
    local autoBtn = CreateFrame("Button", nil, parent, "UIPanelButtonTemplate")
    autoBtn:SetSize(140, 26)
    autoBtn:SetPoint("BOTTOM", parent, "BOTTOM", 0, 10)
    autoBtn:SetText(L["AUTO_GENERATE"])
    autoBtn:SetScript("OnClick", function() AS:AutoAssignInterrupts() end)
end

-- Helper: Crea un editor de notas con botón de anunciar
function AS:CreateNoteEditor(parent, dbKey)
    local container = CreateFrame("Frame", nil, parent)
    container:SetPoint("TOPLEFT", parent, "TOPLEFT", 10, -40)
    container:SetPoint("BOTTOMRIGHT", parent, "BOTTOMRIGHT", -10, 40)
    container:SetBackdrop({
        bgFile = "Interface\\Tooltips\\UI-Tooltip-Background",
        edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
        tile = true, tileSize = 16, edgeSize = 16,
        insets = {left = 4, right = 4, top = 4, bottom = 4}
    })
    container:SetBackdropColor(0, 0, 0, 0.5)
    container:SetBackdropBorderColor(0.5, 0.5, 0.5, 1)

    local scroll = CreateFrame("ScrollFrame", "$parentScroll", container, "UIPanelScrollFrameTemplate")
    scroll:SetPoint("TOPLEFT", 8, -8)
    scroll:SetPoint("BOTTOMRIGHT", -30, 8)

    local edit = CreateFrame("EditBox", nil, scroll)
    edit:SetSize(scroll:GetWidth(), scroll:GetHeight())
    edit:SetMultiLine(true)
    edit:SetFontObject("GameFontHighlight")
    edit:SetAutoFocus(false)
    edit:SetTextInsets(4, 4, 4, 4)
    edit.cursorOffset = 0 -- Fix for 3.3.5 UIPanelTemplates crash
    scroll:SetScrollChild(edit)
    
    -- Placeholder manual (texto gris si está vacío)
    if not self.Current[dbKey] or self.Current[dbKey] == "" then
        edit:SetText(L["NOTE_PLACEHOLDER"] or "...")
    else
        edit:SetText(self.Current[dbKey])
    end
    
    edit:SetScript("OnTextChanged", function(self)
        AS.Current[dbKey] = self:GetText()
        ScrollingEdit_OnTextChanged(self, scroll)
    end)
    edit:SetScript("OnEscapePressed", function(self) self:ClearFocus() end)
    edit:SetScript("OnEditFocusGained", function(self)
        if self:GetText() == (L["NOTE_PLACEHOLDER"] or "...") then
            self:SetText("")
            self:SetTextColor(1, 1, 1, 1)
        end
    end)
    
    -- Botón anunciar
    local btn = CreateFrame("Button", nil, parent, "UIPanelButtonTemplate")
    btn:SetSize(140, 24)
    btn:SetPoint("BOTTOM", 0, 10)
    btn:SetText(L["ANNOUNCE_RAID"] or "Announce")
    btn:SetScript("OnClick", function()
        AS:AnnounceNote(dbKey)
    end)
    
    self.editBoxes = self.editBoxes or {}
    self.editBoxes[dbKey] = edit

    return edit
end

function AS:AnnounceNote(key)
    local text = self.Current[key]
    if type(text) == "string" and text ~= "" and text ~= L["NOTE_PLACEHOLDER"] then
        local title = key == "tanks" and L["TANK_ASSIGNMENTS"] or (key == "healers" and L["HEALER_ASSIGNMENTS"] or (key == "cooldowns" and "Cooldowns" or "Assignments"))
        self:SendChat("[Jaina] --- " .. title .. " ---")
        -- Split por líneas para evitar mensajes muy largos
        for line in string.gmatch(text, "[^\r\n]+") do
            self:SendChat(line)
        end
    end
end

function AS:AnnounceAll()
    if not self:GetOption("announce") then return end
    
    self:AnnounceInterrupts()
    self:AnnounceNote("tanks")
    self:AnnounceNote("healers")
    self:AnnounceNote("cooldowns")
    self:AnnounceNote("marks")
end

function AS:CreateTanksTab(parent)
    local title = parent:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    title:SetPoint("TOPLEFT", parent, "TOPLEFT", 10, -10)
    title:SetText(L["TANK_ASSIGNMENTS"])
    
    self:CreateNoteEditor(parent, "tanks")
end

function AS:CreateHealersTab(parent)
    local title = parent:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    title:SetPoint("TOPLEFT", parent, "TOPLEFT", 10, -10)
    title:SetText(L["HEALER_ASSIGNMENTS"])
    
    self:CreateNoteEditor(parent, "healers")
end

function AS:CreateCooldownsTab(parent)
    local title = parent:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    title:SetPoint("TOPLEFT", parent, "TOPLEFT", 10, -10)
    title:SetText("Asignación de Cooldowns") -- Localizar después si hace falta, pero ya puse claves genéricas
    -- Usaré L["COOLDOWN_ASSIGNMENTS"] si existe, sino string directos temporalmente o claves genéricas
    -- Revisando esMX.lua: No puse COOLDOWN_ASSIGNMENTS. Usaré texto literal o añadiré clave luego.
    -- Mejor uso generic notes.
    title:SetText("Asignación de Cooldowns") 
    self:CreateNoteEditor(parent, "cooldowns")
end

function AS:CreateMarksTab(parent)
    local title = parent:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    title:SetPoint("TOPLEFT", parent, "TOPLEFT", 10, -10)
    title:SetText(L["MARK_ASSIGNMENTS"])
    self:CreateNoteEditor(parent, "marks")
end

function AS:ShowTab(tabName)
    for name, content in pairs(self.Frame.tabContents) do
        if name == tabName then
            content:Show()
            self.Frame.tabs[name]:SetNormalFontObject("GameFontHighlight")
        else
            content:Hide()
            self.Frame.tabs[name]:SetNormalFontObject("GameFontNormal")
        end
    end
    
    if tabName == "interrupts" then
        self:UpdateInterruptersDisplay()
    end
end

function AS:GetRaidInterrupters()
    local interrupters = {}
    
    local function addPlayer(name, class)
        if InterruptClasses[class] then
            table.insert(interrupters, {
                name = name,
                class = class,
                spell = InterruptClasses[class].name,
                cd = InterruptClasses[class].cd
            })
        end
    end
    
    if UnitInRaid("player") then
        for i = 1, GetNumRaidMembers() do
            local name, _, _, _, _, classFile = GetRaidRosterInfo(i)
            if name then
                addPlayer(name, classFile)
            end
        end
    elseif UnitInParty("player") then
        local name = UnitName("player")
        local class = select(2, UnitClass("player"))
        addPlayer(name, class)
        
        for i = 1, GetNumPartyMembers() do
            local pname = UnitName("party"..i)
            local pclass = select(2, UnitClass("party"..i))
            if pname then
                addPlayer(pname, pclass)
            end
        end
    end
    
    -- Ordenar por CD (menor primero)
    table.sort(interrupters, function(a, b) return a.cd < b.cd end)
    
    return interrupters
end

function AS:UpdateInterruptersDisplay()
    local interrupters = self:GetRaidInterrupters()
    local content = self.Frame.tabContents["interrupts"]
    if not content then return end
    
    -- Actualizar panel de disponibles (Texto simple)
    local availableText = ""
    for i, int in ipairs(interrupters) do
        local classColor = RAID_CLASS_COLORS[int.class] or {r=1, g=1, b=1}
        local colorHex = string.format("ff%02x%02x%02x", classColor.r * 255, classColor.g * 255, classColor.b * 255)
        
        availableText = availableText .. string.format("|c%s%s|r (%ds)\n", 
            colorHex, int.name, int.cd)
    end
    
    if #interrupters == 0 then
        availableText = "|cff808080Nadie detectado|r"
    end
    
    content.availText:SetText(availableText)
    
    -- Actualizar panel de rotación (Botones visuales)
    local rotFrame = content.rotationFrame
    
    -- Limpiar botones anteriores
    if rotFrame.buttons then
        for _, btn in pairs(rotFrame.buttons) do btn:Hide() end
    end
    rotFrame.buttons = rotFrame.buttons or {}
    
    local rotation = self.Current.interrupts.rotation or {}
    
    if #rotation == 0 then
        if not rotFrame.emptyText then
            rotFrame.emptyText = rotFrame:CreateFontString(nil, "OVERLAY", "GameFontDisable")
            rotFrame.emptyText:SetPoint("CENTER", 0, 0)
            rotFrame.emptyText:SetText(L["EMPTY"])
        end
        rotFrame.emptyText:Show()
    else
        if rotFrame.emptyText then rotFrame.emptyText:Hide() end
        
        for i, playerName in ipairs(rotation) do
            local btn = rotFrame.buttons[i]
            if not btn then
                btn = CreateFrame("Button", nil, rotFrame)
                btn:SetSize(200, 24)
                
                btn.bg = btn:CreateTexture(nil, "BACKGROUND")
                btn.bg:SetAllPoints()
                btn.bg:SetTexture("Interface\\Buttons\\WHITE8x8")
                
                btn.text = btn:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
                btn.text:SetPoint("LEFT", 30, 0)
                
                btn.order = btn:CreateFontString(nil, "OVERLAY", "GameFontNormal")
                btn.order:SetPoint("LEFT", 5, 0)
                
                -- Botón eliminar (X)
                btn.del = CreateFrame("Button", nil, btn)
                btn.del:SetSize(16, 16)
                btn.del:SetPoint("RIGHT", -2, 0)
                btn.del:SetNormalTexture("Interface\\Buttons\\UI-GroupLoot-Pass-Up")
                btn.del:SetScript("OnClick", function()
                    table.remove(AS.Current.interrupts.rotation, i)
                    AS:UpdateInterruptersDisplay()
                end)
                
                rotFrame.buttons[i] = btn
            end
            
            btn:SetPoint("TOP", rotFrame, "TOP", 0, -25 - ((i-1)*26))
            
            -- Buscar clase para color
            local classColor = {r=0.5, g=0.5, b=0.5}
            for _, int in ipairs(interrupters) do
                if int.name == playerName then
                    classColor = RAID_CLASS_COLORS[int.class] or classColor
                    break
                end
            end
            
            btn.bg:SetVertexColor(classColor.r, classColor.g, classColor.b, 0.2)
            btn.text:SetText(playerName)
            btn.order:SetText(i..".")
            
            btn:Show()
        end
    end
end

function AS:AutoAssignInterrupts()
    local interrupters = self:GetRaidInterrupters()
    
    if #interrupters == 0 then
        print("|cffff0000[Jaina]|r No hay interrupters en el grupo")
        return
    end
    
    self.Current.interrupts = {
        target = "Boss",
        rotation = {}
    }
    
    -- Priorizar por CD más corto
    for i, int in ipairs(interrupters) do
        table.insert(self.Current.interrupts.rotation, int.name)
    end
    
    print("|cff00ff00[Jaina]|r " .. L["ASSIGN_AUTO_SUCCESS"])
    self:UpdateInterruptersDisplay()
    self:AnnounceInterrupts()
end

function AS:AnnounceInterrupts()
    if #self.Current.interrupts.rotation == 0 then
        print("|cffff0000[Jaina]|r No hay rotación de interrupts configurada")
        return
    end
    
    local msg = "[Jaina] Rotación de Interrupts: "
    for i, name in ipairs(self.Current.interrupts.rotation) do
        msg = msg .. i .. ". " .. name
        if i < #self.Current.interrupts.rotation then
            msg = msg .. " → "
        end
    end
    
    self:SendChat(msg)
end

function AS:AssignTank(tankName, target)
    local entry = tankName .. " -> " .. target
    if self.Current.tanks == "" then
        self.Current.tanks = entry
    else
        self.Current.tanks = self.Current.tanks .. "\n" .. entry
    end
    print(string.format("|cff00ff00[Jaina]|r %s asignado a: %s", tankName, target))
end

function AS:AssignHealer(healerName, target)
    local entry = healerName .. " -> " .. target
    if self.Current.healers == "" then
        self.Current.healers = entry
    else
        self.Current.healers = self.Current.healers .. "\n" .. entry
    end
    print(string.format("|cff00ff00[Jaina]|r %s asignado a curar: %s", healerName, target))
end

function AS:AssignCooldown(playerName, spell, phase)
    local entry = playerName .. " - " .. spell .. " (Fase " .. phase .. ")"
    if self.Current.cooldowns == "" then
        self.Current.cooldowns = entry
    else
        self.Current.cooldowns = self.Current.cooldowns .. "\n" .. entry
    end
    print(string.format("|cff00ff00[Jaina]|r %s usará %s en fase %s", playerName, spell, phase))
end

function AS:AssignMark(markIndex, playerName)
    local markNames = {"Estrella", "Círculo", "Diamante", "Triángulo", "Luna", "Cuadrado", "Cruz", "Calavera"}
    local entry = (markNames[markIndex] or tostring(markIndex)) .. " -> " .. playerName
    if self.Current.marks == "" then
        self.Current.marks = entry
    else
        self.Current.marks = self.Current.marks .. "\n" .. entry
    end
    print(string.format("|cff00ff00[Jaina]|r %s asignado a marcar: %s", playerName, markNames[markIndex] or markIndex))
end

-- Note: AnnounceAll is already defined at line 325. This duplicate has been removed.

function AS:ClearAll()
    local data = self:GetAssignmentsData()
    data.interrupts = {}
    data.tanks = ""
    data.healers = ""
    data.cooldowns = ""
    data.marks = ""
    self.Current = data
    self:UpdateInterruptersDisplay()
    
    if self.editBoxes then
        for _, edit in pairs(self.editBoxes) do
            edit:SetText(L["NOTE_PLACEHOLDER"] or "...")
        end
    end
    print("|cff00ff00[Jaina]|r Todas las asignaciones han sido limpiadas")
end

function AS:RegisterComm()
    -- Registrar canal de comunicación para sincronizar asignaciones
    local prefix = "SEQ_ASSIGN"
    
    local commFrame = CreateFrame("Frame")
    commFrame:RegisterEvent("CHAT_MSG_ADDON")
    commFrame:SetScript("OnEvent", function(self, event, pre, msg, channel, sender)
        if pre ~= prefix then return end
        AS:OnCommReceived(msg, sender)
    end)
    
    if RegisterAddonMessagePrefix then
        RegisterAddonMessagePrefix(prefix)
    end
end

function AS:SyncToRaid()
    local channel = self:GetGroupChannel()
    if not channel then
        print("|cffff0000[Jaina]|r No estás en un grupo")
        return
    end
    
    -- Serializar y despachar en fragmentos individuales < 255 bytes (Ley III)
    local parts = self:GetSerializedParts()
    for _, part in ipairs(parts) do
        if #part <= 250 then
            SendAddonMessage("SEQ_ASSIGN", part, channel)
        end
    end
    print("|cff00ff00[Jaina]|r Asignaciones sincronizadas con el grupo")
end

function AS:GetSerializedParts()
    -- Formato: INT:nombres|NOTE:key:contenido|NOTE:key:contenido
    local parts = {}
    
    -- Interrupts
    if self.Current.interrupts.rotation and #self.Current.interrupts.rotation > 0 then
        table.insert(parts, "INT:" .. table.concat(self.Current.interrupts.rotation, ","))
    end
    
    -- Notes (Tanks, Healers, Cooldowns, Marks)
    local function AddNote(key)
        if type(self.Current[key]) == "string" and self.Current[key] ~= "" and self.Current[key] ~= L["NOTE_PLACEHOLDER"] then
            -- Sanitize: Reemplazar | por /
            local cleanVal = string.gsub(self.Current[key], "|", "/")
            table.insert(parts, "NOTE:" .. key .. ":" .. cleanVal)
        end
    end
    
    AddNote("tanks")
    AddNote("healers")
    AddNote("cooldowns")
    AddNote("marks")
    
    return parts
end

function AS:SerializeAssignments()
    return table.concat(self:GetSerializedParts(), "|")
end

function AS:OnCommReceived(msg, sender)
    -- No procesar nuestros propios mensajes
    if sender == UnitName("player") then return end
    
    -- Deserializar
    local parts = {strsplit("|", msg)}
    
    for _, part in ipairs(parts) do
        local typeOrKey, val1, val2 = strsplit(":", part, 3)
        
        if typeOrKey == "INT" then
            -- val1 es la lista CSV
            self.Current.interrupts.rotation = {strsplit(",", val1)}
            self:UpdateInterruptersDisplay()
            
        elseif typeOrKey == "NOTE" then
            -- val1 es la key, val2 es contenido
            local key = val1
            local content = val2
            if key and content then
                self.Current[key] = content
            end
            
        elseif typeOrKey == "PULL" then
            -- Pull Timer Sync
            local seconds = tonumber(val1)
            if seconds then
                self:ShowPullTimer(seconds)
            end
        end
    end
    
    print("|cff00ff00[Jaina]|r Datos recibidos de " .. sender)
end

function AS:StartPullTimer(seconds)
    seconds = tonumber(seconds) or 10
    if S.RaidAssist and S.RaidAssist.StartPullTimer then
        S.RaidAssist:StartPullTimer(seconds)
    else
        self:ShowPullTimer(seconds)
    end
end

function AS:ShowPullTimer(seconds)
    seconds = tonumber(seconds) or 10
    if S.RaidAssist and S.RaidAssist.ShowPullTimer then
        S.RaidAssist:ShowPullTimer(seconds)
    end
end

function AS:Toggle()
    if not self.Frame then
        self:Initialize()
    end
    
    -- Check again after Initialize (module might be disabled)
    if not self.Frame then
        return
    end
    
    self.IsVisible = not self.IsVisible
    if self.IsVisible then
        self.Frame:Show()
        self:UpdateInterruptersDisplay()
    else
        self.Frame:Hide()
    end
end

function AS:Show()
    if not self.Frame then
        self:Initialize()
    end
    self.IsVisible = true
    self.Frame:Show()
    self:UpdateInterruptersDisplay()
end

function AS:Hide()
    if self.Frame then
        self.IsVisible = false
        self.Frame:Hide()
    end
end

-- Helper para obtener configuración
function AS:GetOption(key)
    if S.ModuleConfig then
        return S.ModuleConfig:GetValue("Assignments", key)
    end
    return true
end

-- Note: ModuleConfig registration is handled in Initialize() above.

-- Auto-inicializar
local initFrame = CreateFrame("Frame")
initFrame:RegisterEvent("PLAYER_LOGIN")
initFrame:SetScript("OnEvent", function()
    local timer = CreateFrame("Frame")
    local elapsed = 0
    timer:SetScript("OnUpdate", function(self, delta)
        elapsed = elapsed + delta
        if elapsed >= 3 then
            self:SetScript("OnUpdate", nil)
            AS:Initialize()
        end
    end)
end)
