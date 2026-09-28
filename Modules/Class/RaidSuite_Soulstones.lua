--[[
    Sequito - Soulstone Tracker
    Modulo v11.0: Monitor de Piedras de Alma.
]]

local addonName, S = ...
S.Soulstones = {}
local SS = S.Soulstones

-- Config
local SS_SPELL_NAME = "Resurrección de piedra de alma" -- Check locale
local SS_ICON = "Interface\\Icons\\Spell_Shadow_SoulGem"

function SS:Initialize()
    local _, class = UnitClass("player")
    if class ~= "WARLOCK" then return end
    if S.db and S.db.profile and S.db.profile.SoulstoneTracker == false then return end
    
    self.Frame = CreateFrame("Frame", "SequitoSSTracker", UIParent)
    self.Frame:SetSize(160, 60)
    self.Frame:SetPoint("CENTER", UIParent, "CENTER", -300, 0)
    
    -- Background
    local bg = self.Frame:CreateTexture(nil, "BACKGROUND")
    bg:SetAllPoints()
    bg:SetTexture(0, 0, 0, 0.5)
    
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
    self.Frame:SetScript("OnUpdate", function(self, elapsed)
        self.elapsed = (self.elapsed or 0) + elapsed
        if self.elapsed > 2.0 then -- Check every 2s
            SS:ScanRaid()
            self.elapsed = 0
        end
    end)
    
    self.Rows = {}
    print("|cFF9900FFSequito SS Tracker|r: Online.")
end

function SS:ScanRaid()
    local stoned = {}
    
    -- Helper to check unit
    local function CheckUnit(unit)
        local name = UnitName(unit)
        if not name then return end
        
        for i=1, 40 do
            local buffName, _, _, _, _, duration, expirationTime = UnitBuff(unit, i)
            if not buffName then break end
            
            if buffName == "Resurrección de piedra de alma" or buffName == "Soulstone Resurrection" then
                table.insert(stoned, {
                    name = name,
                    expires = expirationTime,
                    duration = duration
                })
                break
            end
        end
    end
    
    if GetNumRaidMembers() > 0 then
        for i=1, GetNumRaidMembers() do
            CheckUnit("raid"..i)
        end
    elseif GetNumPartyMembers() > 0 then
        CheckUnit("player")
        for i=1, GetNumPartyMembers() do
            CheckUnit("party"..i)
        end
    else
        CheckUnit("player")
    end
    
    self:UpdateDisplay(stoned)
    self:CheckExpirations(stoned)
end

function SS:CheckExpirations(currentList)
    -- Compare current with previous to detect drops
    if not self.LastList then self.LastList = currentList return end
    
    -- Mapa de nombres actuales
    local currentNames = {}
    for _, data in ipairs(currentList) do currentNames[data.name] = true end
    
    for _, oldData in ipairs(self.LastList) do
        if not currentNames[oldData.name] then
            -- Se ha perdido el buffo de oldData.name
            -- Verificar que no haya muerto (si muere, se consume, no expira por tiempo necesariamente, aunque ambos son criticos)
            -- Necrosis avisa SIEMPRE que se pierde.
            
            -- Solo avisar si le quedaba tiempo (no fue un despawn/offline inmediato irrelevante)
            if oldData.expires - GetTime() < 0 then
                -- Expiró por tiempo
                self:AnnounceExpiration(oldData.name, "EXPIRED")
            else
                -- Se consumió (murió y resucitó?) o fue dispelled
                -- Asumimos "Se ha roto/consumido"
                self:AnnounceExpiration(oldData.name, "GONE")
            end
        end
    end
    
    self.LastList = currentList
end

function SS:AnnounceExpiration(name, type)
    if not S.db.profile.SoulstoneAlerts then return end
    
    local msg = ""
    if type == "EXPIRED" then
        msg = "¡LA PIEDRA DE ALMA DE " .. name .. " HA EXPIRADO!"
    else
        msg = "¡La Piedra de Alma de " .. name .. " se ha consumido o perdido!"
    end
    
    SendChatMessage(msg, "RAID_WARNING") -- O "RAID" si no es lider
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
        
        local remaining = data.expires - GetTime()
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
        end
        row:Show()
    end
    
    self.Frame:SetHeight(25 + (#list * 20))
end
