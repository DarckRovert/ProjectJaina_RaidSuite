--[[
    Jaina - FocusFire.lua
    Sistema de Llamadas de Target (Focus Fire)
    Version: 7.3.0
    
    Funcionalidades:
    - El líder marca un objetivo y todos reciben alerta visual/sonora
    - Mostrar % de vida del target marcado a todo el grupo
    - Sincronización via addon messages
    - Keybinds configurables
]]

local addonName, S = ...
S.FocusFire = {}
local FF = S.FocusFire

-- Estado
FF.CurrentTarget = nil
FF.CurrentTargetGUID = nil
FF.CurrentTargetHP = 0
FF.Frame = nil
FF.AlertFrame = nil
FF.IsVisible = false
FF.UpdateInterval = 0.1
FF.TimeSinceLastUpdate = 0

-- Configuración
FF.Config = {
    enabled = true,
    showAlert = true,
    playSound = true,
    showHealthBar = true,
    announceChannel = "RAID_WARNING",
    alertDuration = 3,
    soundFile = "Sound\\Interface\\RaidWarning.wav",
}

-- Colores por % de vida
local HealthColors = {
    {threshold = 0.2, r = 1.0, g = 0.0, b = 0.0},  -- Rojo < 20%
    {threshold = 0.4, r = 1.0, g = 0.5, b = 0.0},  -- Naranja < 40%
    {threshold = 0.6, r = 1.0, g = 1.0, b = 0.0},  -- Amarillo < 60%
    {threshold = 1.0, r = 0.0, g = 1.0, b = 0.0},  -- Verde >= 60%
}

-- Iconos de raid markers
local RaidIcons = {
    [1] = "|TInterface\\TargetingFrame\\UI-RaidTargetingIcon_1:0|t", -- Star
    [2] = "|TInterface\\TargetingFrame\\UI-RaidTargetingIcon_2:0|t", -- Circle
    [3] = "|TInterface\\TargetingFrame\\UI-RaidTargetingIcon_3:0|t", -- Diamond
    [4] = "|TInterface\\TargetingFrame\\UI-RaidTargetingIcon_4:0|t", -- Triangle
    [5] = "|TInterface\\TargetingFrame\\UI-RaidTargetingIcon_5:0|t", -- Moon
    [6] = "|TInterface\\TargetingFrame\\UI-RaidTargetingIcon_6:0|t", -- Square
    [7] = "|TInterface\\TargetingFrame\\UI-RaidTargetingIcon_7:0|t", -- Cross
    [8] = "|TInterface\\TargetingFrame\\UI-RaidTargetingIcon_8:0|t", -- Skull
}

-- Helper para obtener configuración
function FF:GetOption(key)
    if S.ModuleConfig then
        return S.ModuleConfig:GetValue("FocusFire", key)
    end
    return true
end

function FF:Initialize()
    if not self:GetOption("enabled") then
        return
    end
    
    self:CreateFrames()
    self:RegisterEvents()
    self:RegisterComm()
end

function FF:CreateFrames()
    -- Frame principal para tracking
    self.Frame = CreateFrame("Frame", "JainaFocusFireFrame", UIParent)
    self.Frame:SetSize(200, 60)
    self.Frame:SetPoint("TOP", UIParent, "TOP", 0, -150)
    self.Frame:SetMovable(true)
    self.Frame:EnableMouse(true)
    self.Frame:RegisterForDrag("LeftButton")
    self.Frame:SetScript("OnDragStart", function(f) f:StartMoving() end)
    self.Frame:SetScript("OnDragStop", function(f) f:StopMovingOrSizing() end)
    self.Frame:Hide()
    
    -- Fondo (WHITE8X8 conforme a Ley II de 3.3.5a)
    self.Frame.bg = self.Frame:CreateTexture(nil, "BACKGROUND")
    self.Frame.bg:SetAllPoints()
    self.Frame.bg:SetTexture("Interface\\Buttons\\WHITE8X8")
    self.Frame.bg:SetVertexColor(0, 0, 0, 0.8)
    
    -- Borde
    self.Frame.border = CreateFrame("Frame", nil, self.Frame)
    self.Frame.border:SetAllPoints()
    self.Frame.border:SetBackdrop({
        edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
        edgeSize = 12,
    })
    self.Frame.border:SetBackdropBorderColor(1, 0.8, 0, 1)
    
    -- Icono del target
    self.Frame.icon = self.Frame:CreateTexture(nil, "ARTWORK")
    self.Frame.icon:SetSize(40, 40)
    self.Frame.icon:SetPoint("LEFT", self.Frame, "LEFT", 10, 0)
    self.Frame.icon:SetTexture("Interface\\Icons\\Ability_Hunter_SniperShot")
    
    -- Nombre del target
    self.Frame.name = self.Frame:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
    self.Frame.name:SetPoint("TOPLEFT", self.Frame.icon, "TOPRIGHT", 10, -2)
    self.Frame.name:SetText("Target")
    self.Frame.name:SetTextColor(1, 0.8, 0)
    
    -- Barra de vida
    self.Frame.healthBar = CreateFrame("StatusBar", nil, self.Frame)
    self.Frame.healthBar:SetSize(130, 16)
    self.Frame.healthBar:SetPoint("BOTTOMLEFT", self.Frame.icon, "BOTTOMRIGHT", 10, 2)
    self.Frame.healthBar:SetStatusBarTexture("Interface\\TargetingFrame\\UI-StatusBar")
    self.Frame.healthBar:SetStatusBarColor(0, 1, 0)
    self.Frame.healthBar:SetMinMaxValues(0, 100)
    self.Frame.healthBar:SetValue(100)
    
    -- Fondo de barra de vida
    self.Frame.healthBar.bg = self.Frame.healthBar:CreateTexture(nil, "BACKGROUND")
    self.Frame.healthBar.bg:SetAllPoints()
    self.Frame.healthBar.bg:SetTexture("Interface\\Buttons\\WHITE8X8")
    self.Frame.healthBar.bg:SetVertexColor(0.2, 0.2, 0.2, 0.8)
    
    -- Texto de vida
    self.Frame.healthText = self.Frame.healthBar:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    self.Frame.healthText:SetPoint("CENTER", self.Frame.healthBar, "CENTER", 0, 0)
    self.Frame.healthText:SetText("100%")
    
    -- Frame de alerta grande
    self:CreateAlertFrame()
    
    -- OnUpdate para tracking de vida
    self.Frame:SetScript("OnUpdate", function(frame, elapsed)
        self:OnUpdate(elapsed)
    end)
end

function FF:CreateAlertFrame()
    self.AlertFrame = CreateFrame("Frame", "JainaFocusFireAlert", UIParent)
    self.AlertFrame:SetSize(400, 80)
    self.AlertFrame:SetPoint("CENTER", UIParent, "CENTER", 0, 200)
    self.AlertFrame:SetFrameStrata("HIGH")
    self.AlertFrame:Hide()
    
    -- Fondo con gradiente
    self.AlertFrame.bg = self.AlertFrame:CreateTexture(nil, "BACKGROUND")
    self.AlertFrame.bg:SetAllPoints()
    self.AlertFrame.bg:SetTexture("Interface\\Buttons\\WHITE8X8")
    self.AlertFrame.bg:SetVertexColor(0.1, 0, 0, 0.9)
    
    -- Borde brillante
    self.AlertFrame.border = CreateFrame("Frame", nil, self.AlertFrame)
    self.AlertFrame.border:SetAllPoints()
    self.AlertFrame.border:SetBackdrop({
        edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
        edgeSize = 16,
    })
    self.AlertFrame.border:SetBackdropBorderColor(1, 0, 0, 1)
    
    -- Texto principal
    self.AlertFrame.text = self.AlertFrame:CreateFontString(nil, "OVERLAY")
    self.AlertFrame.text:SetFont("Fonts\\FRIZQT__.TTF", 24, "OUTLINE")
    self.AlertFrame.text:SetPoint("CENTER", self.AlertFrame, "CENTER", 0, 10)
    self.AlertFrame.text:SetTextColor(1, 0.2, 0.2)
    self.AlertFrame.text:SetText("¡FOCUS FIRE!")
    
    -- Subtexto con nombre
    self.AlertFrame.subtext = self.AlertFrame:CreateFontString(nil, "OVERLAY")
    self.AlertFrame.subtext:SetFont("Fonts\\FRIZQT__.TTF", 16, "OUTLINE")
    self.AlertFrame.subtext:SetPoint("CENTER", self.AlertFrame, "CENTER", 0, -15)
    self.AlertFrame.subtext:SetTextColor(1, 1, 0)
    self.AlertFrame.subtext:SetText("Target Name")
    
    -- Animación de fade
    self.AlertFrame.fadeTime = 0
    self.AlertFrame:SetScript("OnUpdate", function(frame, elapsed)
        if frame.fadeTime > 0 then
            frame.fadeTime = frame.fadeTime - elapsed
            if frame.fadeTime <= 0.5 then
                local alpha = frame.fadeTime / 0.5
                frame:SetAlpha(alpha)
            end
            if frame.fadeTime <= 0 then
                frame:Hide()
                frame:SetAlpha(1)
            end
        end
    end)
end

function FF:RegisterEvents()
    local eventFrame = CreateFrame("Frame")
    eventFrame:RegisterEvent("RAID_TARGET_UPDATE")
    eventFrame:RegisterEvent("PLAYER_TARGET_CHANGED")
    eventFrame:RegisterEvent("UNIT_HEALTH")
    eventFrame:RegisterEvent("COMBAT_LOG_EVENT_UNFILTERED")
    eventFrame:RegisterEvent("RAID_ROSTER_UPDATE")
    eventFrame:RegisterEvent("PARTY_MEMBERS_CHANGED")
    
    eventFrame:SetScript("OnEvent", function(self, event, ...)
        if event == "RAID_TARGET_UPDATE" then
            FF:OnRaidTargetUpdate()
        elseif event == "PLAYER_TARGET_CHANGED" then
            FF:OnPlayerTargetChanged()
        elseif event == "UNIT_HEALTH" then
            local unit = ...
            FF:OnUnitHealth(unit)
        elseif event == "COMBAT_LOG_EVENT_UNFILTERED" then
            FF:OnCombatLog(...)
        end
    end)
end

function FF:RegisterComm()
    -- Registrar prefijo para comunicación
    if S.RegisterComm then
        S:RegisterComm("SEQFF", function(prefix, message, channel, sender)
            FF:OnCommReceived(prefix, message, channel, sender)
        end)
    end
end

function FF:OnUpdate(elapsed)
    self.TimeSinceLastUpdate = self.TimeSinceLastUpdate + elapsed
    if self.TimeSinceLastUpdate < self.UpdateInterval then return end
    self.TimeSinceLastUpdate = 0
    
    if self.CurrentTargetGUID then
        self:UpdateTargetHealth()
    end
end

function FF:OnRaidTargetUpdate()
    -- Verificar si el líder marcó un nuevo target
    if not UnitExists("target") then return end
    
    local raidIcon = GetRaidTargetIndex("target")
    if raidIcon and raidIcon == 8 then -- Skull = focus fire
        local name = UnitName("target")
        local guid = UnitGUID("target")
        
        if guid ~= self.CurrentTargetGUID then
            self:SetFocusTarget(name, guid, raidIcon)
        end
    end
end

function FF:OnPlayerTargetChanged()
    -- Actualizar icono si el target actual es el focus
    if self.CurrentTargetGUID and UnitExists("target") then
        local guid = UnitGUID("target")
        if guid == self.CurrentTargetGUID then
            self:UpdateTargetHealth()
        end
    end
end

function FF:OnUnitHealth(unit)
    if not self.CurrentTargetGUID then return end
    
    if UnitExists(unit) and UnitGUID(unit) == self.CurrentTargetGUID then
        self:UpdateTargetHealth()
    end
end

function FF:OnCombatLog(...)
    local timestamp, event, sourceGUID, sourceName, sourceFlags, destGUID, destName, destFlags = ...
    
    -- Detectar muerte del target
    if event == "UNIT_DIED" and destGUID == self.CurrentTargetGUID then
        self:ClearFocusTarget()
        if S.Print then
            S:Print("|cFF00FF00¡Focus target eliminado!|r")
        end
    end
end

function FF:SetFocusTarget(name, guid, raidIcon)
    self.CurrentTarget = name
    self.CurrentTargetGUID = guid
    
    -- Actualizar UI
    self.Frame.name:SetText((RaidIcons[raidIcon] or "") .. " " .. name)
    self:UpdateTargetHealth()
    
    if self:GetOption("showFrame") then
        self.Frame:Show()
        self.IsVisible = true
    end
    
    -- Mostrar alerta
    self:ShowAlert(name, raidIcon)
    
    -- Reproducir sonido (configurable)
    if self:GetOption("sound") then
        PlaySoundFile(self.Config.soundFile)
    end
    
    -- Sincronizar con el grupo (configurable)
    if self:GetOption("announce") then
        self:BroadcastFocusTarget(name, guid)
    end
end

function FF:ClearFocusTarget()
    self.CurrentTarget = nil
    self.CurrentTargetGUID = nil
    self.CurrentTargetHP = 0
    self.Frame:Hide()
    self.IsVisible = false
end

function FF:UpdateTargetHealth()
    if not self.CurrentTargetGUID then return end
    
    -- Verificar si showHealthBar está habilitado
    if not self:GetOption("showHealthBar") then
        if self.Frame.healthBar then
            self.Frame.healthBar:Hide()
            self.Frame.healthText:Hide()
        end
        return
    end
    
    -- Buscar el unit ID del target
    local unitID = self:FindUnitByGUID(self.CurrentTargetGUID)
    if not unitID then return end
    
    local health = UnitHealth(unitID)
    local maxHealth = UnitHealthMax(unitID)
    local percent = maxHealth > 0 and (health / maxHealth * 100) or 0
    
    self.CurrentTargetHP = percent
    
    -- Actualizar barra
    if self.Frame.healthBar then
        self.Frame.healthBar:Show()
        self.Frame.healthText:Show()
        self.Frame.healthBar:SetValue(percent)
        self.Frame.healthText:SetText(string.format("%.1f%%", percent))
        
        -- Color según vida
        local r, g, b = self:GetHealthColor(percent / 100)
        self.Frame.healthBar:SetStatusBarColor(r, g, b)
    end
end

function FF:FindUnitByGUID(guid)
    -- Buscar en target
    if UnitExists("target") and UnitGUID("target") == guid then
        return "target"
    end
    
    -- Buscar en focus
    if UnitExists("focus") and UnitGUID("focus") == guid then
        return "focus"
    end
    
    -- Buscar en nameplates
    for i = 1, 40 do
        local unit = "nameplate" .. i
        if UnitExists(unit) and UnitGUID(unit) == guid then
            return unit
        end
    end
    
    -- Buscar en boss frames
    for i = 1, 5 do
        local unit = "boss" .. i
        if UnitExists(unit) and UnitGUID(unit) == guid then
            return unit
        end
    end
    
    return nil
end

function FF:GetHealthColor(percent)
    for _, color in ipairs(HealthColors) do
        if percent <= color.threshold then
            return color.r, color.g, color.b
        end
    end
    return 0, 1, 0
end

function FF:ShowAlert(name, raidIcon)
    local iconStr = RaidIcons[raidIcon] or ""
    self.AlertFrame.subtext:SetText(iconStr .. " " .. name .. " " .. iconStr)
    self.AlertFrame.fadeTime = self.Config.alertDuration
    self.AlertFrame:SetAlpha(1)
    self.AlertFrame:Show()
end

-- Helper para resolución contextual de canales en 3.3.5a (PvE + PvP Battlegrounds)
local function GetFocusFireChannel(preferWarning)
    if IsInInstance then
        local inInstance, instanceType = IsInInstance()
        if inInstance and instanceType == "pvp" then
            return "BATTLEGROUND"
        end
    end

    if GetNumRaidMembers and GetNumRaidMembers() > 0 then
        if preferWarning and (IsRaidLeader() or IsRaidOfficer()) then
            return "RAID_WARNING"
        end
        return "RAID"
    elseif GetNumPartyMembers and GetNumPartyMembers() > 0 then
        return "PARTY"
    end

    return "SAY"
end

function FF:BroadcastFocusTarget(name, guid)
    local channel = GetFocusFireChannel(false)
    if channel and channel ~= "SAY" and S.SendAddonMessage then
        local message = string.format("FOCUS:%s:%s", name, guid or "")
        S:SendAddonMessage("SEQFF", message, channel)
    end
end

function FF:OnCommReceived(prefix, message, channel, sender)
    if sender == UnitName("player") then return end
    
    local cmd, name, guid = strsplit(":", message)
    
    if cmd == "FOCUS" and name then
        -- Recibimos orden de focus
        self.CurrentTarget = name
        self.CurrentTargetGUID = guid ~= "" and guid or nil
        
        -- Actualizar UI
        self.Frame.name:SetText("|TInterface\\TargetingFrame\\UI-RaidTargetingIcon_8:0|t " .. name)
        self.Frame:Show()
        self.IsVisible = true
        
        -- Mostrar alerta (si está habilitado)
        if self:GetOption("showAlert") then
            self:ShowAlert(name, 8)
        end
        
        -- Reproducir sonido (si está habilitado)
        if self:GetOption("playSound") then
            PlaySoundFile("Sound\\Interface\\RaidWarning.wav")
        end
        
        if S.Print then
            S:Print(string.format("|cFFFF0000¡FOCUS FIRE!|r %s llamó focus en: |cFFFFFF00%s|r", sender, name))
        end
    elseif cmd == "CLEAR" then
        self:ClearFocusTarget()
    end
end

-- Comando para llamar focus en el target actual
function FF:CallFocus()
    if not UnitExists("target") then
        if S.Print then
            S:Print("No tienes un objetivo seleccionado.")
        end
        return
    end
    
    local name = UnitName("target")
    local guid = UnitGUID("target")
    
    -- Marcar con Skull si tenemos permisos reales en 3.3.5a
    if GetNumRaidMembers and GetNumRaidMembers() > 0 then
        if IsRaidLeader() or IsRaidOfficer() then
            SetRaidTarget("target", 8) -- Skull
        end
    elseif GetNumPartyMembers and GetNumPartyMembers() > 0 then
        SetRaidTarget("target", 8)
    end
    
    -- Establecer como focus target
    self:SetFocusTarget(name, guid, 8)
    
    -- Anunciar al canal correspondiente (BG, RAID_WARNING, RAID, PARTY o SAY)
    local channel = GetFocusFireChannel(self:GetOption("announceChannel") == "RAID_WARNING")
    if channel then
        SendChatMessage(">>> FOCUS FIRE: " .. name .. " <<<", channel)
    end
end

-- Comando para limpiar focus
function FF:ClearFocus()
    self:ClearFocusTarget()
    
    -- Notificar al grupo
    local channel = GetFocusFireChannel(false)
    if channel and channel ~= "SAY" and S.SendAddonMessage then
        S:SendAddonMessage("SEQFF", "CLEAR", channel)
    end
end

-- Toggle del panel
function FF:Toggle()
    if not self.Frame then return end
    if self.Frame:IsShown() then
        self.Frame:Hide()
    else
        self.Frame:Show()
    end
end

-- Wrapper method for Bindings.xml keybinds
function FF:CallTarget()
    self:CallFocus()
end

-- Anunciar vida actual del focus
function FF:AnnounceHealth()
    if not self.CurrentTarget then
        if S.Print then
            S:Print("No hay focus target activo.")
        end
        return
    end
    
    local channel = GetFocusFireChannel(false)
    if channel then
        SendChatMessage(string.format("[Jaina] Focus Target: %s - %.1f%% HP", 
            self.CurrentTarget, self.CurrentTargetHP), channel)
    end
end

-- API pública
function FF:GetCurrentTarget()
    return self.CurrentTarget, self.CurrentTargetGUID, self.CurrentTargetHP
end

function FF:IsActive()
    return self.CurrentTargetGUID ~= nil
end

-- Registrar configuración en ModuleConfig
if S.ModuleConfig then
    S.ModuleConfig:RegisterModule("FocusFire", {
        name = "Focus Fire",
        icon = "Interface\\Icons\\Ability_Hunter_SniperShot",
        description = "Sistema de llamadas de target con alertas visuales y sonoras",
        category = "raid",
        options = {
            {
                type = "checkbox",
                key = "enabled",
                label = "Habilitar Focus Fire",
                tooltip = "Activa/desactiva el sistema de llamadas de target",
                default = true,
            },
            {
                type = "checkbox",
                key = "showAlert",
                label = "Mostrar Alertas",
                tooltip = "Muestra alertas visuales cuando se marca un nuevo target",
                default = true,
            },
            {
                type = "checkbox",
                key = "playSound",
                label = "Reproducir Sonido",
                tooltip = "Reproduce sonido de alerta al marcar target",
                default = true,
            },
            {
                type = "checkbox",
                key = "showHealthBar",
                label = "Mostrar Barra de Vida",
                tooltip = "Muestra la barra de vida del target marcado",
                default = true,
            },
            {
                type = "dropdown",
                key = "announceChannel",
                label = "Canal de Anuncio",
                tooltip = "Canal donde se anuncian los targets",
                default = "RAID_WARNING",
                values = {
                    {value = "RAID_WARNING", label = "Aviso de Raid"},
                    {value = "RAID", label = "Raid"},
                    {value = "PARTY", label = "Grupo"},
                    {value = "SAY", label = "Decir"},
                    {value = "YELL", label = "Gritar"},
                },
            },
            {
                type = "slider",
                key = "alertDuration",
                label = "Duración de Alerta (seg)",
                tooltip = "Tiempo que permanece visible la alerta",
                min = 1,
                max = 10,
                step = 0.5,
                default = 3,
            },
        },
    })
end

-- Inicializar cuando el addon cargue
if S.RegisterModule then
    S:RegisterModule("FocusFire", FF)
else
    -- Fallback: inicializar en PLAYER_LOGIN
    local initFrame = CreateFrame("Frame")
    initFrame:RegisterEvent("PLAYER_LOGIN")
    initFrame:SetScript("OnEvent", function()
        FF:Initialize()
    end)
end
