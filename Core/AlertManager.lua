--[[
    Jaina - AlertManager.lua
    Sistema centralizado de alertas y notificaciones
    Version: 8.0.0
]]

local addonName, S = ...
S.Alerts = {}
local AM = S.Alerts

local sub = string.sub

-- Tipos de alerta y sus configuraciones por defecto
AM.Types = {
    INFO = { 
        prefix = "", 
        color = "ffffff", 
        sound = nil, 
        output = "CHAT" 
    },
    SUCCESS = { 
        prefix = "√ ", 
        color = "00ff00", 
        sound = "Sound\\Interface\\AuctionWindowClose.wav", 
        output = "FRAME" 
    },
    WARNING = { 
        prefix = "⚠ ", 
        color = "ffff00", 
        sound = "Sound\\Interface\\RaidWarning.wav", 
        output = "FRAME" 
    },
    ERROR = { 
        prefix = "X ", 
        color = "ff0000", 
        sound = "Sound\\Interface\\Error.wav", 
        output = "FRAME" 
    },
    CRITICAL = { 
        prefix = "!!! ", 
        color = "ff0000", 
        sound = "Sound\\Creature\\HoodWolf\\HoodWolfTransformPlayer01.wav", -- Sonido fuerte
        output = "SCREEN" -- Raid Warning Style
    }
}

-- Frame para mensajes flotantes (estilo Blizzard UIErrorsFrame pero propio)
function AM:Initialize()
    self.AlertFrame = CreateFrame("MessageFrame", "JainaAlertMessageFrame", UIParent)
    self.AlertFrame:SetPoint("TOP", 0, -180)
    self.AlertFrame:SetSize(512, 100)
    self.AlertFrame:SetFont("Fonts\\FRIZQT__.TTF", 18, "OUTLINE")
    self.AlertFrame:SetShadowColor(0, 0, 0, 1)
    self.AlertFrame:SetShadowOffset(1, -1)
    self.AlertFrame:SetFadeDuration(3)
    self.AlertFrame:SetTimeVisible(4)
end

-- Método principal
function AM:Show(text, typeId)
    if not self.AlertFrame then self:Initialize() end
    
    typeId = typeId or "INFO"
    local config = self.Types[typeId] or self.Types.INFO
    
    -- 1. Sonido
    if config.sound then
        PlaySoundFile(config.sound)
    end
    
    -- 2. Formato de mensaje
    local formattedText = string.format("|cff%s%s%s|r", config.color, config.prefix, text)
    
    -- 3. Output
    if config.output == "CHAT" then
        print("|cff9966ffJaina:|r " .. formattedText)
        
    elseif config.output == "FRAME" then
        self.AlertFrame:AddMessage(text, 
            tonumber("0x"..sub(config.color,1,2))/255,
            tonumber("0x"..sub(config.color,3,4))/255,
            tonumber("0x"..sub(config.color,5,6))/255, 
            1
        )
        -- También al chat para historial
        print("|cff9966ffJaina:|r " .. formattedText)
        
    elseif config.output == "SCREEN" then
        RaidNotice_AddMessage(RaidWarningFrame, text, ChatTypeInfo["RAID_WARNING"])
        -- También al chat
        print("|cff9966ffJaina:|r " .. formattedText)
    end
end

-- Helpers rápidos
function S:Alert(text) AM:Show(text, "INFO") end
function S:Success(text) AM:Show(text, "SUCCESS") end
function S:Warning(text) AM:Show(text, "WARNING") end
function S:Error(text) AM:Show(text, "ERROR") end
function S:Critical(text) AM:Show(text, "CRITICAL") end
