--[[
    Sequito - VersionSync Module
    Sincronización y auditoría de versiones del addon para WotLK 3.3.5a
    Version: 8.0.0
]]

local addonName, S = ...
S.VersionSync = S.VersionSync or {}
local VSy = S.VersionSync

local guildVersions = {}
VSy.notifiedSenders = {}
VSy.lastResponse = {}

local DEFAULT_OPTIONS = {
    enabled = true,
    autoCheck = true,
    notifyOutdated = true,
    showInTooltip = false,
    checkInterval = 30,
}

-- Helper para obtener la versión real en tiempo de ejecución (evita carreras de carga en el TOC)
function VSy:GetVersion()
    return S.Version or (GetAddOnMetadata and GetAddOnMetadata(addonName, "Version")) or "11.1.0"
end

-- Helper para obtener configuración con fallback defensivo
function VSy:GetOption(key)
    if S.ModuleConfig and S.ModuleConfig.GetValue then
        local val = S.ModuleConfig:GetValue("VersionSync", key)
        if val ~= nil then return val end
    end
    if DEFAULT_OPTIONS[key] ~= nil then
        return DEFAULT_OPTIONS[key]
    end
    return true
end

function VSy:Initialize()
    if self.initialized then return end
    if not self:GetOption("enabled") then
        return
    end
    self.initialized = true
    
    if RegisterAddonMessagePrefix then
        RegisterAddonMessagePrefix("SeqVer")
    end

    self.frame = self:CreateFrame()
    self.Frame = self.frame
    self:RegisterEvents()
end

function VSy:CreateFrame()
    if self.frame then return self.frame end

    local f = CreateFrame("Frame", "SequitoVersionSyncFrame", UIParent)
    self.frame = f
    self.Frame = f
    f:SetSize(360, 320)
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
            S.SmartDefaults:SavePosition("VersionSync", selfFrame)
        end
    end)
    f:SetClampedToScreen(true)
    f:Hide()
    
    f.title = f:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
    f.title:SetPoint("TOP", 0, -12)
    f.title:SetText("|cFFD4AF37Sequito - Versiones de Addon|r")
    
    f.close = CreateFrame("Button", nil, f, "UIPanelCloseButton")
    f.close:SetPoint("TOPRIGHT", -4, -4)
    f.close:SetScript("OnClick", function() f:Hide() end)
    
    f.myVersion = f:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
    f.myVersion:SetPoint("TOPLEFT", 16, -38)
    f.myVersion:SetText("Tu versión: |cFF00FF00" .. self:GetVersion() .. "|r")
    
    local sf = CreateFrame("ScrollFrame", "SequitoVSScroll", f, "UIPanelScrollFrameTemplate")
    f.scrollFrame = sf
    sf:SetPoint("TOPLEFT", 12, -62)
    sf:SetPoint("BOTTOMRIGHT", -32, 50)
    
    local content = CreateFrame("Frame", nil, sf)
    f.scrollChild = content
    content:SetSize(300, 200)
    sf:SetScrollChild(content)
    
    f.refreshBtn = CreateFrame("Button", nil, f, "UIPanelButtonTemplate")
    f.refreshBtn:SetSize(110, 24)
    f.refreshBtn:SetPoint("BOTTOMLEFT", 14, 14)
    f.refreshBtn:SetText("Actualizar")
    f.refreshBtn:SetScript("OnClick", function()
        VSy:RequestVersions(true)
        local msg = "Solicitando versiones al grupo/hermandad..."
        if S.Print then S:Print(msg) else print("|cFFFF9900[Sequito]|r " .. msg) end
    end)

    f.closeBottomBtn = CreateFrame("Button", nil, f, "UIPanelButtonTemplate")
    f.closeBottomBtn:SetSize(90, 24)
    f.closeBottomBtn:SetPoint("BOTTOMRIGHT", -14, 14)
    f.closeBottomBtn:SetText("Cerrar")
    f.closeBottomBtn:SetScript("OnClick", function() f:Hide() end)
    
    f.status = f:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    f.status:SetPoint("BOTTOM", 0, 42)
    f.status:SetText("No hay datos. Haz clic en Actualizar.")
    
    self.versionRows = {}
    
    if S.SmartDefaults then
        S.SmartDefaults:RestorePosition("VersionSync")
    end
    
    return f
end

function VSy:UpdateVersionList()
    if not self.frame or not self.frame.scrollChild then return end

    local myVer = self:GetVersion()
    if self.frame.myVersion then
        self.frame.myVersion:SetText("Tu versión: |cFF00FF00" .. myVer .. "|r")
    end

    for _, row in ipairs(self.versionRows) do
        row:Hide()
    end
    
    local yOffset = 0
    local index = 1
    local outdatedCount = 0
    local upToDateCount = 0
    
    local sorted = {}
    for name, ver in pairs(guildVersions) do
        table.insert(sorted, {name = name, version = ver})
    end
    table.sort(sorted, function(a, b) return a.name < b.name end)
    
    for _, data in ipairs(sorted) do
        local row = self.versionRows[index]
        if not row then
            row = CreateFrame("Frame", nil, self.frame.scrollChild)
            row:SetSize(296, 22)
            
            row.icon = row:CreateTexture(nil, "ARTWORK")
            row.icon:SetSize(16, 16)
            row.icon:SetPoint("LEFT", 4, 0)
            
            row.name = row:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
            row.name:SetPoint("LEFT", 24, 0)
            row.name:SetWidth(160)
            row.name:SetJustifyH("LEFT")
            
            row.version = row:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
            row.version:SetPoint("RIGHT", -8, 0)
            row.version:SetJustifyH("RIGHT")
            
            row.bg = row:CreateTexture(nil, "BACKGROUND")
            row.bg:SetAllPoints()
            row.bg:SetTexture("Interface\\Buttons\\WHITE8X8")
            
            self.versionRows[index] = row
        end
        
        row:SetPoint("TOPLEFT", 0, -yOffset)
        row:Show()
        
        local comparison = self:CompareVersions(data.version, myVer)
        if comparison < 0 then
            row.icon:SetTexture("Interface\\RAIDFRAME\\ReadyCheck-NotReady")
            row.version:SetText("|cFFFF4444" .. data.version .. "|r")
            outdatedCount = outdatedCount + 1
        elseif comparison > 0 then
            row.icon:SetTexture("Interface\\RAIDFRAME\\ReadyCheck-Waiting")
            row.version:SetText("|cFF00CCFF" .. data.version .. " (Nueva)|r")
            outdatedCount = outdatedCount + 1
        else
            row.icon:SetTexture("Interface\\RAIDFRAME\\ReadyCheck-Ready")
            row.version:SetText("|cFF00FF00" .. data.version .. "|r")
            upToDateCount = upToDateCount + 1
        end
        
        row.name:SetText(data.name)
        
        if index % 2 == 0 then
            row.bg:SetVertexColor(1, 1, 1, 0.04)
        else
            row.bg:SetVertexColor(0, 0, 0, 0.25)
        end
        
        yOffset = yOffset + 22
        index = index + 1
    end
    
    self.frame.scrollChild:SetHeight(math.max(200, yOffset))
    
    local total = outdatedCount + upToDateCount
    if total > 0 then
        self.frame.status:SetText(string.format("|cFF00FF00%d|r al día, |cFFFF4444%d|r con diferente versión", upToDateCount, outdatedCount))
    else
        self.frame.status:SetText("No hay datos. Haz clic en Actualizar.")
    end
end

function VSy:RegisterEvents()
    if self.eventsRegistered then return end
    self.eventsRegistered = true

    local events = CreateFrame("Frame")
    events:RegisterEvent("CHAT_MSG_ADDON")
    events:RegisterEvent("RAID_ROSTER_UPDATE")
    events:RegisterEvent("PARTY_MEMBERS_CHANGED")
    events:RegisterEvent("GUILD_ROSTER_UPDATE")
    events:SetScript("OnEvent", function(_, event, ...)
        if event == "CHAT_MSG_ADDON" then
            VSy:OnAddonMessage(...)
        elseif event == "RAID_ROSTER_UPDATE" or event == "PARTY_MEMBERS_CHANGED" or event == "GUILD_ROSTER_UPDATE" then
            VSy:RequestVersions(false)
        end
    end)
end

function VSy:GetSyncChannel()
    local inInstance, instanceType = IsInInstance()
    if inInstance and (instanceType == "pvp" or instanceType == "arena") then
        return "BATTLEGROUND"
    elseif GetNumRaidMembers() > 0 then
        return "RAID"
    elseif GetNumPartyMembers() > 0 then
        return "PARTY"
    elseif IsInGuild() then
        return "GUILD"
    end
    return nil
end

function VSy:RequestVersions(force)
    if not force and not self:GetOption("autoCheck") then
        return
    end
    
    local now = GetTime()
    if not force and self.lastRequest and (now - self.lastRequest < 20) then
        return
    end
    self.lastRequest = now
    
    local channel = self:GetSyncChannel()
    if channel then
        SendAddonMessage("SeqVer", "REQUEST", channel)
    end
end

function VSy:SendVersion(channel)
    local targetChannel = channel or self:GetSyncChannel()
    if not targetChannel then return end

    -- Blindaje anti-tormentas de red: máximo 1 respuesta cada 30 segundos por canal
    local now = GetTime()
    local last = self.lastResponse[targetChannel] or 0
    if (now - last) < 30 then
        return
    end
    self.lastResponse[targetChannel] = now

    local payload = "VERSION:" .. self:GetVersion()
    SendAddonMessage("SeqVer", payload, targetChannel)
end

function VSy:OnAddonMessage(prefix, msg, channel, sender)
    if prefix ~= "SeqVer" or not msg then return end
    if sender == UnitName("player") then return end
    
    if msg == "REQUEST" then
        self:SendVersion(channel)
    elseif msg:find("^VERSION:") then
        local version = msg:gsub("^VERSION:", ""):match("^%s*(.-)%s*$")
        if version and version ~= "" then
            guildVersions[sender] = version
            
            local myVer = self:GetVersion()
            if self:CompareVersions(version, myVer) > 0 and self:GetOption("notifyOutdated") then
                local notifyKey = sender .. "_" .. version
                if not self.notifiedSenders[notifyKey] then
                    self.notifiedSenders[notifyKey] = true
                    local note = string.format("Una versión más reciente de Sequito RaidSuite está disponible (|cFFFFD100v%s|r por %s).", version, sender)
                    if S.Print then S:Print(note) else print("|cFFFF9900[Sequito]|r " .. note) end
                end
            end
            
            if self.frame and self.frame:IsShown() then
                self:UpdateVersionList()
            end
        end
    end
end

function VSy:Toggle()
    if not self.frame then
        self:CreateFrame()
    end
    if self.frame:IsShown() then
        self.frame:Hide()
    else
        self:UpdateVersionList()
        self.frame:Show()
    end
end

-- Comparador semántico resiliente a sufijos (ej. 11.1.0 vs 11.1.0b)
function VSy:CompareVersions(v1, v2)
    if not v1 or not v2 then return 0 end
    local p1 = {strsplit(".", tostring(v1))}
    local p2 = {strsplit(".", tostring(v2))}
    
    for i = 1, 3 do
        local token1 = p1[i] and p1[i]:match("%d+") or "0"
        local token2 = p2[i] and p2[i]:match("%d+") or "0"
        local n1 = tonumber(token1) or 0
        local n2 = tonumber(token2) or 0
        if n1 > n2 then return 1 end
        if n1 < n2 then return -1 end
    end
    return 0
end

function VSy:ShowVersions()
    local myVer = self:GetVersion()
    local header = "Versiones de Sequito RaidSuite registradas (Tu versión: |cFF00FF00" .. myVer .. "|r):"
    if S.Print then S:Print(header) else print("|cFFFF9900[Sequito]|r " .. header) end
    
    local hasAny = false
    for name, ver in pairs(guildVersions) do
        hasAny = true
        local cmp = self:CompareVersions(ver, myVer)
        local color = (cmp < 0 and "|cFFFF4444") or (cmp > 0 and "|cFF00CCFF") or "|cFF00FF00"
        print(string.format("  • %s: %s%s|r", name, color, ver))
    end
    if not hasAny then
        print("  (No hay versiones recibidas aún. Usa /vs check para solicitar)")
    end
end

function VSy:PrintHelp()
    print("|cFFD4AF37=== Sequito VersionSync - Comandos ===|r")
    print("  |cFFFFD100/vs|r : Abre o alterna la interfaz de versiones.")
    print("  |cFFFFD100/vs check|r : Solicita versiones al grupo o hermandad.")
    print("  |cFFFFD100/vs list|r : Muestra en chat las versiones recibidas.")
    print("  |cFFFFD100/vs help|r : Muestra esta guía de ayuda.")
end

function VSy:SlashCommand(msg)
    msg = msg and msg:match("^%s*(.-)%s*$") or ""
    local lower = msg:lower()
    
    if lower == "check" or lower == "verificar" then
        self:RequestVersions(true)
        local text = "Solicitando versiones..."
        if S.Print then S:Print(text) else print("|cFFFF9900[Sequito]|r " .. text) end
    elseif lower == "list" or lower == "lista" then
        self:ShowVersions()
    elseif lower == "help" or lower == "ayuda" then
        self:PrintHelp()
    else
        self:Toggle()
    end
end

-- Registrar configuración en ModuleConfig
if S.ModuleConfig then
    S.ModuleConfig:RegisterModule("VersionSync", {
        name = "Version Sync",
        icon = "Interface\\Icons\\INV_Misc_Gear_08",
        description = "Sincroniza y verifica versiones del addon con otros usuarios",
        category = "utility",
        options = {
            {
                type = "checkbox",
                key = "enabled",
                label = "Habilitar Version Sync",
                tooltip = "Activa/desactiva la sincronización de versiones",
                default = true,
            },
            {
                type = "checkbox",
                key = "autoCheck",
                label = "Verificación Automática",
                tooltip = "Verifica versiones automáticamente al entrar al juego y cambios de grupo",
                default = true,
            },
            {
                type = "checkbox",
                key = "notifyOutdated",
                label = "Notificar Nueva Versión",
                tooltip = "Notifica cuando un compañero posea una versión más reciente",
                default = true,
            },
            {
                type = "slider",
                key = "checkInterval",
                label = "Intervalo de Verificación (min)",
                tooltip = "Frecuencia de verificación automática",
                min = 5,
                max = 60,
                step = 5,
                default = 30,
            },
        },
    })
end

-- Registro canónico de Comandos Slash en WoW 3.3.5a
SLASH_VERSIONSYNC1 = "/vs"
SLASH_VERSIONSYNC2 = "/versionsync"
SLASH_VERSIONSYNC3 = "/vsy"
SlashCmdList["VERSIONSYNC"] = function(msg)
    VSy:SlashCommand(msg)
end

local loader = CreateFrame("Frame")
loader:RegisterEvent("PLAYER_LOGIN")
loader:SetScript("OnEvent", function()
    VSy:Initialize()
end)
