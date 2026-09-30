--[[
    Sequito - TrinketTracker.lua
    Tracker de Trinkets PvP Enemigos de alto rendimiento para WotLK 3.3.5a
    Version: 8.0.0
]]

local addonName, S = ...
S.TrinketTracker = S.TrinketTracker or {}
local TT = S.TrinketTracker

-- Catálogo de hechizos de Trinkets y Raciales anti-CC en WotLK 3.3.5a
local TrinketSpells = {
    [42292] = { name = "PvP Trinket", cd = 120 },
    [59752] = { name = "Every Man for Himself", cd = 120 },
    [7744]  = { name = "Will of the Forsaken", cd = 120 },
    [46642] = { name = "Medallion of the Horde", cd = 120 },
    [46641] = { name = "Medallion of the Alliance", cd = 120 },
    [20594] = { name = "Stoneform", cd = 120 },
    [58984] = { name = "Shadowmeld", cd = 120 },
}

local TRINKET_CD = 120

-- Estado de trinkets enemigos
TT.EnemyTrinkets = {}
TT.Frame = nil
TT.Rows = {}
TT.IsVisible = false
TT.NameplateIcons = {}

local Colors = {
    available   = {0.2, 0.8, 0.2},  -- Verde
    onCooldown  = {0.8, 0.2, 0.2},  -- Rojo
    almostReady = {1.0, 0.8, 0.0},  -- Amarillo (< 15s)
}

local DEFAULT_OPTIONS = {
    enabled = true,
    sound = true,
    announce = true,
    nameplates = true,
    autoShow = true,
    iconSize = 20,
}

-- Helper para obtener configuración con fallback defensivo
function TT:GetOption(key)
    if S.ModuleConfig and S.ModuleConfig.GetValue then
        local val = S.ModuleConfig:GetValue("TrinketTracker", key)
        if val ~= nil then return val end
    end
    if DEFAULT_OPTIONS[key] ~= nil then
        return DEFAULT_OPTIONS[key]
    end
    return true
end

-- Helper canónico de canal PvP en 3.3.5a
function TT:GetChannel()
    local _, instanceType = IsInInstance()
    if instanceType == "pvp" then
        return "BATTLEGROUND"
    elseif instanceType == "arena" then
        return "PARTY"
    elseif GetNumRaidMembers() > 0 then
        return "RAID"
    elseif GetNumPartyMembers() > 0 then
        return "PARTY"
    end
    return nil
end

function TT:Initialize()
    if self.initialized then return end
    if not self:GetOption("enabled") then
        return
    end
    self.initialized = true

    self.frame = self:CreateFrame()
    self.Frame = self.frame
    self:RegisterEvents()
    self:CreateNameplateHook()
end

function TT:CreateFrame()
    if self.Frame then return self.Frame end

    local f = CreateFrame("Frame", "SequitoTrinketTracker", UIParent)
    self.Frame = f
    self.frame = f
    f:SetSize(230, 210)
    f:SetPoint("TOPRIGHT", UIParent, "TOPRIGHT", -20, -200)

    if S.Theme and S.Theme.ApplyPanelBackdrop then
        S.Theme:ApplyPanelBackdrop(f)
    else
        f:SetBackdrop({
            bgFile = "Interface\\Tooltips\\UI-Tooltip-Background",
            edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
            tile = true, tileSize = 16, edgeSize = 16,
            insets = {left = 4, right = 4, top = 4, bottom = 4}
        })
        f:SetBackdropColor(0, 0, 0, 0.85)
        f:SetBackdropBorderColor(0.8, 0.2, 0.2, 1)
    end

    f:EnableMouse(true)
    f:SetMovable(true)
    f:RegisterForDrag("LeftButton")
    f:SetScript("OnDragStart", f.StartMoving)
    f:SetScript("OnDragStop", function(selfFrame)
        selfFrame:StopMovingOrSizing()
        if S.SmartDefaults then
            S.SmartDefaults:SavePosition("TrinketTracker", selfFrame)
        end
    end)
    f:SetClampedToScreen(true)
    f:Hide()

    -- Título
    local title = f:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    title:SetPoint("TOP", f, "TOP", 0, -8)
    title:SetText("|cFFFF4444Sequito|r - Trinkets")
    f.title = title

    -- Botón cerrar
    local closeBtn = CreateFrame("Button", nil, f, "UIPanelCloseButton")
    closeBtn:SetPoint("TOPRIGHT", f, "TOPRIGHT", -2, -2)
    closeBtn:SetScript("OnClick", function() TT:Toggle() end)

    -- Botón limpiar
    local clearBtn = CreateFrame("Button", nil, f, "UIPanelButtonTemplate")
    clearBtn:SetSize(55, 18)
    clearBtn:SetPoint("TOPLEFT", f, "TOPLEFT", 8, -8)
    clearBtn:SetText("Limpiar")
    clearBtn:GetFontString():SetFont("Fonts\\FRIZQT__.TTF", 9)
    clearBtn:SetScript("OnClick", function() TT:ClearAll() end)

    -- Contenedor de scroll
    local scrollFrame = CreateFrame("ScrollFrame", "SequitoTTScroll", f, "UIPanelScrollFrameTemplate")
    scrollFrame:SetPoint("TOPLEFT", f, "TOPLEFT", 8, -32)
    scrollFrame:SetPoint("BOTTOMRIGHT", f, "BOTTOMRIGHT", -28, 8)

    local content = CreateFrame("Frame", nil, scrollFrame)
    content:SetSize(190, 400)
    scrollFrame:SetScrollChild(content)
    f.content = content

    if S.SmartDefaults then
        S.SmartDefaults:RestorePosition("TrinketTracker")
    end

    return f
end

function TT:CreateTrinketRow(parent, index)
    local row = CreateFrame("Frame", nil, parent)
    row:SetSize(190, 28)
    row:SetPoint("TOPLEFT", parent, "TOPLEFT", 0, -((index - 1) * 30))

    row.bg = row:CreateTexture(nil, "BACKGROUND")
    row.bg:SetAllPoints()
    row.bg:SetTexture("Interface\\Buttons\\WHITE8X8")
    row.bg:SetVertexColor(0, 0, 0, 0.35)

    local icon = row:CreateTexture(nil, "ARTWORK")
    icon:SetSize(24, 24)
    icon:SetPoint("LEFT", row, "LEFT", 2, 0)
    icon:SetTexture("Interface\\Icons\\INV_Jewelry_TrinketPVP_02")
    row.icon = icon

    local classIcon = row:CreateTexture(nil, "OVERLAY")
    classIcon:SetSize(14, 14)
    classIcon:SetPoint("BOTTOMRIGHT", icon, "BOTTOMRIGHT", 2, -2)
    row.classIcon = classIcon

    local enemyName = row:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    enemyName:SetPoint("LEFT", icon, "RIGHT", 4, 0)
    enemyName:SetWidth(95)
    enemyName:SetJustifyH("LEFT")
    row.enemyName = enemyName

    local status = row:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    status:SetPoint("RIGHT", row, "RIGHT", -4, 0)
    status:SetWidth(50)
    status:SetJustifyH("RIGHT")
    row.status = status

    local bar = CreateFrame("StatusBar", nil, row)
    bar:SetSize(186, 3)
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
            local _, instanceType = IsInInstance()
            if instanceType == "pvp" or instanceType == "arena" then
                TT:ClearAll()
                if TT:GetOption("autoShow") then
                    TT:Show()
                end
            end
        end
    end)

    -- Timer de actualización de la UI con throttle a 0.1s
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
        end
    end)
end

function TT:OnCombatLog(...)
    local timestamp, event, sourceGUID, sourceName, sourceFlags, destGUID, destName, destFlags, spellId = ...

    if event ~= "SPELL_CAST_SUCCESS" then return end
    if not spellId or not TrinketSpells[spellId] then return end
    if not sourceName or sourceName == "" then return end

    -- Verificación canónica de hostilidad para WotLK 3.3.5a
    local isHostile = bit.band(sourceFlags or 0, COMBATLOG_OBJECT_REACTION_HOSTILE) ~= 0
    local isPlayer  = bit.band(sourceFlags or 0, COMBATLOG_OBJECT_TYPE_PLAYER) ~= 0
    local _, instanceType = IsInInstance()

    if instanceType == "arena" then
        -- En arena, cualquier jugador que no esté en nuestro grupo es enemigo
        if not UnitInParty(sourceName) and not UnitInRaid(sourceName) and sourceName ~= UnitName("player") then
            isHostile = true
            isPlayer = true
        end
    end

    if not isPlayer or not isHostile then return end

    self:RegisterTrinketUse(sourceName, sourceGUID, spellId)
end

function TT:RegisterTrinketUse(playerName, playerGUID, spellId)
    local now = GetTime()
    local spellInfo = TrinketSpells[spellId]
    local cdDuration = spellInfo and spellInfo.cd or TRINKET_CD

    local class = nil
    local classColor = {r = 1, g = 1, b = 1}

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
        duration = cdDuration,
        expires = now + cdDuration,
        onCooldown = true
    }

    self:AlertTrinketUsed(playerName, class, spellInfo and spellInfo.name)

    if not self.IsVisible and self:GetOption("autoShow") then
        self:Show()
    end

    self:UpdateDisplay()
end

function TT:AlertTrinketUsed(playerName, class, spellName)
    if self:GetOption("sound") then
        PlaySound("RaidWarning")
    end

    local classColor = class and RAID_CLASS_COLORS[class] or {r = 1, g = 1, b = 1}
    local colorCode = string.format("|cff%02x%02x%02x", classColor.r * 255, classColor.g * 255, classColor.b * 255)
    local sName = spellName or "TRINKET"

    if RaidWarningFrame then
        RaidNotice_AddMessage(RaidWarningFrame,
            string.format("%s%s|r usó %s!", colorCode, playerName, sName),
            {r = 1, g = 0.4, b = 0})
    end

    print(string.format("|cFFFF0000[Sequito]|r %s%s|r usó %s! (CD: 2 min)", colorCode, playerName, sName))

    if self:GetOption("announce") then
        local channel = self:GetChannel()
        if channel then
            SendChatMessage(string.format("[Sequito] %s usó %s!", playerName, sName), channel)
        end
    end
end

function TT:UpdateTimers()
    local now = GetTime()
    for name, data in pairs(self.EnemyTrinkets) do
        if data.onCooldown and now >= data.expires then
            data.onCooldown = false
            self:AlertTrinketReady(name, data.class)
        end
    end
end

function TT:AlertTrinketReady(playerName, class)
    local classColor = class and RAID_CLASS_COLORS[class] or {r = 1, g = 1, b = 1}
    local colorCode = string.format("|cff%02x%02x%02x", classColor.r * 255, classColor.g * 255, classColor.b * 255)

    print(string.format("|cFF00FF00[Sequito]|r %s%s|r tiene Trinket LISTO!", colorCode, playerName))

    if self:GetOption("sound") then
        PlaySound("igQuestLogAbandonQuest")
    end
end

function TT:UpdateDisplay()
    if not self.Frame or not self.Frame.content then return end

    for _, row in ipairs(self.Rows) do
        row:Hide()
    end

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

        local colorCode = string.format("|cff%02x%02x%02x",
            data.classColor.r * 255, data.classColor.g * 255, data.classColor.b * 255)
        row.enemyName:SetText(colorCode .. data.name .. "|r")

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
            local color = (remaining <= 15) and Colors.almostReady or Colors.onCooldown

            row.status:SetText(string.format("|cff%02x%02x%02x%s|r",
                color[1] * 255, color[2] * 255, color[3] * 255,
                self:FormatTime(remaining)))
            row.bar:SetMinMaxValues(0, data.duration or TRINKET_CD)
            row.bar:SetValue(remaining)
            row.bar:SetStatusBarColor(color[1], color[2], color[3])
            row.icon:SetDesaturated(true)
        else
            row.status:SetText("|cFF00FF00LISTO|r")
            row.bar:SetValue(0)
            row.bar:SetStatusBarColor(Colors.available[1], Colors.available[2], Colors.available[3])
            row.icon:SetDesaturated(false)
        end

        row:Show()
    end

    self.Frame.content:SetHeight(math.max(#sorted * 30, 50))

    local onCD = 0
    for _, data in pairs(self.EnemyTrinkets) do
        if data.onCooldown then onCD = onCD + 1 end
    end
    self.Frame.title:SetText(string.format("|cFFFF4444Sequito|r - Trinkets (%d en CD)", onCD))
end

function TT:FormatTime(seconds)
    if seconds >= 60 then
        return string.format("%d:%02d", math.floor(seconds / 60), seconds % 60)
    else
        return string.format("%.1fs", seconds)
    end
end

-- Sistema de Nameplates optimizado (Zero Allocations en OnUpdate)
function TT:CreateNameplateHook()
    local function UpdateNameplate(nameplate)
        if not nameplate then return end

        local nameStr = nameplate._rsName and nameplate._rsName:GetText()
        if not nameStr then return end

        local data = TT.EnemyTrinkets[nameStr]
        if not data then
            if TT.NameplateIcons[nameplate] then
                TT.NameplateIcons[nameplate]:Hide()
            end
            return
        end

        local iconSize = TT:GetOption("iconSize") or 20
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

    local nameplateTicker = CreateFrame("Frame")
    local elapsed = 0
    nameplateTicker:SetScript("OnUpdate", function(selfFrame, dt)
        -- Guardia de configuración: cero trabajo si nameplates están desactivados
        if not TT:GetOption("nameplates") then return end

        elapsed = elapsed + dt
        if elapsed < 0.25 then return end
        elapsed = 0

        -- 1. Soporte para addons de Nameplates estándar (Aloft, TidyPlates, Kui)
        local foundCustom = false
        for i = 1, 40 do
            local np = _G["NamePlate" .. i]
            if np and np:IsVisible() then
                foundCustom = true
                if not np._rsName then
                    for j = 1, select("#", np:GetRegions()) do
                        local reg = select(j, np:GetRegions())
                        if reg and reg:GetObjectType() == "FontString" then
                            np._rsName = reg
                            break
                        end
                    end
                end
                UpdateNameplate(np)
            end
        end

        -- 2. Fallback de alta velocidad para nameplates nativos de WotLK 3.3.5a en WorldFrame
        if not foundCustom and WorldFrame then
            local numChildren = WorldFrame:GetNumChildren()
            for i = 1, numChildren do
                local child = select(i, WorldFrame:GetChildren())
                if child and child:IsShown() and child:GetName() == nil then
                    if not child._rsName then
                        for j = 1, select("#", child:GetRegions()) do
                            local reg = select(j, child:GetRegions())
                            if reg and reg:GetObjectType() == "FontString" then
                                child._rsName = reg
                                break
                            end
                        end
                    end
                    if child._rsName then
                        UpdateNameplate(child)
                    end
                end
            end
        end
    end)
end

function TT:ClearAll()
    self.EnemyTrinkets = {}
    self:UpdateDisplay()
    local msg = "Trinket tracker limpiado."
    if S.Print then S:Print(msg) else print("|cFF00FF00[Sequito]|r " .. msg) end
end

function TT:Toggle()
    if not self.Frame then
        self:CreateFrame()
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
        self:CreateFrame()
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
            print("|cFFFF4444[Sequito]|r Trinkets en CD: " .. table.concat(onCD, ", "))
        end
        if #ready > 0 then
            print("|cFF00FF00[Sequito]|r Trinkets LISTOS: " .. table.concat(ready, ", "))
        end
    end
end

function TT:PrintHelp()
    print("|cFFD4AF37=== Sequito TrinketTracker - Comandos ===|r")
    print("  |cFFFFD100/tt|r : Abre o cierra el monitor de trinkets enemigos.")
    print("  |cFFFFD100/tt clear|r : Limpia todos los registros.")
    print("  |cFFFFD100/tt announce|r : Anuncia el estado de trinkets en el chat de banda/grupo.")
    print("  |cFFFFD100/tt help|r : Muestra esta guía de ayuda.")
end

function TT:SlashCommand(msg)
    msg = msg and msg:match("^%s*(.-)%s*$") or ""
    local lower = msg:lower()

    if lower == "clear" or lower == "limpiar" then
        self:ClearAll()
    elseif lower == "announce" or lower == "anunciar" then
        self:AnnounceAll()
    elseif lower == "help" or lower == "ayuda" then
        self:PrintHelp()
    else
        self:Toggle()
    end
end

-- Registro canónico de Comandos Slash en WoW 3.3.5a
SLASH_TRINKETTRACKER1 = "/tt"
SLASH_TRINKETTRACKER2 = "/trinket"
SLASH_TRINKETTRACKER3 = "/trinkettracker"
SlashCmdList["TRINKETTRACKER"] = function(msg)
    TT:SlashCommand(msg)
end

-- Registro en ModuleConfig
if S.ModuleConfig then
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
        onSave = function()
            local enabled = TT:GetOption("enabled")
            if enabled and TT.Frame and TT.IsVisible then
                TT.Frame:Show()
            elseif TT.Frame then
                TT.Frame:Hide()
            end
        end,
    })
end

local loader = CreateFrame("Frame")
loader:RegisterEvent("PLAYER_LOGIN")
loader:SetScript("OnEvent", function()
    TT:Initialize()
end)
