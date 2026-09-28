--[[
    Sequito - The Coven (Utility & Rituals)
    Modulo v11.0: Gestion de invos, piedras y maldiciones.
]]

local addonName, S = ...
S.Coven = {}
local Coven = S.Coven

-- Config
local SUMMON_KEYWORDS = {"summ", "tp", "123", "summon", "invo"}

-- State
Coven.Queue = {} -- {name, class, time}
Coven.ActivePortal = false
Coven.DoomActive = false

function Coven:Initialize()
    local _, playerClass = UnitClass("player")
    self.isWarlock = (playerClass == "WARLOCK")

    self.Frame = CreateFrame("Frame")
    self.Frame:RegisterEvent("CHAT_MSG_RAID")
    self.Frame:RegisterEvent("CHAT_MSG_RAID_LEADER")
    self.Frame:RegisterEvent("CHAT_MSG_PARTY")
    self.Frame:RegisterEvent("CHAT_MSG_PARTY_LEADER")
    self.Frame:RegisterEvent("UNIT_SPELLCAST_SUCCEEDED")
    self.Frame:RegisterEvent("COMBAT_LOG_EVENT_UNFILTERED")
    
    self.Frame:SetScript("OnEvent", function(self, event, ...)
        if event == "UNIT_SPELLCAST_SUCCEEDED" then
            Coven:OnSpellCast(...)
        elseif event == "COMBAT_LOG_EVENT_UNFILTERED" then
            Coven:CheckDoomSacrifice(...)
        else
            Coven:OnChatMsg(...)
        end
    end)
    
    -- Crear UI y botón seguro de invocación
    self:CreateSummonFrame()
    if self.isWarlock then
        self:CreateSummonButton()
    end

    -- Slash commands
    SLASH_SEQUITOCOVEN1 = "/scoven"
    SlashCmdList["SEQUITOCOVEN"] = function()
        Coven:Toggle()
    end

    -- Register Config
    if S.ModuleConfig then
        S.ModuleConfig:RegisterModule("Coven", {
            name = "Coven (Invocaciones & Brujo)",
            description = "Herramientas de Aquelarre: Invocaciones con cola automática, Maldiciones y Rituales.",
            category = "class",
            icon = "Interface\\Icons\\Spell_Shadow_DarkRitual",
            options = {
                {key = "enabled", type = "checkbox", label = "Habilitar Coven", default = true},
                {key = "autoSummon", type = "checkbox", label = "Asistente de Invocación", default = true},
                {key = "curseManager", type = "checkbox", label = "Gestor de Maldiciones", default = true}
            }
        })
    end
end

-- ============================================================================
-- SUMMON ASSISTANT & QUEUE
-- ============================================================================

function Coven:OnChatMsg(msg, sender)
    if not sender or sender == "" then return end
    -- Remover reino si viene en formato Nombre-Reino
    sender = string.match(sender, "^([^-]+)") or sender

    msg = string.lower(msg)
    for _, keyword in ipairs(SUMMON_KEYWORDS) do
        if string.find(msg, keyword) then
            self:AddToQueue(sender)
            break
        end
    end
end

function Coven:AddToQueue(sender)
    for _, p in ipairs(self.Queue) do
        if p.name == sender then return end
    end
    
    local _, class = UnitClass(sender)
    if not class then
        -- Buscar en raid/party
        if GetNumRaidMembers() > 0 then
            for i = 1, GetNumRaidMembers() do
                local rName, _, _, _, _, rClass = GetRaidRosterInfo(i)
                if rName == sender then
                    class = rClass
                    break
                end
            end
        elseif GetNumPartyMembers() > 0 then
            for i = 1, GetNumPartyMembers() do
                if UnitName("party" .. i) == sender then
                    _, class = UnitClass("party" .. i)
                    break
                end
            end
        end
    end
    
    table.insert(self.Queue, {
        name = sender,
        class = class or "PRIEST",
        time = GetTime()
    })
    
    self:UpdateUI()
    if S.Print then
        S:Print(string.format("|cFF9900FF[Coven]|r %s añadido a la cola de invocación.", sender))
    end
end

function Coven:RemoveFromQueue(name)
    for i, p in ipairs(self.Queue) do
        if p.name == name then
            table.remove(self.Queue, i)
            break
        end
    end
    self:UpdateUI()
end

function Coven:ClearQueue()
    self.Queue = {}
    self:UpdateUI()
    if S.Print then
        S:Print("|cFF9900FF[Coven]|r Cola de invocación vaciada.")
    end
end

function Coven:PopQueue()
    if #self.Queue > 0 then
        local p = table.remove(self.Queue, 1)
        local chan = (GetNumRaidMembers() > 0) and "RAID" or ((GetNumPartyMembers() > 0) and "PARTY" or nil)
        if chan then
            SendChatMessage("Invocando a " .. p.name .. "...", chan)
        end
        self:UpdateUI()
        return p
    end
    return nil
end

function Coven:GetNextSummonTarget()
    if #self.Queue > 0 then
        return self.Queue[1].name
    end
    return nil
end

-- ============================================================================
-- RITUAL OF DOOM & COMBAT LOG
-- ============================================================================

function Coven:OnSpellCast(unit, spellName, rank, lineId, spellId)
    if unit ~= "player" then return end
    
    -- Ritual de Invocación (ID 698)
    if spellId == 698 or spellName == "Ritual de invocación" then
        local chan = (GetNumRaidMembers() > 0) and "RAID" or ((GetNumPartyMembers() > 0) and "PARTY" or nil)
        if UnitExists("target") and UnitIsPlayer("target") and not UnitIsUnit("target", "player") then
            local targetName = UnitName("target")
            if chan then
                SendChatMessage("Invocando a " .. targetName .. " a mi posición. ¡Clic al portal!", chan)
            end
        else
            if chan then
                SendChatMessage("Invocando portal de reunión. ¡Asistan con dos clics!", chan) 
            end
        end
        self:PopQueue()
    -- Ritual de la Perdición (ID 18540)
    elseif spellId == 18540 or spellName == "Ritual de la perdición" then
        self:StartDoomRoulette()
    end
end

function Coven:StartDoomRoulette()
    local chan = (GetNumRaidMembers() > 0) and "RAID" or ((GetNumPartyMembers() > 0) and "PARTY" or nil)
    if chan then
        SendChatMessage("¡RULETA RUSA INICIADA! ¿Quién será el sacrificio?", "RAID_WARNING")
        SendChatMessage("El Ritual de la Perdición ha comenzado. Uno morirá para invocar al Guardia Apocalíptico.", chan)
    end
    
    self.DoomActive = true
    self.DoomStartTime = GetTime()
    
    local timerFrame = CreateFrame("Frame")
    timerFrame.elapsed = 0
    timerFrame:SetScript("OnUpdate", function(f, d)
        f.elapsed = f.elapsed + d
        if f.elapsed >= 20 then
            Coven.DoomActive = false
            f:SetScript("OnUpdate", nil)
        end
    end)
end

function Coven:CheckDoomSacrifice(...)
    if not self.DoomActive then return end
    
    -- WoW 3.3.5a CLEU signature: timestamp, event, sourceGUID, sourceName, sourceFlags, destGUID, destName, destFlags
    local timestamp, subEvent, sourceGUID, sourceName, sourceFlags, destGUID, destName, destFlags = ...
    
    if subEvent == "UNIT_DIED" then
        if UnitInRaid(destName) or UnitInParty(destName) or destName == UnitName("player") then
            local chan = (GetNumRaidMembers() > 0) and "RAID" or ((GetNumPartyMembers() > 0) and "PARTY" or nil)
            if chan then
                SendChatMessage("¡" .. destName .. " HA SIDO SACRIFICADO!", "RAID_WARNING")
                SendChatMessage("Gracias por tu ofrenda, " .. destName .. ". El Guardia Apocalíptico te saluda.", chan)
            end
            self.DoomActive = false 
            PlaySound("RaidWarning")
        end
    end
end

-- ============================================================================
-- CURSE ASSIGNMENT
-- ============================================================================

function Coven:GetWarlocks()
    local warlocks = {}
    if GetNumRaidMembers() > 0 then
        for i = 1, GetNumRaidMembers() do
            local name, _, _, _, _, class = GetRaidRosterInfo(i)
            if class == "WARLOCK" then
                table.insert(warlocks, name)
            end
        end
    elseif GetNumPartyMembers() > 0 then
        local name, class = UnitName("player"), select(2, UnitClass("player"))
        if class == "WARLOCK" then table.insert(warlocks, name) end
        for i = 1, GetNumPartyMembers() do
            local u = "party" .. i
            if UnitExists(u) and select(2, UnitClass(u)) == "WARLOCK" then
                table.insert(warlocks, UnitName(u))
            end
        end
    else
        local name, class = UnitName("player"), select(2, UnitClass("player"))
        if class == "WARLOCK" then table.insert(warlocks, name) end
    end
    table.sort(warlocks)
    return warlocks
end

function Coven:AssignCurses()
    local warlocks = self:GetWarlocks()
    if #warlocks == 0 then 
        if S.Print then S:Print("|cFF9900FF[Coven]|r No se encontraron brujos en el grupo.") end
        return 
    end
    
    local curses = {
        "Maldición de los Elementos",
        "Maldición de la Agonía",
        "Maldición de la Perdición",
        "Maldición de las Lenguas",
        "Maldición de Debilidad"
    }
    
    local msg = "Sequito: Asignación de Maldiciones -> "
    for i, lock in ipairs(warlocks) do
        local curse = curses[i] or "Maldición de la Agonía"
        msg = msg .. string.format("[%s: %s] ", lock, curse)
    end
    
    if GetNumRaidMembers() > 0 then
        SendChatMessage(msg, (IsRaidLeader() or IsRaidOfficer()) and "RAID_WARNING" or "RAID")
    elseif GetNumPartyMembers() > 0 then
        SendChatMessage(msg, "PARTY")
    else
        if S.Print then S:Print(msg) end
    end
end

-- ============================================================================
-- UI: SUMMON QUEUE FRAME & SECURE ACTION BUTTON
-- ============================================================================

function Coven:CreateSummonFrame()
    if self.SummonFrame then return self.SummonFrame end

    local f = CreateFrame("Frame", "SequitoSummonFrame", UIParent)
    f:SetSize(320, 310)
    f:SetPoint("CENTER", UIParent, "CENTER", 200, 50)
    f:SetMovable(true)
    f:EnableMouse(true)
    f:RegisterForDrag("LeftButton")
    f:SetScript("OnDragStart", f.StartMoving)
    f:SetScript("OnDragStop", f.StopMovingOrSizing)
    f:SetFrameStrata("MEDIUM")

    if S.Theme and S.Theme.ApplyPanelBackdrop then
        S.Theme:ApplyPanelBackdrop(f)
    else
        f:SetBackdrop({
            bgFile = "Interface\\Buttons\\WHITE8x8",
            edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
            tile = false, edgeSize = 12,
            insets = { left = 3, right = 3, top = 3, bottom = 3 }
        })
        f:SetBackdropColor(0.08, 0.05, 0.12, 0.95)
        f:SetBackdropBorderColor(0.6, 0.2, 0.8, 0.8)
    end

    -- Header
    local title = f:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    title:SetPoint("TOPLEFT", 14, -12)
    title:SetText("|cFFCC66FFSequito Coven|r - Asistente de Invocación")

    local subtitle = f:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    subtitle:SetPoint("TOPLEFT", 14, -30)
    subtitle:SetText("Detecta '123', 'summ' o 'tp' en el chat de banda")
    subtitle:SetTextColor(0.65, 0.65, 0.7)

    -- Close Button
    local closeBtn = CreateFrame("Button", nil, f, "UIPanelCloseButton")
    closeBtn:SetPoint("TOPRIGHT", -4, -4)
    closeBtn:SetScript("OnClick", function() f:Hide() end)

    -- Queue List Container
    local queueContainer = CreateFrame("Frame", nil, f)
    queueContainer:SetSize(292, 175)
    queueContainer:SetPoint("TOP", 0, -50)
    queueContainer:SetBackdrop({
        bgFile = "Interface\\Buttons\\WHITE8x8",
        edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
        tile = false, edgeSize = 8,
        insets = { left = 2, right = 2, top = 2, bottom = 2 }
    })
    queueContainer:SetBackdropColor(0.04, 0.03, 0.06, 0.85)
    queueContainer:SetBackdropBorderColor(0.2, 0.15, 0.3, 0.7)
    f.queueContainer = queueContainer

    local emptyText = queueContainer:CreateFontString(nil, "OVERLAY", "GameFontDisable")
    emptyText:SetPoint("CENTER", 0, 0)
    emptyText:SetText("No hay invocaciones en cola.\nEscribe '123' o 'summ' para ingresar.")
    f.emptyText = emptyText

    -- Bottom Buttons Container
    local summonBtn = CreateFrame("Button", "SequitoCovenCastBtn", f, "SecureActionButtonTemplate, UIPanelButtonTemplate")
    summonBtn:SetSize(140, 26)
    summonBtn:SetPoint("BOTTOMLEFT", 14, 40)
    summonBtn:SetText("Invocar Siguiente")
    summonBtn:SetAttribute("type", "macro")

    summonBtn:SetScript("PreClick", function()
        if InCombatLockdown() then return end
        local nextTarget = Coven:GetNextSummonTarget()
        if nextTarget then
            summonBtn:SetAttribute("macrotext", "/target " .. nextTarget .. "\n/cast Ritual de invocación")
            if S.SendMessage then
                S:SendMessage("COVEN_SUMMON_CLICKED", nextTarget)
            end
        else
            summonBtn:SetAttribute("macrotext", "")
        end
    end)
    f.summonBtn = summonBtn

    local clearBtn = CreateFrame("Button", nil, f, "UIPanelButtonTemplate")
    clearBtn:SetSize(90, 26)
    clearBtn:SetPoint("BOTTOMRIGHT", -14, 40)
    clearBtn:SetText("Limpiar")
    clearBtn:SetScript("OnClick", function() Coven:ClearQueue() end)

    local curseBtn = CreateFrame("Button", nil, f, "UIPanelButtonTemplate")
    curseBtn:SetSize(292, 22)
    curseBtn:SetPoint("BOTTOM", 0, 12)
    curseBtn:SetText("Asignar Maldiciones de Brujos")
    curseBtn:SetScript("OnClick", function() Coven:AssignCurses() end)

    self.SummonFrame = f
    self.rowPool = {}
    f:Hide()
    return f
end

function Coven:CreateSummonButton()
    -- Botón flotante independiente si se necesita
    if self.SummonButton then return self.SummonButton end
    local btn = CreateFrame("Button", "SequitoFloatingSummonBtn", UIParent, "SecureActionButtonTemplate")
    btn:SetAttribute("type", "macro")
    btn:SetSize(36, 36)
    btn:SetPoint("BOTTOMRIGHT", UIParent, "BOTTOMRIGHT", -260, 180)
    btn:SetMovable(true)
    btn:EnableMouse(true)
    btn:RegisterForDrag("LeftButton")
    btn:SetScript("OnDragStart", btn.StartMoving)
    btn:SetScript("OnDragStop", btn.StopMovingOrSizing)
    
    local icon = btn:CreateTexture(nil, "ARTWORK")
    icon:SetAllPoints()
    icon:SetTexture("Interface\\Icons\\Spell_Shadow_Twilight")
    
    btn:SetScript("PreClick", function()
        if InCombatLockdown() then return end
        local target = Coven:GetNextSummonTarget()
        if target then
            btn:SetAttribute("macrotext", "/target " .. target .. "\n/cast Ritual de invocación")
            if S.SendMessage then
                S:SendMessage("COVEN_SUMMON_CLICKED", target)
            end
        else
            btn:SetAttribute("macrotext", "")
        end
    end)
    
    btn:Hide()
    self.SummonButton = btn
    return btn
end

function Coven:UpdateUI()
    if not self.SummonFrame then return end
    local f = self.SummonFrame
    local container = f.queueContainer

    if #self.Queue == 0 then
        f.emptyText:Show()
    else
        f.emptyText:Hide()
    end

    local rowHeight = 24
    local maxVisible = 6

    for i = 1, maxVisible do
        local row = self.rowPool[i]
        if not row then
            row = CreateFrame("Frame", nil, container)
            row:SetSize(280, rowHeight)
            row:SetPoint("TOPLEFT", 6, -((i - 1) * (rowHeight + 2) + 6))
            row:SetBackdrop({
                bgFile = "Interface\\Buttons\\WHITE8x8",
                tile = false,
            })
            row:SetBackdropColor(0.1, 0.08, 0.15, 0.6)

            local num = row:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
            num:SetPoint("LEFT", 6, 0)
            row.num = num

            local name = row:CreateFontString(nil, "OVERLAY", "GameFontNormal")
            name:SetPoint("LEFT", 26, 0)
            name:SetWidth(150)
            name:SetJustifyH("LEFT")
            row.name = name

            local timeText = row:CreateFontString(nil, "OVERLAY", "GameFontDisableSmall")
            timeText:SetPoint("RIGHT", -32, 0)
            row.timeText = timeText

            local delBtn = CreateFrame("Button", nil, row)
            delBtn:SetSize(20, 20)
            delBtn:SetPoint("RIGHT", -4, 0)
            delBtn:SetNormalTexture("Interface\\Buttons\\UI-GroupLoot-Pass-Up")
            delBtn:SetHighlightTexture("Interface\\Buttons\\UI-GroupLoot-Pass-Highlight")
            delBtn:SetScript("OnClick", function()
                if row.targetName then
                    Coven:RemoveFromQueue(row.targetName)
                end
            end)
            row.delBtn = delBtn

            self.rowPool[i] = row
        end

        local item = self.Queue[i]
        if item then
            row:Show()
            row.targetName = item.name
            row.num:SetText(tostring(i) .. ".")
            
            local c = RAID_CLASS_COLORS and RAID_CLASS_COLORS[item.class]
            if c then
                row.name:SetText(string.format("|cFF%02x%02x%02x%s|r", c.r * 255, c.g * 255, c.b * 255, item.name))
            else
                row.name:SetText(item.name)
            end

            local elapsed = math.floor(GetTime() - item.time)
            row.timeText:SetText(tostring(elapsed) .. "s")
        else
            row:Hide()
        end
    end

    -- Actualizar macro segura fuera de combate
    if not InCombatLockdown() and f.summonBtn then
        local nextTarget = self:GetNextSummonTarget()
        if nextTarget then
            f.summonBtn:SetText("Invocar (" .. nextTarget .. ")")
            f.summonBtn:SetAttribute("macrotext", "/target " .. nextTarget .. "\n/cast Ritual de invocación")
        else
            f.summonBtn:SetText("Invocar Siguiente")
            f.summonBtn:SetAttribute("macrotext", "")
        end
    end
end

function Coven:Toggle()
    local f = self:CreateSummonFrame()
    if f:IsShown() then
        f:Hide()
    else
        self:UpdateUI()
        f:Show()
    end
end
