--[[
    Sequito - EventCalendar Module
    Calendario de Eventos Integrado
    Version: 7.3.0
]]

local addonName, S = ...
S.EventCalendar = {}
local EC = S.EventCalendar

-- Helper para obtener configuración
function EC:GetOption(key)
    if S.ModuleConfig then
        return S.ModuleConfig:GetValue("EventCalendar", key)
    end
    return true
end

function EC:Initialize()
    if self.initialized then return end
    if not self:GetOption("enabled") then
        return
    end
    self.initialized = true
    
    self.frame = self:CreateFrame()
    self:RegisterEvents()
end

function EC:CreateFrame()
    local f = CreateFrame("Frame", "SequitoEventCalendarFrame", UIParent)
    self.frame = f
    f:SetSize(350, 300)
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
            S.SmartDefaults:SavePosition("EventCalendar", self)
        end
    end)
    f:Hide()
    
    f.title = f:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
    f.title:SetPoint("TOP", 0, -10)
    f.title:SetText("Eventos del Guild")
    
    f.scroll = CreateFrame("ScrollFrame", "SequitoECEventScroll", f, "UIPanelScrollFrameTemplate")
    f.scroll:SetPoint("TOPLEFT", 10, -40)
    f.scroll:SetPoint("BOTTOMRIGHT", -30, 10)
    
    f.content = CreateFrame("Frame", nil, f.scroll)
    f.content:SetSize(300, 400)
    f.scroll:SetScrollChild(f.content)
    
    f.close = CreateFrame("Button", nil, f, "UIPanelCloseButton")
    f.close:SetPoint("TOPRIGHT", -5, -5)
    f.close:SetScript("OnClick", function() f:Hide() end)
    
    if S.SmartDefaults then
        S.SmartDefaults:RestorePosition("EventCalendar")
    end
    
    return f
end

function EC:RegisterEvents()
    local events = CreateFrame("Frame")
    events:RegisterEvent("CALENDAR_UPDATE_EVENT_LIST")
    events:SetScript("OnEvent", function() EC:UpdateEvents() end)
end

function EC:UpdateEvents()
    if not CalendarGetDate then return end
    local weekday, month, day, year = CalendarGetDate()
    if not day or day < 1 then
        local dt = date("*t")
        day = dt and dt.day or 1
    end
    
    local numEvents = CalendarGetNumDayEvents and CalendarGetNumDayEvents(0, day) or 0
    
    self.events = {}
    for i = 1, numEvents do
        local title, hour, minute, calendarType, sequenceType, eventType, texture, modStatus, inviteStatus, invitedBy, difficulty, inviteType = CalendarGetDayEvent(0, day, i)
        
        if title then
            table.insert(self.events, {
                title = title,
                startTime = {hour = hour, minute = minute},
                type = calendarType,
                status = inviteStatus
            })
        end
    end
    
    self:RefreshDisplay()
end

function EC:RefreshDisplay()
    if not self.eventRows then self.eventRows = {} end
    
    for i, row in ipairs(self.eventRows) do row:Hide() end
    
    if not self.emptyText and self.frame and self.frame.content then
        self.emptyText = self.frame.content:CreateFontString(nil, "OVERLAY", "GameFontDisable")
        self.emptyText:SetPoint("CENTER", self.frame, "CENTER", 0, -20)
        self.emptyText:SetText("No hay eventos programados para hoy.")
    end
    
    if not self.events or #self.events == 0 then
        if self.emptyText then self.emptyText:Show() end
        if self.frame and self.frame.content then
            self.frame.content:SetHeight(250)
        end
        return
    else
        if self.emptyText then self.emptyText:Hide() end
    end
    
    local yOffset = 0
    for i, event in ipairs(self.events) do
        local row = self.eventRows[i] or self:CreateEventRow(i)
        row.title:SetText(event.title or "Evento")
        local timeStr = ""
        if event.startTime and event.startTime.hour and event.startTime.minute then
            timeStr = string.format("%02d:%02d", event.startTime.hour, event.startTime.minute)
        end
        row.time:SetText(timeStr)
        row:SetPoint("TOPLEFT", self.frame.content, "TOPLEFT", 0, -yOffset)
        row:Show()
        yOffset = yOffset + 30
    end
    if self.frame and self.frame.content then
        self.frame.content:SetHeight(math.max(yOffset + 10, 250))
    end
end

function EC:CreateEventRow(index)
    local row = CreateFrame("Frame", nil, self.frame.content)
    row:SetSize(290, 28)
    
    row.title = row:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    row.title:SetPoint("LEFT", 5, 0)
    
    row.time = row:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    row.time:SetPoint("RIGHT", -5, 0)
    
    self.eventRows[index] = row
    return row
end

function EC:Toggle()
    if not self.frame then return end
    if self.frame:IsShown() then
        self.frame:Hide()
    else
        self:UpdateEvents()
        self.frame:Show()
    end
end

function EC:SlashCommand(msg)
    self:Toggle()
end

-- Registrar configuración en ModuleConfig
if S.ModuleConfig then
    S.ModuleConfig:RegisterModule("EventCalendar", {
        name = "Event Calendar",
        icon = "Interface\\Icons\\INV_Misc_Book_11",
        description = "Calendario de eventos de guild y raids",
        category = "utility",
        options = {
            {
                type = "checkbox",
                key = "enabled",
                label = "Habilitar Event Calendar",
                tooltip = "Activa/desactiva el calendario de eventos",
                default = true,
            },
            {
                type = "checkbox",
                key = "showReminders",
                label = "Mostrar Recordatorios",
                tooltip = "Muestra recordatorios de eventos próximos",
                default = true,
            },
            {
                type = "slider",
                key = "reminderTime",
                label = "Tiempo Recordatorio (min)",
                tooltip = "Cuánto tiempo antes del evento mostrar recordatorio",
                min = 5,
                max = 120,
                step = 5,
                default = 30,
            },
            {
                type = "checkbox",
                key = "autoAcceptInvites",
                label = "Auto-Aceptar Invitaciones",
                tooltip = "Acepta automáticamente invitaciones de eventos de guild",
                default = false,
            },
            {
                type = "checkbox",
                key = "showInTooltip",
                label = "Mostrar en Tooltip",
                tooltip = "Muestra eventos próximos en el tooltip de la esfera",
                default = true,
            },
        },
    })
end

SLASH_EVENTCALENDAR1 = "/ec"
SLASH_EVENTCALENDAR2 = "/eventcalendar"
SlashCmdList["EVENTCALENDAR"] = function(msg)
    EC:SlashCommand(msg)
end

local loader = CreateFrame("Frame")
loader:RegisterEvent("PLAYER_LOGIN")
loader:SetScript("OnEvent", function() EC:Initialize() end)
