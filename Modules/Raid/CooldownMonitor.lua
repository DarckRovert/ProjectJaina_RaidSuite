--[[
    Sequito - CooldownMonitor.lua
    Monitor de Cooldowns del Raid en tiempo real
    Version: 7.2.0
]]

local addonName, S = ...
S.CooldownMonitor = {}
local CM = S.CooldownMonitor
local L = S.L or {}

-- Cooldowns importantes a trackear por clase
local TrackedCooldowns = {
    -- Resurrecciones de combate
    DRUID = {
        {spellId = 48477, name = "Rebirth", duration = 600, icon = "Interface\\Icons\\Spell_Nature_Reincarnation", type = "bres"},
        {spellId = 29166, name = "Innervate", duration = 180, icon = "Interface\\Icons\\Spell_Nature_Lightning", type = "mana"},
        {spellId = 48447, name = "Tranquility", duration = 480, icon = "Interface\\Icons\\Spell_Nature_Tranquility", type = "raid_cd"},
        {spellId = 22812, name = "Barkskin", duration = 60, icon = "Interface\\Icons\\Spell_Nature_StoneClawTotem", type = "tank_cd"},
        {spellId = 61336, name = "Survival Instincts", duration = 180, icon = "Interface\\Icons\\Ability_Druid_SurvivalInstincts", type = "tank_cd"},
    },
    WARLOCK = {
        {spellId = 47883, name = "Soulstone Resurrection", duration = 900, icon = "Interface\\Icons\\Spell_Shadow_SoulGem", type = "bres"},
    },
    -- Heroism/Bloodlust
    SHAMAN = {
        {spellId = 32182, name = "Heroism", duration = 300, icon = "Interface\\Icons\\Ability_Shaman_Heroism", type = "lust", faction = "Alliance"},
        {spellId = 2825, name = "Bloodlust", duration = 300, icon = "Interface\\Icons\\Spell_Nature_Bloodlust", type = "lust", faction = "Horde"},
        {spellId = 20608, name = "Reincarnation", duration = 1800, icon = "Interface\\Icons\\Spell_Nature_Reincarnation", type = "selfres"},
    },
    -- Cooldowns defensivos de raid
    PALADIN = {
        {spellId = 64205, name = "Divine Sacrifice", duration = 120, icon = "Interface\\Icons\\Spell_Holy_DivineIntervention", type = "raid_cd"},
        {spellId = 31821, name = "Aura Mastery", duration = 120, icon = "Interface\\Icons\\Spell_Holy_AuraMastery", type = "raid_cd"},
        {spellId = 6940, name = "Hand of Sacrifice", duration = 120, icon = "Interface\\Icons\\Spell_Holy_SealOfSacrifice", type = "external"},
        {spellId = 10278, name = "Hand of Protection", duration = 300, icon = "Interface\\Icons\\Spell_Holy_SealOfProtection", type = "external"},
        {spellId = 1038, name = "Hand of Salvation", duration = 120, icon = "Interface\\Icons\\Spell_Holy_SealOfSalvation", type = "utility"},
        {spellId = 19752, name = "Divine Intervention", duration = 600, icon = "Interface\\Icons\\Spell_Nature_TimeStop", type = "emergency"},
    },
    PRIEST = {
        {spellId = 47788, name = "Guardian Spirit", duration = 180, icon = "Interface\\Icons\\Spell_Holy_GuardianSpirit", type = "external"},
        {spellId = 33206, name = "Pain Suppression", duration = 180, icon = "Interface\\Icons\\Spell_Holy_PainSupression", type = "external"},
        {spellId = 64843, name = "Divine Hymn", duration = 480, icon = "Interface\\Icons\\Spell_Holy_DivineHymn", type = "raid_cd"},
        {spellId = 64901, name = "Hymn of Hope", duration = 360, icon = "Interface\\Icons\\Spell_Holy_SymbolOfHope", type = "mana"},
    },
    DEATHKNIGHT = {
        {spellId = 51052, name = "Anti-Magic Zone", duration = 120, icon = "Interface\\Icons\\Spell_DeathKnight_AntiMagicZone", type = "raid_cd"},
        {spellId = 49016, name = "Hysteria", duration = 180, icon = "Interface\\Icons\\Spell_Shadow_UnholyFrenzy", type = "buff"},
    },
    WARRIOR = {
        {spellId = 64382, name = "Shattering Throw", duration = 300, icon = "Interface\\Icons\\Ability_Warrior_ShatteringThrow", type = "utility"},
        {spellId = 871, name = "Shield Wall", duration = 300, icon = "Interface\\Icons\\Ability_Warrior_ShieldWall", type = "tank_cd"},
        {spellId = 12975, name = "Last Stand", duration = 180, icon = "Interface\\Icons\\Spell_Holy_AshesToAshes", type = "tank_cd"},
    },
    MAGE = {
        {spellId = 45438, name = "Ice Block", duration = 300, icon = "Interface\\Icons\\Spell_Frost_Frost", type = "immunity"},
        {spellId = 66, name = "Invisibility", duration = 180, icon = "Interface\\Icons\\Ability_Mage_Invisibility", type = "utility"},
    },
    HUNTER = {
        {spellId = 34477, name = "Misdirection", duration = 30, icon = "Interface\\Icons\\Ability_Hunter_Misdirection", type = "utility"},
        {spellId = 5384, name = "Feign Death", duration = 30, icon = "Interface\\Icons\\Ability_Rogue_FeignDeath", type = "utility"},
    },
    ROGUE = {
        {spellId = 57934, name = "Tricks of the Trade", duration = 30, icon = "Interface\\Icons\\Ability_Rogue_TricksOfTheTrade", type = "utility"},
        {spellId = 31224, name = "Cloak of Shadows", duration = 90, icon = "Interface\\Icons\\Spell_Shadow_NetherCloak", type = "immunity"},
        {spellId = 26889, name = "Vanish", duration = 180, icon = "Interface\\Icons\\Ability_Vanish", type = "utility"},
    },
}

-- Estado de cooldowns del raid
CM.RaidCooldowns = {}
CM.Frame = nil
CM.Rows = {}
CM.IsVisible = false
CM.Filter = "all" -- all, bres, lust, raid_cd, external, tank_cd

-- Colores por tipo
local TypeColors = {
    bres = {0.2, 0.8, 0.2},      -- Verde
    lust = {1.0, 0.5, 0.0},      -- Naranja
    raid_cd = {0.0, 0.7, 1.0},   -- Azul claro
    external = {1.0, 1.0, 0.0},  -- Amarillo
    tank_cd = {0.6, 0.3, 0.0},   -- Marrón
    utility = {0.7, 0.7, 0.7},   -- Gris
    immunity = {1.0, 1.0, 1.0},  -- Blanco
    mana = {0.0, 0.4, 1.0},      -- Azul
    buff = {0.8, 0.0, 0.8},      -- Púrpura
    selfres = {0.2, 0.8, 0.2},   -- Verde
    emergency = {1.0, 0.0, 0.0}, -- Rojo
}

-- Helper para obtener configuración
function CM:GetOption(key)
    if S.ModuleConfig then
        return S.ModuleConfig:GetValue("CooldownMonitor", key)
    end
    return true
end

function CM:Initialize()
    if not self:GetOption("enabled") then
        return
    end
    
    -- Establecer filtro por defecto desde configuración
    self.Filter = self:GetOption("defaultFilter") or "all"
    
    self:CreateFrame()
    self:RegisterEvents()
    self:ScanRaid()
end

function CM:GetGroupChannel()
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

function CM:CreateFrame()
    if self.Frame then return end
    
    local f = CreateFrame("Frame", "SequitoCooldownMonitor", UIParent)
    f:SetSize(280, 400) -- Más alto para ver más barras
    f:SetPoint("TOPLEFT", UIParent, "TOPLEFT", 100, -200)
    f:SetFrameStrata("HIGH") -- Ensure visibility
    
    -- Fondo elegante
    local bg = f:CreateTexture(nil, "BACKGROUND")
    bg:SetAllPoints()
    bg:SetTexture("Interface\\Buttons\\WHITE8X8")
    bg:SetVertexColor(0, 0, 0, 0.8)
    f.bg = bg
    
    -- Borde fino
    local border = CreateFrame("Frame", nil, f)
    border:SetAllPoints()
    border:SetBackdrop({
        edgeFile = "Interface\\Buttons\\WHITE8x8",
        edgeSize = 1,
    })
    border:SetBackdropBorderColor(0.3, 0.3, 0.3, 1)
    
    -- Header Strip (Franja superior)
    local headerBg = f:CreateTexture(nil, "ARTWORK")
    headerBg:SetPoint("TOPLEFT", f, "TOPLEFT", 0, 0)
    headerBg:SetPoint("BOTTOMRIGHT", f, "TOPRIGHT", 0, -24)
    headerBg:SetTexture("Interface\\Buttons\\WHITE8X8")
    headerBg:SetVertexColor(0.1, 0.1, 0.15, 1)
    
    f:EnableMouse(true)
    f:SetMovable(true)
    f:RegisterForDrag("LeftButton")
    f:SetScript("OnDragStart", f.StartMoving)
    f:SetScript("OnDragStop", function(selfFrame)
        selfFrame:StopMovingOrSizing()
        if S.SmartDefaults then
            S.SmartDefaults:SavePosition("CooldownMonitor", selfFrame)
        end
    end)
    f:SetClampedToScreen(true)
    f:Hide()
    
    -- Título
    local title = f:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    title:SetPoint("LEFT", headerBg, "LEFT", 10, 0)
    title:SetText("|cffffcc00" .. L["COOLDOWN_MONITOR"] .. "|r")
    f.title = title
    
    -- Botón cerrar
    local closeBtn = CreateFrame("Button", nil, f, "UIPanelCloseButton")
    closeBtn:SetPoint("TOPRIGHT", f, "TOPRIGHT", -2, -2)
    closeBtn:SetScript("OnClick", function() CM:Toggle() end)
    
    -- Filtros
    local filterY = -30
    local filters = {"all", "bres", "lust", "raid_cd", "external", "tank_cd"}
    local filterNames = {
        all = L["FILTER_ALL"],
        bres = L["FILTER_BRES"],
        lust = L["FILTER_LUST"],
        raid_cd = L["FILTER_RAID_CD"],
        external = L["FILTER_EXTERNAL"],
        tank_cd = L["FILTER_TANK_CD"]
    }
    
    f.filterButtons = {}
    local filterX = 10
    for i, filter in ipairs(filters) do
        local btn = CreateFrame("Button", nil, f, "UIPanelButtonTemplate")
        btn:SetSize(42, 18)
        btn:SetPoint("TOPLEFT", f, "TOPLEFT", filterX, filterY)
        btn:SetText(filterNames[filter])
        btn:GetFontString():SetFont("Fonts\\FRIZQT__.TTF", 9)
        btn:SetScript("OnClick", function()
            CM.Filter = filter
            CM:UpdateDisplay()
            CM:UpdateFilterButtons()
        end)
        f.filterButtons[filter] = btn
        filterX = filterX + 44
    end
    
    -- Contenedor de scroll
    local scrollFrame = CreateFrame("ScrollFrame", "SequitoCMScroll", f, "UIPanelScrollFrameTemplate")
    scrollFrame:SetPoint("TOPLEFT", f, "TOPLEFT", 8, -52)
    scrollFrame:SetPoint("BOTTOMRIGHT", f, "BOTTOMRIGHT", -28, 8)
    
    local content = CreateFrame("Frame", nil, scrollFrame)
    content:SetSize(240, 500)
    scrollFrame:SetScrollChild(content)
    f.content = content
    
    self.Frame = f
    self.frame = f
    if S.SmartDefaults then
        S.SmartDefaults:RestorePosition("CooldownMonitor")
    end
    self:UpdateFilterButtons()
end

function CM:UpdateFilterButtons()
    for filter, btn in pairs(self.Frame.filterButtons) do
        if filter == self.Filter then
            btn:SetNormalFontObject("GameFontHighlight")
        else
            btn:SetNormalFontObject("GameFontNormal")
        end
    end
end

function CM:CreateCooldownRow(parent, index)
    local rowHeight = self:GetOption("compact") and 16 or 22
    local row = CreateFrame("Frame", nil, parent)
    row:SetSize(240, rowHeight)
    row:SetPoint("TOPLEFT", parent, "TOPLEFT", 0, -((index - 1) * (rowHeight + 2)))
    
    -- Icono (fuera de la barra)
    local icon = row:CreateTexture(nil, "ARTWORK")
    icon:SetSize(22, 22)
    icon:SetPoint("LEFT", row, "LEFT", 0, 0)
    icon:SetTexCoord(0.1, 0.9, 0.1, 0.9) -- Trim edges better
    row.icon = icon
    
    -- Fondo de barra
    local bg = row:CreateTexture(nil, "BACKGROUND")
    bg:SetPoint("TOPLEFT", icon, "TOPRIGHT", 1, 0)
    bg:SetPoint("BOTTOMRIGHT", row, "BOTTOMRIGHT", 0, 0)
    bg:SetTexture("Interface\\Tooltips\\UI-Tooltip-Background")
    bg:SetVertexColor(0.1, 0.1, 0.1, 0.8)
    row.bg = bg
    
    -- Barra de progreso
    local bar = CreateFrame("StatusBar", nil, row)
    bar:SetPoint("TOPLEFT", icon, "TOPRIGHT", 1, 0)
    bar:SetPoint("BOTTOMRIGHT", row, "BOTTOMRIGHT", 0, 0)
    bar:SetStatusBarTexture("Interface\\TargetingFrame\\UI-StatusBar") -- Better default texture
    bar:SetFrameLevel(row:GetFrameLevel() + 1)
    bar:SetMinMaxValues(0, 1)
    bar:SetValue(1)
    row.bar = bar
    
    -- Borde de barra (Backdrop simple)
    local barBg = bar:CreateTexture(nil, "BACKGROUND")
    barBg:SetAllPoints()
    barBg:SetTexture("Interface\\Buttons\\WHITE8X8")
    barBg:SetVertexColor(0, 0, 0, 0.5)
    
    -- Spark (brillo final)
    local spark = bar:CreateTexture(nil, "OVERLAY")
    spark:SetTexture("Interface\\CastingBar\\UI-CastingBar-Spark")
    spark:SetWidth(16)
    spark:SetBlendMode("ADD")
    spark:SetPoint("CENTER", bar:GetStatusBarTexture(), "RIGHT", 0, 0)
    row.spark = spark
    
    -- Nombre del jugador
    local playerName = bar:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    playerName:SetPoint("LEFT", bar, "LEFT", 4, 1)
    playerName:SetWidth(120)
    playerName:SetJustifyH("LEFT")
    playerName:SetShadowOffset(1, -1)
    row.playerName = playerName
    
    -- Nombre del spell (oculto en modo compacto si es necesario, o concatenado)
    local spellName = bar:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    spellName:SetPoint("LEFT", playerName, "RIGHT", 2, 0)
    spellName:SetWidth(80)
    spellName:SetJustifyH("LEFT")
    spellName:SetShadowOffset(1, -1)
    spellName:SetTextColor(0.8, 0.8, 0.8)
    row.spellName = spellName
    
    -- Timer
    local status = bar:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    status:SetPoint("RIGHT", bar, "RIGHT", -4, 0)
    status:SetJustifyH("RIGHT")
    status:SetShadowOffset(1, -1)
    row.status = status
    
    row:Hide()
    return row
end

function CM:RegisterEvents()
    local eventFrame = CreateFrame("Frame")
    eventFrame:RegisterEvent("UNIT_SPELLCAST_SUCCEEDED")
    eventFrame:RegisterEvent("RAID_ROSTER_UPDATE")
    eventFrame:RegisterEvent("PARTY_MEMBERS_CHANGED")
    eventFrame:RegisterEvent("PLAYER_ENTERING_WORLD")
    
    eventFrame:SetScript("OnEvent", function(self, event, ...)
        if event == "UNIT_SPELLCAST_SUCCEEDED" then
            CM:OnSpellCast(...)
        elseif event == "RAID_ROSTER_UPDATE" or event == "PARTY_MEMBERS_CHANGED" or event == "PLAYER_ENTERING_WORLD" then
            CM:ScanRaid()
        end
    end)

    if S.CLEU and S.CLEU.Register then
        S.CLEU:Register("SPELL_CAST_SUCCESS", function(...)
            CM:OnCombatLog(...)
        end)
    else
        eventFrame:RegisterEvent("COMBAT_LOG_EVENT_UNFILTERED")
        eventFrame:HookScript("OnEvent", function(self, event, ...)
            if event == "COMBAT_LOG_EVENT_UNFILTERED" then
                CM:OnCombatLog(...)
            end
        end)
    end
    
    -- Timer de actualización
    local updateFrame = CreateFrame("Frame")
    local elapsed = 0
    updateFrame:SetScript("OnUpdate", function(self, delta)
        elapsed = elapsed + delta
        if elapsed >= 0.05 then -- 20 FPS updates for smoother bars
            elapsed = 0
            if CM.IsVisible then
                CM:UpdateTimers()
            end
        end
    end)
end

function CM:OnSpellCast(unit, spellName, spellRank, lineID)
    if not unit or not spellName then return end
    if unit ~= "player" and not UnitInRaid(unit) and not UnitInParty(unit) then return end
    
    local playerName = UnitName(unit)
    local class = select(2, UnitClass(unit))
    if not class then return end
    
    -- Buscar si es un CD trackeado
    local cooldowns = TrackedCooldowns[class]
    if not cooldowns then return end
    
    for _, cd in ipairs(cooldowns) do
        local locName = GetSpellInfo(cd.spellId)
        if (locName and locName == spellName) or (cd.name == spellName) then
            self:StartCooldown(playerName, class, cd)
            break
        end
    end
end

function CM:OnCombatLog(...)
    local timestamp, event, sourceGUID, sourceName, _, _, _, _, spellId = ...
    
    if event ~= "SPELL_CAST_SUCCESS" then return end
    if not sourceName then return end
    
    -- Verificar si está en el raid o grupo
    local inRaid = false
    local class = nil
    local numRaid = GetNumRaidMembers()
    local numParty = GetNumPartyMembers()
    
    if numRaid > 0 then
        for i = 1, numRaid do
            local name, _, _, _, _, classFile = GetRaidRosterInfo(i)
            if name == sourceName then
                inRaid = true
                class = classFile
                break
            end
        end
    elseif numParty > 0 then
        if UnitName("player") == sourceName then
            inRaid = true
            class = select(2, UnitClass("player"))
        else
            for i = 1, numParty do
                if UnitName("party"..i) == sourceName then
                    inRaid = true
                    class = select(2, UnitClass("party"..i))
                    break
                end
            end
        end
    else
        if UnitName("player") == sourceName then
            inRaid = true
            class = select(2, UnitClass("player"))
        end
    end
    
    if not inRaid or not class then return end
    
    local cooldowns = TrackedCooldowns[class]
    if not cooldowns then return end
    
    for _, cd in ipairs(cooldowns) do
        if cd.spellId == spellId then
            self:StartCooldown(sourceName, class, cd)
            break
        end
    end
end

function CM:StartCooldown(playerName, class, cdInfo)
    -- Verificar si debemos trackear este tipo de cooldown
    local trackOption = "track" .. cdInfo.type:sub(1,1):upper() .. cdInfo.type:sub(2):gsub("_", "")
    if cdInfo.type == "bres" and not self:GetOption("trackBRes") then return end
    if cdInfo.type == "lust" and not self:GetOption("trackLust") then return end
    if cdInfo.type == "raid_cd" and not self:GetOption("trackRaidCD") then return end
    if cdInfo.type == "external" and not self:GetOption("trackExternal") then return end
    if cdInfo.type == "tank_cd" and not self:GetOption("trackTankCD") then return end
    
    local key = playerName .. "_" .. cdInfo.spellId
    
    self.RaidCooldowns[key] = {
        player = playerName,
        class = class,
        spell = cdInfo.name,
        spellId = cdInfo.spellId,
        icon = cdInfo.icon,
        type = cdInfo.type,
        duration = cdInfo.duration,
        expires = GetTime() + cdInfo.duration,
        ready = false
    }
    
    -- Anunciar en raid si es importante
    if cdInfo.type == "bres" or cdInfo.type == "lust" then
        local channel = self:GetGroupChannel()
        if channel then
            SendChatMessage(string.format("[Sequito] %s usó %s - CD: %s", 
                playerName, cdInfo.name, self:FormatTime(cdInfo.duration)), channel)
        end
    end
    
    self:UpdateDisplay()
end

function CM:ScanRaid()
    -- Limpiar CDs de jugadores que ya no están
    local currentMembers = {}
    local numRaid = GetNumRaidMembers()
    local numParty = GetNumPartyMembers()
    
    if numRaid > 0 then
        for i = 1, numRaid do
            local name = GetRaidRosterInfo(i)
            if name then
                currentMembers[name] = true
            end
        end
    elseif numParty > 0 then
        currentMembers[UnitName("player")] = true
        for i = 1, numParty do
            local name = UnitName("party"..i)
            if name then
                currentMembers[name] = true
            end
        end
    else
        currentMembers[UnitName("player")] = true
    end
    
    -- Remover CDs de jugadores que se fueron
    for key, cd in pairs(self.RaidCooldowns) do
        if not currentMembers[cd.player] then
            self.RaidCooldowns[key] = nil
        end
    end
    
    -- Agregar jugadores nuevos con CDs listos
    for name, _ in pairs(currentMembers) do
        self:AddPlayerCooldowns(name)
    end
    
    self:UpdateDisplay()
end

function CM:AddPlayerCooldowns(playerName)
    local class = nil
    
    -- Obtener clase
    local numRaid = GetNumRaidMembers()
    local numParty = GetNumPartyMembers()
    
    if numRaid > 0 then
        for i = 1, numRaid do
            local name, _, _, _, _, classFile = GetRaidRosterInfo(i)
            if name == playerName then
                class = classFile
                break
            end
        end
    elseif numParty > 0 then
        if UnitName("player") == playerName then
            class = select(2, UnitClass("player"))
        else
            for i = 1, numParty do
                if UnitName("party"..i) == playerName then
                    class = select(2, UnitClass("party"..i))
                    break
                end
            end
        end
    else
        if UnitName("player") == playerName then
            class = select(2, UnitClass("player"))
        end
    end
    
    if not class then return end
    
    local cooldowns = TrackedCooldowns[class]
    if not cooldowns then return end

    -- Obtener facción de la unidad para filtrar Heroism/Bloodlust
    local unitFaction = nil
    if numRaid > 0 then
        for i = 1, numRaid do
            local name = GetRaidRosterInfo(i)
            if name == playerName then
                unitFaction = UnitFactionGroup("raid" .. i)
                break
            end
        end
    elseif numParty > 0 then
        if UnitName("player") == playerName then
            unitFaction = UnitFactionGroup("player")
        else
            for i = 1, numParty do
                if UnitName("party" .. i) == playerName then
                    unitFaction = UnitFactionGroup("party" .. i)
                    break
                end
            end
        end
    else
        unitFaction = UnitFactionGroup("player")
    end
    unitFaction = unitFaction or UnitFactionGroup("player")
    
    for _, cd in ipairs(cooldowns) do
        -- Filtrar por facción si aplica (evitar duplicar Heroism y Bloodlust)
        local shouldTrack = true
        if cd.faction and unitFaction and cd.faction ~= unitFaction then
            shouldTrack = false
        end

        -- Verificar si debemos trackear este tipo de cooldown
        if shouldTrack and cd.type == "bres" and not self:GetOption("trackBRes") then shouldTrack = false end
        if shouldTrack and cd.type == "lust" and not self:GetOption("trackLust") then shouldTrack = false end
        if shouldTrack and cd.type == "raid_cd" and not self:GetOption("trackRaidCD") then shouldTrack = false end
        if shouldTrack and cd.type == "external" and not self:GetOption("trackExternal") then shouldTrack = false end
        if shouldTrack and cd.type == "tank_cd" and not self:GetOption("trackTankCD") then shouldTrack = false end
        
        if shouldTrack then
            local key = playerName .. "_" .. cd.spellId
            if not self.RaidCooldowns[key] then
                self.RaidCooldowns[key] = {
                    player = playerName,
                    class = class,
                    spell = cd.name,
                    spellId = cd.spellId,
                    icon = cd.icon,
                    type = cd.type,
                    duration = cd.duration,
                    expires = 0,
                    ready = true
                }
            end
        end
    end
end

function CM:UpdateTimers()
    local now = GetTime()
    
    for key, cd in pairs(self.RaidCooldowns) do
        if cd.expires > 0 and cd.expires <= now then
            cd.ready = true
            cd.expires = 0
            
            -- Alertas cuando están listos (si está habilitado)
            if self:GetOption("alerts") then
                local msg = string.format("%s: %s " .. L["CD_READY"] .. "!", cd.player, cd.spell)
                print("|cff00ff00[Sequito]|r " .. msg)
            end
            
            -- Anunciar BRes listos en raid (si está habilitado)
            if cd.type == "bres" and self:GetOption("announceReady") then
                local channel = self:GetGroupChannel()
                if channel then
                    SendChatMessage(string.format("[Sequito] %s: %s disponible!", cd.player, cd.spell), channel)
                end
            end
        end
    end
    
    self:UpdateDisplay()
end

function CM:UpdateDisplay()
    if not self.Frame or not self.Frame.content then return end
    
    -- Ocultar todas las filas
    for _, row in ipairs(self.Rows) do
        row:Hide()
    end
    
    -- Filtrar y ordenar cooldowns
    local filtered = {}
    for key, cd in pairs(self.RaidCooldowns) do
        if self.Filter == "all" or cd.type == self.Filter then
            table.insert(filtered, cd)
        end
    end
    
    -- Ordenar: listos primero, luego por tiempo restante
    table.sort(filtered, function(a, b)
        if a.ready and not b.ready then return true end
        if not a.ready and b.ready then return false end
        if a.ready and b.ready then return a.player < b.player end
        return a.expires < b.expires
    end)
    
    -- Mostrar
    local now = GetTime()
    for i, cd in ipairs(filtered) do
        local row = self.Rows[i]
        if not row then
            row = self:CreateCooldownRow(self.Frame.content, i)
            self.Rows[i] = row
        end
        
        row.icon:SetTexture(cd.icon)
        
            -- Color de barra
            local r, g, b = 0.5, 0.5, 0.5
            
            if self:GetOption("classColor") then
                local classColor = RAID_CLASS_COLORS[cd.class] or {r=0.5, g=0.5, b=0.5}
                r, g, b = classColor.r, classColor.g, classColor.b
            elseif self:GetOption("colorByType") then
                 local typeColor = TypeColors[cd.type] or {0.5, 0.5, 0.5}
                 r, g, b = unpack(typeColor)
            else
                 r, g, b = 0.5, 0.5, 0.5 -- Default gray
            end
            
            if cd.ready then
                row.playerName:SetText("|cff00ff00" .. cd.player .. "|r")
                row.spellName:SetText("|cffffffff" .. cd.spell .. "|r")
                row.status:SetText("|cff00ff00" .. L["CD_READY"] .. "|r")
                
                row.bar:SetValue(1)
                row.bar:SetStatusBarColor(0, 1, 0, 0.7) -- Verde brillante para LISTO siempre
                row.spark:Hide()
            else
                row.playerName:SetText("|cffffffff" .. cd.player .. "|r")
                row.spellName:SetText("|cffcccccc" .. cd.spell .. "|r")
                
                local remaining = cd.expires - now
                row.status:SetText(self:FormatTime(remaining))
                
                local progress = 1 - (remaining / cd.duration) -- Barra llena = listo
                row.bar:SetValue(progress)
                row.bar:SetStatusBarColor(r, g, b, 0.9)
                
                -- Actualizar Spark
                row.spark:Show()
                if progress > 0 and progress < 1 then
                    row.spark:SetPoint("CENTER", row.bar:GetStatusBarTexture(), "RIGHT", 0, 0)
                else
                    row.spark:Hide()
                end
            end
        
        row:Show()
    end
    
    -- Ajustar altura del contenido
    local rowHeight = self:GetOption("compact") and 16 or 22
    self.Frame.content:SetHeight(math.max(#filtered * (rowHeight + 2), 100))
end

function CM:FormatTime(seconds)
    if seconds >= 60 then
        return string.format("%d:%02d", math.floor(seconds / 60), seconds % 60)
    else
        return string.format("%ds", seconds)
    end
end

function CM:Toggle()
    if not self.Frame then
        self:Initialize()
    end
    
    -- Check again after Initialize (module might be disabled)
    if not self.Frame then
        return
    end
    
    self.IsVisible = not self.IsVisible
    if self.IsVisible then
        self:ScanRaid()
        self:UpdateTimers()
        self.Frame:Show()
    else
        self.Frame:Hide()
    end
end

function CM:Show()
    if not self.Frame then
        self:Initialize()
    end
    self.IsVisible = true
    self:ScanRaid()
    self:UpdateTimers()
    self.Frame:Show()
end

function CM:Hide()
    if self.Frame then
        self.IsVisible = false
        self.Frame:Hide()
    end
end

function CM:GetAvailableBRes()
    local available = {}
    for key, cd in pairs(self.RaidCooldowns) do
        if cd.type == "bres" and cd.ready then
            table.insert(available, cd)
        end
    end
    return available
end

function CM:GetAvailableLust()
    for key, cd in pairs(self.RaidCooldowns) do
        if cd.type == "lust" and cd.ready then
            return cd
        end
    end
    return nil
end

function CM:AnnounceAvailable(cdType)
    local available = {}
    for key, cd in pairs(self.RaidCooldowns) do
        if cd.type == cdType and cd.ready then
            table.insert(available, cd.player .. " (" .. cd.spell .. ")")
        end
    end
    
    if #available > 0 then
        local msg = "[Sequito] " .. cdType:upper() .. " disponibles: " .. table.concat(available, ", ")
        local channel = self:GetGroupChannel()
        if channel then
            if #msg > 250 then
                msg = msg:sub(1, 247) .. "..."
            end
            SendChatMessage(msg, channel)
        else
            print(msg)
        end
    else
        print("|cffff0000[Sequito]|r No hay " .. cdType .. " disponibles")
    end
end

-- Helper para obtener configuración
function CM:GetOption(key)
    if S.ModuleConfig then
        return S.ModuleConfig:GetValue("CooldownMonitor", key)
    end
    return true -- Default habilitado
end

-- ============================================
-- CALLBACKS PARA AUTOSYNC (v8.0.0)
-- ============================================

-- Recibir datos de otro jugador (desde AutoSync)
function CM:OnPlayerDataReceived(sender, data)
    -- Actualizar datos de jugador en nuestro tracking
    if not data or not data.class then return end
    
    -- Si el jugador tiene spec/rol, podemos usarlo para mejorar el tracking
    -- Por ahora, solo actualizamos si tenemos CDs pendientes
    if self.RaidCooldowns then
        for key, cd in pairs(self.RaidCooldowns) do
            if cd.playerName == sender then
                cd.playerClass = data.class
                cd.playerRole = data.role
            end
        end
    end
    
    -- Forzar rescan para nuevos miembros
    if not self.knownPlayers then self.knownPlayers = {} end
    if not self.knownPlayers[sender] then
        self.knownPlayers[sender] = true
        self:AddPlayerCooldowns(sender)
    end
end

-- Recibir update de cooldown desde otro jugador
function CM:OnCooldownUpdate(sender, spellId, ready, expires)
    if not self.RaidCooldowns then return end
    
    local key = sender .. "_" .. spellId
    
    if self.RaidCooldowns[key] then
        if ready then
            -- CD está listo
            self.RaidCooldowns[key].expires = 0
            self.RaidCooldowns[key].ready = true
        else
            -- CD usado, en cooldown
            self.RaidCooldowns[key].expires = expires
            self.RaidCooldowns[key].ready = false
        end
        
        if self.IsVisible then
            self:UpdateDisplay()
        end
    end
end

-- Obtener cooldowns del jugador local para broadcast
function CM:GetPlayerCooldowns()
    local cooldowns = {}
    local playerName = UnitName("player")
    local _, playerClass = UnitClass("player")
    
    local trackedCDs = TrackedCooldowns[playerClass]
    if not trackedCDs then return cooldowns end
    
    for _, cd in ipairs(trackedCDs) do
        local start, duration = GetSpellCooldown(cd.spellId)
        if start and duration then
            local ready = (start == 0 or duration == 0)
            local expires = 0
            if not ready then
                expires = start + duration
            end
            
            table.insert(cooldowns, {
                spellId = cd.spellId,
                name = cd.name,
                type = cd.type,
                ready = ready,
                expires = expires
            })
        end
    end
    
    return cooldowns
end

-- Verificar si un spellId es un CD importante para tracking
function CM:IsImportantCooldown(spellId)
    -- Buscar en todas las clases
    for class, cds in pairs(TrackedCooldowns) do
        for _, cd in ipairs(cds) do
            if cd.spellId == spellId then
                return true
            end
        end
    end
    return false
end

-- Registrar configuración en ModuleConfig
local function RegisterConfig()
    if not S.ModuleConfig then return end
    
    S.ModuleConfig:RegisterModule("CooldownMonitor", {
        name = L["COOLDOWN_MONITOR"],
        description = "Raid Cooldown Tracker",
        icon = "Interface\\Icons\\Spell_Holy_BorrowedTime",
        category = "raid",
        options = {
            {key = "enabled", type = "checkbox", label = L["CFG_ENABLED"], default = true,
                tooltip = "Activa o desactiva el monitor de cooldowns"},
            {key = "locked", type = "checkbox", label = L["CFG_LOCKED"], default = false,
                tooltip = "Bloquea la posición del monitor de cooldowns"},
            {key = "scale", type = "slider", label = L["CFG_SCALE"], min = 0.5, max = 2.0, step = 0.1, default = 1.0,
                tooltip = "Escala el tamaño del monitor de cooldowns"},
            {type = "checkbox", key = "alerts", label = "Alertas cuando están listos", default = true,
                tooltip = "Muestra alerta cuando cooldowns importantes están listos"},
            {type = "checkbox", key = "announceReady", label = "Anunciar BRes listos", default = false,
                tooltip = "Anuncia en raid cuando resurrecciones de combate están listas"},
            {type = "checkbox", key = "trackBRes", label = "Rastrear BRes", default = true,
                tooltip = "Rastrea resurrecciones de combate"},
            {type = "checkbox", key = "trackLust", label = "Rastrear Lust/Hero", default = true,
                tooltip = "Rastrea Heroism/Bloodlust"},
            {type = "checkbox", key = "trackRaidCD", label = "Rastrear CDs de raid", default = true,
                tooltip = "Rastrea cooldowns defensivos de raid"},
            {type = "checkbox", key = "trackExternal", label = "Rastrear externos", default = true,
                tooltip = "Rastrea cooldowns externos (Guardian Spirit, Pain Suppression, etc.)"},
            {type = "checkbox", key = "trackTankCD", label = "Rastrear CDs de tank", default = true,
                tooltip = "Rastrea cooldowns defensivos de tanks"},
            {
                type = "checkbox",
                key = "colorByType",
                label = "Colorear por Tipo",
                tooltip = "Usa colores por tipo de hechizo (ej: defensivos en amarillo) en lugar de color de clase.",
                default = false,
            },
            {type = "header", label = "Filtros de visualización"},
            {type = "dropdown", key = "defaultFilter", label = "Filtro por defecto", 
                options = {
                    {text = "Todos", value = "all"},
                    {text = "Solo BRes", value = "bres"},
                    {text = "Solo Lust", value = "lust"},
                    {text = "Solo Raid CDs", value = "raid_cd"},
                    {text = "Solo Externos", value = "external"},
                    {text = "Solo Tank CDs", value = "tank_cd"},
                },
                default = "all",
                tooltip = "Filtro que se muestra al abrir el panel"},
        },
        onSave = function(db)
            local enabled = S.ModuleConfig:GetValue("CooldownMonitor", "enabled")
            if enabled and CM.Frame then
                CM.Frame:Show()
            elseif CM.Frame then
                CM.Frame:Hide()
            end
        end,
    })
end

-- Auto-inicializar
local initFrame = CreateFrame("Frame")
initFrame:RegisterEvent("PLAYER_LOGIN")
initFrame:SetScript("OnEvent", function()
    -- Delay para asegurar que todo esté cargado
    local timer = CreateFrame("Frame")
    local elapsed = 0
    timer:SetScript("OnUpdate", function(self, delta)
        elapsed = elapsed + delta
        if elapsed >= 3 then
            self:SetScript("OnUpdate", nil)
            RegisterConfig()
            CM:Initialize()
        end
    end)
end)
