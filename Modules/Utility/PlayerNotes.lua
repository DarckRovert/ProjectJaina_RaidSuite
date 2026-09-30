--[[
    Sequito - PlayerNotes Module
    Sistema de notas de jugadores
    Version: 7.3.0
]]

local addonName, S = ...
S.PlayerNotes = {}
local PN = S.PlayerNotes

SequitoPlayerNotesDB = SequitoPlayerNotesDB or {}

-- Helper para obtener configuración
function PN:GetOption(key)
    if S.ModuleConfig then
        return S.ModuleConfig:GetValue("PlayerNotes", key)
    end
    return true
end

function PN:Initialize()
    if self.initialized then return end
    if not self:GetOption("enabled") then
        return
    end
    self.initialized = true
    
    self.frame = self:CreateFrame()
    self:RegisterEvents()
    self:HookTooltip()
end

function PN:CreateFrame()
    local f = CreateFrame("Frame", "SequitoPlayerNotesFrame", UIParent)
    self.frame = f
    f:SetSize(350, 250)
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
            S.SmartDefaults:SavePosition("PlayerNotes", self)
        end
    end)
    f:Hide()
    
    f.title = f:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
    f.title:SetPoint("TOP", 0, -10)
    f.title:SetText("Notas de Jugador")
    
    f.playerName = f:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    f.playerName:SetPoint("TOPLEFT", 15, -40)
    
    f.editBox = CreateFrame("EditBox", nil, f)
    f.editBox:SetSize(320, 120)
    f.editBox:SetPoint("TOP", 0, -70)
    f.editBox:SetMultiLine(true)
    f.editBox:SetAutoFocus(false)
    f.editBox:SetFontObject(GameFontNormal)
    f.editBox:SetBackdrop({bgFile = "Interface\\Buttons\\WHITE8x8", edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border", edgeSize = 8})
    f.editBox:SetBackdropColor(0, 0, 0, 0.5)
    
    f.saveBtn = CreateFrame("Button", nil, f, "UIPanelButtonTemplate")
    f.saveBtn:SetSize(80, 25)
    f.saveBtn:SetPoint("BOTTOMLEFT", 15, 10)
    f.saveBtn:SetText("Guardar")
    f.saveBtn:SetScript("OnClick", function() PN:SaveNote() end)
    
    f.close = CreateFrame("Button", nil, f, "UIPanelCloseButton")
    f.close:SetPoint("TOPRIGHT", -5, -5)
    f.close:SetScript("OnClick", function() f:Hide() end)
    
    if S.SmartDefaults then
        S.SmartDefaults:RestorePosition("PlayerNotes")
    end
    
    return f
end

function PN:RegisterEvents()
    local events = CreateFrame("Frame")
    events:RegisterEvent("PLAYER_TARGET_CHANGED")
    events:SetScript("OnEvent", function() PN:OnTargetChanged() end)
end

function PN:SetNote(playerName, note)
    if not playerName then return end
    if note and note:match("%S") then
        SequitoPlayerNotesDB[playerName] = note
        if S.Print then
            S:Print("Nota guardada para " .. playerName)
        else
            print("|cFFFF9900[Sequito]|r Nota guardada para " .. playerName)
        end
    else
        self:DeleteNote(playerName)
    end
end

function PN:AddNote(playerName, note)
    self:SetNote(playerName, note)
end

function PN:DeleteNote(playerName)
    if SequitoPlayerNotesDB and playerName then
        SequitoPlayerNotesDB[playerName] = nil
        if S.Print then
            S:Print("Nota eliminada para " .. playerName)
        else
            print("|cFFFF9900[Sequito]|r Nota eliminada para " .. playerName)
        end
        if self.currentPlayer == playerName and self.frame and self.frame:IsShown() and self.frame.editBox then
            self.frame.editBox:SetText("")
        end
    end
end

function PN:GetNote(playerName)
    return SequitoPlayerNotesDB[playerName]
end

function PN:ShowNote(playerName)
    self.currentPlayer = playerName
    if self.frame then
        if self.frame.playerName then self.frame.playerName:SetText(playerName) end
        if self.frame.editBox then self.frame.editBox:SetText(self:GetNote(playerName) or "") end
        self.frame:Show()
    end
end

function PN:SaveNote()
    if self.currentPlayer and self.frame and self.frame.editBox then
        local noteText = self.frame.editBox:GetText()
        self:SetNote(self.currentPlayer, noteText)
    end
end

function PN:HookTooltip()
    if self.tooltipHooked then return end
    self.tooltipHooked = true
    GameTooltip:HookScript("OnTooltipSetUnit", function(tip)
        if not PN:GetOption("enabled") or not PN:GetOption("showInTooltip") then return end
        local _, unit = tip:GetUnit()
        if unit and UnitIsPlayer(unit) then
            local name = UnitName(unit)
            local note = PN:GetNote(name)
            if note and note ~= "" then
                tip:AddLine(" ")
                tip:AddDoubleLine("|cFFFFD100Nota Sequito:|r", note, 1, 0.82, 0, 1, 1, 1, 1)
                tip:Show()
            end
        end
    end)
end

function PN:OnTargetChanged()
    if not self:GetOption("enabled") then return end
    if UnitIsPlayer("target") then
        local name = UnitName("target")
        local note = self:GetNote(name)
        if note and note ~= "" then
            if S.Print then
                S:Print(name .. ": " .. note)
            else
                print("|cFFFF9900[Sequito]|r " .. name .. ": " .. note)
            end
        end
    end
end

function PN:Toggle()
    if not self.frame then return end
    if self.frame:IsShown() then self.frame:Hide() else self.frame:Show() end
end

function PN:SlashCommand(msg)
    local cmd, rest = strsplit(" ", msg, 2)
    if cmd and rest then
        local name, note = strsplit(" ", rest, 2)
        if name and note then
            self:SetNote(name, note)
        elseif name then
            self:ShowNote(name)
        end
    else
        if UnitIsPlayer("target") then
            self:ShowNote(UnitName("target"))
        else
            self:Toggle()
        end
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
                key = "shareWithGuild",
                label = "Compartir con Guild",
                tooltip = "Permite compartir notas con miembros de la guild",
                default = false,
            },
            {
                type = "checkbox",
                key = "showInTooltip",
                label = "Mostrar en Tooltip",
                tooltip = "Muestra las notas en el tooltip del jugador",
                default = true,
            },
            {
                type = "checkbox",
                key = "autoSave",
                label = "Guardado Automático",
                tooltip = "Guarda las notas automáticamente al cerrar",
                default = true,
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
loader:SetScript("OnEvent", function() PN:Initialize() end)
