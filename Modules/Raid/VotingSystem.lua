--[[
    Sequito - VotingSystem Module
    Sistema Democrático de Votaciones para Raid y Grupos
    Version: 8.0.0 (WotLK 3.3.5a Build 12340)
]]

local addonName, S = ...
S.VotingSystem = {}
local VS = S.VotingSystem

local currentPoll = nil
local votes = {}
local myVote = nil

-- Helper para obtener configuración
function VS:GetOption(key)
    if S.ModuleConfig then
        return S.ModuleConfig:GetValue("VotingSystem", key)
    end
    if key == "enabled" then return true end
    if key == "timeout" then return 60 end
    if key == "announceResults" then return true end
    if key == "playSound" then return true end
    return true
end

function VS:Initialize()
    if self.initialized then return end
    if not self:GetOption("enabled") then
        return
    end
    self.initialized = true
    
    self.frame = self:CreateFrame()
    self:RegisterEvents()
    
    if RegisterAddonMessagePrefix then
        RegisterAddonMessagePrefix("SeqVote")
    end
end

function VS:GetGroupChannel()
    if IsInInstance then
        local inInstance, instanceType = IsInInstance()
        if inInstance and instanceType == "pvp" then
            return "BATTLEGROUND"
        end
    end
    if GetNumRaidMembers() > 0 then
        return "RAID"
    elseif GetNumPartyMembers() > 0 then
        return "PARTY"
    end
    return nil
end

function VS:CreateFrame()
    local f = CreateFrame("Frame", "SequitoVotingFrame", UIParent)
    self.frame = f
    f:SetSize(340, 260)
    f:SetPoint("CENTER", UIParent, "CENTER", 0, 80)
    f:SetMovable(true)
    f:EnableMouse(true)
    f:SetClampedToScreen(true)
    f:RegisterForDrag("LeftButton")
    f:SetScript("OnDragStart", f.StartMoving)
    f:SetScript("OnDragStop", function(self)
        self:StopMovingOrSizing()
        if S.SmartDefaults then
            S.SmartDefaults:SavePosition("VotingSystem", self)
        end
    end)
    f:Hide()

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

    -- Botón de Cierre
    f.close = CreateFrame("Button", nil, f, "UIPanelCloseButton")
    f.close:SetPoint("TOPRIGHT", -4, -4)
    f.close:SetScript("OnClick", function()
        f:Hide()
    end)

    -- Título
    f.title = f:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
    f.title:SetPoint("TOP", 0, -12)
    f.title:SetText("Votación")

    -- =========================================================
    -- PANEL 1: VISTA DE VOTACIÓN ACTIVA (PollView)
    -- =========================================================
    local pView = CreateFrame("Frame", nil, f)
    pView:SetAllPoints()
    f.pollView = pView

    pView.question = pView:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
    pView.question:SetPoint("TOP", 0, -38)
    pView.question:SetWidth(300)
    pView.question:SetJustifyH("CENTER")

    pView.timerText = pView:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    pView.timerText:SetPoint("TOP", pView.question, "BOTTOM", 0, -4)
    pView.timerText:SetText("")

    pView.options = {}
    for i = 1, 4 do
        local btn = CreateFrame("Button", nil, pView, "UIPanelButtonTemplate")
        btn:SetSize(280, 24)
        btn:SetPoint("TOP", 0, -78 - (i - 1) * 28)
        btn:SetScript("OnClick", function()
            VS:Vote(i)
        end)
        btn:Hide()
        pView.options[i] = btn
    end

    -- Botón de Cerrar Votación (para creador/líder)
    pView.closePollBtn = CreateFrame("Button", nil, pView, "UIPanelButtonTemplate")
    pView.closePollBtn:SetSize(130, 22)
    pView.closePollBtn:SetPoint("BOTTOMLEFT", 20, 12)
    pView.closePollBtn:SetText("Finalizar Votación")
    pView.closePollBtn:SetScript("OnClick", function()
        VS:ClosePoll()
    end)

    -- Botón para ir al creador
    pView.newPollBtn = CreateFrame("Button", nil, pView, "UIPanelButtonTemplate")
    pView.newPollBtn:SetSize(130, 22)
    pView.newPollBtn:SetPoint("BOTTOMRIGHT", -20, 12)
    pView.newPollBtn:SetText("Nueva Encuesta")
    pView.newPollBtn:SetScript("OnClick", function()
        VS:OpenCreationDialog()
    end)

    -- =========================================================
    -- PANEL 2: VISTA DE CREACIÓN (CreateView)
    -- =========================================================
    local cView = CreateFrame("Frame", nil, f)
    cView:SetAllPoints()
    cView:Hide()
    f.createView = cView

    cView.lblQuestion = cView:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    cView.lblQuestion:SetPoint("TOPLEFT", 20, -36)
    cView.lblQuestion:SetText("Pregunta:")

    cView.inputQuestion = CreateFrame("EditBox", "SequitoVoteQuestionEdit", cView, "InputBoxTemplate")
    cView.inputQuestion:SetSize(296, 22)
    cView.inputQuestion:SetPoint("TOPLEFT", 24, -54)
    cView.inputQuestion:SetAutoFocus(false)
    cView.inputQuestion:SetMaxLetters(100)

    cView.lblPresets = cView:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    cView.lblPresets:SetPoint("TOPLEFT", 20, -82)
    cView.lblPresets:SetText("Preajustes de respuesta rápida:")

    -- Presets rápidos
    cView.btnPresetYN = CreateFrame("Button", nil, cView, "UIPanelButtonTemplate")
    cView.btnPresetYN:SetSize(90, 20)
    cView.btnPresetYN:SetPoint("TOPLEFT", 20, -100)
    cView.btnPresetYN:SetText("Sí / No")
    cView.btnPresetYN:SetScript("OnClick", function()
        cView.inputOpt1:SetText("Sí")
        cView.inputOpt2:SetText("No")
        cView.inputOpt3:SetText("")
        cView.inputOpt4:SetText("")
    end)

    cView.btnPresetReady = CreateFrame("Button", nil, cView, "UIPanelButtonTemplate")
    cView.btnPresetReady:SetSize(95, 20)
    cView.btnPresetReady:SetPoint("LEFT", cView.btnPresetYN, "RIGHT", 8, 0)
    cView.btnPresetReady:SetText("Listo / Esperar")
    cView.btnPresetReady:SetScript("OnClick", function()
        cView.inputOpt1:SetText("Listo")
        cView.inputOpt2:SetText("Esperar")
        cView.inputOpt3:SetText("")
        cView.inputOpt4:SetText("")
    end)

    cView.btnPresetGo = CreateFrame("Button", nil, cView, "UIPanelButtonTemplate")
    cView.btnPresetGo:SetSize(95, 20)
    cView.btnPresetGo:SetPoint("LEFT", cView.btnPresetReady, "RIGHT", 8, 0)
    cView.btnPresetGo:SetText("Pull / Pausa")
    cView.btnPresetGo:SetScript("OnClick", function()
        cView.inputOpt1:SetText("Pull Inmediato")
        cView.inputOpt2:SetText("Pausa / Buffs")
        cView.inputOpt3:SetText("")
        cView.inputOpt4:SetText("")
    end)

    -- Campos de opciones personalizadas (1 a 4)
    local function makeOptInput(index, yOffset)
        local eb = CreateFrame("EditBox", "SequitoVoteOpt" .. index, cView, "InputBoxTemplate")
        eb:SetSize(135, 20)
        eb:SetAutoFocus(false)
        eb:SetMaxLetters(30)
        return eb
    end

    cView.inputOpt1 = makeOptInput(1)
    cView.inputOpt1:SetPoint("TOPLEFT", 24, -132)
    cView.inputOpt1:SetText("Sí")

    cView.inputOpt2 = makeOptInput(2)
    cView.inputOpt2:SetPoint("TOPRIGHT", -20, -132)
    cView.inputOpt2:SetText("No")

    cView.inputOpt3 = makeOptInput(3)
    cView.inputOpt3:SetPoint("TOPLEFT", 24, -160)

    cView.inputOpt4 = makeOptInput(4)
    cView.inputOpt4:SetPoint("TOPRIGHT", -20, -160)

    -- Botón de Iniciar Votación
    cView.btnStart = CreateFrame("Button", nil, cView, "UIPanelButtonTemplate")
    cView.btnStart:SetSize(140, 24)
    cView.btnStart:SetPoint("BOTTOMLEFT", 20, 14)
    cView.btnStart:SetText("|cFF00FF00Iniciar Votación|r")
    cView.btnStart:SetScript("OnClick", function()
        local q = cView.inputQuestion:GetText()
        if not q or q:gsub("%s+", "") == "" then
            if S.Print then
                S:Print("Debes ingresar una pregunta para la votación.")
            else
                DEFAULT_CHAT_FRAME:AddMessage("|cFFFF0000[Sequito]|r Debes ingresar una pregunta para la votación.")
            end
            return
        end

        local opts = {}
        local o1 = cView.inputOpt1:GetText()
        local o2 = cView.inputOpt2:GetText()
        local o3 = cView.inputOpt3:GetText()
        local o4 = cView.inputOpt4:GetText()

        if o1 and o1:gsub("%s+", "") ~= "" then table.insert(opts, o1) end
        if o2 and o2:gsub("%s+", "") ~= "" then table.insert(opts, o2) end
        if o3 and o3:gsub("%s+", "") ~= "" then table.insert(opts, o3) end
        if o4 and o4:gsub("%s+", "") ~= "" then table.insert(opts, o4) end

        if #opts < 2 then
            table.insert(opts, "Sí")
            table.insert(opts, "No")
        end

        VS:CreatePoll(q, unpack(opts))
    end)

    -- Botón de Cancelar / Volver
    cView.btnCancel = CreateFrame("Button", nil, cView, "UIPanelButtonTemplate")
    cView.btnCancel:SetSize(120, 24)
    cView.btnCancel:SetPoint("BOTTOMRIGHT", -20, 14)
    cView.btnCancel:SetText("Cancelar")
    cView.btnCancel:SetScript("OnClick", function()
        if currentPoll then
            cView:Hide()
            pView:Show()
            f.title:SetText("Votación")
        else
            f:Hide()
        end
    end)

    if S.SmartDefaults then
        S.SmartDefaults:RestorePosition("VotingSystem")
    end

    return f
end

function VS:RegisterEvents()
    local events = CreateFrame("Frame")
    events:RegisterEvent("CHAT_MSG_ADDON")
    events:SetScript("OnEvent", function(_, _, prefix, msg, channel, sender)
        if prefix == "SeqVote" then
            VS:OnAddonMessage(msg, sender)
        end
    end)
end

function VS:OpenCreationDialog()
    if not self.frame then
        self:Initialize()
    end
    if not self.frame then return end

    self.frame.pollView:Hide()
    self.frame.createView:Show()
    self.frame.title:SetText("Crear Votación")
    self.frame:Show()
    self.frame.createView.inputQuestion:SetFocus()
end

function VS:CreatePoll(question, ...)
    local options = {...}
    if #options < 2 then
        options = {"Sí", "No"}
    end

    -- Sanitizar y respetar límite de 240 bytes (Ley III)
    if #question > 120 then
        question = question:sub(1, 117) .. "..."
    end

    currentPoll = {
        question = question,
        options = options,
        votes = {},
        creator = UnitName("player"),
    }
    votes = {}
    myVote = nil

    local msg = "POLL:" .. question
    for _, opt in ipairs(options) do
        local safeOpt = opt:sub(1, 30):gsub("[|:]", "")
        msg = msg .. "|" .. safeOpt
    end

    if #msg > 240 then
        msg = msg:sub(1, 240)
    end

    local channel = self:GetGroupChannel()
    if channel then
        SendAddonMessage("SeqVote", msg, channel)
        SendChatMessage("[Sequito] Votación: " .. question, channel)
    end

    if self:GetOption("playSound") then
        PlaySoundFile("Sound\\Interface\\ReadyCheck.wav")
    end

    self:ShowPoll(question, options)
end

function VS:ShowPoll(question, options)
    if not self.frame then
        self:Initialize()
    end
    if not self.frame then return end

    local pView = self.frame.pollView
    self.frame.createView:Hide()
    pView:Show()

    pView.question:SetText(question or "Votación")

    for i, btn in ipairs(pView.options) do
        if options and options[i] then
            btn:SetText(options[i] .. " (0)")
            btn:Enable()
            btn:Show()
        else
            btn:Hide()
        end
    end

    -- Configurar permisos de cierre anticipado
    local isLeader = UnitIsRaidOfficer("player")
    local isCreator = (currentPoll and currentPoll.creator == UnitName("player"))
    if isLeader or isCreator then
        pView.closePollBtn:Show()
    else
        pView.closePollBtn:Hide()
    end

    self.frame.title:SetText("Votación")
    self.frame:Show()

    -- Ticker OnUpdate para cuenta regresiva (Ley II & IV)
    local timeout = tonumber(self:GetOption("timeout")) or 60
    self.frame.timeRemaining = timeout
    self.frame.elapsedTimer = 0

    self.frame:SetScript("OnUpdate", function(f, elapsed)
        f.timeRemaining = (f.timeRemaining or 60) - elapsed
        f.elapsedTimer = (f.elapsedTimer or 0) + elapsed

        if f.elapsedTimer >= 0.5 then
            f.elapsedTimer = 0
            local secs = math.max(0, math.ceil(f.timeRemaining))
            pView.timerText:SetText(string.format("Tiempo restante: |cFFFFD100%ds|r", secs))
            f.title:SetText(string.format("Votación (%ds)", secs))
        end

        if f.timeRemaining <= 0 then
            f:SetScript("OnUpdate", nil)
            if currentPoll then
                VS:ClosePoll()
            end
        end
    end)
end

function VS:Vote(optionIndex)
    if not currentPoll then return end

    local opt = tonumber(optionIndex)
    if not opt and type(optionIndex) == "string" then
        local str = optionIndex:lower()
        if str == "yes" or str == "si" or str == "sí" then
            opt = 1
        elseif str == "no" then
            opt = 2
        end
    end
    opt = opt or 1

    local channel = self:GetGroupChannel()
    if channel then
        SendAddonMessage("SeqVote", "VOTE:" .. opt, channel)
    end

    votes[UnitName("player")] = opt
    myVote = opt
    self:UpdateResults()
end

function VS:UpdateResults()
    if not currentPoll or not self.frame then return end

    local counts = {}
    for _, opt in pairs(votes) do
        counts[opt] = (counts[opt] or 0) + 1
    end

    local pView = self.frame.pollView
    for i, btn in ipairs(pView.options) do
        if currentPoll.options[i] then
            local count = counts[i] or 0
            if myVote == i then
                btn:SetText(string.format("|cFF00FF00[✓] %s (%d)|r", currentPoll.options[i], count))
            else
                btn:SetText(string.format("%s (%d)", currentPoll.options[i], count))
            end
        end
    end
end

function VS:OnAddonMessage(msg, sender)
    local cmd, data = strsplit(":", msg, 2)
    if not cmd then return end

    if cmd == "POLL" then
        local parts = {strsplit("|", data)}
        local question = parts[1] or "Votación"
        local options = {}
        for i = 2, #parts do
            if parts[i] and parts[i] ~= "" then
                table.insert(options, parts[i])
            end
        end
        if #options < 2 then
            options = {"Sí", "No"}
        end

        currentPoll = {
            question = question,
            options = options,
            creator = sender,
        }
        votes = {}
        myVote = nil

        if self:GetOption("playSound") then
            PlaySoundFile("Sound\\Interface\\ReadyCheck.wav")
        end

        self:ShowPoll(question, options)

    elseif cmd == "VOTE" then
        local opt = tonumber(data)
        if not opt and type(data) == "string" then
            local str = data:lower()
            if str == "yes" or str == "si" or str == "sí" then opt = 1
            elseif str == "no" then opt = 2
            end
        end
        if opt and currentPoll then
            votes[sender] = opt
            self:UpdateResults()
        end

    elseif cmd == "END" then
        -- Verificación de seguridad de permisos: emisor con rango de líder/oficial, creador o local
        local isLeader = UnitIsRaidOfficer(sender)
        local isCreator = (currentPoll and currentPoll.creator and (sender == currentPoll.creator))
        local isSelf = (sender == UnitName("player"))

        if isLeader or isCreator or isSelf then
            if self.frame then
                self.frame:SetScript("OnUpdate", nil)
                self.frame:Hide()
            end
            currentPoll = nil
            myVote = nil
        end
    end
end

function VS:ClosePoll()
    if not currentPoll then return end

    if self.frame then
        self.frame:SetScript("OnUpdate", nil)
    end

    if self:GetOption("announceResults") then
        self:AnnounceResults()
    end

    local channel = self:GetGroupChannel()
    if channel then
        SendAddonMessage("SeqVote", "END:", channel)
    end

    currentPoll = nil
    myVote = nil
    if self.frame then
        self.frame:Hide()
    end
end

function VS:EndPoll()
    self:ClosePoll()
end

function VS:AnnounceResults()
    if not currentPoll then return end

    local counts = {}
    local totalVotes = 0
    for _, opt in pairs(votes) do
        counts[opt] = (counts[opt] or 0) + 1
        totalVotes = totalVotes + 1
    end

    local msg = string.format("[Sequito] Encuesta: '%s' | Total: %d votos -> ", currentPoll.question, totalVotes)
    for i, option in ipairs(currentPoll.options) do
        local c = counts[i] or 0
        local pct = totalVotes > 0 and math.floor((c / totalVotes) * 100) or 0
        msg = msg .. string.format("%s: %d (%d%%) | ", option, c, pct)
    end

    local channel = self:GetGroupChannel()
    if channel then
        if #msg > 240 then
            msg = msg:sub(1, 237) .. "..."
        end
        SendChatMessage(msg, channel)
    else
        DEFAULT_CHAT_FRAME:AddMessage("|cFF00FFFF" .. msg .. "|r")
    end
end

function VS:Toggle()
    if not self.frame then
        self:Initialize()
    end
    if not self.frame then return end

    if self.frame:IsShown() then
        self.frame:Hide()
    else
        if currentPoll then
            self.frame.createView:Hide()
            self.frame.pollView:Show()
            self.frame.title:SetText("Votación")
            self.frame:Show()
        else
            self:OpenCreationDialog()
        end
    end
end

function VS:Show()
    if not self.frame then
        self:Initialize()
    end
    if self.frame then
        self.frame:Show()
    end
end

-- Atajos para Bindings.xml
function VS:VoteYes()
    self:Vote(1)
end

function VS:VoteNo()
    self:Vote(2)
end

function VS:SlashCommand(msg)
    msg = msg and msg:gsub("^%s*(.-)%s*$", "%1") or ""

    if msg == "" then
        self:Toggle()
        return
    end

    local lower = msg:lower()

    if lower == "yes" or lower == "si" or lower == "sí" or lower == "1" then
        self:Vote(1)
        return
    elseif lower == "no" or lower == "2" then
        self:Vote(2)
        return
    elseif lower == "3" then
        self:Vote(3)
        return
    elseif lower == "4" then
        self:Vote(4)
        return
    elseif lower == "end" or lower == "close" then
        self:ClosePoll()
        return
    elseif lower == "new" or lower == "create" then
        self:OpenCreationDialog()
        return
    end

    -- Parser avanzado con comillas o pipes: /vote "¿Vamos a ICC?" Si No
    local question, rest
    if msg:find('^"([^"]+)"%s*(.*)$') then
        question, rest = msg:match('^"([^"]+)"%s*(.*)$')
    elseif msg:find("|") then
        local parts = {strsplit("|", msg)}
        question = parts[1]:gsub("^%s*(.-)%s*$", "%1")
        local options = {}
        for i = 2, #parts do
            local opt = parts[i]:gsub("^%s*(.-)%s*$", "%1")
            if opt ~= "" then table.insert(options, opt) end
        end
        if #options >= 2 then
            self:CreatePoll(question, unpack(options))
            return
        end
    end

    if not question then
        local parts = {strsplit(" ", msg)}
        if #parts >= 3 then
            -- Si la última o últimas dos son opciones típicas
            question = table.concat(parts, " ", 1, #parts - 2)
            local opt1 = parts[#parts - 1]
            local opt2 = parts[#parts]
            self:CreatePoll(question, opt1, opt2)
            return
        else
            question = msg
        end
    end

    if question and question ~= "" then
        local options = {}
        if rest and rest ~= "" then
            for opt in rest:gmatch("%S+") do
                table.insert(options, opt)
            end
        end
        if #options < 2 then
            options = {"Sí", "No"}
        end
        self:CreatePoll(question, unpack(options))
    else
        self:OpenCreationDialog()
    end
end

-- Registro Canónico de Comandos Slash
SLASH_SEQUITOVOTE1 = "/vote"
SLASH_SEQUITOVOTE2 = "/poll"
SLASH_SEQUITOVOTE3 = "/voting"
SLASH_SEQUITOVOTE4 = "/seqvote"
SlashCmdList["SEQUITOVOTE"] = function(msg)
    VS:SlashCommand(msg)
end

local loader = CreateFrame("Frame")
loader:RegisterEvent("PLAYER_LOGIN")
loader:SetScript("OnEvent", function()
    VS:Initialize()
end)
