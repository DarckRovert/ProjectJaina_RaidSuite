--[[
    Sequito - VersionSync Module
    Sincronización de versiones del addon con UI completa
    Version: 7.3.0
]]

local addonName, S = ...
S.VersionSync = {}
local VSy = S.VersionSync

local ADDON_VERSION = S.Version or "8.0.0"
local guildVersions = {}

-- Helper para obtener configuración
function VSy:GetOption(key)
    if S.ModuleConfig then
        return S.ModuleConfig:GetValue("VersionSync", key)
    end
    return true
end

function VSy:Initialize()
    if not self:GetOption("enabled") then
        return
    end
    if self.initialized then return end
    self.initialized = true
    
    self:CreateFrame()
    self:RegisterEvents()
    if RegisterAddonMessagePrefix then
        RegisterAddonMessagePrefix("SeqVer")
    end
end

function VSy:CreateFrame()
    local f = CreateFrame("Frame", "SequitoVersionSyncFrame", UIParent)
    f:SetSize(350, 300)
    f:SetPoint("CENTER")
    f:SetBackdrop({
        bgFile = "Interface\\DialogFrame\\UI-DialogBox-Background",
        edgeFile = "Interface\\DialogFrame\\UI-DialogBox-Border",
        edgeSize = 16,
        insets = {left = 4, right = 4, top = 4, bottom = 4}
    })
    f:SetMovable(true)
    f:EnableMouse(true)
    f:RegisterForDrag("LeftButton")
    f:SetScript("OnDragStart", f.StartMoving)
    f:SetScript("OnDragStop", f.StopMovingOrSizing)
    f:Hide()
    
    f.title = f:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
    f.title:SetPoint("TOP", 0, -12)
    f.title:SetText("|cff00ff00Sequito|r - Versiones")
    
    f.close = CreateFrame("Button", nil, f, "UIPanelCloseButton")
    f.close:SetPoint("TOPRIGHT", -5, -5)
    
    f.myVersion = f:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    f.myVersion:SetPoint("TOPLEFT", 15, -40)
    f.myVersion:SetText("Tu versión: |cff00ff00" .. ADDON_VERSION .. "|r")
    
    f.scrollFrame = CreateFrame("ScrollFrame", "SequitoVSScroll", f, "UIPanelScrollFrameTemplate")
    f.scrollFrame:SetPoint("TOPLEFT", 10, -65)
    f.scrollFrame:SetPoint("BOTTOMRIGHT", -30, 50)
    
    f.scrollChild = CreateFrame("Frame", nil, f.scrollFrame)
    f.scrollChild:SetSize(300, 200)
    f.scrollFrame:SetScrollChild(f.scrollChild)
    
    f.refreshBtn = CreateFrame("Button", nil, f, "UIPanelButtonTemplate")
    f.refreshBtn:SetSize(120, 25)
    f.refreshBtn:SetPoint("BOTTOMLEFT", 15, 15)
    f.refreshBtn:SetText("Actualizar")
    f.refreshBtn:SetScript("OnClick", function()
        VSy:RequestVersions(true)
        S:Print("Solicitando versiones...")
    end)
    
    f.status = f:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    f.status:SetPoint("BOTTOM", 0, 45)
    f.status:SetText("")
    
    self.frame = f
    self.versionRows = {}
end

function VSy:UpdateVersionList()
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
            row:SetSize(290, 22)
            
            row.icon = row:CreateTexture(nil, "ARTWORK")
            row.icon:SetSize(16, 16)
            row.icon:SetPoint("LEFT", 5, 0)
            
            row.name = row:CreateFontString(nil, "OVERLAY", "GameFontNormal")
            row.name:SetPoint("LEFT", 25, 0)
            row.name:SetWidth(150)
            row.name:SetJustifyH("LEFT")
            
            row.version = row:CreateFontString(nil, "OVERLAY", "GameFontNormal")
            row.version:SetPoint("RIGHT", -10, 0)
            
            row.bg = row:CreateTexture(nil, "BACKGROUND")
            row.bg:SetAllPoints()
            row.bg:SetTexture("Interface\\Buttons\\WHITE8X8")
            row.bg:SetVertexColor(1, 1, 1, 0.05)
            
            self.versionRows[index] = row
        end
        
        row:SetPoint("TOPLEFT", 0, -yOffset)
        row:Show()
        
        local comparison = self:CompareVersions(data.version, ADDON_VERSION)
        if comparison < 0 then
            row.icon:SetTexture("Interface\\RAIDFRAME\\ReadyCheck-NotReady")
            row.version:SetTextColor(1, 0.3, 0.3)
            outdatedCount = outdatedCount + 1
        else
            row.icon:SetTexture("Interface\\RAIDFRAME\\ReadyCheck-Ready")
            row.version:SetTextColor(0.3, 1, 0.3)
            upToDateCount = upToDateCount + 1
        end
        
        row.name:SetText(data.name)
        row.version:SetText(data.version)
        
        if index % 2 == 0 then
            row.bg:SetVertexColor(1, 1, 1, 0.05)
        else
            row.bg:SetVertexColor(0, 0, 0, 0.2)
        end
        
        yOffset = yOffset + 22
        index = index + 1
    end
    
    self.frame.scrollChild:SetHeight(math.max(200, yOffset))
    
    local total = outdatedCount + upToDateCount
    if total > 0 then
        self.frame.status:SetText(string.format("|cff00ff00%d|r actualizados, |cffff0000%d|r desactualizados", upToDateCount, outdatedCount))
    else
        self.frame.status:SetText("No hay datos. Haz clic en Actualizar.")
    end
end

function VSy:RegisterEvents()
    local events = CreateFrame("Frame")
    events:RegisterEvent("CHAT_MSG_ADDON")
    events:RegisterEvent("RAID_ROSTER_UPDATE")
    events:RegisterEvent("PARTY_MEMBERS_CHANGED")
    events:RegisterEvent("GUILD_ROSTER_UPDATE")
    events:SetScript("OnEvent", function(_, event, ...)
        if event == "CHAT_MSG_ADDON" then
            VSy:OnAddonMessage(...)
        elseif event == "RAID_ROSTER_UPDATE" or event == "PARTY_MEMBERS_CHANGED" or event == "GUILD_ROSTER_UPDATE" then
            VSy:RequestVersions()
        end
    end)
end

function VSy:GetSyncChannel()
    if IsInInstance then
        local inInstance, instanceType = IsInInstance()
        if inInstance and instanceType == "pvp" then
            return "BATTLEGROUND"
        end
    end
    if GetNumRaidMembers() > 0 then
        return "RAID"
    elseif GetNumPartyMembers() > 0 then
        return "PARTY"
    elseif IsInGuild() then
        return "GUILD"
    end
    return nil
end

function VSy:RequestVersions(force)
    -- Verificar si auto-check está habilitado
    if not force and not self:GetOption("autoCheck") then
        return
    end
    
    local now = GetTime()
    if not force and self.lastRequest and (now - self.lastRequest < 15) then
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
    if targetChannel then
        SendAddonMessage("SeqVer", "VERSION:" .. ADDON_VERSION, targetChannel)
    end
end

function VSy:OnAddonMessage(prefix, msg, channel, sender)
    if prefix ~= "SeqVer" then return end
    if sender == UnitName("player") then return end
    
    if msg == "REQUEST" then
        self:SendVersion(channel)
    elseif msg:find("VERSION:") then
        local version = msg:gsub("VERSION:", "")
        guildVersions[sender] = version
        
        if self:CompareVersions(version, ADDON_VERSION) > 0 and self:GetOption("notifyOutdated") then
            S:Print("|cffff0000" .. sender .. " tiene una versión más nueva: " .. version .. "|r")
        end
        
        if self.frame and self.frame:IsShown() then
            self:UpdateVersionList()
        end
    end
end

function VSy:Toggle()
    if not self.frame then return end
    if self.frame:IsShown() then
        self.frame:Hide()
    else
        self.frame:Show()
        self:UpdateVersionList()
    end
end

function VSy:CompareVersions(v1, v2)
    local p1 = {strsplit(".", v1)}
    local p2 = {strsplit(".", v2)}
    
    for i = 1, 3 do
        local n1 = tonumber(p1[i]) or 0
        local n2 = tonumber(p2[i]) or 0
        if n1 > n2 then return 1 end
        if n1 < n2 then return -1 end
    end
    return 0
end

function VSy:ShowVersions()
    S:Print("Versiones de Sequito:")
    S:Print("  Tu versión: " .. ADDON_VERSION)
    for name, ver in pairs(guildVersions) do
        local color = self:CompareVersions(ver, ADDON_VERSION) < 0 and "|cffff0000" or "|cff00ff00"
        S:Print("  " .. color .. name .. ": " .. ver .. "|r")
    end
end

function VSy:SlashCommand(msg)
    if msg == "check" then
        self:RequestVersions()
        S:Print("Solicitando versiones...")
    elseif msg == "" or msg == "ui" then
        self:Toggle()
    else
        self:ShowVersions()
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
                tooltip = "Verifica versiones automáticamente al entrar al juego",
                default = true,
            },
            {
                type = "checkbox",
                key = "notifyOutdated",
                label = "Notificar Versión Antigua",
                tooltip = "Notifica cuando tu versión está desactualizada",
                default = true,
            },
            {
                type = "checkbox",
                key = "showInTooltip",
                label = "Mostrar en Tooltip",
                tooltip = "Muestra info de versiones en el tooltip de la esfera",
                default = false,
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

local loader = CreateFrame("Frame")
loader:RegisterEvent("PLAYER_LOGIN")
loader:SetScript("OnEvent", function() VSy:Initialize() end)
