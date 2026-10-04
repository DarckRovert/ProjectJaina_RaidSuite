--[[
    Sequito - PullGuide.lua
    Guía de Pulls y Marcado Táctico para Mazmorras y Bandas
    Version: 8.0.0
    Compatibilidad: WotLK 3.3.5a (Build 12340) | Español (esES/esMX) & Inglés (enUS)
]]

local addonName, S = ...
S.PullGuide = {}
local PG = S.PullGuide

-- Estado
PG.Frame = nil
PG.CurrentPack = {}  -- {guid = {name, type, priority, marked, mark, unit}}
PG.IsVisible = false

-- Orden de marcas de kill
local KILL_ORDER = {
    8, -- Skull (1ra prioridad)
    7, -- Cross (2da prioridad)
    6, -- Square
    4, -- Triangle
    3, -- Diamond
}

-- Marcas de CC
local CC_MARKS = {
    5, -- Moon (Polymorph / Hex)
    2, -- Circle (Sap)
    1, -- Star (Trap / Repentance)
}

-- Prioridades de mobs
local DANGEROUS_TYPES = {
    ["Healer"] = 10,
    ["Caster"] = 8,
    ["Ranged"] = 6,
    ["Elite"]  = 5,
    ["Normal"] = 1,
}

-- Nombres de marcas para la Interfaz (UI FontStrings)
local MARK_NAMES = {
    [1] = "|TInterface\\TargetingFrame\\UI-RaidTargetingIcon_1:0|t Estrella",
    [2] = "|TInterface\\TargetingFrame\\UI-RaidTargetingIcon_2:0|t Círculo",
    [3] = "|TInterface\\TargetingFrame\\UI-RaidTargetingIcon_3:0|t Diamante",
    [4] = "|TInterface\\TargetingFrame\\UI-RaidTargetingIcon_4:0|t Triángulo",
    [5] = "|TInterface\\TargetingFrame\\UI-RaidTargetingIcon_5:0|t Luna",
    [6] = "|TInterface\\TargetingFrame\\UI-RaidTargetingIcon_6:0|t Cuadrado",
    [7] = "|TInterface\\TargetingFrame\\UI-RaidTargetingIcon_7:0|t Cruz",
    [8] = "|TInterface\\TargetingFrame\\UI-RaidTargetingIcon_8:0|t Calavera",
}

-- Tokens canónicos para canales de Chat de WoW 3.3.5a
local CHAT_MARK_TOKENS = {
    [1] = "{star}",
    [2] = "{circle}",
    [3] = "{diamond}",
    [4] = "{triangle}",
    [5] = "{moon}",
    [6] = "{square}",
    [7] = "{cross}",
    [8] = "{skull}",
}

-- Catálogo Bilingüe de Hechizos (Inglés y Español)
local HEALER_SPELLS = {
    -- Español
    ["sanacion"] = true, ["sanacion relampago"] = true, ["sanacion superior"] = true,
    ["ola de sanacion"] = true, ["ola de sanacion inferior"] = true, ["sanacion en cadena"] = true,
    ["luz sagrada"] = true, ["destello de luz"] = true, ["recrecimiento"] = true,
    ["rejuvenecimiento"] = true, ["toque de sanacion"] = true, ["penitencia"] = true,
    ["circulo de sanacion"] = true, ["crecimiento salvaje"] = true, ["rezo de sanacion"] = true,
    -- Inglés
    ["heal"] = true, ["flash heal"] = true, ["greater heal"] = true,
    ["healing wave"] = true, ["lesser healing wave"] = true, ["chain heal"] = true,
    ["holy light"] = true, ["flash of light"] = true, ["regrowth"] = true,
    ["rejuvenation"] = true, ["healing touch"] = true, ["penance"] = true,
    ["circle of healing"] = true, ["wild growth"] = true, ["prayer of healing"] = true,
}

local CASTER_SPELLS = {
    -- Español
    ["bola de fuego"] = true, ["descarga de escarcha"] = true, ["descarga de las sombras"] = true,
    ["descarga de relampagos"] = true, ["cadena de relampagos"] = true, ["misiles arcanos"] = true,
    ["castigo"] = true, ["tortura mental"] = true, ["incinerar"] = true, ["colera"] = true,
    ["fuego estelar"] = true, ["rafaga de lava"] = true, ["piroexplosion"] = true,
    -- Inglés
    ["fireball"] = true, ["frostbolt"] = true, ["shadow bolt"] = true,
    ["lightning bolt"] = true, ["chain lightning"] = true, ["arcane missiles"] = true,
    ["smite"] = true, ["mind flay"] = true, ["incinerate"] = true, ["wrath"] = true,
    ["starfire"] = true, ["lava burst"] = true, ["pyroblast"] = true,
}

-- Función utilitaria para normalizar texto
local function CleanString(str)
    if not str then return "" end
    local s = str:lower()
    s = s:gsub("á", "a"):gsub("é", "e"):gsub("í", "i"):gsub("ó", "o"):gsub("ú", "u"):gsub("ñ", "n")
    return s
end

-- Búfer estático de ordenamiento reutilizable (Cero Heap Thrashing Ley IV)
local sortedBuffer = {}
local function ComparePriority(a, b)
    return (a.data.priority or 0) > (b.data.priority or 0)
end

function PG:GetOption(key)
    if S.ModuleConfig then
        return S.ModuleConfig:GetValue("PullGuide", key)
    end
    return true
end

function PG:Initialize()
    if not self:GetOption("enabled") then return end
    if self.initialized then return end
    self.initialized = true

    self:CreateFrame()
    self:RegisterEvents()

    if S.SmartDefaults then
        S.SmartDefaults:RestorePosition("PullGuide")
    end
end

function PG:GetGroupChannel()
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

function PG:CanMarkTargets()
    if GetNumRaidMembers() > 0 then
        return (IsRaidLeader() or IsRaidOfficer()) and true or false
    elseif GetNumPartyMembers() > 0 then
        return IsPartyLeader() and true or false
    end
    return true
end

function PG:CreateFrame()
    self.Frame = CreateFrame("Frame", "SequitoPullGuideFrame", UIParent)
    self.Frame:SetSize(250, 200)
    self.Frame:SetPoint("RIGHT", UIParent, "RIGHT", -20, 0)
    self.Frame:SetFrameStrata("HIGH")
    self.Frame:SetMovable(true)
    self.Frame:EnableMouse(true)
    self.Frame:RegisterForDrag("LeftButton")
    self.Frame:SetScript("OnDragStart", function(f) f:StartMoving() end)
    self.Frame:SetScript("OnDragStop", function(f)
        f:StopMovingOrSizing()
        if S.SmartDefaults then
            S.SmartDefaults:SavePosition("PullGuide", f)
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
    self.Frame.border:SetBackdropBorderColor(0.8, 0.6, 0.2, 1)

    -- Título
    self.Frame.title = self.Frame:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
    self.Frame.title:SetPoint("TOP", self.Frame, "TOP", 0, -10)
    self.Frame.title:SetText("|cFFCC9900Pull Guide|r")

    -- Botón cerrar
    self.Frame.closeBtn = CreateFrame("Button", nil, self.Frame, "UIPanelCloseButton")
    self.Frame.closeBtn:SetPoint("TOPRIGHT", self.Frame, "TOPRIGHT", -2, -2)
    self.Frame.closeBtn:SetScript("OnClick", function() self.Frame:Hide() end)

    -- Info del pack
    self.Frame.packInfo = self.Frame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    self.Frame.packInfo:SetPoint("TOPLEFT", self.Frame, "TOPLEFT", 15, -35)
    self.Frame.packInfo:SetText("Escanea un pack con Auto-Marcar")
    self.Frame.packInfo:SetJustifyH("LEFT")
    self.Frame.packInfo:SetWidth(220)

    -- Lista de mobs (pool fijo de 5 ranuras reciclables)
    self.Frame.mobList = CreateFrame("Frame", nil, self.Frame)
    self.Frame.mobList:SetSize(220, 100)
    self.Frame.mobList:SetPoint("TOPLEFT", self.Frame.packInfo, "BOTTOMLEFT", 0, -10)
    self.Frame.mobRows = {}

    for i = 1, 5 do
        local row = self.Frame.mobList:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
        row:SetPoint("TOPLEFT", self.Frame.mobList, "TOPLEFT", 0, -(i-1) * 16)
        row:SetJustifyH("LEFT")
        row:SetWidth(220)
        self.Frame.mobRows[i] = row
    end

    self:CreateActionButtons()
end

function PG:CreateActionButtons()
    -- Botón Auto-Mark
    local autoMarkBtn = CreateFrame("Button", nil, self.Frame)
    autoMarkBtn:SetSize(100, 24)
    autoMarkBtn:SetPoint("BOTTOMLEFT", self.Frame, "BOTTOMLEFT", 15, 15)

    autoMarkBtn.bg = autoMarkBtn:CreateTexture(nil, "BACKGROUND")
    autoMarkBtn.bg:SetAllPoints()
    autoMarkBtn.bg:SetTexture("Interface\\Buttons\\WHITE8X8")
    autoMarkBtn.bg:SetVertexColor(0.2, 0.4, 0.2, 0.8)

    autoMarkBtn.text = autoMarkBtn:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    autoMarkBtn.text:SetPoint("CENTER")
    autoMarkBtn.text:SetText("Auto-Marcar")

    autoMarkBtn:SetHighlightTexture("Interface\\Buttons\\UI-Listbox-Highlight")
    autoMarkBtn:SetScript("OnClick", function() PG:AutoMarkPack() end)
    self.Frame.autoMarkBtn = autoMarkBtn

    -- Botón Clear Marks
    local clearBtn = CreateFrame("Button", nil, self.Frame)
    clearBtn:SetSize(100, 24)
    clearBtn:SetPoint("BOTTOMRIGHT", self.Frame, "BOTTOMRIGHT", -15, 15)

    clearBtn.bg = clearBtn:CreateTexture(nil, "BACKGROUND")
    clearBtn.bg:SetAllPoints()
    clearBtn.bg:SetTexture("Interface\\Buttons\\WHITE8X8")
    clearBtn.bg:SetVertexColor(0.4, 0.2, 0.2, 0.8)

    clearBtn.text = clearBtn:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    clearBtn.text:SetPoint("CENTER")
    clearBtn.text:SetText("Limpiar")

    clearBtn:SetHighlightTexture("Interface\\Buttons\\UI-Listbox-Highlight")
    clearBtn:SetScript("OnClick", function() PG:ClearMarks() end)
    self.Frame.clearBtn = clearBtn
end

function PG:RegisterEvents()
    local eventFrame = CreateFrame("Frame")
    eventFrame:RegisterEvent("PLAYER_TARGET_CHANGED")
    eventFrame:RegisterEvent("UPDATE_MOUSEOVER_UNIT")
    eventFrame:RegisterEvent("PLAYER_REGEN_ENABLED")

    eventFrame:SetScript("OnEvent", function(f, event, ...)
        if event == "PLAYER_TARGET_CHANGED" then
            PG:RegisterUnitIfHostile("target")
        elseif event == "UPDATE_MOUSEOVER_UNIT" then
            PG:RegisterUnitIfHostile("mouseover")
        elseif event == "PLAYER_REGEN_ENABLED" then
            -- Opcional fuera de combate
        end
    end)

    if S.CLEU and S.CLEU.Register then
        local function onCast(...)
            PG:OnCombatLog(...)
        end
        S.CLEU:Register("SPELL_CAST_START", onCast)
        S.CLEU:Register("SPELL_CAST_SUCCESS", onCast)
    else
        eventFrame:RegisterEvent("COMBAT_LOG_EVENT_UNFILTERED")
        eventFrame:HookScript("OnEvent", function(f, event, ...)
            if event == "COMBAT_LOG_EVENT_UNFILTERED" then
                PG:OnCombatLog(...)
            end
        end)
    end
end

function PG:RegisterUnitIfHostile(unit)
    if not UnitExists(unit) or not UnitIsEnemy("player", unit) or UnitIsDead(unit) then return end

    local guid = UnitGUID(unit)
    local name = UnitName(unit)
    if not guid then return end

    if not self.CurrentPack[guid] then
        self.CurrentPack[guid] = {
            name = name,
            type = self:DetectMobType(unit),
            priority = 0,
            marked = (GetRaidTargetIndex(unit) ~= nil),
            mark = GetRaidTargetIndex(unit),
            unit = unit,
        }
        self:CalculatePriority(guid)
        self:UpdateDisplay()
    else
        self.CurrentPack[guid].unit = unit
        self.CurrentPack[guid].marked = (GetRaidTargetIndex(unit) ~= nil)
        self.CurrentPack[guid].mark = GetRaidTargetIndex(unit)
    end
end

function PG:OnCombatLog(...)
    local timestamp, event, sourceGUID, sourceName, sourceFlags, destGUID, destName, destFlags, spellId, spellName = ...
    if not sourceGUID or not sourceFlags then return end

    if event == "SPELL_CAST_START" or event == "SPELL_CAST_SUCCESS" then
        if bit.band(sourceFlags, COMBATLOG_OBJECT_REACTION_HOSTILE) > 0 then
            if self.CurrentPack[sourceGUID] and spellName then
                local cleanName = CleanString(spellName)
                if HEALER_SPELLS[cleanName] then
                    self.CurrentPack[sourceGUID].type = "Healer"
                    self:CalculatePriority(sourceGUID)
                    self:UpdateDisplay()
                elseif CASTER_SPELLS[cleanName] then
                    self.CurrentPack[sourceGUID].type = "Caster"
                    self:CalculatePriority(sourceGUID)
                    self:UpdateDisplay()
                end
            end
        end
    end
end

function PG:DetectMobType(unit)
    if not UnitExists(unit) then return "Normal" end

    local classification = UnitClassification(unit)
    if classification == "elite" or classification == "rareelite" or classification == "worldboss" then
        return "Elite"
    end

    local powerType = UnitPowerType(unit)
    if powerType == 0 then
        return "Caster"
    end

    return "Normal"
end

function PG:CalculatePriority(guid)
    local mob = self.CurrentPack[guid]
    if not mob then return end

    local basePriority = DANGEROUS_TYPES[mob.type] or 1
    if mob.type == "Healer" and self:GetOption("prioritizeHealers") then
        basePriority = 10
    elseif mob.type == "Caster" and self:GetOption("prioritizeCasters") then
        basePriority = 8
    end
    mob.priority = basePriority
end

-- Sondeo canónico de unidades de WotLK 3.3.5a (Sin nameplate1..40)
function PG:ScanPack()
    wipe(self.CurrentPack)

    local unitsToScan = {
        "target", "focus", "mouseover", "targettarget", "focustarget", "mouseovertarget"
    }

    local numParty = GetNumPartyMembers()
    if numParty > 0 then
        for i = 1, numParty do
            table.insert(unitsToScan, "party" .. i .. "target")
            table.insert(unitsToScan, "partypet" .. i .. "target")
        end
    end

    local numRaid = GetNumRaidMembers()
    if numRaid > 0 then
        for i = 1, numRaid do
            table.insert(unitsToScan, "raid" .. i .. "target")
        end
    end

    for _, unit in ipairs(unitsToScan) do
        self:RegisterUnitIfHostile(unit)
    end

    self:UpdateDisplay()

    local count = 0
    for _ in pairs(self.CurrentPack) do count = count + 1 end

    if S.Print then
        S:Print(string.format("Pack escaneado: %d enemigos detectados.", count))
    end
end

function PG:FindUnitByGUID(guid)
    if not guid then return nil end

    local candidates = {
        "target", "focus", "mouseover", "targettarget", "focustarget", "mouseovertarget"
    }

    local numParty = GetNumPartyMembers()
    if numParty > 0 then
        for i = 1, numParty do
            table.insert(candidates, "party" .. i .. "target")
        end
    end

    local numRaid = GetNumRaidMembers()
    if numRaid > 0 then
        for i = 1, numRaid do
            table.insert(candidates, "raid" .. i .. "target")
        end
    end

    for _, u in ipairs(candidates) do
        if UnitExists(u) and UnitGUID(u) == guid then
            return u
        end
    end

    return nil
end

function PG:AutoMarkPack()
    if not self:CanMarkTargets() then
        if S.Print then
            S:Print("|cFFFF0000Aviso:|r Se requieren permisos de líder o asistente de banda para marcar.")
        end
        return
    end

    self:ScanPack()

    wipe(sortedBuffer)
    for guid, data in pairs(self.CurrentPack) do
        table.insert(sortedBuffer, {guid = guid, data = data})
    end
    table.sort(sortedBuffer, ComparePriority)

    local killIndex = 1
    local ccIndex = 1
    local suggestCC = self:GetOption("suggestCC")
    local hasCC = self:HasCCInGroup()

    for _, item in ipairs(sortedBuffer) do
        local mob = item.data
        local unit = self:FindUnitByGUID(item.guid) or mob.unit

        if unit and UnitExists(unit) and UnitGUID(unit) == item.guid then
            if mob.priority >= 8 then
                if killIndex <= #KILL_ORDER then
                    SetRaidTarget(unit, KILL_ORDER[killIndex])
                    mob.marked = true
                    mob.mark = KILL_ORDER[killIndex]
                    killIndex = killIndex + 1
                end
            elseif mob.priority >= 5 then
                if suggestCC and ccIndex <= #CC_MARKS and hasCC then
                    SetRaidTarget(unit, CC_MARKS[ccIndex])
                    mob.marked = true
                    mob.mark = CC_MARKS[ccIndex]
                    ccIndex = ccIndex + 1
                elseif killIndex <= #KILL_ORDER then
                    SetRaidTarget(unit, KILL_ORDER[killIndex])
                    mob.marked = true
                    mob.mark = KILL_ORDER[killIndex]
                    killIndex = killIndex + 1
                end
            end
        end
    end

    self:UpdateDisplay()
    self:AnnounceMarks()
end

function PG:HasCCInGroup()
    local ccClasses = {
        MAGE = true, ROGUE = true, HUNTER = true,
        WARLOCK = true, PRIEST = true, SHAMAN = true, DRUID = true
    }

    local numRaid = GetNumRaidMembers()
    if numRaid > 0 then
        for i = 1, numRaid do
            local _, class = UnitClass("raid" .. i)
            if class and ccClasses[class] then return true end
        end
    else
        local _, playerClass = UnitClass("player")
        if playerClass and ccClasses[playerClass] then return true end
        local numParty = GetNumPartyMembers()
        for i = 1, numParty do
            local _, class = UnitClass("party" .. i)
            if class and ccClasses[class] then return true end
        end
    end

    return false
end

function PG:ClearMarks()
    if not self:CanMarkTargets() then
        if S.Print then
            S:Print("|cFFFF0000Aviso:|r Se requieren permisos de líder para limpiar marcas.")
        end
        return
    end

    for guid, data in pairs(self.CurrentPack) do
        local unit = self:FindUnitByGUID(guid) or data.unit
        if unit and UnitExists(unit) then
            SetRaidTarget(unit, 0)
        end
        data.marked = false
        data.mark = nil
    end

    self:UpdateDisplay()
    if S.Print then
        S:Print("Marcas limpiadas.")
    end
end

function PG:ClearPack()
    wipe(self.CurrentPack)
    wipe(sortedBuffer)
    self:UpdateDisplay()
    if S.Print then
        S:Print("Pack limpiado.")
    end
end

function PG:AnnounceMarks()
    if not self:GetOption("announceMarks") then return end

    local channel = self:GetGroupChannel()
    if not channel then return end

    local byMark = {}
    for guid, data in pairs(self.CurrentPack) do
        if data.mark then
            byMark[data.mark] = data
        end
    end

    if not next(byMark) then return end

    SendChatMessage("=== Orden de Kill ===", channel)
    for _, markId in ipairs(KILL_ORDER) do
        if byMark[markId] then
            local token = CHAT_MARK_TOKENS[markId] or string.format("{rt%d}", markId)
            SendChatMessage(string.format("%s -> %s (%s)",
                token, byMark[markId].name, byMark[markId].type), channel)
        end
    end

    local hasCCs = false
    for _, markId in ipairs(CC_MARKS) do
        if byMark[markId] then
            if not hasCCs then
                SendChatMessage("=== CC ===", channel)
                hasCCs = true
            end
            local token = CHAT_MARK_TOKENS[markId] or string.format("{rt%d}", markId)
            SendChatMessage(string.format("%s -> %s (CC)",
                token, byMark[markId].name), channel)
        end
    end
end

function PG:UpdateDisplay()
    if not self.Frame or not self.Frame:IsShown() then return end

    local count, healers, casters, elites = 0, 0, 0, 0
    for guid, data in pairs(self.CurrentPack) do
        count = count + 1
        if data.type == "Healer" then healers = healers + 1 end
        if data.type == "Caster" then casters = casters + 1 end
        if data.type == "Elite"  then elites = elites + 1 end
    end

    self.Frame.packInfo:SetText(string.format(
        "Pack: %d mobs\nHealers: %d | Casters: %d | Elites: %d",
        count, healers, casters, elites
    ))

    wipe(sortedBuffer)
    for guid, data in pairs(self.CurrentPack) do
        table.insert(sortedBuffer, {guid = guid, data = data})
    end
    table.sort(sortedBuffer, ComparePriority)

    for i, row in ipairs(self.Frame.mobRows) do
        if sortedBuffer[i] then
            local mob = sortedBuffer[i].data
            local markStr = mob.mark and MARK_NAMES[mob.mark] or ""
            local typeColor = mob.type == "Healer" and "|cFF00FF00" or
                              mob.type == "Caster" and "|cFFFF6600" or
                              mob.type == "Elite"  and "|cFFFF00FF" or "|cFFFFFFFF"

            row:SetText(string.format("%s %s%s|r (%s)",
                markStr, typeColor, mob.name, mob.type))
        else
            row:SetText("")
        end
    end
end

function PG:Toggle()
    if not self.Frame then return end
    if self.Frame:IsShown() then
        self.Frame:Hide()
    else
        self.Frame:Show()
        self:UpdateDisplay()
    end
end

function PG:MarkPack()
    self:AutoMarkPack()
end

function PG:MarkTarget(markId)
    if not UnitExists("target") then
        if S.Print then S:Print("No tienes un objetivo.") end
        return
    end

    if not self:CanMarkTargets() then
        if S.Print then
            S:Print("|cFFFF0000Aviso:|r Se requieren permisos de líder para marcar objetivos.")
        end
        return
    end

    SetRaidTarget("target", markId)

    if S.Print then
        local markName = MARK_NAMES[markId] or tostring(markId)
        S:Print(string.format("Marcado: %s -> %s", UnitName("target"), markName))
    end
end

-- Registro en ModuleConfig
if S.ModuleConfig then
    S.ModuleConfig:RegisterModule("PullGuide", {
        name = "Pull Guide",
        icon = "Interface\\Icons\\Ability_Hunter_MasterMarksman",
        description = "Guía automática de pulls con marcado y sugerencias de CC en mazmorras y bandas",
        category = "dungeon",
        options = {
            { type = "checkbox", key = "enabled", label = "Habilitar Pull Guide", default = true },
            { type = "checkbox", key = "autoMark", label = "Marcado Automático", default = false },
            { type = "checkbox", key = "suggestCC", label = "Sugerir CC", default = true },
            { type = "checkbox", key = "announceMarks", label = "Anunciar Marcas", default = true },
            { type = "checkbox", key = "prioritizeHealers", label = "Priorizar Healers", default = true },
            { type = "checkbox", key = "prioritizeCasters", label = "Priorizar Casters", default = true },
            { type = "slider", key = "minPackSize", label = "Tamaño Mínimo Pack", min = 2, max = 10, step = 1, default = 3 },
        },
    })
end

-- Inicialización
if S.RegisterModule then
    S:RegisterModule("PullGuide", PG)
else
    local initFrame = CreateFrame("Frame")
    initFrame:RegisterEvent("PLAYER_LOGIN")
    initFrame:SetScript("OnEvent", function()
        PG:Initialize()
    end)
end
