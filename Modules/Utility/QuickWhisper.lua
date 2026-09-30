--[[
    Sequito - QuickWhisper Module
    Mensajes rápidos predefinidos con despacho inteligente y gestión dinámica
    Version: 8.0.0
]]

local addonName, S = ...
S.QuickWhisper = S.QuickWhisper or {}
local QW = S.QuickWhisper

-- Base de datos inicial
SequitoQuickWhisperDB = SequitoQuickWhisperDB or {}

local DEFAULT_TEMPLATES = {
    {name = "Inv", text = "Inv please"},
    {name = "AFK", text = "AFK 5 min"},
    {name = "Summon", text = "Need summon please"},
    {name = "Ready", text = "Ready when you are"},
    {name = "Thanks", text = "Thanks for the group!"}
}

local DEFAULT_OPTIONS = {
    enabled = true,
    sendMode = "smart", -- "smart" (Target > Grupo), "whisper" (Solo Target), "group" (Solo Grupo)
    showInChat = true,  -- Mostrar eco local de confirmación
    maxTemplates = 15,
}

-- Helper para obtener configuración con fallback defensivo
function QW:GetOption(key)
    if S.ModuleConfig and S.ModuleConfig.GetValue then
        local val = S.ModuleConfig:GetValue("QuickWhisper", key)
        if val ~= nil then return val end
    end
    if DEFAULT_OPTIONS[key] ~= nil then
        return DEFAULT_OPTIONS[key]
    end
    return true
end

function QW:EnsureDB()
    if type(SequitoQuickWhisperDB) ~= "table" then
        SequitoQuickWhisperDB = {}
    end
    if not SequitoQuickWhisperDB.templates or #SequitoQuickWhisperDB.templates == 0 then
        SequitoQuickWhisperDB.templates = {}
        for _, t in ipairs(DEFAULT_TEMPLATES) do
            table.insert(SequitoQuickWhisperDB.templates, {name = t.name, text = t.text})
        end
    end
    return SequitoQuickWhisperDB
end

function QW:Initialize()
    if self.initialized then return end
    self:EnsureDB()

    if not self:GetOption("enabled") then
        return
    end
    self.initialized = true

    self.frame = self:CreateFrame()
    self.Frame = self.frame
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

function QW:CreateFrame()
    if self.frame then return self.frame end

    local f = CreateFrame("Frame", "SequitoQuickWhisperFrame", UIParent)
    self.frame = f
    self.Frame = f
    f:SetSize(340, 360)
    f:SetPoint("CENTER", UIParent, "CENTER", 0, 0)
    
    if S.Theme and S.Theme.ApplyPanelBackdrop then
        S.Theme:ApplyPanelBackdrop(f)
    else
        f:SetBackdrop({
            bgFile = "Interface\\DialogFrame\\UI-DialogBox-Background",
            edgeFile = "Interface\\DialogFrame\\UI-DialogBox-Border",
            tile = true, tileSize = 32, edgeSize = 16,
            insets = {left = 4, right = 4, top = 4, bottom = 4}
        })
    end
    
    f:SetMovable(true)
    f:EnableMouse(true)
    f:RegisterForDrag("LeftButton")
    f:SetScript("OnDragStart", f.StartMoving)
    f:SetScript("OnDragStop", function(selfFrame)
        selfFrame:StopMovingOrSizing()
        if S.SmartDefaults then
            S.SmartDefaults:SavePosition("QuickWhisper", selfFrame)
        end
    end)
    f:SetClampedToScreen(true)
    f:Hide()

    -- Título
    f.title = f:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
    f.title:SetPoint("TOP", 0, -12)
    f.title:SetText("|cFFD4AF37Whispers Rápidos|r")

    -- Subtítulo indicador de modo
    f.modeText = f:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    f.modeText:SetPoint("TOP", 0, -32)
    f.modeText:SetText("Modo: |cFF00FF00Objetivo > Grupo (Inteligente)|r")

    -- Botón Cerrar X
    f.close = CreateFrame("Button", nil, f, "UIPanelCloseButton")
    f.close:SetPoint("TOPRIGHT", -4, -4)
    f.close:SetScript("OnClick", function() f:Hide() end)

    -- ScrollFrame de plantillas
    local sf = CreateFrame("ScrollFrame", "SequitoQWScrollFrame", f, "UIPanelScrollFrameTemplate")
    f.scrollFrame = sf
    sf:SetPoint("TOPLEFT", 14, -52)
    sf:SetPoint("BOTTOMRIGHT", -32, 70)

    local content = CreateFrame("Frame", nil, sf)
    f.content = content
    content:SetSize(285, 200)
    sf:SetScrollChild(content)

    -- Formulario inferior: Agregar plantilla
    local addBg = f:CreateTexture(nil, "BACKGROUND")
    addBg:SetPoint("TOPLEFT", 12, -295)
    addBg:SetPoint("BOTTOMRIGHT", -12, 10)
    addBg:SetTexture("Interface\\Buttons\\WHITE8X8")
    addBg:SetVertexColor(0, 0, 0, 0.4)

    local addLabel = f:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    addLabel:SetPoint("TOPLEFT", 16, -298)
    addLabel:SetText("Nueva plantilla:")

    local editName = CreateFrame("EditBox", "SequitoQWEditName", f, "InputBoxTemplate")
    f.editName = editName
    editName:SetSize(75, 20)
    editName:SetPoint("TOPLEFT", 16, -316)
    editName:SetAutoFocus(false)
    editName:SetScript("OnEscapePressed", function(selfEb) selfEb:ClearFocus() end)

    local editText = CreateFrame("EditBox", "SequitoQWEditText", f, "InputBoxTemplate")
    f.editText = editText
    editText:SetSize(160, 20)
    editText:SetPoint("LEFT", editName, "RIGHT", 8, 0)
    editText:SetAutoFocus(false)
    editText:SetScript("OnEscapePressed", function(selfEb) selfEb:ClearFocus() end)
    editText:SetScript("OnEnterPressed", function()
        QW:AddTemplateFromUI()
    end)

    local addBtn = CreateFrame("Button", nil, f, "UIPanelButtonTemplate")
    f.addBtn = addBtn
    addBtn:SetSize(55, 22)
    addBtn:SetPoint("LEFT", editText, "RIGHT", 6, 0)
    addBtn:SetText("+ Añadir")
    addBtn:SetScript("OnClick", function()
        QW:AddTemplateFromUI()
    end)

    f.rows = {}

    if S.SmartDefaults then
        S.SmartDefaults:RestorePosition("QuickWhisper")
    end

    self:UpdateButtons()
    return f
end

function QW:AddTemplateFromUI()
    if not self.frame then return end
    local name = self.frame.editName and self.frame.editName:GetText()
    local text = self.frame.editText and self.frame.editText:GetText()

    name = name and name:match("^%s*(.-)%s*$") or ""
    text = text and text:match("^%s*(.-)%s*$") or ""

    if name ~= "" and text ~= "" then
        self:AddTemplate(name, text)
        self.frame.editName:SetText("")
        self.frame.editText:SetText("")
        self.frame.editName:ClearFocus()
        self.frame.editText:ClearFocus()
    else
        local warn = "Ingresa un nombre y texto válidos para la plantilla."
        if S.Print then S:Print(warn) else print("|cFFFF9900[Sequito]|r " .. warn) end
    end
end

function QW:UpdateButtons()
    if not self.frame or not self.frame.content then return end
    local db = self:EnsureDB()
    local templates = db.templates or {}

    -- Actualizar texto de modo
    local mode = self:GetOption("sendMode") or "smart"
    if self.frame.modeText then
        if mode == "whisper" then
            self.frame.modeText:SetText("Modo: |cFF00CCFFSolo Susurro (Objetivo)|r")
        elseif mode == "group" then
            self.frame.modeText:SetText("Modo: |cFFFFCC00Solo Grupo/Banda|r")
        else
            self.frame.modeText:SetText("Modo: |cFF00FF00Objetivo > Grupo (Inteligente)|r")
        end
    end

    for _, row in ipairs(self.frame.rows) do
        row:Hide()
    end

    local yOffset = 0
    for i, t in ipairs(templates) do
        local row = self.frame.rows[i]
        if not row then
            row = CreateFrame("Frame", nil, self.frame.content)
            row:SetSize(280, 26)

            local bg = row:CreateTexture(nil, "BACKGROUND")
            bg:SetAllPoints()
            bg:SetTexture("Interface\\Buttons\\WHITE8X8")
            bg:SetVertexColor(0.1, 0.1, 0.12, 0.6)
            row.bg = bg

            -- Botón de envío principal
            local sendBtn = CreateFrame("Button", nil, row, "UIPanelButtonTemplate")
            sendBtn:SetSize(248, 22)
            sendBtn:SetPoint("LEFT", 2, 0)
            row.sendBtn = sendBtn

            -- Botón de eliminar X
            local delBtn = CreateFrame("Button", nil, row, "UIPanelButtonTemplate")
            delBtn:SetSize(22, 22)
            delBtn:SetPoint("RIGHT", -2, 0)
            delBtn:SetText("×")
            row.delBtn = delBtn

            self.frame.rows[i] = row
        end

        row:SetPoint("TOPLEFT", self.frame.content, "TOPLEFT", 0, -yOffset)
        row:Show()

        local index = i
        local labelText = string.format("|cFFFFD100[%s]|r %s", t.name, t.text)
        if #labelText > 38 then
            labelText = labelText:sub(1, 35) .. "..."
        end
        row.sendBtn:SetText(labelText)
        row.sendBtn:SetScript("OnClick", function()
            QW:SendTemplate(index)
        end)

        row.delBtn:SetScript("OnClick", function()
            QW:DeleteTemplate(index)
        end)

        yOffset = yOffset + 28
    end

    self.frame.content:SetHeight(math.max(yOffset + 5, 200))
end

function QW:SendTemplate(index)
    local db = self:EnsureDB()
    local template = db.templates and db.templates[index]
    if not template or not template.text or template.text == "" then return end

    local msg = template.text
    if #msg > 240 then msg = msg:sub(1, 237) .. "..." end

    local mode = self:GetOption("sendMode") or "smart"
    local hasPlayerTarget = UnitExists("target") and UnitIsPlayer("target")
    local targetName = hasPlayerTarget and UnitName("target") or nil
    local groupChannel = self:GetGroupChannel()

    -- Modo 1: Solo Whisper
    if mode == "whisper" then
        if targetName and targetName ~= "" and targetName ~= UNKNOWNOBJECT then
            SendChatMessage(msg, "WHISPER", nil, targetName)
            if self:GetOption("showInChat") then
                local echo = string.format("Susurro a |cFFFFD100%s|r: %s", targetName, msg)
                if S.Print then S:Print(echo) else print("|cFFFF9900[Sequito]|r " .. echo) end
            end
        else
            local err = "Modo 'Solo Susurro' activo: Debes tener seleccionado a un jugador."
            if S.Print then S:Print(err) else print("|cFFFF9900[Sequito]|r " .. err) end
        end
        return
    end

    -- Modo 2: Solo Grupo
    if mode == "group" then
        if groupChannel then
            SendChatMessage(msg, groupChannel)
        else
            local err = "Modo 'Solo Grupo' activo: No te encuentras en un grupo o banda."
            if S.Print then S:Print(err) else print("|cFFFF9900[Sequito]|r " .. err) end
        end
        return
    end

    -- Modo 3: Inteligente (Target First > Grupo Fallback)
    if targetName and targetName ~= "" and targetName ~= UNKNOWNOBJECT then
        SendChatMessage(msg, "WHISPER", nil, targetName)
        if self:GetOption("showInChat") then
            local echo = string.format("Susurro a |cFFFFD100%s|r: %s", targetName, msg)
            if S.Print then S:Print(echo) else print("|cFFFF9900[Sequito]|r " .. echo) end
        end
    elseif groupChannel then
        SendChatMessage(msg, groupChannel)
    else
        local err = "Selecciona a un jugador para susurrar o únete a un grupo/banda."
        if S.Print then S:Print(err) else print("|cFFFF9900[Sequito]|r " .. err) end
    end
end

function QW:AddTemplate(name, text)
    local db = self:EnsureDB()
    local maxCount = self:GetOption("maxTemplates") or 15
    if #db.templates >= maxCount then
        local warn = string.format("Límite alcanzado (%d plantillas). Elimina una antes de agregar más.", maxCount)
        if S.Print then S:Print(warn) else print("|cFFFF9900[Sequito]|r " .. warn) end
        return
    end

    table.insert(db.templates, {name = name, text = text})
    self:UpdateButtons()
    local msg = string.format("Plantilla '|cFFFFD100%s|r' agregada.", name)
    if S.Print then S:Print(msg) else print("|cFFFF9900[Sequito]|r " .. msg) end
end

function QW:DeleteTemplate(index)
    local db = self:EnsureDB()
    if db.templates and db.templates[index] then
        local removed = table.remove(db.templates, index)
        self:UpdateButtons()
        local msg = string.format("Plantilla '|cFFFFD100%s|r' eliminada.", removed.name or tostring(index))
        if S.Print then S:Print(msg) else print("|cFFFF9900[Sequito]|r " .. msg) end
    end
end

function QW:Toggle()
    if not self.frame then
        self:CreateFrame()
    end
    if self.frame:IsShown() then
        self.frame:Hide()
    else
        self:UpdateButtons()
        self.frame:Show()
    end
end

function QW:SendMsg(index)
    self:SendTemplate(index)
end

function QW:ListTemplates()
    local db = self:EnsureDB()
    local templates = db.templates or {}
    local total = #templates
    if total == 0 then
        local msg = "No hay plantillas de whispers guardadas."
        if S.Print then S:Print(msg) else print("|cFFFF9900[Sequito]|r " .. msg) end
        return
    end

    local header = string.format("Plantillas de Whispers Rápidos (%d):", total)
    if S.Print then S:Print(header) else print("|cFFFF9900[Sequito]|r " .. header) end

    for i, t in ipairs(templates) do
        print(string.format("  [%d] |cFFFFD100%s|r: %s", i, t.name, t.text))
    end
end

function QW:PrintHelp()
    print("|cFFD4AF37=== Sequito QuickWhisper - Comandos ===|r")
    print("  |cFFFFD100/qw|r : Abre o cierra la interfaz de whispers rápidos.")
    print("  |cFFFFD100/qw send <número>|r : Envía la plantilla especificada.")
    print("  |cFFFFD100/qw add <nombre> <texto>|r : Agrega una nueva plantilla.")
    print("  |cFFFFD100/qw del <número>|r : Elimina la plantilla por índice.")
    print("  |cFFFFD100/qw list|r : Muestra todas las plantillas registradas.")
    print("  |cFFFFD100/qw help|r : Muestra esta guía de ayuda.")
end

function QW:SlashCommand(msg)
    msg = msg and msg:match("^%s*(.-)%s*$") or ""

    if msg == "" then
        self:Toggle()
        return
    end

    local cmd, rest = msg:match("^(%S+)%s*(.*)$")
    if not cmd then
        self:Toggle()
        return
    end

    local lowerCmd = cmd:lower()

    if lowerCmd == "add" and rest and rest ~= "" then
        local name, text = rest:match("^(%S+)%s+(.+)$")
        if name and text then
            self:AddTemplate(name, text)
        else
            print("|cFFFF9900[Sequito]|r Uso: /qw add <nombre> <texto>")
        end
    elseif lowerCmd == "del" or lowerCmd == "delete" or lowerCmd == "borrar" then
        local index = tonumber(rest:match("^(%d+)"))
        if index then
            self:DeleteTemplate(index)
        else
            print("|cFFFF9900[Sequito]|r Uso: /qw del <número>")
        end
    elseif lowerCmd == "send" or lowerCmd == "enviar" then
        local index = tonumber(rest:match("^(%d+)"))
        if index then
            self:SendTemplate(index)
        else
            print("|cFFFF9900[Sequito]|r Uso: /qw send <número>")
        end
    elseif lowerCmd == "list" or lowerCmd == "lista" then
        self:ListTemplates()
    elseif lowerCmd == "help" or lowerCmd == "ayuda" then
        self:PrintHelp()
    else
        self:Toggle()
    end
end

-- Registrar módulo en ModuleConfig
if S.ModuleConfig then
    S.ModuleConfig:RegisterModule({
        id = "QuickWhisper",
        name = "Whispers Rápidos",
        description = "Mensajes rápidos predefinidos para whispers y grupos",
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
                key = "sendMode",
                type = "dropdown",
                name = "Modo de Envío",
                description = "Canal de destino del mensaje",
                options = {
                    {text = "Inteligente (Target > Grupo)", value = "smart"},
                    {text = "Solo Susurro (Objetivo)", value = "whisper"},
                    {text = "Solo Grupo (Banda/Grupo)", value = "group"},
                },
                default = "smart"
            },
            {
                key = "showInChat",
                type = "checkbox",
                name = "Eco en Chat Local",
                description = "Muestra confirmación de envío en el chat local",
                default = true
            },
            {
                key = "maxTemplates",
                type = "slider",
                name = "Máximo de Plantillas",
                description = "Número máximo de plantillas guardadas",
                min = 5,
                max = 20,
                step = 1,
                default = 15
            }
        }
    })
end

SLASH_QUICKWHISPER1 = "/qw"
SLASH_QUICKWHISPER2 = "/quickwhisper"
SlashCmdList["QUICKWHISPER"] = function(msg)
    QW:SlashCommand(msg)
end

local loader = CreateFrame("Frame")
loader:RegisterEvent("PLAYER_LOGIN")
loader:SetScript("OnEvent", function()
    QW:Initialize()
end)
