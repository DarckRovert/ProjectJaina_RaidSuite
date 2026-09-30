--[[
    Sequito - DefensiveAlerts.lua
    Sistema de Llamadas de Defensivos
    Version: 7.3.0
    
    Funcionalidades:
    - Botón rápido para anunciar "NECESITO PEEL" o "USANDO DEFENSIVO"
    - El grupo ve quién necesita ayuda
    - Keybinds configurables
    - Alertas visuales para el grupo
]]

local addonName, S = ...
S.DefensiveAlerts = {}
local DA = S.DefensiveAlerts

-- Estado
DA.Frame = nil
DA.AlertHistory = {}
DA.Keybinds = {}
DA.IsVisible = false

-- Tipos de alertas
DA.AlertTypes = {
    NEED_PEEL = {
        text = "¡NECESITO PEEL!",
        color = {1, 0.3, 0.3},
        icon = "Interface\\Icons\\Spell_Holy_SealOfProtection",
        sound = "Sound\\Interface\\RaidWarning.wav",
        priority = 1,
    },
    USING_DEFENSIVE = {
        text = "Usando Defensivo",
        color = {0.3, 1, 0.3},
        icon = "Interface\\Icons\\Spell_Holy_DivineIntervention",
        sound = "Sound\\Interface\\iQuestUpdate.wav",
        priority = 2,
    },
    LOW_HP = {
        text = "¡HP BAJO!",
        color = {1, 0, 0},
        icon = "Interface\\Icons\\Ability_Rogue_FeignDeath",
        sound = "Sound\\Interface\\RaidWarning.wav",
        priority = 1,
    },
    NEED_HEAL = {
        text = "¡NECESITO HEAL!",
        color = {0.3, 1, 0.3},
        icon = "Interface\\Icons\\Spell_Holy_FlashHeal",
        sound = "Sound\\Interface\\RaidWarning.wav",
        priority = 1,
    },
    NEED_DISPEL = {
        text = "¡NECESITO DISPEL!",
        color = {0.8, 0.3, 1},
        icon = "Interface\\Icons\\Spell_Holy_Dispel",
        sound = "Sound\\Interface\\RaidWarning.wav",
        priority = 1,
    },
    GOING_IN = {
        text = "¡VOY A ENTRAR!",
        color = {1, 0.8, 0},
        icon = "Interface\\Icons\\Ability_Warrior_Charge",
        sound = "Sound\\Interface\\iQuestUpdate.wav",
        priority = 2,
    },
    FALLING_BACK = {
        text = "Retrocediendo",
        color = {0.5, 0.5, 1},
        icon = "Interface\\Icons\\Ability_Rogue_Sprint",
        sound = "Sound\\Interface\\iQuestUpdate.wav",
        priority = 3,
    },
}

-- Defensivos por clase para auto-detectar
local CLASS_DEFENSIVES = {
    ["WARRIOR"] = {
        [871] = "Shield Wall",
        [12975] = "Last Stand",
        [55694] = "Enraged Regeneration",
        [2565] = "Shield Block",
        [23920] = "Spell Reflection",
    },
    ["PALADIN"] = {
        [642] = "Divine Shield",
        [498] = "Divine Protection",
        [1022] = "Hand of Protection",
        [6940] = "Hand of Sacrifice",
        [64205] = "Divine Sacrifice",
        [31821] = "Aura Mastery",
    },
    ["HUNTER"] = {
        [19263] = "Deterrence",
        [5384] = "Feign Death",
    },
    ["ROGUE"] = {
        [31224] = "Cloak of Shadows",
        [5277] = "Evasion",
        [1856] = "Vanish",
        [45182] = "Cheating Death",
    },
    ["PRIEST"] = {
        [47585] = "Dispersion",
        [33206] = "Pain Suppression",
        [47788] = "Guardian Spirit",
        [586] = "Fade",
    },
    ["DEATHKNIGHT"] = {
        [48707] = "Anti-Magic Shell",
        [48792] = "Icebound Fortitude",
        [55233] = "Vampiric Blood",
        [49039] = "Lichborne",
        [51052] = "Anti-Magic Zone",
    },
    ["SHAMAN"] = {
        [30823] = "Shamanistic Rage",
        [16188] = "Nature's Swiftness",
    },
    ["MAGE"] = {
        [45438] = "Ice Block",
        [66] = "Invisibility",
        [11958] = "Cold Snap",
    },
    ["WARLOCK"] = {
        [6229] = "Shadow Ward",
        [47891] = "Shadow Ward (Rank 6)",
    },
    ["DRUID"] = {
        [22812] = "Barkskin",
        [61336] = "Survival Instincts",
        [22842] = "Frenzied Regeneration",
        [17116] = "Nature's Swiftness",
    },
}

-- Helper para obtener configuración
function DA:GetOption(key)
    if S.ModuleConfig then
        return S.ModuleConfig:GetValue("DefensiveAlerts", key)
    end
    return true
end

-- Helper canónico de canal PvP en 3.3.5a
function DA:GetChannel()
    local _, instanceType = IsInInstance()
    if instanceType == "pvp" then
        return "BATTLEGROUND"
    elseif IsInRaid() then
        return "RAID"
    elseif (IsInGroup and IsInGroup()) or (GetNumPartyMembers() > 0) then
        return "PARTY"
    end
    return nil
end

function DA:Initialize()
    if not self:GetOption("enabled") then
        return
    end
    
    self:CreateFrame()
    self:CreateAlertFrame()
    self:RegisterEvents()
    self:RegisterComm()
    self:SetupKeybinds()
end

function DA:CreateFrame()
    self.Frame = CreateFrame("Frame", "SequitoDefensiveAlertsFrame", UIParent)
    self.Frame:SetSize(180, 220)
    self.Frame:SetPoint("LEFT", UIParent, "LEFT", 20, -100)
    self.Frame:SetMovable(true)
    self.Frame:EnableMouse(true)
    self.Frame:RegisterForDrag("LeftButton")
    self.Frame:SetScript("OnDragStart", function(f) f:StartMoving() end)
    self.Frame:SetScript("OnDragStop", function(f) f:StopMovingOrSizing() end)
    self.Frame:Hide()
    
    -- Fondo
    self.Frame.bg = self.Frame:CreateTexture(nil, "BACKGROUND")
    self.Frame.bg:SetAllPoints()
    self.Frame.bg:SetTexture("Interface\\Buttons\\WHITE8X8")
    self.Frame.bg:SetVertexColor(0, 0, 0, 0.85)
    
    -- Borde
    self.Frame.border = CreateFrame("Frame", nil, self.Frame)
    self.Frame.border:SetAllPoints()
    self.Frame.border:SetBackdrop({
        edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
        edgeSize = 14,
    })
    self.Frame.border:SetBackdropBorderColor(1, 0.5, 0, 1)
    
    -- Título
    self.Frame.title = self.Frame:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
    self.Frame.title:SetPoint("TOP", self.Frame, "TOP", 0, -10)
    self.Frame.title:SetText("|cFFFF8800Alertas Rápidas|r")
    
    -- Botón cerrar
    self.Frame.closeBtn = CreateFrame("Button", nil, self.Frame, "UIPanelCloseButton")
    self.Frame.closeBtn:SetPoint("TOPRIGHT", self.Frame, "TOPRIGHT", -2, -2)
    self.Frame.closeBtn:SetScript("OnClick", function() self.Frame:Hide() end)
    
    -- Crear botones de alerta
    self:CreateAlertButtons()
end

function DA:CreateAlertButtons()
    local buttons = {
        {type = "NEED_PEEL", label = "¡Necesito Peel!", y = -35},
        {type = "USING_DEFENSIVE", label = "Usando Defensivo", y = -65},
        {type = "NEED_HEAL", label = "¡Necesito Heal!", y = -95},
        {type = "NEED_DISPEL", label = "¡Necesito Dispel!", y = -125},
        {type = "GOING_IN", label = "¡Voy a Entrar!", y = -155},
        {type = "FALLING_BACK", label = "Retrocediendo", y = -185},
    }
    
    self.Frame.buttons = {}
    
    for i, btnData in ipairs(buttons) do
        local btn = CreateFrame("Button", nil, self.Frame)
        btn:SetSize(150, 24)
        btn:SetPoint("TOP", self.Frame, "TOP", 0, btnData.y)
        
        -- Fondo del botón
        btn.bg = btn:CreateTexture(nil, "BACKGROUND")
        btn.bg:SetAllPoints()
        local alertType = self.AlertTypes[btnData.type]
        btn.bg:SetTexture("Interface\\Buttons\\WHITE8X8")
        btn.bg:SetVertexColor(alertType.color[1] * 0.3, alertType.color[2] * 0.3, alertType.color[3] * 0.3, 0.8)
        
        -- Texto
        btn.text = btn:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
        btn.text:SetPoint("CENTER")
        btn.text:SetText(btnData.label)
        btn.text:SetTextColor(alertType.color[1], alertType.color[2], alertType.color[3])
        
        -- Highlight
        btn:SetHighlightTexture("Interface\\Buttons\\UI-Listbox-Highlight")
        
        -- Click handler
        btn.alertType = btnData.type
        btn:SetScript("OnClick", function(self)
            DA:SendAlert(self.alertType)
        end)
        
        self.Frame.buttons[i] = btn
    end
end

function DA:CreateAlertFrame()
    -- Frame de alerta que aparece cuando alguien del grupo envía una alerta
    self.AlertDisplay = CreateFrame("Frame", "SequitoDefensiveAlertDisplay", UIParent)
    self.AlertDisplay:SetSize(300, 50)
    self.AlertDisplay:SetPoint("TOP", UIParent, "TOP", 0, -100)
    self.AlertDisplay:SetFrameStrata("HIGH")
    self.AlertDisplay:Hide()
    
    -- Fondo
    self.AlertDisplay.bg = self.AlertDisplay:CreateTexture(nil, "BACKGROUND")
    self.AlertDisplay.bg:SetAllPoints()
    
    -- Borde
    self.AlertDisplay.border = CreateFrame("Frame", nil, self.AlertDisplay)
    self.AlertDisplay.border:SetAllPoints()
    self.AlertDisplay.border:SetBackdrop({
        edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
        edgeSize = 14,
    })
    
    -- Icono
    self.AlertDisplay.icon = self.AlertDisplay:CreateTexture(nil, "ARTWORK")
    self.AlertDisplay.icon:SetSize(36, 36)
    self.AlertDisplay.icon:SetPoint("LEFT", self.AlertDisplay, "LEFT", 10, 0)
    
    -- Nombre del jugador
    self.AlertDisplay.playerName = self.AlertDisplay:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
    self.AlertDisplay.playerName:SetPoint("TOPLEFT", self.AlertDisplay.icon, "TOPRIGHT", 10, -2)
    
    -- Texto de alerta
    self.AlertDisplay.alertText = self.AlertDisplay:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    self.AlertDisplay.alertText:SetPoint("BOTTOMLEFT", self.AlertDisplay.icon, "BOTTOMRIGHT", 10, 2)
    
    -- Animación de fade
    self.AlertDisplay.fadeTime = 0
    self.AlertDisplay:SetScript("OnUpdate", function(frame, elapsed)
        if frame.fadeTime > 0 then
            frame.fadeTime = frame.fadeTime - elapsed
            if frame.fadeTime <= 0.5 then
                frame:SetAlpha(frame.fadeTime / 0.5)
            end
            if frame.fadeTime <= 0 then
                frame:Hide()
                frame:SetAlpha(1)
            end
        end
    end)
end

function DA:RegisterEvents()
    local eventFrame = CreateFrame("Frame")
    eventFrame:RegisterEvent("COMBAT_LOG_EVENT_UNFILTERED")
    eventFrame:RegisterEvent("UNIT_HEALTH")
    
    eventFrame:SetScript("OnEvent", function(self, event, ...)
        if event == "COMBAT_LOG_EVENT_UNFILTERED" then
            DA:OnCombatLog(...)
        elseif event == "UNIT_HEALTH" then
            local unit = ...
            if unit == "player" then
                DA:CheckAutoAlert()
            end
        end
    end)
end

function DA:OnCombatLog(...)
    local timestamp, event, sourceGUID, sourceName, sourceFlags, destGUID, destName, destFlags, spellId, spellName = ...
    
    -- Detectar uso de defensivos propios
    if event == "SPELL_CAST_SUCCESS" and sourceGUID == UnitGUID("player") then
        local _, class = UnitClass("player")
        local defensives = CLASS_DEFENSIVES[class]
        
        if defensives and defensives[spellId] then
            -- Auto-anunciar defensivo
            self:SendDefensiveUsed(spellName)
        end
    end
end

function DA:CheckAutoAlert()
    local hp = UnitHealth("player") / UnitHealthMax("player")
    
    -- Auto-alerta si HP muy bajo
    if hp <= 0.20 and not self.lowHPAlerted then
        self.lowHPAlerted = true
        -- No enviar automáticamente, solo preparar
    elseif hp > 0.40 then
        self.lowHPAlerted = false
    end
end

function DA:RegisterComm()
    if S.RegisterComm then
        S:RegisterComm("SEQDA", function(prefix, message, channel, sender)
            DA:OnCommReceived(prefix, message, channel, sender)
        end)
    end
end

function DA:SetupKeybinds()
    -- Los keybinds se configuran en Bindings.xml
    -- Aquí solo definimos las funciones globales
    
    _G.BINDING_HEADER_SEQUITO_DEFENSIVE = "Sequito - Alertas Defensivas"
    _G.BINDING_NAME_SEQUITO_NEED_PEEL = "Necesito Peel"
    _G.BINDING_NAME_SEQUITO_USING_DEFENSIVE = "Usando Defensivo"
    _G.BINDING_NAME_SEQUITO_NEED_HEAL = "Necesito Heal"
    
    -- Funciones globales para keybinds
    function Sequito_NeedPeel()
        DA:SendAlert("NEED_PEEL")
    end
    
    function Sequito_UsingDefensive()
        DA:SendAlert("USING_DEFENSIVE")
    end
    
    function Sequito_NeedHeal()
        DA:SendAlert("NEED_HEAL")
    end
end

function DA:SendAlert(alertType)
    local alertData = self.AlertTypes[alertType]
    if not alertData then return end
    
    if self:GetOption("showOnlyInCombat") and not UnitAffectingCombat("player") then
        return
    end
    
    local now = GetTime()
    self.lastAlertTimes = self.lastAlertTimes or {}
    local cd = self:GetOption("alertCooldown") or 10
    if self.lastAlertTimes[alertType] and (now - self.lastAlertTimes[alertType] < cd) then
        return
    end
    self.lastAlertTimes[alertType] = now
    
    local playerName = UnitName("player")
    local hp = math.floor((UnitHealth("player") / UnitHealthMax("player")) * 100)
    local channel = self:GetChannel()
    
    if channel and self:GetOption("announceToChat") then
        SendChatMessage(string.format("[Sequito] %s (%d%% HP)", alertData.text, hp), channel)
        if S.SendAddonMessage then
            local message = string.format("%s:%s:%d", alertType, playerName, hp)
            S:SendAddonMessage("SEQDA", message, channel)
        end
    end
    
    if S.Print then
        S:Print(string.format("|cFF%02x%02x%02x%s|r enviado al grupo.", 
            alertData.color[1] * 255, alertData.color[2] * 255, alertData.color[3] * 255, 
            alertData.text))
    end
    
    if self:GetOption("playSound") then
        PlaySoundFile(alertData.sound)
    end
end

function DA:SendDefensiveUsed(spellName)
    local channel = self:GetChannel()
    if channel and self:GetOption("announceToChat") then
        SendChatMessage(string.format("[Sequito] Usando: %s", spellName), channel)
    end
end

-- Wrapper methods for Bindings.xml keybinds
function DA:RequestPeel()
    self:SendAlert("NEED_PEEL")
end

function DA:RequestHeal()
    self:SendAlert("NEED_HEAL")
end

function DA:RequestDispel()
    self:SendAlert("NEED_DISPEL")
end

function DA:AnnounceDefensive()
    self:SendAlert("USING_DEFENSIVE")
end

function DA:OnCommReceived(prefix, message, channel, sender)
    if sender == UnitName("player") then return end
    
    local alertType, playerName, hp = strsplit(":", message)
    hp = tonumber(hp) or 0
    
    local alertData = self.AlertTypes[alertType]
    if not alertData then return end
    
    -- Mostrar alerta visual
    self:ShowAlert(playerName, alertData, hp)
    
    -- Guardar en historial
    table.insert(self.AlertHistory, {
        player = playerName,
        type = alertType,
        hp = hp,
        time = GetTime(),
    })
    
    -- Limitar historial
    while #self.AlertHistory > 20 do
        table.remove(self.AlertHistory, 1)
    end
end

function DA:ShowAlert(playerName, alertData, hp)
    -- Verificar si alertas visuales están habilitadas
    if not self:GetOption("showVisualAlert") then return end
    
    -- Configurar display
    self.AlertDisplay.icon:SetTexture(alertData.icon)
    self.AlertDisplay.playerName:SetText(playerName)
    self.AlertDisplay.playerName:SetTextColor(unpack(alertData.color))
    self.AlertDisplay.alertText:SetText(string.format("%s (%d%% HP)", alertData.text, hp))
    self.AlertDisplay.border:SetBackdropBorderColor(unpack(alertData.color))
    self.AlertDisplay.bg:SetTexture("Interface\\Buttons\\WHITE8X8")
    self.AlertDisplay.bg:SetVertexColor(alertData.color[1] * 0.2, alertData.color[2] * 0.2, alertData.color[3] * 0.2, 0.9)
    
    -- Duración configurable
    local duration = self:GetOption("alertDuration") or 4
    
    -- Mostrar
    self.AlertDisplay.fadeTime = duration
    self.AlertDisplay:SetAlpha(1)
    self.AlertDisplay:Show()
    
    -- Sonido si está habilitado
    if self:GetOption("playSound") then
        PlaySoundFile(alertData.sound)
    end
    
    -- Print
    if S.Print then
        S:Print(string.format("|cFF%02x%02x%02x[%s]|r %s (%d%% HP)", 
            alertData.color[1] * 255, alertData.color[2] * 255, alertData.color[3] * 255,
            playerName, alertData.text, hp))
    end
end

function DA:Toggle()
    if not self.Frame then return end
    if self.Frame:IsShown() then
        self.Frame:Hide()
    else
        self.Frame:Show()
    end
end

function DA:GetHistory()
    return self.AlertHistory
end

function DA:ClearHistory()
    wipe(self.AlertHistory)
    if S.Print then
        S:Print("Historial de alertas limpiado.")
    end
end

-- Registrar configuración en ModuleConfig
if S.ModuleConfig then
    S.ModuleConfig:RegisterModule("DefensiveAlerts", {
        name = "Defensive Alerts",
        icon = "Interface\\Icons\\Spell_Holy_SealOfProtection",
        description = "Sistema de alertas rápidas para pedir ayuda o anunciar defensivos",
        category = "pvp",
        options = {
            {
                type = "checkbox",
                key = "enabled",
                label = "Habilitar Defensive Alerts",
                tooltip = "Activa/desactiva el sistema de alertas defensivas",
                default = true,
            },
            {
                type = "checkbox",
                key = "playSound",
                label = "Reproducir Sonido",
                tooltip = "Reproduce sonido al recibir alertas",
                default = true,
            },
            {
                type = "checkbox",
                key = "showVisualAlert",
                label = "Mostrar Alerta Visual",
                tooltip = "Muestra alerta visual en pantalla",
                default = true,
            },
            {
                type = "checkbox",
                key = "announceToChat",
                label = "Anunciar en Chat",
                tooltip = "Anuncia las alertas en el chat del grupo",
                default = true,
            },
            {
                type = "slider",
                key = "alertDuration",
                label = "Duración Alerta (seg)",
                tooltip = "Tiempo que permanece visible la alerta",
                min = 2,
                max = 10,
                step = 0.5,
                default = 4,
            },
            {
                type = "slider",
                key = "alertCooldown",
                label = "Cooldown entre Alertas (seg)",
                tooltip = "Tiempo mínimo entre alertas del mismo tipo",
                min = 5,
                max = 30,
                step = 1,
                default = 10,
            },
            {
                type = "checkbox",
                key = "showOnlyInCombat",
                label = "Solo en Combate",
                tooltip = "Muestra alertas solo durante combate",
                default = false,
            },
        },
    })
end

-- Inicializar
if S.RegisterModule then
    S:RegisterModule("DefensiveAlerts", DA)
else
    local initFrame = CreateFrame("Frame")
    initFrame:RegisterEvent("PLAYER_LOGIN")
    initFrame:SetScript("OnEvent", function()
        DA:Initialize()
    end)
end
