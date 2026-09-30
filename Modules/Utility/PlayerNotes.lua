--[[
    Sequito - PlayerNotes Module
    Sistema de notas de jugadores optimizado para WotLK 3.3.5a
    Version: 8.0.0
]]

local addonName, S = ...
S.PlayerNotes = S.PlayerNotes or {}
local PN = S.PlayerNotes

SequitoPlayerNotesDB = SequitoPlayerNotesDB or {}

-- Opciones por defecto
local DEFAULT_OPTIONS = {
    enabled = true,
    showInTooltip = true,
    autoSave = true,
    showInChatOnTarget = false,
}

-- Normalizador canónico de nombres (ej. "arthas" -> "Arthas", "arthas-ragnaros" -> "Arthas-Ragnaros")
local function NormalizePlayerName(name)
    if not name or type(name) ~= "string" then return nil end
    local clean = name:match("^%s*(.-)%s*$")
    if not clean or clean == "" then return nil end
    
    local playerName, realm = clean:match("^([^-]+)%-(.+)$")
    if playerName and realm then
        return playerName:sub(1,1):upper() .. playerName:sub(2):lower() .. "-" .. realm:sub(1,1):upper() .. realm:sub(2):lower()
    else
        return clean:sub(1,1):upper() .. clean:sub(2):lower()
    end
end

-- Helper para obtener configuración con fallback defensivo
function PN:GetOption(key)
    if S.ModuleConfig and S.ModuleConfig.GetValue then
        local val = S.ModuleConfig:GetValue("PlayerNotes", key)
        if val ~= nil then return val end
    end
    if DEFAULT_OPTIONS[key] ~= nil then
        return DEFAULT_OPTIONS[key]
    end
    return true
end

function PN:EnsureDB()
    if type(SequitoPlayerNotesDB) ~= "table" then
        SequitoPlayerNotesDB = {}
    end
    return SequitoPlayerNotesDB
end

function PN:Initialize()
    if self.initialized then return end
    self:EnsureDB()
    
    if not self:GetOption("enabled") then
        return
    end
    self.initialized = true
    
    self.frame = self:CreateFrame()
    self.Frame = self.frame
    self:RegisterEvents()
    self:HookTooltip()
end

function PN:CreateFrame()
    if self.frame then return self.frame end

    local f = CreateFrame("Frame", "SequitoPlayerNotesFrame", UIParent)
    self.frame = f
    self.Frame = f
    f:SetSize(360, 260)
    f:SetPoint("CENTER", UIParent, "CENTER", 0, 50)
    
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
            S.SmartDefaults:SavePosition("PlayerNotes", selfFrame)
        end
    end)
    f:SetClampedToScreen(true)
    f:Hide()
    
    -- Título
    f.title = f:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
    f.title:SetPoint("TOP", 0, -12)
    f.title:SetText("|cFFD4AF37Notas de Jugador|r")
    
    -- Etiqueta de jugador actual
    f.playerName = f:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
    f.playerName:SetPoint("TOPLEFT", 18, -38)
    f.playerName:SetText("Jugador: |cFFFFD100Ninguno|r")
    
    -- EditBox con márgenes y soporte multilínea
    local eb = CreateFrame("EditBox", "SequitoPlayerNotesEditBox", f)
    f.editBox = eb
    eb:SetSize(324, 130)
    eb:SetPoint("TOP", 0, -62)
    eb:SetMultiLine(true)
    eb:SetAutoFocus(false)
    eb:SetFontObject(GameFontHighlight)
    eb:SetTextInsets(8, 8, 8, 8)
    eb:SetBackdrop({
        bgFile = "Interface\\Buttons\\WHITE8X8",
        edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
        tile = true, tileSize = 8, edgeSize = 8,
        insets = {left = 2, right = 2, top = 2, bottom = 2}
    })
    eb:SetBackdropColor(0.05, 0.05, 0.08, 0.85)
    eb:SetBackdropBorderColor(0.4, 0.4, 0.5, 0.8)
    
    eb:SetScript("OnEscapePressed", function(selfEb)
        selfEb:ClearFocus()
        f:Hide()
    end)
    
    -- Botón Guardar
    f.saveBtn = CreateFrame("Button", nil, f, "UIPanelButtonTemplate")
    f.saveBtn:SetSize(85, 24)
    f.saveBtn:SetPoint("BOTTOMLEFT", 16, 12)
    f.saveBtn:SetText("Guardar")
    f.saveBtn:SetScript("OnClick", function()
        PN:SaveNote(false)
    end)
    
    -- Botón Eliminar
    f.deleteBtn = CreateFrame("Button", nil, f, "UIPanelButtonTemplate")
    f.deleteBtn:SetSize(85, 24)
    f.deleteBtn:SetPoint("LEFT", f.saveBtn, "RIGHT", 8, 0)
    f.deleteBtn:SetText("Eliminar")
    f.deleteBtn:SetScript("OnClick", function()
        if PN.currentPlayer then
            PN:DeleteNote(PN.currentPlayer, false)
        end
    end)
    
    -- Botón Cerrar inferior
    f.closeBottomBtn = CreateFrame("Button", nil, f, "UIPanelButtonTemplate")
    f.closeBottomBtn:SetSize(85, 24)
    f.closeBottomBtn:SetPoint("BOTTOMRIGHT", -16, 12)
    f.closeBottomBtn:SetText("Cerrar")
    f.closeBottomBtn:SetScript("OnClick", function()
        f:Hide()
    end)
    
    -- Botón X superior derecha
    f.close = CreateFrame("Button", nil, f, "UIPanelCloseButton")
    f.close:SetPoint("TOPRIGHT", -4, -4)
    f.close:SetScript("OnClick", function()
        f:Hide()
    end)
    
    -- Hook OnHide para autosave y liberación de teclado
    f:SetScript("OnHide", function(selfFrame)
        if PN:GetOption("autoSave") and PN.currentPlayer then
            PN:SaveNote(true)
        end
        if f.editBox then
            f.editBox:ClearFocus()
        end
    end)
    
    if S.SmartDefaults then
        S.SmartDefaults:RestorePosition("PlayerNotes")
    end
    
    return f
end

function PN:RegisterEvents()
    if self.eventsRegistered then return end
    self.eventsRegistered = true
    
    local events = CreateFrame("Frame")
    events:RegisterEvent("PLAYER_TARGET_CHANGED")
    events:SetScript("OnEvent", function()
        PN:OnTargetChanged()
    end)
end

function PN:SetNote(playerName, note, silent)
    local norm = NormalizePlayerName(playerName)
    if not norm then return end
    
    local db = self:EnsureDB()
    if note and note:match("%S") then
        local trimmed = note:match("^%s*(.-)%s*$")
        db[norm] = trimmed
        if not silent then
            local msg = "Nota guardada para |cFFFFD100" .. norm .. "|r."
            if S.Print then
                S:Print(msg)
            else
                print("|cFFFF9900[Sequito]|r " .. msg)
            end
        end
    else
        self:DeleteNote(norm, silent)
    end
end

function PN:AddNote(playerName, note)
    self:SetNote(playerName, note, false)
end

function PN:DeleteNote(playerName, silent)
    local norm = NormalizePlayerName(playerName)
    if not norm then return end
    
    local db = self:EnsureDB()
    if db[norm] then
        db[norm] = nil
        if not silent then
            local msg = "Nota eliminada para |cFFFFD100" .. norm .. "|r."
            if S.Print then
                S:Print(msg)
            else
                print("|cFFFF9900[Sequito]|r " .. msg)
            end
        end
    end
    
    if self.currentPlayer == norm and self.frame and self.frame.editBox then
        self.frame.editBox:SetText("")
    end
end

function PN:GetNote(playerName)
    local norm = NormalizePlayerName(playerName)
    if not norm then return nil end
    local db = self:EnsureDB()
    return db[norm]
end

function PN:ShowNote(playerName)
    local norm = NormalizePlayerName(playerName)
    if not norm then
        if UnitIsPlayer("target") then
            norm = NormalizePlayerName(UnitName("target"))
        end
    end
    
    if not self.frame then
        self:CreateFrame()
    end
    
    self.currentPlayer = norm
    if self.frame then
        if norm then
            self.frame.playerName:SetText("Jugador: |cFFFFD100" .. norm .. "|r")
            local existing = self:GetNote(norm) or ""
            self.frame.editBox:SetText(existing)
            self.frame.deleteBtn:Enable()
        else
            self.frame.playerName:SetText("Jugador: |cFF888888(Selecciona o escribe un nombre)|r")
            self.frame.editBox:SetText("")
            self.frame.deleteBtn:Disable()
        end
        self.frame:Show()
    end
end

function PN:SaveNote(silent)
    if self.currentPlayer and self.frame and self.frame.editBox then
        local noteText = self.frame.editBox:GetText()
        self:SetNote(self.currentPlayer, noteText, silent)
    end
end

function PN:HookTooltip()
    if self.tooltipHooked then return end
    self.tooltipHooked = true
    
    GameTooltip:HookScript("OnTooltipSetUnit", function(tip)
        if not PN:GetOption("enabled") or not PN:GetOption("showInTooltip") then return end
        local _, unit = tip:GetUnit()
        if unit and UnitIsPlayer(unit) then
            local rawName = UnitName(unit)
            local note = PN:GetNote(rawName)
            if note and note ~= "" then
                tip:AddLine(" ")
                tip:AddLine("|cFFFFD100[Nota Sequito]|r", 1, 0.82, 0)
                for line in note:gmatch("[^\r\n]+") do
                    tip:AddLine("  " .. line, 0.9, 0.9, 0.9, true)
                end
                tip:Show()
            end
        end
    end)
end

function PN:OnTargetChanged()
    if not self:GetOption("enabled") or not self:GetOption("showInChatOnTarget") then return end
    if InCombatLockdown() then return end
    
    if UnitIsPlayer("target") then
        local name = UnitName("target")
        local norm = NormalizePlayerName(name)
        if norm and norm ~= self.lastTargetAnnounced then
            self.lastTargetAnnounced = norm
            local note = self:GetNote(norm)
            if note and note ~= "" then
                local formatted = note:gsub("\n", " ")
                if S.Print then
                    S:Print("|cFFFFD100" .. norm .. ":|r " .. formatted)
                else
                    print("|cFFFF9900[Sequito]|r |cFFFFD100" .. norm .. ":|r " .. formatted)
                end
            end
        end
    else
        self.lastTargetAnnounced = nil
    end
end

function PN:Toggle()
    if not self.frame then
        self:CreateFrame()
    end
    if self.frame:IsShown() then
        self.frame:Hide()
    else
        local targetName = UnitIsPlayer("target") and UnitName("target") or self.currentPlayer
        self:ShowNote(targetName)
    end
end

function PN:ListNotes()
    local db = self:EnsureDB()
    local names = {}
    for name, note in pairs(db) do
        if note and note:match("%S") then
            table.insert(names, name)
        end
    end
    table.sort(names)
    
    local total = #names
    if total == 0 then
        local msg = "No hay notas guardadas actualmente."
        if S.Print then S:Print(msg) else print("|cFFFF9900[Sequito]|r " .. msg) end
        return
    end
    
    local header = string.format("Notas de jugadores registradas (%d):", total)
    if S.Print then S:Print(header) else print("|cFFFF9900[Sequito]|r " .. header) end
    
    for _, name in ipairs(names) do
        local notePreview = db[name] or ""
        notePreview = notePreview:gsub("[\r\n]+", " ")
        if #notePreview > 45 then
            notePreview = notePreview:sub(1, 42) .. "..."
        end
        print(string.format("  • |cFFFFD100%s|r: %s", name, notePreview))
    end
end

function PN:PrintHelp()
    print("|cFFD4AF37=== Sequito PlayerNotes - Comandos ===|r")
    print("  |cFFFFD100/pn|r : Abre la ventana de notas del objetivo actual o alterna la ventana.")
    print("  |cFFFFD100/pn <nombre>|r : Abre la ventana de notas para el jugador especificado.")
    print("  |cFFFFD100/pn <nombre> <nota>|r : Guarda directamente una nota para el jugador.")
    print("  |cFFFFD100/pn del <nombre>|r : Elimina la nota del jugador.")
    print("  |cFFFFD100/pn list|r : Muestra un resumen de todas las notas guardadas.")
    print("  |cFFFFD100/pn help|r : Muestra esta guía de ayuda.")
end

function PN:SlashCommand(msg)
    msg = msg and msg:match("^%s*(.-)%s*$") or ""
    
    if msg == "" then
        if UnitIsPlayer("target") then
            self:ShowNote(UnitName("target"))
        else
            self:Toggle()
        end
        return
    end
    
    local cmd, rest = msg:match("^(%S+)%s*(.*)$")
    if not cmd then
        self:Toggle()
        return
    end
    
    local lowerCmd = cmd:lower()
    
    if lowerCmd == "list" or lowerCmd == "lista" then
        self:ListNotes()
        return
    elseif lowerCmd == "del" or lowerCmd == "delete" or lowerCmd == "borrar" then
        local targetName = rest:match("^(%S+)")
        if targetName and targetName ~= "" then
            self:DeleteNote(targetName, false)
        elseif UnitIsPlayer("target") then
            self:DeleteNote(UnitName("target"), false)
        else
            self:PrintHelp()
        end
        return
    elseif lowerCmd == "help" or lowerCmd == "ayuda" then
        self:PrintHelp()
        return
    end
    
    local targetName = cmd
    local noteText = rest:match("^%s*(.-)%s*$")
    
    if noteText and noteText ~= "" then
        self:SetNote(targetName, noteText, false)
        if self.frame and self.frame:IsShown() and self.currentPlayer == NormalizePlayerName(targetName) then
            self:ShowNote(targetName)
        end
    else
        self:ShowNote(targetName)
    end
end

-- Registrar configuración en ModuleConfig
if S.ModuleConfig then
    S.ModuleConfig:RegisterModule("PlayerNotes", {
        name = "Player Notes",
        icon = "Interface\\Icons\\INV_Misc_Note_01",
        description = "Sistema de notas personales sobre jugadores",
        category = "utility",
        options = {
            {
                type = "checkbox",
                key = "enabled",
                label = "Habilitar Player Notes",
                tooltip = "Activa/desactiva el sistema de notas",
                default = true,
            },
            {
                type = "checkbox",
                key = "showInTooltip",
                label = "Mostrar en Tooltip",
                tooltip = "Muestra las notas en el tooltip del jugador al pasar el ratón",
                default = true,
            },
            {
                type = "checkbox",
                key = "autoSave",
                label = "Guardado Automático",
                tooltip = "Guarda las notas automáticamente al cerrar la ventana",
                default = true,
            },
            {
                type = "checkbox",
                key = "showInChatOnTarget",
                label = "Anunciar en Chat al Seleccionar",
                tooltip = "Imprime la nota en la consola de chat al seleccionar al jugador (fuera de combate)",
                default = false,
            },
        },
    })
end

SLASH_PLAYERNOTES1 = "/pn"
SLASH_PLAYERNOTES2 = "/playernotes"
SlashCmdList["PLAYERNOTES"] = function(msg)
    PN:SlashCommand(msg)
end

local loader = CreateFrame("Frame")
loader:RegisterEvent("PLAYER_LOGIN")
loader:SetScript("OnEvent", function()
    PN:Initialize()
end)
