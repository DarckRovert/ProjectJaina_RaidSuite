--[[
    SEQUITO - Soulstone Tracker
    Módulo de Clase para Brujos (Warlock) en WotLK 3.3.5a (Build 12340).
    Arquitectura desacoplada: Worker Frame inmortal + Display HUD con Zero-Heap.
]]--

local addonName, S = ...
S.Soulstones = {}
local SS = S.Soulstones

-- Catálogo oficial de rangos de Piedra de Alma en WotLK 3.3.5a
local SOULSTONE_SPELL_IDS = {
    [20707] = true, -- Rango 1: Menor
    [20762] = true, -- Rango 2: Inferior
    [20763] = true, -- Rango 3: Normal
    [20764] = true, -- Rango 4: Superior
    [20765] = true, -- Rango 5: Mayor
    [27239] = true, -- Rango 6: Sublime
    [47883] = true, -- Rango 7: Demoníaca (Nivel 80)
}

-- Mapeo bilingüe dinámico
local SOULSTONE_NAMES = {
    ["Soulstone Resurrection"] = true,
    ["Resurrección con piedra de alma"] = true,
    ["Resurrección de piedra de alma"] = true,
}

for spellId in pairs(SOULSTONE_SPELL_IDS) do
    local sName = GetSpellInfo(spellId)
    if sName then
        SOULSTONE_NAMES[sName] = true
    end
end

-- Buffers estáticos (Zero Heap Thrashing - Ley IV)
local staticStonedPool = {}
for i = 1, 40 do
    staticStonedPool[i] = {
        name = "",
        expires = 0,
        duration = 0,
        class = "WARRIOR",
    }
end
local staticStonedList = {}
local previousStonedMap = {}

-- Helper de configuración
function SS:GetOption(key)
    if S.ModuleConfig then
        local val = S.ModuleConfig:GetValue("Soulstones", key)
        if val ~= nil then return val end
    end
    if S.db and S.db.profile then
        if key == "enabled" and S.db.profile.SoulstoneTracker ~= nil then return S.db.profile.SoulstoneTracker end
        if key == "alerts" and S.db.profile.SoulstoneAlerts ~= nil then return S.db.profile.SoulstoneAlerts end
    end
    if key == "enabled" or key == "alerts" then return true end
    return false
end

function SS:Initialize()
    local _, class = UnitClass("player")
    if class ~= "WARLOCK" then return end
    if not self:GetOption("enabled") then return end
    if self.initialized then return end
    self.initialized = true

    self.Rows = {}
    self.isTestMode = false
    self.testTimer = 0

    self:CreateDisplayFrame()
    self:CreateWorkerFrame()
    self:CreateSlashCommands()

    if S.Print then
        S:Print("|cFF9900FF[Soulstones]|r Monitor de Piedras de Alma iniciado. Usa |cFFFFD700/ss test|r para posicionar.")
    end
end

-- Marco Visual HUD (Display Frame)
function SS:CreateDisplayFrame()
    if self.Frame then return self.Frame end

    local f = CreateFrame("Frame", "JainaSSTracker", UIParent)
    f:SetSize(170, 50)
    f:SetPoint("CENTER", UIParent, "CENTER", -300, 0)
    f:SetFrameStrata("MEDIUM")
    f:SetClampedToScreen(true)
    f:SetMovable(true)
    f:EnableMouse(true)
    f:RegisterForDrag("LeftButton")

    -- Estilo Glassmorphism WotLK 3.3.5a
    f:SetBackdrop({
        bgFile   = "Interface\\Buttons\\WHITE8X8",
        edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
        tile     = false,
        edgeSize = 12,
        insets   = { left = 3, right = 3, top = 3, bottom = 3 }
    })
    f:SetBackdropColor(0.05, 0.04, 0.08, 0.88)
    f:SetBackdropBorderColor(0.5, 0.25, 0.7, 0.85)

    -- Título
    f.title = f:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    f.title:SetPoint("TOPLEFT", 6, -5)
    f.title:SetText("|cFFCC66FFPiedras de Alma|r")

    -- Icono decorativo
    f.icon = f:CreateTexture(nil, "OVERLAY")
    f.icon:SetSize(12, 12)
    f.icon:SetPoint("TOPRIGHT", -6, -5)
    f.icon:SetTexture("Interface\\Icons\\Spell_Shadow_SoulGem")

    f:SetScript("OnDragStart", function(self)
        self:StartMoving()
    end)
    f:SetScript("OnDragStop", function(self)
        self:StopMovingOrSizing()
        if S.SmartDefaults then
            S.SmartDefaults:SavePosition("Soulstones", self)
        end
    end)

    -- Ticker suave de 1.0s para cuenta regresiva (solo corre cuando el DisplayFrame está visible)
    f:SetScript("OnUpdate", function(self, elapsed)
        self.elapsed = (self.elapsed or 0) + elapsed
        if self.elapsed >= 1.0 then
            self.elapsed = 0
            if SS.isTestMode then
                SS.testTimer = SS.testTimer - 1
                if SS.testTimer <= 0 then
                    SS.isTestMode = false
                    SS:ScanRaid()
                else
                    SS:UpdateDisplayCountdown()
                end
            else
                SS:UpdateDisplayCountdown()
            end
        end
    end)

    if S.SmartDefaults then
        S.SmartDefaults:RestorePosition("Soulstones", f)
    end

    f:Hide()
    self.Frame = f
    return f
end

-- Marco Motor Permanente (Worker Frame inmortal - Nunca se oculta)
function SS:CreateWorkerFrame()
    if self.WorkerFrame then return self.WorkerFrame end

    local wf = CreateFrame("Frame", "JainaSSWorker", UIParent)
    wf:RegisterEvent("UNIT_AURA")
    wf:RegisterEvent("RAID_ROSTER_UPDATE")
    wf:RegisterEvent("PARTY_MEMBERS_CHANGED")
    wf:RegisterEvent("PLAYER_ENTERING_WORLD")

    local scanPending = false
    wf:SetScript("OnUpdate", function(self, elapsed)
        if scanPending then
            scanPending = false
            SS:ScanRaid()
        end
    end)

    wf:SetScript("OnEvent", function(self, event, unit)
        if event == "UNIT_AURA" then
            if unit and (unit:find("^raid") or unit:find("^party") or unit == "player") then
                scanPending = true
            end
        else
            scanPending = true
        end
    end)

    self.WorkerFrame = wf
    return wf
end

-- Inspección de auras en unidad sin asignación de heap
local function CheckUnitSoulstone(unit, count)
    local name = UnitName(unit)
    if not name or name == "" or name == UNKNOWNOBJECT then return count end

    for i = 1, 40 do
        local buffName, _, _, _, _, duration, expirationTime, _, _, _, spellId = UnitBuff(unit, i)
        if not buffName then break end

        if (spellId and SOULSTONE_SPELL_IDS[spellId]) or SOULSTONE_NAMES[buffName] then
            count = count + 1
            local item = staticStonedPool[count]
            if item then
                item.name = name
                item.expires = expirationTime or 0
                item.duration = duration or 1800
                local _, class = UnitClass(unit)
                item.class = class or "WARRIOR"
                staticStonedList[count] = item
            end
            break
        end
    end
    return count
end

-- Escaneo de Banda / Grupo
function SS:ScanRaid()
    if self.isTestMode then return end

    for k in pairs(staticStonedList) do staticStonedList[k] = nil end
    local count = 0

    if GetNumRaidMembers() > 0 then
        local num = math.min(40, GetNumRaidMembers())
        for i = 1, num do
            count = CheckUnitSoulstone("raid" .. i, count)
        end
    elseif GetNumPartyMembers() > 0 then
        count = CheckUnitSoulstone("player", count)
        for i = 1, GetNumPartyMembers() do
            count = CheckUnitSoulstone("party" .. i, count)
        end
    else
        count = CheckUnitSoulstone("player", count)
    end

    self:CheckExpirations(count)
    self:UpdateDisplay(count)
end

-- Detección y anuncio de expiración o consumo
function SS:CheckExpirations(count)
    local currentMap = {}
    for i = 1, count do
        local d = staticStonedList[i]
        if d then
            currentMap[d.name] = d.expires
        end
    end

    local now = GetTime()
    for oldName, oldExpires in pairs(previousStonedMap) do
        if not currentMap[oldName] then
            local expiredByTime = oldExpires and oldExpires > 0 and (oldExpires <= now + 2)
            if expiredByTime then
                self:AnnounceExpiration(oldName, "EXPIRED")
            else
                self:AnnounceExpiration(oldName, "GONE")
            end
        end
    end

    for k in pairs(previousStonedMap) do previousStonedMap[k] = nil end
    for name, expires in pairs(currentMap) do
        previousStonedMap[name] = expires
    end
end

function SS:GetAnnouncementChannel()
    local inInstance, instanceType = IsInInstance()
    if inInstance and instanceType == "pvp" then
        return "BATTLEGROUND"
    end
    if GetNumRaidMembers() > 0 then
        if IsRaidLeader() or IsRaidOfficer() then
            return "RAID_WARNING"
        else
            return "RAID"
        end
    elseif GetNumPartyMembers() > 0 then
        return "PARTY"
    end
    return nil
end

function SS:AnnounceExpiration(name, alertType)
    if not self:GetOption("alerts") then return end

    local msg = (alertType == "EXPIRED")
        and string.format("¡La Piedra de Alma de %s ha EXPIRADO!", name)
        or string.format("¡La Piedra de Alma de %s ha sido consumida o purgada!", name)

    local channel = self:GetAnnouncementChannel()
    if channel then
        SendChatMessage(msg, channel)
    end

    PlaySound("RaidWarning")
    if S.Print then
        S:Print("|cFFFF0000" .. msg .. "|r")
    end
end

-- Renderizado visual de filas
function SS:UpdateDisplay(count)
    if not self.Frame then return end

    if count == 0 and not self.isTestMode then
        self.Frame:Hide()
        return
    end

    for i = 1, count do
        if not self.Rows[i] then
            local row = CreateFrame("Frame", nil, self.Frame)
            row:SetSize(160, 18)
            row:SetPoint("TOPLEFT", self.Frame, "TOPLEFT", 6, -20 - ((i - 1) * 18))

            row.text = row:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
            row.text:SetPoint("LEFT", 0, 0)
            row.text:SetWidth(100)
            row.text:SetJustifyH("LEFT")

            row.time = row:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
            row.time:SetPoint("RIGHT", 0, 0)
            row.time:SetJustifyH("RIGHT")

            self.Rows[i] = row
        end

        local row = self.Rows[i]
        local data = staticStonedList[i]
        if data then
            row.text:SetText(data.name)
            row:Show()
        end
    end

    for i = count + 1, #self.Rows do
        if self.Rows[i] then self.Rows[i]:Hide() end
    end

    self.Frame:SetHeight(28 + (math.max(1, count) * 18))
    self:UpdateDisplayCountdown()
    self.Frame:Show()
end

-- Actualización por segundo del temporizador MM:SS
function SS:UpdateDisplayCountdown()
    if not self.Frame or not self.Frame:IsShown() then return end

    local now = GetTime()
    local count = self.isTestMode and 2 or #staticStonedList

    for i = 1, count do
        local row = self.Rows[i]
        local data = staticStonedList[i]
        if row and data and row:IsShown() then
            local remaining = (data.expires and data.expires > 0) and math.max(0, data.expires - now) or 0
            if remaining > 0 then
                local m = math.floor(remaining / 60)
                local s = math.floor(remaining % 60)
                row.time:SetText(string.format("%d:%02d", m, s))

                if remaining < 60 then
                    row.time:SetTextColor(1, 0.2, 0.2, 1) -- Alerta roja
                elseif remaining < 300 then
                    row.time:SetTextColor(1, 0.8, 0.2, 1) -- Advertencia naranja
                else
                    row.time:SetTextColor(0.3, 1, 0.3, 1) -- Seguro verde
                end
            else
                row.time:SetText("|cFFFF0000EXP|r")
            end
        end
    end
end

-- Modo de prueba para posicionamiento
function SS:StartTestMode()
    self.isTestMode = true
    self.testTimer = 15

    for k in pairs(staticStonedList) do staticStonedList[k] = nil end
    staticStonedList[1] = { name = "TankPrincipal", expires = GetTime() + 1740, duration = 1800, class = "WARRIOR" }
    staticStonedList[2] = { name = "HealerTop",     expires = GetTime() + 45,   duration = 1800, class = "PRIEST" }

    self:UpdateDisplay(2)
    if S.Print then
        S:Print("|cFF9900FF[Soulstones]|r Modo prueba activado durante 15s. Arrastra la ventana para posicionarla.")
    end
end

function SS:Toggle()
    if not self.Frame then self:CreateDisplayFrame() end
    if self.Frame:IsShown() then
        self.isTestMode = false
        self.Frame:Hide()
    else
        self:StartTestMode()
    end
end

function SS:CreateSlashCommands()
    SLASH_SEQUITOSS1 = "/ss"
    SLASH_SEQUITOSS2 = "/soulstone"
    SLASH_SEQUITOSS3 = "/soulstones"
    SlashCmdList["SEQUITOSS"] = function(msg)
        local cmd = (msg or ""):lower():match("^%s*(%S+)")
        if cmd == "test" then
            SS:StartTestMode()
        elseif cmd == "scan" then
            SS.isTestMode = false
            SS:ScanRaid()
        else
            SS:Toggle()
        end
    end
end

-- Registro en Jaina
S.Soulstones = SS
