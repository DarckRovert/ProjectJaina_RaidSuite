--[[
    Sequito - VotingSystem Module
    Sistema de Votaciones
    Version: 7.3.0
]]

local addonName, S = ...
S.VotingSystem = {}
local VS = S.VotingSystem

local currentPoll = nil
local votes = {}

-- Helper para obtener configuración
function VS:GetOption(key)
    if S.ModuleConfig then
        return S.ModuleConfig:GetValue("VotingSystem", key)
    end
    return true
end

function VS:Initialize()
    if not self:GetOption("enabled") then
        return
    end
    if self.initialized then return end
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
    f:SetSize(300, 200)
    f:SetPoint("CENTER")
    f:SetBackdrop({bgFile = "Interface\\DialogFrame\\UI-DialogBox-Background", edgeFile = "Interface\\DialogFrame\\UI-DialogBox-Border", edgeSize = 16, insets = {left = 4, right = 4, top = 4, bottom = 4}})
    f:SetMovable(true)
    f:EnableMouse(true)
    f:RegisterForDrag("LeftButton")
    f:SetScript("OnDragStart", f.StartMoving)
    f:SetScript("OnDragStop", f.StopMovingOrSizing)
    f:Hide()
    
    f.title = f:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
    f.title:SetPoint("TOP", 0, -10)
    f.title:SetText("Votación")
    
    f.question = f:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    f.question:SetPoint("TOP", 0, -40)
    f.question:SetWidth(280)
    
    f.options = {}
    for i = 1, 4 do
        local btn = CreateFrame("Button", nil, f, "UIPanelButtonTemplate")
        btn:SetSize(120, 25)
        btn:SetPoint("TOP", 0, -60 - (i-1) * 30)
        btn:SetScript("OnClick", function() VS:Vote(i) end)
        btn:Hide()
        f.options[i] = btn
    end
    
    f.close = CreateFrame("Button", nil, f, "UIPanelCloseButton")
    f.close:SetPoint("TOPRIGHT", -5, -5)
    
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

function VS:CreatePoll(question, ...)
    local options = {...}
    if #options < 2 then
        S:Print("Necesitas al menos 2 opciones")
        return
    end
    
    currentPoll = {question = question, options = options, votes = {}}
    votes = {}
    
    local msg = "POLL:" .. question
    for i, opt in ipairs(options) do
        msg = msg .. "|" .. opt
    end
    
    local channel = self:GetGroupChannel()
    if channel then
        SendAddonMessage("SeqVote", msg, channel)
        SendChatMessage("[Sequito] Votación: " .. question, channel)
    end
    
    self:ShowPoll(question, options)
end

function VS:ShowPoll(question, options)
    self.frame.question:SetText(question)
    
    for i, btn in ipairs(self.frame.options) do
        if options[i] then
            btn:SetText(options[i] .. " (0)")
            btn:Show()
        else
            btn:Hide()
        end
    end
    
    self.frame:Show()
    
    -- Auto-cerrar después de timeout configurado (Ley II & IV: Ticker OnUpdate en 3.3.5a)
    local timeout = self:GetOption("voteTimeout") or 60
    self.frame.timeRemaining = timeout
    self.frame:SetScript("OnUpdate", function(f, elapsed)
        f.timeRemaining = (f.timeRemaining or 60) - elapsed
        if f.timeRemaining <= 0 then
            f:SetScript("OnUpdate", nil)
            if currentPoll then
                VS:ClosePoll()
            end
        end
    end)
end

function VS:Vote(optionIndex)
    if currentPoll then
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
        self:UpdateResults()
    end
end

function VS:UpdateResults()
    if not currentPoll then return end
    
    local counts = {}
    for _, opt in pairs(votes) do
        counts[opt] = (counts[opt] or 0) + 1
    end
    
    for i, btn in ipairs(self.frame.options) do
        if currentPoll.options[i] then
            btn:SetText(currentPoll.options[i] .. " (" .. (counts[i] or 0) .. ")")
        end
    end
end

function VS:OnAddonMessage(msg, sender)
    local cmd, data = strsplit(":", msg, 2)
    
    if cmd == "POLL" then
        local parts = {strsplit("|", data)}
        local question = parts[1]
        local options = {}
        for i = 2, #parts do
            table.insert(options, parts[i])
        end
        currentPoll = {question = question, options = options}
        votes = {}
        self:ShowPoll(question, options)
    elseif cmd == "VOTE" then
        local opt = tonumber(data)
        if not opt and type(data) == "string" then
            local str = data:lower()
            if str == "yes" or str == "si" or str == "sí" then opt = 1
            elseif str == "no" then opt = 2
            end
        end
        if opt then
            votes[sender] = opt
            self:UpdateResults()
        end
    elseif cmd == "END" then
        currentPoll = nil
        self.frame:Hide()
    end
end

function VS:ClosePoll()
    if not currentPoll then return end
    
    if self.frame then
        self.frame:SetScript("OnUpdate", nil)
    end
    
    -- Anunciar resultados si está habilitado
    if self:GetOption("announceResults") then
        self:AnnounceResults()
    end
    
    local channel = self:GetGroupChannel()
    if channel then
        SendAddonMessage("SeqVote", "END:", channel)
    end
    
    currentPoll = nil
    self.frame:Hide()
end

function VS:AnnounceResults()
    if not currentPoll then return end
    
    local counts = {}
    for _, opt in pairs(votes) do
        counts[opt] = (counts[opt] or 0) + 1
    end
    
    local msg = "[Sequito] Resultados: "
    for i, option in ipairs(currentPoll.options) do
        msg = msg .. option .. " (" .. (counts[i] or 0) .. ") "
    end
    
    local channel = self:GetGroupChannel()
    if channel then
        if #msg > 240 then
            msg = msg:sub(1, 237) .. "..."
        end
        SendChatMessage(msg, channel)
    end
end

function VS:Toggle()
    if not self.frame then return end
    if self.frame:IsShown() then self.frame:Hide() else self.frame:Show() end
end

-- Wrapper methods for Bindings.xml keybinds
function VS:VoteYes()
    self:Vote(1)  -- First option is typically "Yes"
end

function VS:VoteNo()
    self:Vote(2)  -- Second option is typically "No"
end

function VS:SlashCommand(msg)
    local parts = {strsplit(" ", msg)}
    if #parts >= 3 then
        local question = parts[1]:gsub('"', '')
        local options = {}
        for i = 2, #parts do
            table.insert(options, parts[i])
        end
        self:CreatePoll(question, unpack(options))
    else
        self:Toggle()
    end
end

-- Registrar configuración en ModuleConfig
if S.ModuleConfig then
    S.ModuleConfig:RegisterModule("VotingSystem", {
        name = "Voting System",
        icon = "Interface\\Icons\\INV_Misc_Note_02",
        description = "Sistema de votaciones para el grupo o raid",
        category = "utility",
        options = {
            {
                type = "checkbox",
                key = "enabled",
                label = "Habilitar Voting System",
                tooltip = "Activa/desactiva el sistema de votaciones",
                default = true,
            },
            {
                type = "slider",
                key = "voteTimeout",
                label = "Tiempo Límite (seg)",
                tooltip = "Tiempo máximo para votar antes de cerrar la votación",
                min = 15,
                max = 300,
                step = 15,
                default = 60,
            },
            {
                type = "checkbox",
                key = "announceResults",
                label = "Anunciar Resultados",
                tooltip = "Anuncia los resultados al grupo automáticamente",
                default = true,
            },
            {
                type = "checkbox",
                key = "allowAnonymous",
                label = "Permitir Votos Anónimos",
                tooltip = "Los votos no muestran quién votó qué",
                default = false,
            },
            {
                type = "checkbox",
                key = "requireMinVotes",
                label = "Requerir Mínimo de Votos",
                tooltip = "Requiere un número mínimo de votos para validar",
                default = false,
            },
            {
                type = "slider",
                key = "minVotesPercent",
                label = "Mínimo de Votos (%)",
                tooltip = "Porcentaje mínimo del grupo que debe votar",
                min = 25,
                max = 100,
                step = 5,
                default = 50,
            },
        },
    })
end

local loader = CreateFrame("Frame")
loader:RegisterEvent("PLAYER_LOGIN")
loader:SetScript("OnEvent", function() VS:Initialize() end)
