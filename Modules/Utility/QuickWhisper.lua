--[[
    Sequito - QuickWhisper Module
    Mensajes rápidos predefinidos
    Version: 7.3.0
]]

local addonName, S = ...
S.QuickWhisper = {}
local QW = S.QuickWhisper

SequitoQuickWhisperDB = SequitoQuickWhisperDB or {
    templates = {
        {name = "Inv", text = "Inv please"},
        {name = "AFK", text = "AFK 5 min"},
        {name = "Summon", text = "Need summon please"},
        {name = "Ready", text = "Ready when you are"},
        {name = "Thanks", text = "Thanks for the group!"}
    }
}

-- Helper para obtener configuración
function QW:GetOption(key)
    if S.ModuleConfig then
        return S.ModuleConfig:GetValue("QuickWhisper", key)
    end
    return true
end

function QW:Initialize()
    if self.initialized then return end
    if not self:GetOption("enabled") then
        return
    end
    self.initialized = true
    
    self.frame = self:CreateFrame()
end

function QW:CreateFrame()
    local f = CreateFrame("Frame", "SequitoQuickWhisperFrame", UIParent)
    self.frame = f -- Asignación temprana para evitar error en UpdateButtons
    f:SetSize(200, 180)
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
            S.SmartDefaults:SavePosition("QuickWhisper", self)
        end
    end)
    f:Hide()
    
    f.title = f:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
    f.title:SetPoint("TOP", 0, -10)
    f.title:SetText("Quick Whisper")
    
    f.buttons = {}
    for i = 1, 5 do
        local btn = CreateFrame("Button", nil, f, "UIPanelButtonTemplate")
        btn:SetSize(170, 22)
        btn:SetPoint("TOP", 0, -30 - (i-1) * 26)
        btn:SetScript("OnClick", function() QW:SendTemplate(i) end)
        f.buttons[i] = btn
    end
    
    f.close = CreateFrame("Button", nil, f, "UIPanelCloseButton")
    f.close:SetPoint("TOPRIGHT", -5, -5)
    f.close:SetScript("OnClick", function() f:Hide() end)
    
    if S.SmartDefaults then
        S.SmartDefaults:RestorePosition("QuickWhisper")
    end
    
    self:UpdateButtons()
    return f
end

function QW:UpdateButtons()
    if not self.frame or not self.frame.buttons then return end
    for i, template in ipairs(SequitoQuickWhisperDB.templates) do
        if self.frame.buttons[i] then
            self.frame.buttons[i]:SetText(template.name)
            self.frame.buttons[i]:Show()
        end
    end
    for i = #SequitoQuickWhisperDB.templates + 1, #self.frame.buttons do
        if self.frame.buttons[i] then
            self.frame.buttons[i]:Hide()
        end
    end
end

function QW:GetGroupChannel()
    local inInstance, instanceType = IsInInstance()
    if inInstance and (instanceType == "pvp" or instanceType == "arena") then
        return "BATTLEGROUND"
    elseif GetNumRaidMembers() > 0 then
        return "RAID"
    elseif GetNumPartyMembers() > 0 then
        return "PARTY"
    end
    return nil
end

function QW:SendTemplate(index)
    local template = SequitoQuickWhisperDB.templates[index]
    if template and template.text and template.text ~= "" then
        local msg = template.text
        if #msg > 240 then msg = msg:sub(1, 237) .. "..." end
        local channel = self:GetGroupChannel()
        if channel then
            SendChatMessage(msg, channel)
        elseif UnitExists("target") and UnitIsPlayer("target") then
            local targetName = UnitName("target")
            if targetName and targetName ~= "" and targetName ~= UNKNOWNOBJECT then
                SendChatMessage(msg, "WHISPER", nil, targetName)
            end
        else
            if S.Print then
                S:Print("No hay grupo o target para enviar mensaje")
            else
                print("|cFFFF9900[Sequito]|r No hay grupo o target para enviar mensaje")
            end
        end
    end
end

function QW:AddTemplate(name, text)
    table.insert(SequitoQuickWhisperDB.templates, {name = name, text = text})
    self:UpdateButtons()
    if S.Print then
        S:Print("Template '" .. name .. "' agregado")
    else
        print("|cFFFF9900[Sequito]|r Template '" .. name .. "' agregado")
    end
end

function QW:Toggle()
    if not self.frame then return end
    if self.frame:IsShown() then self.frame:Hide() else self.frame:Show() end
end

function QW:SlashCommand(msg)
    local cmd, rest = strsplit(" ", msg, 2)
    if cmd == "add" and rest then
        local name, text = strsplit(" ", rest, 2)
        if name and text then
            self:AddTemplate(name, text)
        end
    elseif cmd == "send" then
        local index = tonumber(rest)
        if index then self:SendTemplate(index) end
    else
        self:Toggle()
    end
end

-- Wrapper method for Bindings.xml keybinds
function QW:SendMsg(index)
    self:SendTemplate(index)
end

-- Registrar módulo en ModuleConfig
if S.ModuleConfig then
    S.ModuleConfig:RegisterModule({
        id = "QuickWhisper",
        name = "Whispers Rápidos",
        description = "Mensajes rápidos predefinidos para whispers",
        category = "utility",
        icon = "Interface\\Icons\\INV_Letter_15",
        options = {
            {
                key = "enabled",
                type = "checkbox",
                name = "Habilitar Quick Whisper",
                description = "Habilitar/deshabilitar mensajes rápidos",
                default = true
            },
            {
                key = "showButton",
                type = "checkbox",
                name = "Mostrar Botón",
                description = "Mostrar botón de acceso rápido",
                default = true
            },
            {
                key = "customTemplates",
                type = "checkbox",
                name = "Templates Personalizados",
                description = "Permitir crear templates personalizados",
                default = true
            },
            {
                key = "maxTemplates",
                type = "slider",
                name = "Máximo de Templates",
                description = "Número máximo de templates guardados",
                min = 5,
                max = 20,
                step = 1,
                default = 10
            }
        }
    })
end

SLASH_QUICKWHISPER1 = "/qw"
SlashCmdList["QUICKWHISPER"] = function(msg)
    QW:SlashCommand(msg)
end

local loader = CreateFrame("Frame")
loader:RegisterEvent("PLAYER_LOGIN")
loader:SetScript("OnEvent", function() QW:Initialize() end)
