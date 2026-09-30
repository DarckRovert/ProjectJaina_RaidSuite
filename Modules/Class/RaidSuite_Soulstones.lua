--[[
    Sequito - Soulstone Tracker
    Modulo v11.0: Monitor de Piedras de Alma.
]]

local addonName, S = ...
S.Soulstones = {}
local SS = S.Soulstones

-- Config & Localized Buff Detection
local SS_SPELL_ID = 20707 -- Soulstone Resurrection
local SS_LOCALIZED_NAME = GetSpellInfo(SS_SPELL_ID) or "Soulstone Resurrection"
local SS_ICON = "Interface\\Icons\\Spell_Shadow_SoulGem"

function SS:Initialize()
    local _, class = UnitClass("player")
    if class ~= "WARLOCK" then return end
    if S.db and S.db.profile and S.db.profile.SoulstoneTracker == false then return end
    
    self.Frame = CreateFrame("Frame", "SequitoSSTracker", UIParent)
    self.Frame:SetSize(160, 60)
    self.Frame:SetPoint("CENTER", UIParent, "CENTER", -300, 0)
    
    -- Background (Cumplimiento estricto Ley II: Texturas sólidas en 3.3.5a)
    local bg = self.Frame:CreateTexture(nil, "BACKGROUND")
    bg:SetAllPoints()
    bg:SetTexture("Interface\\Buttons\\WHITE8X8")
    bg:SetVertexColor(0, 0, 0, 0.5)
    
    -- Title
    local title = self.Frame:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    title:SetPoint("TOP", 0, -2)
    title:SetText("Soulstones")
    
    -- Dragging
    self.Frame:EnableMouse(true)
    self.Frame:SetMovable(true)
    self.Frame:RegisterForDrag("LeftButton")
    self.Frame:SetScript("OnDragStart", self.Frame.StartMoving)
    self.Frame:SetScript("OnDragStop", self.Frame.StopMovingOrSizing)
    
    -- Scan Loop
    self.Frame:SetScript("OnUpdate", function(f, elapsed)
        f.elapsed = (f.elapsed or 0) + elapsed
        if f.elapsed > 2.0 then -- Check every 2s
            SS:ScanRaid()
            f.elapsed = 0
        end
    end)
    
    self.Rows = {}
    print("|cFF9900FFSequito SS Tracker|r: Online.")
end

-- Función estática fuera del bucle para evitar Heap Thrashing (Ley IV)
local function CheckUnitBuffs(unit, stoned)
    local name = UnitName(unit)
    if not name then return end
    
    for i = 1, 40 do
        local buffName, _, _, _, _, duration, expirationTime, _, _, _, spellId = UnitBuff(unit, i)
        if not buffName then break end
        
        if (spellId and spellId == SS_SPELL_ID) or 
           buffName == SS_LOCALIZED_NAME or 
           buffName == "Soulstone Resurrection" or 
           buffName == "Resurrección de piedra de alma" then
            table.insert(stoned, {
                name = name,
                expires = expirationTime or 0,
                duration = duration or 0
            })
            break
        end
    end
end

function SS:ScanRaid()
    local stoned = {}
    
    if GetNumRaidMembers() > 0 then
        for i = 1, GetNumRaidMembers() do
            CheckUnitBuffs("raid"..i, stoned)
        end
    elseif GetNumPartyMembers() > 0 then
        CheckUnitBuffs("player", stoned)
        for i = 1, GetNumPartyMembers() do
            CheckUnitBuffs("party"..i, stoned)
        end
    else
        CheckUnitBuffs("player", stoned)
    end
    
    self:UpdateDisplay(stoned)
    self:CheckExpirations(stoned)
end

function SS:CheckExpirations(currentList)
    -- Compare current with previous to detect drops
    if not self.LastList then 
        self.LastList = currentList 
        return 
    end
    
    -- Mapa de nombres actuales
    local currentNames = {}
    for _, data in ipairs(currentList) do 
        currentNames[data.name] = true 
    end
    
    local now = GetTime()
    for _, oldData in ipairs(self.LastList) do
        if not currentNames[oldData.name] then
            -- Se ha perdido el buffo de oldData.name
            local expiredByTime = oldData.expires and oldData.expires > 0 and (oldData.expires <= now)
            if expiredByTime then
                self:AnnounceExpiration(oldData.name, "EXPIRED")
            else
                self:AnnounceExpiration(oldData.name, "GONE")
            end
        end
    end
    
    self.LastList = currentList
end

function SS:GetAnnouncementChannel()
    if IsInInstance then
        local inInstance, instanceType = IsInInstance()
        if inInstance and instanceType == "pvp" then
            return "BATTLEGROUND"
        end
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
    if S.db and S.db.profile and S.db.profile.SoulstoneAlerts == false then return end
    
    local msg = ""
    if alertType == "EXPIRED" then
        msg = "¡LA PIEDRA DE ALMA DE " .. name .. " HA EXPIRADO!"
    else
        msg = "¡La Piedra de Alma de " .. name .. " se ha consumido o perdido!"
    end
    
    local channel = self:GetAnnouncementChannel()
    if channel then
        SendChatMessage(msg, channel)
    end
    
    PlaySound("RaidWarning")
    print("|cFFFF0000Sequito:|r " .. msg)
end

function SS:UpdateDisplay(list)
    -- Hide old rows
    for _, row in pairs(self.Rows) do row:Hide() end
    
    if #list == 0 then
        self.Frame:Hide()
        return
    end
    self.Frame:Show()
    
    local now = GetTime()
    for i, data in ipairs(list) do
        if not self.Rows[i] then
            local row = CreateFrame("Frame", nil, self.Frame)
            row:SetSize(160, 20)
            row:SetPoint("TOP", 0, -20 - ((i-1)*20))
            
            row.text = row:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
            row.text:SetPoint("LEFT", 5, 0)
            
            row.time = row:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
            row.time:SetPoint("RIGHT", -5, 0)
            row.time:SetJustifyH("RIGHT")
            
            self.Rows[i] = row
        end
        
        local row = self.Rows[i]
        row.text:SetText(data.name)
        
        local remaining = (data.expires and data.expires > 0) and (data.expires - now) or 0
        if remaining > 0 then
            local m = math.floor(remaining / 60)
            local s = remaining % 60
            row.time:SetText(string.format("%d:%02d", m, s))
            
            -- Color code time
            if remaining < 60 then
                row.time:SetTextColor(1, 0, 0) -- Red alert
            else
                row.time:SetTextColor(0, 1, 0)
            end
        else
            row.time:SetText("EXP")
            row.time:SetTextColor(1, 0.2, 0.2)
        end
        row:Show()
    end
    
    self.Frame:SetHeight(25 + (#list * 20))
end
