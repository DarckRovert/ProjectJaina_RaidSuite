--[[
    Sequito - ReadyChecker.lua
    Chequeo Pre-Pull Mejorado
    Version: 7.2.0
]]

local addonName, S = ...
S.ReadyChecker = {}
local RC = S.ReadyChecker

-- Buffs/Debuffs a verificar por clase
local ClassChecks = {
    ROGUE = {
        {type = "poison_mh", name = "Veneno MH", check = function(unit) 
            if unit == "player" then
                return GetWeaponEnchantInfo()
            end
            return true
        end},
        {type = "poison_oh", name = "Veneno OH", check = function(unit)
            if unit == "player" then
                local _, _, _, _, hasOH = GetWeaponEnchantInfo()
                return hasOH
            end
            return true
        end},
    },
    WARLOCK = {
        {type = "pet", name = "Mascota", check = function(unit)
            return UnitExists(unit.."pet")
        end},
        {type = "healthstone", name = "Piedra de Salud", check = function(unit)
            -- Verificar si tiene healthstone en bolsas (solo para el jugador)
            if unit == "player" then
                for bag = 0, 4 do
                    for slot = 1, GetContainerNumSlots(bag) do
                        local itemId = GetContainerItemID(bag, slot)
                        if itemId and (itemId == 36892 or itemId == 36893 or itemId == 36894) then
                            return true
                        end
                    end
                end
            end
            return nil -- No podemos verificar otros jugadores
        end},
        {type = "spellstone", name = "Piedra de Hechizo", check = function(unit)
            if unit == "player" then
                local hasMainHandEnchant = GetWeaponEnchantInfo()
                return hasMainHandEnchant
            end
            return true
        end},
    },
    HUNTER = {
        {type = "pet", name = "Mascota", check = function(unit)
            return UnitExists(unit.."pet")
        end},
        {type = "aspect", name = "Aspecto", check = function(unit)
            -- Verificar aspectos comunes
            local aspects = {13165, 34074, 13163, 5118, 13159, 20043, 27044}
            for _, spellId in ipairs(aspects) do
                local name = GetSpellInfo(spellId)
                if name and UnitBuff(unit, name) then
                    return true
                end
            end
            return false
        end},
    },
    DEATHKNIGHT = {
        {type = "presence", name = "Presencia", check = function(unit)
            local presences = {
                GetSpellInfo(48263), -- Blood
                GetSpellInfo(48266), -- Frost  
                GetSpellInfo(48265), -- Unholy
            }
            for _, name in ipairs(presences) do
                if name and UnitBuff(unit, name) then
                    return true
                end
            end
            return false
        end},
        {type = "horn", name = "Cuerno de Invierno", check = function(unit)
            local name = GetSpellInfo(57623) -- Horn of Winter
            return name and UnitBuff(unit, name)
        end},
    },
    PALADIN = {
        {type = "aura", name = "Aura", check = function(unit)
            local auras = {
                GetSpellInfo(48942), -- Devotion
                GetSpellInfo(54043), -- Retribution
                GetSpellInfo(19746), -- Concentration
                GetSpellInfo(48943), -- Shadow Resistance
                GetSpellInfo(48945), -- Frost Resistance
                GetSpellInfo(48947), -- Fire Resistance
                GetSpellInfo(32223), -- Crusader
            }
            for _, name in ipairs(auras) do
                if name and UnitBuff(unit, name) then
                    return true
                end
            end
            return false
        end},
        {type = "seal", name = "Sello", check = function(unit)
            local seals = {
                GetSpellInfo(31801), -- Vengeance
                GetSpellInfo(20165), -- Light
                GetSpellInfo(20164), -- Justice
                GetSpellInfo(20166), -- Wisdom
                GetSpellInfo(53736), -- Corruption
                GetSpellInfo(21084), -- Righteousness
                GetSpellInfo(20375), -- Command
            }
            for _, name in ipairs(seals) do
                if name and UnitBuff(unit, name) then
                    return true
                end
            end
            return false
        end},
    },
    SHAMAN = {
        {type = "shield", name = "Escudo", check = function(unit)
            local shields = {
                GetSpellInfo(57960), -- Water Shield
                GetSpellInfo(49281), -- Lightning Shield
                GetSpellInfo(974),   -- Earth Shield (on others)
            }
            for _, name in ipairs(shields) do
                if name and UnitBuff(unit, name) then
                    return true
                end
            end
            return false
        end},
        {type = "weapon", name = "Imbuir Arma", check = function(unit)
            if unit == "player" then
                return GetWeaponEnchantInfo()
            end
            return true
        end},
    },
    MAGE = {
        {type = "armor", name = "Armadura", check = function(unit)
            local armors = {
                GetSpellInfo(43024), -- Molten Armor
                GetSpellInfo(43046), -- Mage Armor
                GetSpellInfo(43008), -- Ice Armor
            }
            for _, name in ipairs(armors) do
                if name and UnitBuff(unit, name) then
                    return true
                end
            end
            return false
        end},
    },
    WARRIOR = {
        {type = "shout", name = "Grito", check = function(unit)
            local shouts = {
                GetSpellInfo(47436), -- Battle Shout
                GetSpellInfo(47440), -- Commanding Shout
            }
            for _, name in ipairs(shouts) do
                if name and UnitBuff(unit, name) then
                    return true
                end
            end
            return false
        end},
        {type = "stance", name = "Postura", check = function(unit)
            -- Solo podemos verificar esto para el jugador
            if unit == "player" then
                return GetShapeshiftForm() > 0
            end
            return nil
        end},
    },
    DRUID = {
        {type = "motw", name = "Don de lo Salvaje", check = function(unit)
            local name = GetSpellInfo(48470) -- Gift of the Wild
            local name2 = GetSpellInfo(48469) -- Mark of the Wild
            return (name and UnitBuff(unit, name)) or (name2 and UnitBuff(unit, name2))
        end},
    },
    PRIEST = {
        {type = "fortitude", name = "Fortaleza", check = function(unit)
            local name = GetSpellInfo(48162) -- Prayer of Fortitude
            local name2 = GetSpellInfo(48161) -- Power Word: Fortitude
            return (name and UnitBuff(unit, name)) or (name2 and UnitBuff(unit, name2))
        end},
        {type = "spirit", name = "Espíritu Divino", check = function(unit)
            local name = GetSpellInfo(48074) -- Prayer of Spirit
            local name2 = GetSpellInfo(48073) -- Divine Spirit
            return (name and UnitBuff(unit, name)) or (name2 and UnitBuff(unit, name2))
        end},
        {type = "shadow", name = "Protección Sombras", check = function(unit)
            local name = GetSpellInfo(48170) -- Prayer of Shadow Protection
            local name2 = GetSpellInfo(48169) -- Shadow Protection
            return (name and UnitBuff(unit, name)) or (name2 and UnitBuff(unit, name2))
        end},
    },
}

-- Consumibles a verificar
local ConsumableChecks = {
    {type = "flask", name = "Flask", buffs = {
        GetSpellInfo(53758), -- Flask of Stoneblood
        GetSpellInfo(53755), -- Flask of the Frost Wyrm
        GetSpellInfo(53760), -- Flask of Endless Rage
        GetSpellInfo(54212), -- Flask of Pure Mojo
        GetSpellInfo(53752), -- Lesser Flask of Toughness
    }},
    {type = "food", name = "Comida", buffs = {
        GetSpellInfo(57399), -- Well Fed (Fish Feast)
        GetSpellInfo(57294), -- Well Fed
    }},
}

RC.Frame = nil
RC.Results = {}
RC.IsVisible = false

-- Helper para obtener configuración
function RC:GetOption(key)
    if S.ModuleConfig then
        return S.ModuleConfig:GetValue("ReadyChecker", key)
    end
    return true
end

function RC:Initialize()
    if not self:GetOption("enabled") then
        return
    end
    
    self:CreateFrame()
end

function RC:GetGroupChannel()
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

function RC:CreateFrame()
    if self.Frame then return end
    
    local f = CreateFrame("Frame", "SequitoReadyChecker", UIParent)
    f:SetSize(350, 400)
    f:SetPoint("CENTER", UIParent, "CENTER", 0, 0)
    f:SetBackdrop({
        bgFile = "Interface\\Tooltips\\UI-Tooltip-Background",
        edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
        tile = true, tileSize = 16, edgeSize = 16,
        insets = {left = 4, right = 4, top = 4, bottom = 4}
    })
    f:SetBackdropColor(0, 0, 0, 0.9)
    f:SetBackdropBorderColor(0.2, 0.6, 0.2, 1)
    f:EnableMouse(true)
    f:SetMovable(true)
    f:RegisterForDrag("LeftButton")
    f:SetScript("OnDragStart", f.StartMoving)
    f:SetScript("OnDragStop", f.StopMovingOrSizing)
    f:SetClampedToScreen(true)
    f:Hide()
    
    -- Título
    local title = f:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
    title:SetPoint("TOP", f, "TOP", 0, -10)
    title:SetText("|cff00ff00Sequito|r - Ready Check Mejorado")
    
    -- Botón cerrar
    local closeBtn = CreateFrame("Button", nil, f, "UIPanelCloseButton")
    closeBtn:SetPoint("TOPRIGHT", f, "TOPRIGHT", -2, -2)
    closeBtn:SetScript("OnClick", function() RC:Toggle() end)
    
    -- Botón de escaneo
    local scanBtn = CreateFrame("Button", nil, f, "UIPanelButtonTemplate")
    scanBtn:SetSize(120, 24)
    scanBtn:SetPoint("TOP", f, "TOP", 0, -35)
    scanBtn:SetText("Escanear Raid")
    scanBtn:SetScript("OnClick", function() RC:ScanRaid() end)
    
    -- Scroll frame para resultados
    local scrollFrame = CreateFrame("ScrollFrame", "SequitoRCScroll", f, "UIPanelScrollFrameTemplate")
    scrollFrame:SetPoint("TOPLEFT", f, "TOPLEFT", 10, -65)
    scrollFrame:SetPoint("BOTTOMRIGHT", f, "BOTTOMRIGHT", -30, 45)
    
    local content = CreateFrame("Frame", nil, scrollFrame)
    content:SetSize(300, 600)
    scrollFrame:SetScrollChild(content)
    f.content = content
    
    -- Botón anunciar problemas
    local announceBtn = CreateFrame("Button", nil, f, "UIPanelButtonTemplate")
    announceBtn:SetSize(150, 24)
    announceBtn:SetPoint("BOTTOM", f, "BOTTOM", 0, 12)
    announceBtn:SetText("Anunciar Problemas")
    announceBtn:SetScript("OnClick", function() RC:AnnounceProblems() end)
    
    self.Frame = f
    self.Rows = {}
end

function RC:CreateResultRow(parent, index)
    local row = CreateFrame("Frame", nil, parent)
    row:SetSize(300, 20)
    row:SetPoint("TOPLEFT", parent, "TOPLEFT", 0, -((index - 1) * 22))
    
    -- Icono de estado
    local statusIcon = row:CreateTexture(nil, "ARTWORK")
    statusIcon:SetSize(16, 16)
    statusIcon:SetPoint("LEFT", row, "LEFT", 0, 0)
    row.statusIcon = statusIcon
    
    -- Nombre del jugador
    local playerName = row:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    playerName:SetPoint("LEFT", statusIcon, "RIGHT", 4, 0)
    playerName:SetWidth(80)
    playerName:SetJustifyH("LEFT")
    row.playerName = playerName
    
    -- Problemas
    local problems = row:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    problems:SetPoint("LEFT", playerName, "RIGHT", 4, 0)
    problems:SetWidth(200)
    problems:SetJustifyH("LEFT")
    row.problems = problems
    
    row:Hide()
    return row
end

function RC:ScanRaid()
    -- Verificar si auto-check está habilitado
    if not self:GetOption("autoCheck") then
        return
    end
    
    self.Results = {}
    
    local function checkPlayer(unit, name, class)
        local result = {
            name = name,
            class = class,
            unit = unit,
            problems = {},
            ready = true
        }
        
        -- Verificar checks específicos de clase
        local classChecks = ClassChecks[class]
        if classChecks then
            for _, check in ipairs(classChecks) do
                local passed = check.check(unit)
                if passed == false then
                    table.insert(result.problems, check.name)
                    result.ready = false
                end
            end
        end
        
        -- Verificar consumibles
        for _, consumable in ipairs(ConsumableChecks) do
            local hasConsumable = false
            for _, buffName in ipairs(consumable.buffs) do
                if buffName and UnitBuff(unit, buffName) then
                    hasConsumable = true
                    break
                end
            end
            if not hasConsumable then
                table.insert(result.problems, "Sin " .. consumable.name)
                result.ready = false
            end
        end
        
        -- Verificar vida y mana
        local healthPct = UnitHealth(unit) / UnitHealthMax(unit) * 100
        if healthPct < 100 then
            table.insert(result.problems, string.format("Vida: %d%%", healthPct))
            if healthPct < 80 then
                result.ready = false
            end
        end
        
        local powerType = UnitPowerType(unit)
        if powerType == 0 then -- Mana
            local manaPct = UnitMana(unit) / UnitManaMax(unit) * 100
            if manaPct < 80 then
                table.insert(result.problems, string.format("Mana: %d%%", manaPct))
                result.ready = false
            end
        end
        
        -- Verificar si está muerto
        if UnitIsDead(unit) then
            result.problems = {"MUERTO"}
            result.ready = false
        end
        
        -- Verificar si está desconectado
        if not UnitIsConnected(unit) then
            result.problems = {"DESCONECTADO"}
            result.ready = false
        end
        
        -- Verificar si está AFK
        if UnitIsAFK(unit) then
            table.insert(result.problems, "AFK")
            result.ready = false
        end
        
        table.insert(self.Results, result)
    end
    
    local numRaid = GetNumRaidMembers()
    local numParty = GetNumPartyMembers()
    
    if numRaid > 0 then
        for i = 1, numRaid do
            local name, _, _, _, _, classFile = GetRaidRosterInfo(i)
            if name then
                checkPlayer("raid"..i, name, classFile)
            end
        end
    elseif numParty > 0 then
        -- Jugador
        local name = UnitName("player")
        local class = select(2, UnitClass("player"))
        checkPlayer("player", name, class)
        
        -- Party members
        for i = 1, numParty do
            local pname = UnitName("party"..i)
            local pclass = select(2, UnitClass("party"..i))
            if pname then
                checkPlayer("party"..i, pname, pclass)
            end
        end
    else
        -- Solo
        local name = UnitName("player")
        local class = select(2, UnitClass("player"))
        checkPlayer("player", name, class)
    end
    
    -- Ordenar: problemas primero
    table.sort(self.Results, function(a, b)
        if a.ready and not b.ready then return false end
        if not a.ready and b.ready then return true end
        return a.name < b.name
    end)
    
    self:UpdateDisplay()
    
    -- Resumen
    local readyCount = 0
    local totalCount = #self.Results
    for _, result in ipairs(self.Results) do
        if result.ready then readyCount = readyCount + 1 end
    end
    
    local color = readyCount == totalCount and "|cff00ff00" or "|cffff0000"
    print(string.format("%s[Sequito]|r Ready Check: %d/%d listos", color, readyCount, totalCount))
end

function RC:UpdateDisplay()
    if not self.Frame or not self.Frame.content then return end
    
    -- Ocultar todas las filas
    for _, row in ipairs(self.Rows) do
        row:Hide()
    end
    
    for i, result in ipairs(self.Results) do
        local row = self.Rows[i]
        if not row then
            row = self:CreateResultRow(self.Frame.content, i)
            self.Rows[i] = row
        end
        
        -- Icono de estado
        if result.ready then
            row.statusIcon:SetTexture("Interface\\RaidFrame\\ReadyCheck-Ready")
        else
            row.statusIcon:SetTexture("Interface\\RaidFrame\\ReadyCheck-NotReady")
        end
        
        -- Nombre con color de clase
        local classColor = RAID_CLASS_COLORS[result.class] or {r=1, g=1, b=1}
        row.playerName:SetText(string.format("|cff%02x%02x%02x%s|r",
            classColor.r * 255, classColor.g * 255, classColor.b * 255, result.name))
        
        -- Problemas
        if #result.problems > 0 then
            row.problems:SetText("|cffff6600" .. table.concat(result.problems, ", ") .. "|r")
        else
            row.problems:SetText("|cff00ff00OK|r")
        end
        
        row:Show()
    end
    
    self.Frame.content:SetHeight(math.max(#self.Results * 22, 100))
end

function RC:AnnounceProblems()
    -- Verificar si anuncios están habilitados
    if not self:GetOption("announce") then
        return
    end
    
    local problems = {}
    
    for _, result in ipairs(self.Results) do
        if not result.ready and #result.problems > 0 then
            table.insert(problems, result.name .. ": " .. table.concat(result.problems, ", "))
        end
    end
    
    if #problems == 0 then
        local msg = "[Sequito] ¡Todos listos!"
        local channel = self:GetGroupChannel()
        if channel then
            SendChatMessage(msg, channel)
        else
            print(msg)
        end
        return
    end
    
    local channel = self:GetGroupChannel()
    
    if channel then
        -- Concatenar para evitar desconexión por flood (Ley III: 255 bytes max)
        local header = string.format("[Sequito] %d jugador(es) con problemas: ", #problems)
        local line = header
        for _, problem in ipairs(problems) do
            if #(line .. problem .. "; ") > 240 then
                SendChatMessage(line, channel)
                line = "  - " .. problem .. "; "
            else
                line = line .. problem .. "; "
            end
        end
        if line ~= "" then
            SendChatMessage(line, channel)
        end
    else
        print("|cffff0000[Sequito]|r Problemas detectados:")
        for _, problem in ipairs(problems) do
            print("  - " .. problem)
        end
    end
end

function RC:QuickCheck()
    self:ScanRaid()
    
    local allReady = true
    for _, result in ipairs(self.Results) do
        if not result.ready then
            allReady = false
            break
        end
    end
    
    return allReady
end

function RC:Toggle()
    if not self.Frame then
        self:Initialize()
    end
    
    -- Check again after Initialize (module might be disabled)
    if not self.Frame then
        return
    end
    
    self.IsVisible = not self.IsVisible
    if self.IsVisible then
        self.Frame:Show()
        self:ScanRaid()
    else
        self.Frame:Hide()
    end
end

function RC:Show()
    if not self.Frame then
        self:Initialize()
    end
    self.IsVisible = true
    self.Frame:Show()
    self:ScanRaid()
end

function RC:Hide()
    if self.Frame then
        self.IsVisible = false
        self.Frame:Hide()
    end
end

-- Helper para obtener configuración
function RC:GetOption(key)
    if S.ModuleConfig then
        return S.ModuleConfig:GetValue("ReadyChecker", key)
    end
    return true
end

-- Registrar módulo en ModuleConfig
if S.ModuleConfig then
    S.ModuleConfig:RegisterModule({
        id = "ReadyChecker",
        name = "Ready Checker",
        description = "Verificación pre-pull de buffs, consumibles y preparación",
        category = "raid",
        icon = "Interface\\Icons\\INV_Misc_QuestionMark",
        options = {
            {
                key = "enabled",
                type = "checkbox",
                name = "Habilitar Ready Check",
                description = "Habilitar/deshabilitar verificación de preparación",
                default = true
            },
            {
                key = "autoCheck",
                type = "checkbox",
                name = "Check Automático",
                description = "Verificar automáticamente antes de pull",
                default = false
            },
            {
                key = "checkBuffs",
                type = "checkbox",
                name = "Verificar Buffs",
                description = "Verificar buffs de raid (Fort, Mark, etc)",
                default = true
            },
            {
                key = "checkConsumables",
                type = "checkbox",
                name = "Verificar Consumibles",
                description = "Verificar flasks, food, pots",
                default = true
            },
            {
                key = "checkClass",
                type = "checkbox",
                name = "Verificar Clase",
                description = "Verificar requisitos específicos de clase (venenos, mascotas, etc)",
                default = true
            },
            {
                key = "alertSound",
                type = "checkbox",
                name = "Sonido de Alerta",
                description = "Reproducir sonido cuando faltan requisitos",
                default = true
            },
            {
                key = "announceResults",
                type = "checkbox",
                name = "Anunciar Resultados",
                description = "Anunciar resultados del check al raid",
                default = false
            }
        }
    })
end

-- Auto-inicializar
local initFrame = CreateFrame("Frame")
initFrame:RegisterEvent("PLAYER_LOGIN")
initFrame:SetScript("OnEvent", function()
    local timer = CreateFrame("Frame")
    local elapsed = 0
    timer:SetScript("OnUpdate", function(self, delta)
        elapsed = elapsed + delta
        if elapsed >= 3 then
            self:SetScript("OnUpdate", nil)
            RC:Initialize()
        end
    end)
end)
