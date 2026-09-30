--[[
    Sequito - PullGuide.lua
    Guía de Pulls para Dungeons
    Version: 7.3.0
    
    Funcionalidades:
    - Marcar automáticamente el orden de kill (Skull, X, etc.)
    - Sugerir CCs para packs grandes
    - Detectar composición del pack
    - Comandos rápidos para el tank
]]

local addonName, S = ...
S.PullGuide = {}
local PG = S.PullGuide

-- Estado
PG.Frame = nil
PG.CurrentPack = {}
PG.MarkedTargets = {}
PG.IsVisible = false

-- Orden de marcas para kill
local KILL_ORDER = {
    8, -- Skull (primera prioridad)
    7, -- X (segunda prioridad)
    6, -- Square
    4, -- Triangle
    3, -- Diamond
}

-- Marcas para CC
local CC_MARKS = {
    5, -- Moon (Polymorph/Hex)
    2, -- Circle (Sap)
    1, -- Star (Trap)
}

-- Tipos de mobs peligrosos (prioridad alta)
local DANGEROUS_TYPES = {
    ["Healer"] = 10,
    ["Caster"] = 8,
    ["Ranged"] = 6,
    ["Elite"] = 5,
    ["Normal"] = 1,
}

-- Nombres de marcas
local MARK_NAMES = {
    [1] = "|TInterface\\TargetingFrame\\UI-RaidTargetingIcon_1:0|t Star",
    [2] = "|TInterface\\TargetingFrame\\UI-RaidTargetingIcon_2:0|t Circle",
    [3] = "|TInterface\\TargetingFrame\\UI-RaidTargetingIcon_3:0|t Diamond",
    [4] = "|TInterface\\TargetingFrame\\UI-RaidTargetingIcon_4:0|t Triangle",
    [5] = "|TInterface\\TargetingFrame\\UI-RaidTargetingIcon_5:0|t Moon",
    [6] = "|TInterface\\TargetingFrame\\UI-RaidTargetingIcon_6:0|t Square",
    [7] = "|TInterface\\TargetingFrame\\UI-RaidTargetingIcon_7:0|t Cross",
    [8] = "|TInterface\\TargetingFrame\\UI-RaidTargetingIcon_8:0|t Skull",
}

-- Spells que indican que es un healer
local HEALER_SPELLS = {
    ["Heal"] = true,
    ["Flash Heal"] = true,
    ["Greater Heal"] = true,
    ["Healing Wave"] = true,
    ["Chain Heal"] = true,
    ["Holy Light"] = true,
    ["Regrowth"] = true,
    ["Rejuvenation"] = true,
}

-- Spells que indican que es un caster
local CASTER_SPELLS = {
    ["Fireball"] = true,
    ["Frostbolt"] = true,
    ["Shadow Bolt"] = true,
    ["Lightning Bolt"] = true,
    ["Arcane Missiles"] = true,
}

-- Helper para obtener configuración
function PG:GetOption(key)
    if S.ModuleConfig then
        return S.ModuleConfig:GetValue("PullGuide", key)
    end
    return true
end

function PG:Initialize()
    if not self:GetOption("enabled") then
        return
    end
    if self.initialized then return end
    self.initialized = true
    
    self:CreateFrame()
    self:RegisterEvents()
end

function PG:GetGroupChannel()
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
    end
    return nil
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
    self.Frame:SetScript("OnDragStop", function(f) f:StopMovingOrSizing() end)
    self.Frame:Hide()
    
    -- Fondo
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
    self.Frame.packInfo:SetText("Escanea un pack con /sequito scanpack")
    self.Frame.packInfo:SetJustifyH("LEFT")
    self.Frame.packInfo:SetWidth(220)
    
    -- Lista de mobs
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
    
    -- Botones de acción
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
    
    eventFrame:SetScript("OnEvent", function(self, event, ...)
        if event == "PLAYER_TARGET_CHANGED" then
            PG:OnTargetChanged("target")
        elseif event == "UPDATE_MOUSEOVER_UNIT" then
            PG:OnTargetChanged("mouseover")
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
        eventFrame:HookScript("OnEvent", function(self, event, ...)
            if event == "COMBAT_LOG_EVENT_UNFILTERED" then
                PG:OnCombatLog(...)
            end
        end)
    end
end

function PG:OnTargetChanged(unit)
    unit = unit or "target"
    if not UnitExists(unit) then return end
    if not UnitIsEnemy("player", unit) then return end
    if UnitIsDead(unit) then return end
    
    -- Agregar al pack actual si está cerca
    local guid = UnitGUID(unit)
    local name = UnitName(unit)
    
    if not self.CurrentPack[guid] then
        self.CurrentPack[guid] = {
            name = name,
            type = self:DetectMobType(unit),
            priority = 0,
            marked = false,
        }
        self:CalculatePriority(guid)
        self:UpdateDisplay()
    end
end

function PG:OnCombatLog(...)
    local timestamp, event, sourceGUID, sourceName, sourceFlags, destGUID, destName, destFlags, spellId, spellName = ...
    
    -- Detectar tipo de mob por sus casts
    if event == "SPELL_CAST_START" or event == "SPELL_CAST_SUCCESS" then
        if bit.band(sourceFlags, COMBATLOG_OBJECT_REACTION_HOSTILE) > 0 then
            if self.CurrentPack[sourceGUID] then
                -- Actualizar tipo basado en spell
                if HEALER_SPELLS[spellName] then
                    self.CurrentPack[sourceGUID].type = "Healer"
                    self:CalculatePriority(sourceGUID)
                elseif CASTER_SPELLS[spellName] then
                    self.CurrentPack[sourceGUID].type = "Caster"
                    self:CalculatePriority(sourceGUID)
                end
            end
        end
    end
end

function PG:OnNameplateAdded(unit)
    if not UnitExists(unit) then return end
    if not UnitIsEnemy("player", unit) then return end
    if UnitIsDead(unit) then return end
    
    local guid = UnitGUID(unit)
    local name = UnitName(unit)
    
    if not self.CurrentPack[guid] then
        self.CurrentPack[guid] = {
            name = name,
            type = self:DetectMobType(unit),
            priority = 0,
            marked = false,
        }
        self:CalculatePriority(guid)
    end
end

function PG:DetectMobType(unit)
    if not UnitExists(unit) then return "Normal" end
    
    -- Verificar si es elite
    local classification = UnitClassification(unit)
    if classification == "elite" or classification == "rareelite" or classification == "worldboss" then
        return "Elite"
    end
    
    -- Verificar power type (mana = probable caster/healer)
    local powerType = UnitPowerType(unit)
    if powerType == 0 then -- Mana
        return "Caster"
    end
    
    return "Normal"
end

function PG:CalculatePriority(guid)
    local mob = self.CurrentPack[guid]
    if not mob then return end
    
    local basePriority = DANGEROUS_TYPES[mob.type] or 1
    mob.priority = basePriority
end

function PG:ScanPack()
    -- Limpiar pack actual
    wipe(self.CurrentPack)
    
    -- Escanear nameplates visibles
    for i = 1, 40 do
        local unit = "nameplate" .. i
        if UnitExists(unit) and UnitIsEnemy("player", unit) and not UnitIsDead(unit) then
            local guid = UnitGUID(unit)
            local name = UnitName(unit)
            
            self.CurrentPack[guid] = {
                name = name,
                type = self:DetectMobType(unit),
                priority = 0,
                marked = GetRaidTargetIndex(unit) ~= nil,
                unit = unit,
            }
            self:CalculatePriority(guid)
        end
    end
    
    -- También incluir target y focus
    for _, unit in ipairs({"target", "focus"}) do
        if UnitExists(unit) and UnitIsEnemy("player", unit) and not UnitIsDead(unit) then
            local guid = UnitGUID(unit)
            if not self.CurrentPack[guid] then
                local name = UnitName(unit)
                self.CurrentPack[guid] = {
                    name = name,
                    type = self:DetectMobType(unit),
                    priority = 0,
                    marked = GetRaidTargetIndex(unit) ~= nil,
                    unit = unit,
                }
                self:CalculatePriority(guid)
            end
        end
    end
    
    self:UpdateDisplay()
    
    local count = 0
    for _ in pairs(self.CurrentPack) do count = count + 1 end
    
    if S.Print then
        S:Print(string.format("Pack escaneado: %d mobs detectados.", count))
    end
end

function PG:AutoMarkPack()
    -- Verificar si autoMark está habilitado
    if not self:GetOption("autoMark") then
        if S.Print then
            S:Print("Auto-marcado deshabilitado en configuración.")
        end
        return
    end
    
    -- Ordenar mobs por prioridad
    local sorted = {}
    for guid, data in pairs(self.CurrentPack) do
        table.insert(sorted, {guid = guid, data = data})
    end
    table.sort(sorted, function(a, b)
        return a.data.priority > b.data.priority
    end)
    
    -- Asignar marcas de kill
    local killIndex = 1
    local ccIndex = 1
    local suggestCC = self:GetOption("suggestCC")
    
    for i, mob in ipairs(sorted) do
        local unit = self:FindUnitByGUID(mob.guid)
        if unit then
            if mob.data.priority >= 8 then
                -- Alta prioridad = marca de kill
                if killIndex <= #KILL_ORDER then
                    SetRaidTarget(unit, KILL_ORDER[killIndex])
                    mob.data.marked = true
                    mob.data.mark = KILL_ORDER[killIndex]
                    killIndex = killIndex + 1
                end
            elseif mob.data.priority >= 5 then
                -- Media prioridad = CC o kill secundario
                if suggestCC and ccIndex <= #CC_MARKS and self:HasCCInGroup() then
                    SetRaidTarget(unit, CC_MARKS[ccIndex])
                    mob.data.marked = true
                    mob.data.mark = CC_MARKS[ccIndex]
                    ccIndex = ccIndex + 1
                elseif killIndex <= #KILL_ORDER then
                    SetRaidTarget(unit, KILL_ORDER[killIndex])
                    mob.data.marked = true
                    mob.data.mark = KILL_ORDER[killIndex]
                    killIndex = killIndex + 1
                end
            end
        end
    end
    
    self:UpdateDisplay()
    self:AnnounceMarks()
end

function PG:FindUnitByGUID(guid)
    -- Buscar en nameplates
    for i = 1, 40 do
        local unit = "nameplate" .. i
        if UnitExists(unit) and UnitGUID(unit) == guid then
            return unit
        end
    end
    
    -- Buscar en target/focus
    if UnitExists("target") and UnitGUID("target") == guid then
        return "target"
    end
    if UnitExists("focus") and UnitGUID("focus") == guid then
        return "focus"
    end
    
    return nil
end

function PG:HasCCInGroup()
    -- Verificar si hay clases con CC en el grupo
    local ccClasses = {MAGE = true, ROGUE = true, HUNTER = true, WARLOCK = true, PRIEST = true, SHAMAN = true, DRUID = true}
    local numRaid = GetNumRaidMembers()
    local numParty = GetNumPartyMembers()
    
    if numRaid > 0 then
        for i = 1, numRaid do
            local _, class = UnitClass("raid"..i)
            if class and ccClasses[class] then
                return true
            end
        end
    elseif numParty > 0 then
        local _, playerClass = UnitClass("player")
        if playerClass and ccClasses[playerClass] then return true end
        for i = 1, numParty do
            local _, class = UnitClass("party"..i)
            if class and ccClasses[class] then
                return true
            end
        end
    else
        local _, playerClass = UnitClass("player")
        if playerClass and ccClasses[playerClass] then return true end
    end
    
    return false
end

function PG:ClearMarks()
    -- Limpiar todas las marcas del pack
    for guid, data in pairs(self.CurrentPack) do
        local unit = self:FindUnitByGUID(guid)
        if unit then
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
    self:UpdateDisplay()
    
    if S.Print then
        S:Print("Pack limpiado.")
    end
end

function PG:AnnounceMarks()
    -- Verificar si anuncios están habilitados
    if not self:GetOption("announceMarks") then
        return
    end
    
    local channel = self:GetGroupChannel()
    if not channel then return end
    
    SendChatMessage("=== Orden de Kill ===", channel)
    
    -- Ordenar por marca
    local byMark = {}
    for guid, data in pairs(self.CurrentPack) do
        if data.mark then
            byMark[data.mark] = data
        end
    end
    
    -- Anunciar en orden
    for _, markId in ipairs(KILL_ORDER) do
        if byMark[markId] then
            local markName = MARK_NAMES[markId] or tostring(markId)
            SendChatMessage(string.format("%s -> %s (%s)", 
                markName, byMark[markId].name, byMark[markId].type), channel)
        end
    end
    
    -- Anunciar CCs
    local hasCCs = false
    for _, markId in ipairs(CC_MARKS) do
        if byMark[markId] then
            if not hasCCs then
                SendChatMessage("=== CC ===", channel)
                hasCCs = true
            end
            local markName = MARK_NAMES[markId] or tostring(markId)
            SendChatMessage(string.format("%s -> %s (CC)", 
                markName, byMark[markId].name), channel)
        end
    end
end

function PG:UpdateDisplay()
    if not self.Frame:IsShown() then return end
    
    -- Contar mobs
    local count = 0
    local healers = 0
    local casters = 0
    local elites = 0
    
    for guid, data in pairs(self.CurrentPack) do
        count = count + 1
        if data.type == "Healer" then healers = healers + 1 end
        if data.type == "Caster" then casters = casters + 1 end
        if data.type == "Elite" then elites = elites + 1 end
    end
    
    self.Frame.packInfo:SetText(string.format(
        "Pack: %d mobs\nHealers: %d | Casters: %d | Elites: %d",
        count, healers, casters, elites
    ))
    
    -- Ordenar y mostrar mobs
    local sorted = {}
    for guid, data in pairs(self.CurrentPack) do
        table.insert(sorted, {guid = guid, data = data})
    end
    table.sort(sorted, function(a, b)
        return a.data.priority > b.data.priority
    end)
    
    for i, row in ipairs(self.Frame.mobRows) do
        if sorted[i] then
            local mob = sorted[i].data
            local markStr = mob.mark and MARK_NAMES[mob.mark] or ""
            local typeColor = mob.type == "Healer" and "|cFF00FF00" or
                              mob.type == "Caster" and "|cFFFF6600" or
                              mob.type == "Elite" and "|cFFFF00FF" or "|cFFFFFFFF"
            
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

-- Wrapper method for Bindings.xml keybinds
function PG:MarkPack()
    self:AutoMarkPack()
end

-- Marcar target actual con marca específica
function PG:MarkTarget(markId)
    if not UnitExists("target") then
        if S.Print then
            S:Print("No tienes un objetivo.")
        end
        return
    end
    
    SetRaidTarget("target", markId)
    
    if S.Print then
        local markName = MARK_NAMES[markId] or tostring(markId)
        S:Print(string.format("Marcado: %s -> %s", UnitName("target"), markName))
    end
end

-- Registrar configuración en ModuleConfig
if S.ModuleConfig then
    S.ModuleConfig:RegisterModule("PullGuide", {
        name = "Pull Guide",
        icon = "Interface\\Icons\\Ability_Hunter_MasterMarksman",
        description = "Guía automática de pulls con marcado y sugerencias de CC",
        category = "dungeon",
        options = {
            {
                type = "checkbox",
                key = "enabled",
                label = "Habilitar Pull Guide",
                tooltip = "Activa/desactiva la guía de pulls",
                default = true,
            },
            {
                type = "checkbox",
                key = "autoMark",
                label = "Marcado Automático",
                tooltip = "Marca automáticamente los enemigos en orden de prioridad",
                default = false,
            },
            {
                type = "checkbox",
                key = "suggestCC",
                label = "Sugerir CC",
                tooltip = "Sugiere qué enemigos deberían ser CC'd",
                default = true,
            },
            {
                type = "checkbox",
                key = "announceMarks",
                label = "Anunciar Marcas",
                tooltip = "Anuncia el orden de kill al grupo",
                default = true,
            },
            {
                type = "checkbox",
                key = "prioritizeHealers",
                label = "Priorizar Healers",
                tooltip = "Marca healers con prioridad alta automáticamente",
                default = true,
            },
            {
                type = "checkbox",
                key = "prioritizeCasters",
                label = "Priorizar Casters",
                tooltip = "Marca casters con prioridad alta",
                default = true,
            },
            {
                type = "slider",
                key = "minPackSize",
                label = "Tamaño Mínimo Pack",
                tooltip = "Número mínimo de enemigos para activar sugerencias",
                min = 2,
                max = 10,
                step = 1,
                default = 3,
            },
        },
    })
end

-- Inicializar
if S.RegisterModule then
    S:RegisterModule("PullGuide", PG)
else
    local initFrame = CreateFrame("Frame")
    initFrame:RegisterEvent("PLAYER_LOGIN")
    initFrame:SetScript("OnEvent", function()
        PG:Initialize()
    end)
end
