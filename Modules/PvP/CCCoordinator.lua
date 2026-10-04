--[[
    Sequito - CCCoordinator.lua
    Coordinador de Crowd Control con DR Tracking Canónico WotLK 3.3.5a
    Version: 8.0.0
]]

local addonName, S = ...
S.CCCoordinator = {}
local CC = S.CCCoordinator

-- Estado
CC.Assignments = {}  -- {targetName = {player = "Name", spell = "Polymorph", icon = 123}}
CC.ActiveCCs = {}    -- {targetGUID = {spell, spellId, caster, startTime, category}}
CC.DRTracking = {}   -- {targetGUID = {category = {stacks, resetTime, isActive}}}
CC.Frame = nil
CC.IsVisible = false

-- Reducción oficial por acumulación de DR (1 = 100%, 2 = 50%, 3 = 25%, 4 = Inmune)
local DR_REDUCTION = {1.0, 0.5, 0.25, 0}

-- Helper para normalizar cadenas
local function CleanString(str)
    if not str then return "" end
    local s = str:lower()
    s = s:gsub("á", "a"):gsub("é", "e"):gsub("í", "i"):gsub("ó", "o"):gsub("ú", "u"):gsub("ñ", "n")
    return s
end

-- Catálogo de Hechizos DR (WotLK 3.3.5a - Todos los rangos + nombres canónicos)
local DR_SPELLS = {
    -- Stuns
    [853] = "stun", [5588] = "stun", [5589] = "stun", [10308] = "stun", -- Hammer of Justice
    [408] = "stun", [8643] = "stun",                                      -- Kidney Shot
    [1833] = "stun",                                                      -- Cheap Shot
    [5211] = "stun", [6798] = "stun", [8983] = "stun",                   -- Bash
    [22570] = "stun", [49802] = "stun",                                  -- Maim
    [30283] = "stun", [30413] = "stun", [30414] = "stun", [47846] = "stun", [47847] = "stun", -- Shadowfury
    [44572] = "stun",                                                     -- Deep Freeze
    [46968] = "stun",                                                     -- Shockwave
    [12809] = "stun",                                                     -- Concussion Blow
    [20549] = "stun",                                                     -- War Stomp
    [25274] = "stun", [20252] = "stun", [20615] = "stun", [20614] = "stun", [20616] = "stun", -- Intercept
    [47481] = "stun",                                                     -- Gnaw
    [49203] = "stun",                                                     -- Hungering Cold
    [19577] = "stun", [24394] = "stun",                                  -- Intimidation

    -- Fears
    [5782] = "fear", [6213] = "fear", [6215] = "fear",                   -- Fear
    [5484] = "fear", [17928] = "fear",                                   -- Howl of Terror
    [8122] = "fear", [8124] = "fear", [10888] = "fear", [10890] = "fear",-- Psychic Scream
    [5246] = "fear",                                                      -- Intimidating Shout
    [1513] = "fear", [14326] = "fear", [14327] = "fear",                 -- Scare Beast
    [10326] = "fear",                                                     -- Turn Evil

    -- Roots
    [339] = "root", [1062] = "root", [5195] = "root", [5196] = "root",
    [9852] = "root", [9853] = "root", [26989] = "root", [53308] = "root", -- Entangling Roots
    [19970] = "root", [19971] = "root", [19972] = "root", [19973] = "root",
    [19974] = "root", [19975] = "root", [27010] = "root", [53313] = "root", -- Nature's Grasp
    [122] = "root", [865] = "root", [6131] = "root", [10230] = "root",
    [27088] = "root", [42917] = "root",                                   -- Frost Nova
    [33395] = "root",                                                     -- Freeze
    [16979] = "root", [45334] = "root",                                  -- Feral Charge
    [64695] = "root",                                                     -- Earthgrab
    [55080] = "root",                                                     -- Shattered Barrier

    -- Incapacitates
    [118] = "incapacitate", [12824] = "incapacitate", [12825] = "incapacitate", [12826] = "incapacitate",
    [28271] = "incapacitate", [28272] = "incapacitate", [61305] = "incapacitate", [61721] = "incapacitate", [61780] = "incapacitate", -- Polymorph
    [6770] = "incapacitate", [2070] = "incapacitate", [11297] = "incapacitate", [51724] = "incapacitate", -- Sap
    [1776] = "incapacitate", [1777] = "incapacitate", [8629] = "incapacitate", [11285] = "incapacitate",
    [11286] = "incapacitate", [12540] = "incapacitate", [1778] = "incapacitate", [38764] = "incapacitate", -- Gouge
    [2094] = "incapacitate",                                              -- Blind
    [51514] = "incapacitate",                                             -- Hex
    [20066] = "incapacitate",                                             -- Repentance
    [3355] = "incapacitate", [14308] = "incapacitate", [14309] = "incapacitate", [60192] = "incapacitate", [14311] = "incapacitate", -- Freezing Trap
    [19386] = "incapacitate", [24132] = "incapacitate", [24133] = "incapacitate",
    [27068] = "incapacitate", [49011] = "incapacitate", [49012] = "incapacitate", -- Wyvern Sting
    [2637] = "incapacitate", [18657] = "incapacitate", [18658] = "incapacitate",   -- Hibernate
    [710] = "incapacitate", [18647] = "incapacitate",                     -- Banish
    [6358] = "incapacitate",                                              -- Seduction

    -- Silences
    [15487] = "silence",                                                  -- Silence
    [1330] = "silence",                                                   -- Garrote - Silence
    [18469] = "silence",                                                  -- Imp Counterspell
    [18425] = "silence",                                                  -- Imp Kick
    [34490] = "silence",                                                  -- Silencing Shot
    [47476] = "silence",                                                  -- Strangulate
    [19647] = "silence", [24259] = "silence",                             -- Spell Lock

    -- Disarms
    [676] = "disarm",                                                     -- Disarm
    [51722] = "disarm",                                                   -- Dismantle
    [64058] = "disarm",                                                   -- Psychic Horror (disarm)
    [53359] = "disarm",                                                   -- Chimera Shot - Scorpid

    -- Cyclone
    [33786] = "cyclone",                                                  -- Cyclone

    -- Horrors
    [6789] = "horror", [17925] = "horror", [17926] = "horror",
    [27223] = "horror", [47859] = "horror", [47860] = "horror",          -- Death Coil
    [64044] = "horror",                                                   -- Psychic Horror
}

-- Mapeo por nombre bilingüe (fallback seguro de rango)
local DR_BY_NAME = {
    ["hammer of justice"] = "stun", ["martillo de justicia"] = "stun",
    ["kidney shot"] = "stun", ["golpe en los rinones"] = "stun",
    ["cheap shot"] = "stun", ["golpe bajo"] = "stun",
    ["bash"] = "stun", ["azote"] = "stun",
    ["maim"] = "stun", ["mutilar"] = "stun",
    ["shadowfury"] = "stun", ["furia de las sombras"] = "stun",
    ["deep freeze"] = "stun", ["congelacion profunda"] = "stun",
    ["shockwave"] = "stun", ["onda de choque"] = "stun",
    ["concussion blow"] = "stun", ["golpe de conmocion"] = "stun",
    ["war stomp"] = "stun", ["pisoteo de guerra"] = "stun",
    ["fear"] = "fear", ["miedo"] = "fear",
    ["howl of terror"] = "fear", ["aullido de terror"] = "fear",
    ["psychic scream"] = "fear", ["alarido psiquico"] = "fear",
    ["intimidating shout"] = "fear", ["alarido intimidador"] = "fear",
    ["entangling roots"] = "root", ["raices enredadoras"] = "root",
    ["frost nova"] = "root", ["nueva de escarcha"] = "root",
    ["freeze"] = "root", ["congelar"] = "root",
    ["polymorph"] = "incapacitate", ["polimorfia"] = "incapacitate",
    ["sap"] = "incapacitate", ["porrazo"] = "incapacitate",
    ["gouge"] = "incapacitate", ["gubia"] = "incapacitate",
    ["blind"] = "incapacitate", ["ceguera"] = "incapacitate",
    ["hex"] = "incapacitate", ["maleficio"] = "incapacitate",
    ["repentance"] = "incapacitate", ["arrepentimiento"] = "incapacitate",
    ["freezing trap"] = "incapacitate", ["trampa congelante"] = "incapacitate",
    ["cyclone"] = "cyclone", ["ciclon"] = "cyclone",
    ["death coil"] = "horror", ["espiral de la muerte"] = "horror",
    ["silence"] = "silence", ["silencio"] = "silencio",
    ["strangulate"] = "silence", ["estrangulamiento"] = "silence",
    ["disarm"] = "disarm", ["desarmar"] = "disarm",
    ["dismantle"] = "disarm", ["desmantelar"] = "disarm",
}

function CC:GetOption(key)
    if S.ModuleConfig then
        return S.ModuleConfig:GetValue("CCCoordinator", key)
    end
    if key == "drResetTime" then return 18 end
    return true
end

function CC:GetResetDuration()
    local val = tonumber(self:GetOption("drResetTime"))
    return (val and val >= 10 and val <= 40) and val or 18
end

function CC:GetChannel()
    local _, instanceType = IsInInstance()
    if instanceType == "pvp" or instanceType == "arena" then
        return "BATTLEGROUND"
    elseif GetNumRaidMembers() > 0 then
        return "RAID"
    elseif GetNumPartyMembers() > 0 then
        return "PARTY"
    end
    return nil
end

function CC:Initialize()
    if not self:GetOption("enabled") then return end
    if self.initialized then return end
    self.initialized = true

    self:CreateFrame()
    self:RegisterEvents()
    self:RegisterComm()

    if S.SmartDefaults then
        S.SmartDefaults:RestorePosition("CCCoordinator")
    end
end

function CC:CreateFrame()
    self.Frame = CreateFrame("Frame", "SequitoCCCoordinatorFrame", UIParent)
    self.Frame:SetSize(300, 250)
    self.Frame:SetPoint("LEFT", UIParent, "LEFT", 50, 0)
    self.Frame:SetMovable(true)
    self.Frame:EnableMouse(true)
    self.Frame:RegisterForDrag("LeftButton")
    self.Frame:SetScript("OnDragStart", function(f) f:StartMoving() end)
    self.Frame:SetScript("OnDragStop", function(f)
        f:StopMovingOrSizing()
        if S.SmartDefaults then
            S.SmartDefaults:SavePosition("CCCoordinator", f)
        end
    end)
    self.Frame:Hide()

    -- Fondo sólido (Ley II: WHITE8X8)
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
    self.Frame.border:SetBackdropBorderColor(0.6, 0.2, 0.8, 1)

    -- Título
    self.Frame.title = self.Frame:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
    self.Frame.title:SetPoint("TOP", self.Frame, "TOP", 0, -10)
    self.Frame.title:SetText("|cFF9932CCCC Coordinator|r")

    -- Botón cerrar
    self.Frame.closeBtn = CreateFrame("Button", nil, self.Frame, "UIPanelCloseButton")
    self.Frame.closeBtn:SetPoint("TOPRIGHT", self.Frame, "TOPRIGHT", -2, -2)
    self.Frame.closeBtn:SetScript("OnClick", function() self.Frame:Hide() end)

    -- Encabezado Asignaciones
    self.Frame.assignHeader = self.Frame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    self.Frame.assignHeader:SetPoint("TOPLEFT", self.Frame, "TOPLEFT", 15, -35)
    self.Frame.assignHeader:SetText("|cFFFFFF00Asignaciones de CC:|r")

    self.Frame.assignList = CreateFrame("Frame", nil, self.Frame)
    self.Frame.assignList:SetSize(270, 80)
    self.Frame.assignList:SetPoint("TOPLEFT", self.Frame.assignHeader, "BOTTOMLEFT", 0, -5)
    self.Frame.assignRows = {}
    for i = 1, 4 do
        local row = self.Frame.assignList:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
        row:SetPoint("TOPLEFT", self.Frame.assignList, "TOPLEFT", 0, -(i-1) * 18)
        row:SetText("")
        row:SetJustifyH("LEFT")
        self.Frame.assignRows[i] = row
    end

    -- Encabezado DR
    self.Frame.drHeader = self.Frame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    self.Frame.drHeader:SetPoint("TOPLEFT", self.Frame.assignList, "BOTTOMLEFT", 0, -15)
    self.Frame.drHeader:SetText("|cFFFF6600DR Tracking (Oficial):|r")

    self.Frame.drList = CreateFrame("Frame", nil, self.Frame)
    self.Frame.drList:SetSize(270, 100)
    self.Frame.drList:SetPoint("TOPLEFT", self.Frame.drHeader, "BOTTOMLEFT", 0, -5)
    self.Frame.drRows = {}
    for i = 1, 5 do
        local row = self.Frame.drList:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
        row:SetPoint("TOPLEFT", self.Frame.drList, "TOPLEFT", 0, -(i-1) * 18)
        row:SetText("")
        row:SetJustifyH("LEFT")
        self.Frame.drRows[i] = row
    end

    -- OnUpdate throttled 0.1s
    self.updateTimer = 0
    self.Frame:SetScript("OnUpdate", function(f, elapsed)
        self.updateTimer = (self.updateTimer or 0) + elapsed
        if self.updateTimer >= 0.1 then
            self:OnUpdate(self.updateTimer)
            self.updateTimer = 0
        end
    end)
end

function CC:RegisterEvents()
    local eventFrame = CreateFrame("Frame")
    eventFrame:RegisterEvent("COMBAT_LOG_EVENT_UNFILTERED")
    eventFrame:RegisterEvent("PLAYER_REGEN_ENABLED")

    eventFrame:SetScript("OnEvent", function(f, event, ...)
        if event == "COMBAT_LOG_EVENT_UNFILTERED" then
            CC:OnCombatLog(...)
        elseif event == "PLAYER_REGEN_ENABLED" then
            CC:ClearActiveCCs()
        end
    end)
end

function CC:RegisterComm()
    if S.RegisterComm then
        S:RegisterComm("SEQCC", function(prefix, message, channel, sender)
            CC:OnCommReceived(prefix, message, channel, sender)
        end)
    end
end

function CC:GetDRCategory(spellId, spellName)
    if spellId and DR_SPELLS[spellId] then
        return DR_SPELLS[spellId]
    end
    if spellName then
        local clean = CleanString(spellName)
        for nameKey, category in pairs(DR_BY_NAME) do
            if clean:find(nameKey, 1, true) then
                return category
            end
        end
    end
    return nil
end

function CC:OnCombatLog(...)
    local timestamp, event, sourceGUID, sourceName, sourceFlags, destGUID, destName, destFlags, spellId, spellName = ...
    if not self:GetOption("trackDR") then return end

    if event == "SPELL_AURA_APPLIED" or event == "SPELL_AURA_REFRESH" then
        local category = self:GetDRCategory(spellId, spellName)
        if category and destGUID then
            self:OnCCApplied(destGUID, destName, spellId, spellName, sourceName, category)
        end
    elseif event == "SPELL_AURA_REMOVED" then
        local category = self:GetDRCategory(spellId, spellName)
        if category and destGUID then
            self:OnCCRemoved(destGUID, destName, spellId, spellName, category)
        end
    elseif event == "SPELL_AURA_BROKEN_SPELL" then
        local _, extraSpellId, extraSpellName = select(11, ...)
        local category = self:GetDRCategory(extraSpellId, extraSpellName)
        if category and destGUID then
            self:OnCCBroken(destGUID, destName, extraSpellId, extraSpellName, sourceName, category)
        end
    elseif event == "SPELL_AURA_BROKEN" then
        local category = self:GetDRCategory(spellId, spellName)
        if category and destGUID then
            self:OnCCBroken(destGUID, destName, spellId, spellName, sourceName, category)
        end
    elseif event == "UNIT_DIED" then
        if destGUID and self.ActiveCCs[destGUID] then
            self.ActiveCCs[destGUID] = nil
            self:UpdateDisplay()
        end
    end
end

function CC:OnCCApplied(targetGUID, targetName, spellId, spellName, casterName, category)
    self.ActiveCCs[targetGUID] = {
        spell = spellName,
        spellId = spellId,
        caster = casterName,
        startTime = GetTime(),
        category = category,
    }

    if not self.DRTracking[targetGUID] then
        self.DRTracking[targetGUID] = {}
    end

    local dr = self.DRTracking[targetGUID][category]
    local now = GetTime()

    if not dr or (not dr.isActive and now > (dr.resetTime or 0)) then
        self.DRTracking[targetGUID][category] = {
            stacks = 1,
            isActive = true,
            resetTime = 0,
        }
    else
        dr.stacks = math.min((dr.stacks or 1) + 1, 4)
        dr.isActive = true
        dr.resetTime = 0
    end

    self:UpdateDisplay()
    self:CheckAssignment(targetName, casterName, spellName)
end

function CC:OnCCRemoved(targetGUID, targetName, spellId, spellName, category)
    if self.ActiveCCs[targetGUID] and self.ActiveCCs[targetGUID].spellId == spellId then
        self.ActiveCCs[targetGUID] = nil
    end

    if self.DRTracking[targetGUID] and self.DRTracking[targetGUID][category] then
        local dr = self.DRTracking[targetGUID][category]
        dr.isActive = false
        dr.resetTime = GetTime() + self:GetResetDuration()
    end

    self:UpdateDisplay()
end

function CC:OnCCBroken(targetGUID, targetName, spellId, spellName, breakerName, category)
    self:OnCCRemoved(targetGUID, targetName, spellId, spellName, category)

    if not self:GetOption("alerts") then return end

    if S.Print then
        S:Print(string.format("|cFFFF0000¡CC ROTO!|r %s rompió %s en %s",
            breakerName or "Alguien", spellName or "CC", targetName or "Objetivo"))
    end

    if self:GetOption("playSound") then
        PlaySound("RaidWarning")
    end

    if self:GetOption("announce") then
        local channel = self:GetChannel()
        if channel then
            SendChatMessage(string.format("[Sequito] CC ROTO: %s rompió %s en %s!",
                breakerName or "Alguien", spellName or "CC", targetName or "Objetivo"), channel)
        end
    end
end

function CC:CheckAssignment(targetName, casterName, spellName)
    local assignment = self.Assignments[targetName]
    if assignment then
        if assignment.player ~= casterName then
            if S.Print then
                S:Print(string.format("|cFFFFFF00Aviso:|r %s debería hacer CC en %s, pero %s lo hizo.",
                    assignment.player, targetName, casterName))
            end
        else
            if S.Print then
                S:Print(string.format("|cFF00FF00✓|r %s -> %s (%s)", casterName, targetName, spellName))
            end
        end
    end
end

function CC:OnUpdate(elapsed)
    local now = GetTime()
    local needsUpdate = false

    for guid, categories in pairs(self.DRTracking) do
        for category, data in pairs(categories) do
            if not data.isActive and now > (data.resetTime or 0) then
                categories[category] = nil
                needsUpdate = true
            end
        end
        if not next(categories) then
            self.DRTracking[guid] = nil
        end
    end

    if needsUpdate and self.Frame:IsShown() then
        self:UpdateDisplay()
    end
end

function CC:UpdateDisplay()
    if not self.Frame or not self.Frame:IsShown() then return end

    if self:GetOption("showDROnNameplates") then
        self:UpdateNameplates()
    end

    -- Actualizar asignaciones
    local i = 1
    for target, data in pairs(self.Assignments) do
        if i <= 4 then
            self.Frame.assignRows[i]:SetText(string.format("%s -> %s (%s)",
                data.player, target, data.spell or "CC"))
            i = i + 1
        end
    end
    for j = i, 4 do
        self.Frame.assignRows[j]:SetText("")
    end

    -- Actualizar DR tracking
    i = 1
    local now = GetTime()
    for guid, categories in pairs(self.DRTracking) do
        for category, data in pairs(categories) do
            if i <= 5 then
                local drPercent = DR_REDUCTION[data.stacks] or 0
                local color = drPercent == 0 and "|cFFFF0000" or
                              drPercent <= 0.25 and "|cFFFF6600" or
                              drPercent <= 0.5 and "|cFFFFFF00" or "|cFF00FF00"
                local targetName = self:GetNameFromGUID(guid) or "Desconocido"

                if data.isActive then
                    self.Frame.drRows[i]:SetText(string.format("%s%s|r: %s (%.0f%%) - |cFFFF0000ACTIVO|r",
                        color, targetName, category, drPercent * 100))
                else
                    local timeLeft = math.max(0, (data.resetTime or 0) - now)
                    self.Frame.drRows[i]:SetText(string.format("%s%s|r: %s (%.0f%%) - %.1fs",
                        color, targetName, category, drPercent * 100, timeLeft))
                end
                i = i + 1
            end
        end
    end
    for j = i, 5 do
        self.Frame.drRows[j]:SetText("")
    end
end

-- Búsqueda de región sin asignación de tablas temporales (Ley IV)
local function GetPlateName(frame)
    if frame.seqPlateNameRegion then
        return frame.seqPlateNameRegion:GetText()
    end
    local numRegions = frame:GetNumRegions()
    for r = 1, numRegions do
        local region = select(r, frame:GetRegions())
        if region and region:GetObjectType() == "FontString" then
            frame.seqPlateNameRegion = region
            return region:GetText()
        end
    end
    return nil
end

function CC:UpdateNameplates()
    if not self:GetOption("showDROnNameplates") then return end

    local numChildren = WorldFrame:GetNumChildren()
    for i = 1, numChildren do
        local frame = select(i, WorldFrame:GetChildren())
        if frame and frame:IsShown() and frame:GetName() == nil then
            local name = GetPlateName(frame)
            if name then
                local foundDR = false
                for guid, categories in pairs(self.DRTracking) do
                    local targetName = self:GetNameFromGUID(guid)
                    if targetName == name then
                        for category, data in pairs(categories) do
                            if data.stacks > 0 then
                                self:ShowNameplateDR(frame, category, data.stacks, data.isActive)
                                foundDR = true
                                break
                            end
                        end
                    end
                    if foundDR then break end
                end

                if not foundDR and frame.seqDRIcon then
                    frame.seqDRIcon:Hide()
                    if frame.seqDRText then frame.seqDRText:Hide() end
                end
            elseif frame.seqDRIcon then
                frame.seqDRIcon:Hide()
                if frame.seqDRText then frame.seqDRText:Hide() end
            end
        end
    end
end

function CC:ShowNameplateDR(nameplate, category, stacks, isActive)
    if not nameplate.seqDRIcon then
        nameplate.seqDRIcon = nameplate:CreateTexture(nil, "OVERLAY")
        nameplate.seqDRIcon:SetSize(16, 16)
        nameplate.seqDRIcon:SetPoint("RIGHT", nameplate, "RIGHT", 20, 0)
        nameplate.seqDRIcon:SetTexture("Interface\\Icons\\Spell_Magic_LesserInvisibilty")

        nameplate.seqDRText = nameplate:CreateFontString(nil, "OVERLAY")
        nameplate.seqDRText:SetFont("Fonts\\FRIZQT__.TTF", 10, "OUTLINE")
        nameplate.seqDRText:SetPoint("CENTER", nameplate.seqDRIcon, "CENTER", 0, 0)
    end

    if stacks == 1 then
        nameplate.seqDRIcon:SetVertexColor(0, 1, 0)
    elseif stacks == 2 then
        nameplate.seqDRIcon:SetVertexColor(1, 1, 0)
    else
        nameplate.seqDRIcon:SetVertexColor(1, 0, 0)
    end

    nameplate.seqDRText:SetText(stacks)
    nameplate.seqDRIcon:Show()
    nameplate.seqDRText:Show()
end

-- Resolución de nombres por GUID compatible con WotLK 3.3.5a (Sin nameplate1..40)
function CC:GetNameFromGUID(guid)
    if not guid then return nil end

    local units = {"target", "focus", "mouseover", "targettarget", "focustarget"}
    for _, u in ipairs(units) do
        if UnitExists(u) and UnitGUID(u) == guid then
            return UnitName(u)
        end
    end

    for i = 1, 5 do
        local u = "arena" .. i
        if UnitExists(u) and UnitGUID(u) == guid then
            return UnitName(u)
        end
    end

    for i = 1, 4 do
        local u = "party" .. i
        if UnitExists(u) and UnitGUID(u) == guid then
            return UnitName(u)
        end
    end

    for i = 1, 40 do
        local u = "raid" .. i
        if UnitExists(u) and UnitGUID(u) == guid then
            return UnitName(u)
        end
    end

    return nil
end

function CC:ClearActiveCCs()
    wipe(self.ActiveCCs)
    wipe(self.DRTracking)
    self:UpdateDisplay()
end

function CC:Assign(playerName, targetName, spellName)
    self.Assignments[targetName] = {
        player = playerName,
        spell = spellName,
    }
    if S.Print then
        S:Print(string.format("CC Asignado: %s -> %s (%s)", playerName, targetName, spellName or "CC"))
    end
    self:SyncAssignment(playerName, targetName, spellName)
    self:UpdateDisplay()
end

function CC:RemoveAssignment(targetName)
    self.Assignments[targetName] = nil
    self:UpdateDisplay()
end

function CC:ClearAssignments()
    wipe(self.Assignments)
    self:UpdateDisplay()
    if S.Print then
        S:Print("Todas las asignaciones de CC han sido borradas.")
    end
end

function CC:SyncAssignment(playerName, targetName, spellName)
    local channel = self:GetChannel()
    if channel and S.SendAddonMessage then
        local message = string.format("ASSIGN:%s:%s:%s", playerName, targetName, spellName or "CC")
        S:SendAddonMessage("SEQCC", message, channel)
    end
end

function CC:OnCommReceived(prefix, message, channel, sender)
    if sender == UnitName("player") then return end
    local cmd, arg1, arg2, arg3 = strsplit(":", message)
    if cmd == "ASSIGN" then
        self.Assignments[arg2] = {
            player = arg1,
            spell = arg3,
        }
        self:UpdateDisplay()
    elseif cmd == "CLEAR" then
        wipe(self.Assignments)
        self:UpdateDisplay()
    end
end

local function CanAnnounceGroup()
    if GetNumRaidMembers() > 0 then
        return IsRaidLeader() or IsRaidOfficer()
    elseif GetNumPartyMembers() > 0 then
        return IsPartyLeader()
    end
    return true
end

function CC:AnnounceAssignments()
    local channel = self:GetChannel()
    if not channel then
        if S.Print then S:Print("No estás en un grupo.") end
        return
    end

    if not CanAnnounceGroup() then
        if S.Print then
            S:Print("Solo el líder o los asistentes de banda/grupo pueden anunciar asignaciones de CC.")
        end
        return
    end

    SendChatMessage("=== Asignaciones de CC ===", channel)
    for target, data in pairs(self.Assignments) do
        SendChatMessage(string.format("%s -> %s (%s)", data.player, target, data.spell or "CC"), channel)
    end
end

function CC:GetDRInfo(targetGUID, category)
    if self.DRTracking[targetGUID] and self.DRTracking[targetGUID][category] then
        local data = self.DRTracking[targetGUID][category]
        local timeLeft = data.isActive and self:GetResetDuration() or math.max(0, (data.resetTime or 0) - GetTime())
        local reduction = DR_REDUCTION[data.stacks] or 0
        return data.stacks, reduction, timeLeft, data.isActive
    end
    return 0, 1.0, 0, false
end

function CC:Toggle()
    if not self.Frame then return end
    if self.Frame:IsShown() then
        self.Frame:Hide()
    else
        self.Frame:Show()
        self:UpdateDisplay()
    end
end

function CC:AnnounceCC()
    self:AnnounceAssignments()
end

-- Registro en ModuleConfig
if S.ModuleConfig then
    S.ModuleConfig:RegisterModule("CCCoordinator", {
        name = "CC Coordinator",
        icon = "Interface\\Icons\\Spell_Frost_FreezingBreath",
        description = "Coordinador de Crowd Control con tracking de Diminishing Returns",
        category = "pvp",
        options = {
            { type = "checkbox", key = "enabled", label = "Habilitar CC Coordinator", default = true },
            { type = "checkbox", key = "trackDR", label = "Trackear Diminishing Returns", default = true },
            { type = "checkbox", key = "alerts", label = "Alertar CC Roto", default = true },
            { type = "checkbox", key = "announce", label = "Anunciar en Chat", default = false },
            { type = "checkbox", key = "showDROnNameplates", label = "Mostrar DR en Nameplates", default = false },
            { type = "checkbox", key = "playSound", label = "Reproducir Sonido", default = true },
            { type = "slider", key = "drResetTime", label = "Tiempo Reset DR (seg)", min = 15, max = 30, step = 1, default = 18 },
        },
    })
end

-- Inicialización
if S.RegisterModule then
    S:RegisterModule("CCCoordinator", CC)
else
    local initFrame = CreateFrame("Frame")
    initFrame:RegisterEvent("PLAYER_LOGIN")
    initFrame:SetScript("OnEvent", function()
        CC:Initialize()
    end)
end
