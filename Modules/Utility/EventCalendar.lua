--[[
    Sequito - EventCalendar Module
    Calendario de Eventos y Raids Integrado
    Version: 8.0.0 (WotLK 3.3.5a Build 12340)
]]

local addonName, S = ...
S.EventCalendar = {}
local EC = S.EventCalendar

EC.events = {}
EC.eventRows = {}
EC.selectedOffset = 0
EC.selectedDay = nil
EC.selectedMonth = nil
EC.selectedYear = nil
EC.alertedEvents = {}

local MONTH_NAMES = {
    "Enero", "Febrero", "Marzo", "Abril", "Mayo", "Junio",
    "Julio", "Agosto", "Septiembre", "Octubre", "Noviembre", "Diciembre"
}

local WEEKDAY_NAMES = {
    "Domingo", "Lunes", "Martes", "Miércoles", "Jueves", "Viernes", "Sábado"
}

local INVITE_STATUS_INFO = {
    [1] = { text = "Invitado", color = "|cFFFFFF00" },
    [2] = { text = "Aceptado", color = "|cFF00FF00" },
    [3] = { text = "Rechazado", color = "|cFFFF0000" },
    [4] = { text = "Confirmado", color = "|cFF00FFFF" },
    [5] = { text = "Fuera", color = "|cFF888888" },
    [6] = { text = "En Reserva", color = "|cFFFF8000" },
    [7] = { text = "Inscrito", color = "|cFF00FF00" },
    [8] = { text = "No Inscrito", color = "|cFF888888" },
}

local CALENDAR_TYPE_PREFIX = {
    ["GUILD_EVENT"]        = "|cFF00FF00[Guild]|r ",
    ["GUILD_ANNOUNCEMENT"] = "|cFFFFFF00[Anuncio]|r ",
    ["COMMUNITY_EVENT"]    = "|cFF00FFFF[Comunidad]|r ",
    ["RAID_LOCKOUT"]       = "|cFFFF4040[Lockout]|r ",
    ["RAID_RESET"]         = "|cFFFF4040[Reinicio]|r ",
    ["HOLIDAY"]            = "|cFF8080FF[Festivo]|r ",
    ["PLAYER"]             = "|cFFFFFFFF[Personal]|r ",
}

-- Helper para obtener configuración
function EC:GetOption(key)
    if S.ModuleConfig then
        return S.ModuleConfig:GetValue("EventCalendar", key)
    end
    if key == "enabled" then return true end
    if key == "reminders" then return true end
    if key == "reminderTime" then return 15 end
    if key == "soundAlert" then return true end
    return true
end

function EC:Initialize()
    if self.initialized then return end
    if not self:GetOption("enabled") then
        return
    end
    self.initialized = true

    -- Sincronizar fecha inicial
    if CalendarGetDate then
        local weekday, month, day, year = CalendarGetDate()
        self.selectedDay = day or 1
        self.selectedMonth = month or 1
        self.selectedYear = year or 2026
    else
        local dt = date("*t")
        self.selectedDay = dt.day
        self.selectedMonth = dt.month
        self.selectedYear = dt.year
    end

    self.frame = self:CreateFrame()
    self:RegisterEvents()
    self:StartReminderTicker()

    -- Solicitar datos al servidor defensivamente (Ley II & V)
    if OpenCalendar then
        pcall(OpenCalendar)
    end
end

function EC:CreateFrame()
    local f = CreateFrame("Frame", "SequitoEventCalendarFrame", UIParent)
    self.frame = f
    f:SetSize(380, 360)
    f:SetPoint("CENTER", UIParent, "CENTER", 0, 40)
    f:SetMovable(true)
    f:EnableMouse(true)
    f:SetClampedToScreen(true)
    f:RegisterForDrag("LeftButton")
    f:SetScript("OnDragStart", f.StartMoving)
    f:SetScript("OnDragStop", function(self)
        self:StopMovingOrSizing()
        if S.SmartDefaults then
            S.SmartDefaults:SavePosition("EventCalendar", self)
        end
    end)
    f:Hide()

    -- Registrar para cierre nativo con tecla Escape (WotLK 3.3.5a)
    tinsert(UISpecialFrames, "SequitoEventCalendarFrame")

    if S.Theme and S.Theme.ApplyPanelBackdrop then
        S.Theme:ApplyPanelBackdrop(f)
    else
        f:SetBackdrop({
            bgFile = "Interface\\DialogFrame\\UI-DialogBox-Background",
            edgeFile = "Interface\\DialogFrame\\UI-DialogBox-Border",
            edgeSize = 16,
            insets = { left = 4, right = 4, top = 4, bottom = 4 }
        })
    end

    -- Botón de Cierre (X)
    f.close = CreateFrame("Button", nil, f, "UIPanelCloseButton")
    f.close:SetPoint("TOPRIGHT", -4, -4)
    f.close:SetScript("OnClick", function()
        f:Hide()
    end)

    -- Título
    f.title = f:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
    f.title:SetPoint("TOP", 0, -12)
    f.title:SetText("Calendario de Hermandad")

    -- Barra de Navegación de Fecha
    local nav = CreateFrame("Frame", nil, f)
    nav:SetPoint("TOPLEFT", 10, -36)
    nav:SetPoint("TOPRIGHT", -10, -36)
    nav:SetHeight(28)
    f.navBar = nav

    nav.btnPrev = CreateFrame("Button", nil, nav, "UIPanelButtonTemplate")
    nav.btnPrev:SetSize(28, 22)
    nav.btnPrev:SetPoint("LEFT", 6, 0)
    nav.btnPrev:SetText("<")
    nav.btnPrev:SetScript("OnClick", function()
        EC:ChangeDay(-1)
    end)

    nav.dateText = nav:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
    nav.dateText:SetPoint("CENTER", 0, 0)
    nav.dateText:SetText("Fecha")

    nav.btnToday = CreateFrame("Button", nil, nav, "UIPanelButtonTemplate")
    nav.btnToday:SetSize(45, 22)
    nav.btnToday:SetPoint("RIGHT", -38, 0)
    nav.btnToday:SetText("Hoy")
    nav.btnToday:SetScript("OnClick", function()
        EC:ResetToToday()
    end)

    nav.btnNext = CreateFrame("Button", nil, nav, "UIPanelButtonTemplate")
    nav.btnNext:SetSize(28, 22)
    nav.btnNext:SetPoint("RIGHT", -6, 0)
    nav.btnNext:SetText(">")
    nav.btnNext:SetScript("OnClick", function()
        EC:ChangeDay(1)
    end)

    -- Área de Scroll para Eventos
    f.scroll = CreateFrame("ScrollFrame", "SequitoECEventScroll", f, "UIPanelScrollFrameTemplate")
    f.scroll:SetPoint("TOPLEFT", 12, -70)
    f.scroll:SetPoint("BOTTOMRIGHT", -32, 45)

    f.content = CreateFrame("Frame", nil, f.scroll)
    f.content:SetSize(330, 400)
    f.scroll:SetScrollChild(f.content)

    -- Texto cuando no hay eventos
    f.emptyText = f.content:CreateFontString(nil, "OVERLAY", "GameFontDisable")
    f.emptyText:SetPoint("CENTER", f.scroll, "CENTER", 0, 0)
    f.emptyText:SetText("No hay eventos programados para este día.")
    f.emptyText:Hide()

    -- Botón Inferior: Abrir Calendario de WoW Oficial
    f.btnBlizzCal = CreateFrame("Button", nil, f, "UIPanelButtonTemplate")
    f.btnBlizzCal:SetSize(220, 24)
    f.btnBlizzCal:SetPoint("BOTTOM", 0, 12)
    f.btnBlizzCal:SetText("Abrir Calendario de WoW")
    f.btnBlizzCal:SetScript("OnClick", function()
        if ToggleCalendar then
            ToggleCalendar()
        elseif Calendar_LoadUI then
            Calendar_LoadUI()
            if CalendarFrame then CalendarFrame:Show() end
        end
    end)

    if S.SmartDefaults then
        S.SmartDefaults:RestorePosition("EventCalendar")
    end

    return f
end

function EC:RegisterEvents()
    local events = CreateFrame("Frame")
    events:RegisterEvent("CALENDAR_UPDATE_EVENT_LIST")
    events:RegisterEvent("CALENDAR_UPDATE_PENDING_INVITES")
    events:RegisterEvent("CALENDAR_ACTION_PENDING")
    events:RegisterEvent("CALENDAR_EVENT_ALARM")
    events:SetScript("OnEvent", function(self, event, ...)
        EC:UpdateEvents()
    end)
end

function EC:ResetToToday()
    if CalendarGetDate then
        local weekday, month, day, year = CalendarGetDate()
        self.selectedDay = day or 1
        self.selectedMonth = month or 1
        self.selectedYear = year or 2026
    else
        local dt = date("*t")
        self.selectedDay = dt.day
        self.selectedMonth = dt.month
        self.selectedYear = dt.year
    end
    self.selectedOffset = 0
    self:UpdateEvents()
end

function EC:ChangeDay(delta)
    if not self.selectedDay then
        self:ResetToToday()
        return
    end

    local newDay = self.selectedDay + delta
    if newDay < 1 then
        newDay = 1
    elseif newDay > 31 then
        newDay = 31
    end
    self.selectedDay = newDay
    self:UpdateEvents()
end

function EC:UpdateEvents()
    if not CalendarGetDate then return end

    local curWeekday, curMonth, curDay, curYear = CalendarGetDate()
    if not self.selectedDay then
        self.selectedDay = curDay or 1
        self.selectedMonth = curMonth or 1
        self.selectedYear = curYear or 2026
    end

    local day = self.selectedDay
    local offset = self.selectedOffset or 0
    local numEvents = CalendarGetNumDayEvents and CalendarGetNumDayEvents(offset, day) or 0

    self.events = {}
    for i = 1, numEvents do
        local title, hour, minute, calendarType, sequenceType, eventType, texture, modStatus, inviteStatus, invitedBy, difficulty, inviteType = CalendarGetDayEvent(offset, day, i)

        if title then
            table.insert(self.events, {
                index = i,
                day = day,
                monthOffset = offset,
                title = title,
                hour = hour or 0,
                minute = minute or 0,
                type = calendarType or "PLAYER",
                modStatus = modStatus,
                status = inviteStatus or 1,
                invitedBy = invitedBy or "Desconocido",
                difficulty = difficulty or "",
                texture = texture or "Interface\\Icons\\INV_Misc_Book_11",
            })
        end
    end

    -- Ordenar eventos por hora ascendente
    table.sort(self.events, function(a, b)
        if a.hour ~= b.hour then
            return a.hour < b.hour
        end
        return a.minute < b.minute
    end)

    self:RefreshDisplay()
end

function EC:RefreshDisplay()
    if not self.frame then return end

    -- Actualizar barra de fecha
    local mName = MONTH_NAMES[self.selectedMonth] or ("Mes " .. tostring(self.selectedMonth))
    local dateStr = string.format("%d de %s", self.selectedDay, mName)
    self.frame.navBar.dateText:SetText(dateStr)

    -- Ocultar filas existentes
    for _, row in ipairs(self.eventRows) do
        row:Hide()
    end

    if not self.events or #self.events == 0 then
        self.frame.emptyText:Show()
        self.frame.content:SetHeight(200)
        return
    else
        self.frame.emptyText:Hide()
    end

    local yOffset = 0
    for i, ev in ipairs(self.events) do
        local row = self.eventRows[i] or self:CreateEventRow(i)
        row.eventData = ev

        -- Prefijo por tipo de evento
        local prefix = CALENDAR_TYPE_PREFIX[ev.type] or ""
        row.title:SetText(prefix .. (ev.title or "Evento"))

        -- Hora formateada
        row.time:SetText(string.format("%02d:%02d", ev.hour, ev.minute))

        -- Estado de invitación
        local statusInfo = INVITE_STATUS_INFO[ev.status]
        if statusInfo then
            row.status:SetText(statusInfo.color .. statusInfo.text .. "|r")
        else
            row.status:SetText("")
        end

        row:SetPoint("TOPLEFT", self.frame.content, "TOPLEFT", 0, -yOffset)
        row:Show()
        yOffset = yOffset + 32
    end

    self.frame.content:SetHeight(math.max(yOffset + 10, 220))
end

function EC:CreateEventRow(index)
    local row = CreateFrame("Button", nil, self.frame.content)
    row:SetSize(326, 28)
    row:EnableMouse(true)

    -- Fondo sutil y resalte al pasar el cursor (Ley II)
    local highlight = row:CreateTexture(nil, "HIGHLIGHT")
    highlight:SetAllPoints()
    highlight:SetTexture("Interface\\QuestFrame\\UI-QuestTitleHighlight")
    highlight:SetBlendMode("ADD")
    highlight:SetAlpha(0.6)

    -- Icono del tipo de evento
    row.icon = row:CreateTexture(nil, "ARTWORK")
    row.icon:SetSize(18, 18)
    row.icon:SetPoint("LEFT", 4, 0)
    row.icon:SetTexture("Interface\\Icons\\INV_Misc_Book_11")
    row.icon:SetTexCoord(0.08, 0.92, 0.08, 0.92)

    -- Título del evento
    row.title = row:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    row.title:SetPoint("LEFT", row.icon, "RIGHT", 6, 0)
    row.title:SetWidth(180)
    row.title:SetJustifyH("LEFT")

    -- Estado de invitación
    row.status = row:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    row.status:SetPoint("RIGHT", -55, 0)
    row.status:SetJustifyH("RIGHT")

    -- Hora
    row.time = row:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    row.time:SetPoint("RIGHT", -4, 0)
    row.time:SetJustifyH("RIGHT")

    -- Tooltip rico al pasar el mouse
    row:SetScript("OnEnter", function(self)
        local ev = self.eventData
        if not ev then return end

        GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
        GameTooltip:AddLine(ev.title or "Evento", 1, 1, 1)

        local typeName = ev.type or "Evento"
        if typeName == "GUILD_EVENT" then typeName = "Evento de Hermandad"
        elseif typeName == "GUILD_ANNOUNCEMENT" then typeName = "Anuncio de Hermandad"
        elseif typeName == "RAID_LOCKOUT" or typeName == "RAID_RESET" then typeName = "Reinicio de Banda"
        elseif typeName == "HOLIDAY" then typeName = "Evento Festivo"
        end

        GameTooltip:AddDoubleLine("Tipo:", typeName, 1, 0.82, 0, 1, 1, 1)
        GameTooltip:AddDoubleLine("Hora de Inicio:", string.format("%02d:%02d", ev.hour, ev.minute), 1, 0.82, 0, 1, 1, 1)

        if ev.invitedBy and ev.invitedBy ~= "" and ev.invitedBy ~= "Desconocido" then
            GameTooltip:AddDoubleLine("Organizador:", ev.invitedBy, 1, 0.82, 0, 0, 1, 0)
        end

        if ev.difficulty and ev.difficulty ~= "" then
            GameTooltip:AddDoubleLine("Dificultad:", ev.difficulty, 1, 0.82, 0, 1, 1, 1)
        end

        local statusInfo = INVITE_STATUS_INFO[ev.status]
        if statusInfo then
            GameTooltip:AddDoubleLine("Tu Estado:", statusInfo.text, 1, 0.82, 0, 0, 1, 1)
        end

        GameTooltip:AddLine(" ")
        GameTooltip:AddLine("|cFF00FF00Clic izquierdo:|r Abrir en el Calendario oficial de WoW", 0.5, 0.5, 0.5)
        GameTooltip:Show()
    end)

    row:SetScript("OnLeave", function()
        GameTooltip:Hide()
    end)

    -- Al hacer clic: Abrir el evento en el Calendario oficial de Blizzard
    row:SetScript("OnClick", function(self)
        local ev = self.eventData
        if ev and ev.index and CalendarOpenEvent then
            CalendarOpenEvent(ev.monthOffset or 0, ev.day or 1, ev.index)
        elseif ToggleCalendar then
            ToggleCalendar()
        end
    end)

    self.eventRows[index] = row
    return row
end

-- ===========================================================================
-- SISTEMA DE RECORDATORIOS AUTOMÁTICOS
-- ===========================================================================
function EC:StartReminderTicker()
    if self.reminderTicker then return end

    local ticker = CreateFrame("Frame")
    ticker.elapsed = 0
    ticker:SetScript("OnUpdate", function(f, elapsed)
        f.elapsed = f.elapsed + elapsed
        if f.elapsed >= 30 then -- Verificar cada 30 segundos
            f.elapsed = 0
            EC:CheckReminders()
        end
    end)
    self.reminderTicker = ticker
end

function EC:CheckReminders()
    if not self:GetOption("reminders") then return end
    if not CalendarGetDate then return end

    local _, _, curDay, _ = CalendarGetDate()
    if not curDay then return end

    local dt = date("*t")
    local curHour = dt.hour or 0
    local curMin = dt.min or 0
    local curTotalMinutes = curHour * 60 + curMin

    local reminderTime = tonumber(self:GetOption("reminderTime")) or 15
    local numEvents = CalendarGetNumDayEvents and CalendarGetNumDayEvents(0, curDay) or 0

    for i = 1, numEvents do
        local title, hour, minute, calendarType, _, _, _, _, _, _, _, _ = CalendarGetDayEvent(0, curDay, i)
        if title and hour and minute then
            local eventTotalMinutes = hour * 60 + minute
            local diffMinutes = eventTotalMinutes - curTotalMinutes

            local eventKey = string.format("%d_%s_%d_%d", curDay, title, hour, minute)

            -- Si falta entre 0 y reminderTime minutos y no fue alertado antes
            if diffMinutes >= 0 and diffMinutes <= reminderTime and not self.alertedEvents[eventKey] then
                self.alertedEvents[eventKey] = true

                local msg
                if diffMinutes == 0 then
                    msg = string.format("|cFF00FFFF[Sequito]|r ¡El evento '|cFFFFD100%s|r' comienza AHORA MISMO!", title)
                else
                    msg = string.format("|cFF00FFFF[Sequito]|r Recordatorio: '|cFFFFD100%s|r' comienza a las %02d:%02d (en %d min).", title, hour, minute, diffMinutes)
                end

                DEFAULT_CHAT_FRAME:AddMessage(msg)

                if self:GetOption("soundAlert") then
                    PlaySoundFile("Sound\\Interface\\RaidWarning.wav")
                end
            end
        end
    end
end

function EC:Toggle()
    if not self.frame then
        self:Initialize()
    end
    if not self.frame then return end

    if self.frame:IsShown() then
        self.frame:Hide()
    else
        self:Show()
    end
end

function EC:Show()
    if not self.frame then
        self:Initialize()
    end
    if not self.frame then return end

    -- Solicitar datos al servidor para asegurar lista fresca en 3.3.5a
    if OpenCalendar then
        pcall(OpenCalendar)
    end

    self:UpdateEvents()
    self.frame:Show()
end

function EC:Hide()
    if self.frame then
        self.frame:Hide()
    end
end

function EC:SlashCommand(msg)
    self:Toggle()
end

SLASH_EVENTCALENDAR1 = "/ec"
SLASH_EVENTCALENDAR2 = "/eventcalendar"
SLASH_EVENTCALENDAR3 = "/cal"
SlashCmdList["EVENTCALENDAR"] = function(msg)
    EC:SlashCommand(msg)
end

local loader = CreateFrame("Frame")
loader:RegisterEvent("PLAYER_LOGIN")
loader:SetScript("OnEvent", function()
    EC:Initialize()
end)
