--[[
    Sequito - TrinketTracker.lua
    Tracker de Trinkets PvP Enemigos
    Version: 7.2.0
    
    Funcionalidades:
    - Detecta cuando un enemigo usa su trinket PvP
    - Muestra timer de 2 minutos hasta que vuelva a estar disponible
    - Panel flotante con iconos y timers
    - Integración con nameplates (opcional)
]]

local addonName, S = ...
S.TrinketTracker = {}
local TT = S.TrinketTracker

-- Trinkets PvP (spellIds de los efectos de trinket)
local TrinketSpells = {
    -- PvP Trinket effect (Will of the Forsaken style break)
    [42292] = true,  -- PvP Trinket
    [59752] = true,  -- Every Man for Himself (Human racial)
    [7744] = true,   -- Will of the Forsaken (Undead racial)
    -- Medallones específicos por facción
    [46642] = true,  -- PvP Trinket (Horde)
    [46641] = true,  -- PvP Trinket (Alliance)
}

-- Duración del CD del trinket PvP
local TRINKET_CD = 120 -- 2 minutos

-- Estado de trinkets enemigos
TT.EnemyTrinkets = {}
TT.Frame = nil
TT.Rows = {}
TT.IsVisible = false
TT.NameplateIcons = {}

-- Colores
local Colors = {
    available = {0.2, 0.8, 0.2},   -- Verde
    onCooldown = {0.8, 0.2, 0.2},  -- Rojo
    almostReady = {1.0, 0.8, 0.0}, -- Amarillo (últimos 15 segundos)
}

-- Helper para obtener configuración
function TT:GetOption(key)
    if S.ModuleConfig then
        return S.ModuleConfig:GetValue("TrinketTracker", key)
    end
    return true -- Default habilitado
end

-- Helper canónico de canal PvP en 3.3.5a
function TT:GetChannel()
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

function TT:Initialize()
    -- Verificar si el módulo está habilitado
    if not self:GetOption("enabled") then
        return
    end
    
    self:CreateFrame()
    self:RegisterEvents()
    self:CreateNameplateHook()
end

function TT:CreateFrame()
    if self.Frame then return end
    
    local f = CreateFrame("Frame", "SequitoTrinketTracker", UIParent)
    f:SetSize(220, 200)
    f:SetPoint("TOPRIGHT", UIParent, "TOPRIGHT", -20, -200)
    f:SetBackdrop({
        bgFile = "Interface\\Tooltips\\UI-Tooltip-Background",
        edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
        tile = true, tileSize = 16, edgeSize = 16,
        insets = {left = 4, right = 4, top = 4, bottom = 4}
    })
    f:SetBackdropColor(0, 0, 0, 0.85)
    f:SetBackdropBorderColor(0.8, 0.2, 0.2, 1)
    f:EnableMouse(true)
    f:SetMovable(true)
    f:RegisterForDrag("LeftButton")
    f:SetScript("OnDragStart", f.StartMoving)
    f:SetScript("OnDragStop", f.StopMovingOrSizing)
    f:SetClampedToScreen(true)
    f:Hide()
    
    -- Título
    local title = f:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
    title:SetPoint("TOP", f, "TOP", 0, -8)
    title:SetText("|cffff0000Sequito|r - Trinkets Enemigos")
    f.title = title
    
    -- Botón cerrar
    local closeBtn = CreateFrame("Button", nil, f, "UIPanelCloseButton")
    closeBtn:SetPoint("TOPRIGHT", f, "TOPRIGHT", -2, -2)
    closeBtn:SetScript("OnClick", function() TT:Toggle() end)
    
    -- Botón limpiar
    local clearBtn = CreateFrame("Button", nil, f, "UIPanelButtonTemplate")
    clearBtn:SetSize(60, 18)
    clearBtn:SetPoint("TOPLEFT", f, "TOPLEFT", 8, -8)
    clearBtn:SetText("Limpiar")
    clearBtn:GetFontString():SetFont("Fonts\\FRIZQT__.TTF", 9)
    clearBtn:SetScript("OnClick", function() TT:ClearAll() end)
    
    -- Contenedor de scroll
    local scrollFrame = CreateFrame("ScrollFrame", "SequitoTTScroll", f, "UIPanelScrollFrameTemplate")
    scrollFrame:SetPoint("TOPLEFT", f, "TOPLEFT", 8, -32)
    scrollFrame:SetPoint("BOTTOMRIGHT", f, "BOTTOMRIGHT", -28, 8)
    
    local content = CreateFrame("Frame", nil, scrollFrame)
    content:SetSize(180, 400)
    scrollFrame:SetScrollChild(content)
    f.content = content
    
    self.Frame = f
end

function TT:CreateTrinketRow(parent, index)
    local row = CreateFrame("Frame", nil, parent)
    row:SetSize(180, 28)
    row:SetPoint("TOPLEFT", parent, "TOPLEFT", 0, -((index - 1) * 30))
    
    -- Fondo de la fila
    row.bg = row:CreateTexture(nil, "BACKGROUND")
    row.bg:SetAllPoints()
    row.bg:SetTexture("Interface\\Buttons\\WHITE8X8")
    row.bg:SetVertexColor(0, 0, 0, 0.3)
    
    -- Icono del trinket
    local icon = row:CreateTexture(nil, "ARTWORK")
    icon:SetSize(24, 24)
    icon:SetPoint("LEFT", row, "LEFT", 2, 0)
    icon:SetTexture("Interface\\Icons\\INV_Jewelry_TrinketPVP_02") -- Icono genérico de trinket PvP
    row.icon = icon
    
    -- Icono de clase
    local classIcon = row:CreateTexture(nil, "OVERLAY")
    classIcon:SetSize(14, 14)
    classIcon:SetPoint("BOTTOMRIGHT", icon, "BOTTOMRIGHT", 2, -2)
    row.classIcon = classIcon
    
    -- Nombre del enemigo
    local enemyName = row:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    enemyName:SetPoint("LEFT", icon, "RIGHT", 4, 0)
    enemyName:SetWidth(90)
    enemyName:SetJustifyH("LEFT")
    row.enemyName = enemyName
    
    -- Timer/Estado
    local status = row:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    status:SetPoint("RIGHT", row, "RIGHT", -4, 0)
    status:SetWidth(50)
    status:SetJustifyH("RIGHT")
    row.status = status
    
    -- Barra de progreso
    local bar = CreateFrame("StatusBar", nil, row)
    bar:SetSize(176, 3)
    bar:SetPoint("BOTTOM", row, "BOTTOM", 0, 0)
    bar:SetStatusBarTexture("Interface\\TargetingFrame\\UI-StatusBar")
    bar:SetMinMaxValues(0, TRINKET_CD)
    bar:SetValue(0)
    row.bar = bar
    
    row:Hide()
    return row
end

function TT:RegisterEvents()
    local eventFrame = CreateFrame("Frame")
    eventFrame:RegisterEvent("COMBAT_LOG_EVENT_UNFILTERED")
    eventFrame:RegisterEvent("PLAYER_ENTERING_WORLD")
    eventFrame:RegisterEvent("ZONE_CHANGED_NEW_AREA")
    
    eventFrame:SetScript("OnEvent", function(self, event, ...)
        if event == "COMBAT_LOG_EVENT_UNFILTERED" then
            TT:OnCombatLog(...)
        elseif event == "PLAYER_ENTERING_WORLD" or event == "ZONE_CHANGED_NEW_AREA" then
            -- Limpiar al cambiar de zona (nueva arena/BG)
            local _, instanceType = IsInInstance()
            if instanceType == "pvp" or instanceType == "arena" then
                TT:ClearAll()
                -- Mostrar automáticamente si la opción está habilitada
                if TT:GetOption("autoShow") then
                    TT:Show()
                end
            end
        end
    end)
    
    -- Timer de actualización
    local updateFrame = CreateFrame("Frame")
    local elapsed = 0
    updateFrame:SetScript("OnUpdate", function(self, delta)
        elapsed = elapsed + delta
        if elapsed >= 0.1 then
            elapsed = 0
            TT:UpdateTimers()
            if TT.IsVisible then
                TT:UpdateDisplay()
            end
            TT:UpdateNameplates()
        end
    end)
end

function TT:OnCombatLog(...)
    local timestamp, event, sourceGUID, sourceName, sourceFlags, destGUID, destName, destFlags, spellId, spellName = ...
    
    -- Solo nos interesan los casts exitosos
    if event ~= "SPELL_CAST_SUCCESS" then return end
    
    -- Verificar si es un trinket PvP
    if not TrinketSpells[spellId] then return end
    
    -- Verificar que es un enemigo
    if not sourceName then return end
    if not CombatLog_Object_IsA(sourceFlags, COMBATLOG_FILTER_HOSTILE_PLAYERS) then return end
    
    -- Registrar el uso del trinket
    self:RegisterTrinketUse(sourceName, sourceGUID, spellId)
end

function TT:RegisterTrinketUse(playerName, playerGUID, spellId)
    local now = GetTime()
    
    -- Obtener clase del enemigo si es posible
    local class = nil
    local classColor = {r = 1, g = 1, b = 1}
    
    -- Intentar obtener la clase del GUID
    local _, classFile = GetPlayerInfoByGUID(playerGUID)
    if classFile then
        class = classFile
        classColor = RAID_CLASS_COLORS[classFile] or classColor
    end
    
    self.EnemyTrinkets[playerName] = {
        name = playerName,
        guid = playerGUID,
        class = class,
        classColor = classColor,
        spellId = spellId,
        usedAt = now,
        expires = now + TRINKET_CD,
        onCooldown = true
    }
    
    -- Alerta visual y sonora
    self:AlertTrinketUsed(playerName, class)
    
    -- Mostrar el panel si no está visible y autoShow está habilitado
    if not self.IsVisible and self:GetOption("autoShow") then
        self:Show()
    end
    
    self:UpdateDisplay()
end

function TT:AlertTrinketUsed(playerName, class)
    -- Sonido (configurable)
    if self:GetOption("sound") then
        PlaySound("RaidWarning")
    end
    
    -- Mensaje en pantalla
    local classColor = class and RAID_CLASS_COLORS[class] or {r = 1, g = 1, b = 1}
    local colorCode = string.format("|cff%02x%02x%02x", classColor.r * 255, classColor.g * 255, classColor.b * 255)
    
    -- Usar RaidWarning si está disponible
    if RaidWarningFrame then
        RaidNotice_AddMessage(RaidWarningFrame, 
            colorCode .. playerName .. "|r usó TRINKET!", 
            {r = 1, g = 0.5, b = 0})
    end
    
    -- También en chat local
    print(string.format("|cffff0000[Sequito]|r %s%s|r usó su trinket PvP! (CD: 2 min)", colorCode, playerName))
    
    -- Anunciar en party/raid/battleground (configurable)
    if self:GetOption("announce") then
        local channel = self:GetChannel()
        if channel then
            SendChatMessage(string.format("[Sequito] %s usó TRINKET!", playerName), channel)
        end
    end
end

function TT:UpdateTimers()
    local now = GetTime()
    
    for name, data in pairs(self.EnemyTrinkets) do
        if data.onCooldown then
            if now >= data.expires then
                data.onCooldown = false
                -- Alertar que el trinket está listo de nuevo
                self:AlertTrinketReady(name, data.class)
            end
        end
    end
end

function TT:AlertTrinketReady(playerName, class)
    local classColor = class and RAID_CLASS_COLORS[class] or {r = 1, g = 1, b = 1}
    local colorCode = string.format("|cff%02x%02x%02x", classColor.r * 255, classColor.g * 255, classColor.b * 255)
    
    print(string.format("|cff00ff00[Sequito]|r %s%s|r tiene trinket LISTO!", colorCode, playerName))
    
    -- Sonido más suave (configurable)
    if self:GetOption("sound") then
        PlaySound("igQuestLogAbandonQuest")
    end
end

function TT:UpdateDisplay()
    if not self.Frame or not self.Frame.content then return end
    
    -- Ocultar todas las filas
    for _, row in ipairs(self.Rows) do
        row:Hide()
    end
    
    -- Ordenar: en CD primero, luego por tiempo restante
    local sorted = {}
    for name, data in pairs(self.EnemyTrinkets) do
        table.insert(sorted, data)
    end
    
    table.sort(sorted, function(a, b)
        if a.onCooldown and not b.onCooldown then return true end
        if not a.onCooldown and b.onCooldown then return false end
        if a.onCooldown and b.onCooldown then
            return a.expires < b.expires
        end
        return a.name < b.name
    end)
    
    local now = GetTime()
    for i, data in ipairs(sorted) do
        local row = self.Rows[i]
        if not row then
            row = self:CreateTrinketRow(self.Frame.content, i)
            self.Rows[i] = row
        end
        
        -- Nombre con color de clase
        local colorCode = string.format("|cff%02x%02x%02x", 
            data.classColor.r * 255, data.classColor.g * 255, data.classColor.b * 255)
        row.enemyName:SetText(colorCode .. data.name .. "|r")
        
        -- Icono de clase
        if data.class then
            local coords = CLASS_ICON_TCOORDS[data.class]
            if coords then
                row.classIcon:SetTexture("Interface\\Glues\\CharacterCreate\\UI-CharacterCreate-Classes")
                row.classIcon:SetTexCoord(unpack(coords))
                row.classIcon:Show()
            else
                row.classIcon:Hide()
            end
        else
            row.classIcon:Hide()
        end
        
        if data.onCooldown then
            local remaining = data.expires - now
            local color
            
            if remaining <= 15 then
                color = Colors.almostReady
            else
                color = Colors.onCooldown
            end
            
            row.status:SetText(string.format("|cff%02x%02x%02x%s|r", 
                color[1] * 255, color[2] * 255, color[3] * 255,
                self:FormatTime(remaining)))
            row.bar:SetValue(remaining)
            row.bar:SetStatusBarColor(color[1], color[2], color[3])
            row.icon:SetDesaturated(true)
        else
            row.status:SetText("|cff00ff00LISTO|r")
            row.bar:SetValue(0)
            row.bar:SetStatusBarColor(Colors.available[1], Colors.available[2], Colors.available[3])
            row.icon:SetDesaturated(false)
        end
        
        row:Show()
    end
    
    -- Ajustar altura del contenido
    self.Frame.content:SetHeight(math.max(#sorted * 30, 50))
    
    -- Actualizar título con contador
    local onCD = 0
    for _, data in pairs(self.EnemyTrinkets) do
        if data.onCooldown then onCD = onCD + 1 end
    end
    self.Frame.title:SetText(string.format("|cffff0000Sequito|r - Trinkets (%d en CD)", onCD))
end

function TT:FormatTime(seconds)
    if seconds >= 60 then
        return string.format("%d:%02d", math.floor(seconds / 60), math.floor(seconds % 60))
    else
        return string.format("%.1fs", seconds)
    end
end

-- Sistema de Nameplates
function TT:CreateNameplateHook()
    -- Hook para mostrar iconos en nameplates
    local function UpdateNameplate(nameplate)
        if not nameplate then return end
        
        -- Verificar si la opción de nameplates está habilitada
        if not TT:GetOption("nameplates") then
            if TT.NameplateIcons[nameplate] then
                TT.NameplateIcons[nameplate]:Hide()
            end
            return
        end
        
        local name = nameplate.name and nameplate.name:GetText()
        if not name then return end
        
        local data = TT.EnemyTrinkets[name]
        if not data then
            -- Ocultar icono si existe
            if TT.NameplateIcons[nameplate] then
                TT.NameplateIcons[nameplate]:Hide()
            end
            return
        end
        
        -- Obtener tamaño de icono de la configuración
        local iconSize = TT:GetOption("iconSize") or 20
        
        -- Crear o mostrar icono
        local icon = TT.NameplateIcons[nameplate]
        if not icon then
            icon = CreateFrame("Frame", nil, nameplate)
            icon:SetSize(iconSize, iconSize)
            icon:SetPoint("RIGHT", nameplate, "LEFT", -5, 0)
            
            icon.texture = icon:CreateTexture(nil, "OVERLAY")
            icon.texture:SetAllPoints()
            icon.texture:SetTexture("Interface\\Icons\\INV_Jewelry_TrinketPVP_02")
            
            icon.cd = icon:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
            icon.cd:SetPoint("CENTER", icon, "CENTER", 0, 0)
            
            TT.NameplateIcons[nameplate] = icon
        else
            -- Actualizar tamaño si cambió la configuración
            icon:SetSize(iconSize, iconSize)
        end
        
        if data.onCooldown then
            local remaining = data.expires - GetTime()
            icon.texture:SetDesaturated(true)
            icon.cd:SetText(math.floor(remaining))
            icon.cd:Show()
        else
            icon.texture:SetDesaturated(false)
            icon.cd:Hide()
        end
        
        icon:Show()
    end
    
    -- Actualizar nameplates periódicamente
    local updateFrame = CreateFrame("Frame")
    updateFrame:SetScript("OnUpdate", function(self, elapsed)
        self.elapsed = (self.elapsed or 0) + elapsed
        if self.elapsed < 0.2 then return end
        self.elapsed = 0
        
        -- Iterar sobre nameplates visibles (soporte híbrido addon/nativo 3.3.5a)
        local foundCustom = false
        for i = 1, 40 do
            local nameplate = _G["NamePlate" .. i]
            if nameplate and nameplate:IsVisible() then
                foundCustom = true
                UpdateNameplate(nameplate)
            end
        end
        
        -- Fallback para nameplates nativos de WotLK 3.3.5a en WorldFrame
        if not foundCustom and WorldFrame then
            local numChildren = WorldFrame:GetNumChildren()
            for i = 1, numChildren do
                local frame = select(i, WorldFrame:GetChildren())
                if frame and frame:IsShown() and frame:GetName() == nil then
                    local regions = { frame:GetRegions() }
                    for _, region in ipairs(regions) do
                        if region:GetObjectType() == "FontString" then
                            frame.name = region
                            UpdateNameplate(frame)
                            break
                        end
                    end
                end
            end
        end
    end)
end

function TT:UpdateNameplates()
    -- Esta función se llama desde el timer principal
    -- La lógica real está en el hook de nameplates
end

function TT:ClearAll()
    self.EnemyTrinkets = {}
    self:UpdateDisplay()
    print("|cff00ff00[Sequito]|r Trinket tracker limpiado")
end

function TT:Toggle()
    if not self.Frame then
        self:Initialize()
    end
    
    -- Check again after Initialize (module might be disabled)
    if not self.Frame then
        return
    end
    
    self.IsVisible = not self.IsVisible
    if self.IsVisible then
        self.Frame:Show()
        self:UpdateDisplay()
    else
        self.Frame:Hide()
    end
end

function TT:Show()
    if not self.Frame then
        self:Initialize()
    end
    self.IsVisible = true
    self.Frame:Show()
    self:UpdateDisplay()
end

function TT:Hide()
    if self.Frame then
        self.IsVisible = false
        self.Frame:Hide()
    end
end

-- Función para obtener estado de trinket de un enemigo específico
function TT:GetTrinketStatus(playerName)
    local data = self.EnemyTrinkets[playerName]
    if not data then
        return nil -- No tenemos información
    end
    
    if data.onCooldown then
        return "cd", data.expires - GetTime()
    else
        return "ready", 0
    end
end

-- Función para anunciar todos los trinkets en CD
function TT:AnnounceAll()
    local onCD = {}
    local ready = {}
    local now = GetTime()
    
    for name, data in pairs(self.EnemyTrinkets) do
        if data.onCooldown then
            local remaining = data.expires - now
            table.insert(onCD, string.format("%s (%s)", name, self:FormatTime(remaining)))
        else
            table.insert(ready, name)
        end
    end
    
    local channel = self:GetChannel()
    
    if channel then
        if #onCD > 0 then
            SendChatMessage("[Sequito] Trinkets en CD: " .. table.concat(onCD, ", "), channel)
        end
        if #ready > 0 then
            SendChatMessage("[Sequito] Trinkets LISTOS: " .. table.concat(ready, ", "), channel)
        end
    else
        if #onCD > 0 then
            print("|cffff0000[Sequito]|r Trinkets en CD: " .. table.concat(onCD, ", "))
        end
        if #ready > 0 then
            print("|cff00ff00[Sequito]|r Trinkets LISTOS: " .. table.concat(ready, ", "))
        end
    end
end

-- Registrar configuración en ModuleConfig
local function RegisterConfig()
    if not S.ModuleConfig then return end
    
    S.ModuleConfig:RegisterModule("TrinketTracker", {
        name = "Trinket Tracker",
        description = "Rastrea el uso de trinkets PvP enemigos y muestra timers de cooldown.",
        icon = "Interface\\Icons\\INV_Jewelry_TrinketPVP_02",
        category = "pvp",
        options = {
            {type = "checkbox", key = "enabled", label = "Habilitado", default = true,
                tooltip = "Activa o desactiva el tracker de trinkets"},
            {type = "checkbox", key = "sound", label = "Sonido de alerta", default = true,
                tooltip = "Reproduce sonido cuando un enemigo usa trinket"},
            {type = "checkbox", key = "announce", label = "Anunciar en chat", default = true,
                tooltip = "Anuncia en party/raid cuando un enemigo usa trinket"},
            {type = "checkbox", key = "nameplates", label = "Iconos en nameplates", default = true,
                tooltip = "Muestra iconos de trinket en los nameplates enemigos"},
            {type = "checkbox", key = "autoShow", label = "Mostrar automáticamente", default = true,
                tooltip = "Muestra el panel automáticamente al entrar en arena/BG"},
            {type = "slider", key = "iconSize", label = "Tamaño de iconos", 
                min = 16, max = 32, step = 2, default = 20,
                tooltip = "Tamaño de los iconos en nameplates"},
        },
        onSave = function(db)
            local enabled = S.ModuleConfig:GetValue("TrinketTracker", "enabled")
            if enabled and TT.Frame then
                TT.Frame:Show()
            elseif TT.Frame then
                TT.Frame:Hide()
            end
        end,
    })
end

-- Auto-inicializar
local initFrame = CreateFrame("Frame")
initFrame:RegisterEvent("PLAYER_LOGIN")
initFrame:SetScript("OnEvent", function()
    local timer = CreateFrame("Frame")
    local elapsed = 0
    timer:SetScript("OnUpdate", function(self, delta)
        elapsed = elapsed + delta
        if elapsed >= 3 then
            self:SetScript("OnUpdate", nil)
            RegisterConfig()
            TT:Initialize()
        end
    end)
end)
