--[[
    Sequito - ReadyChecker.lua
    Chequeo Pre-Pull Mejorado de Bandas y Grupos
    Version: 8.5.0 (WotLK 3.3.5a Build 12340)

    Características:
    - Escaneo dinámico con UnitIDs válidos para mascotas (pet, partypetX, raidpetX).
    - Desacople de escaneo manual vs auto-check por evento READY_CHECK.
    - Soporte nativo de eventos READY_CHECK y READY_CHECK_FINISHED.
    - Detección precisa de consumibles, auras y requisitos de clase WotLK 3.3.5a.
    - Protección contra división por cero en cálculos de porcentaje de salud/maná.
    - Transición de UnitMana a UnitPower(unit, 0).
    - Guardado y restauración de ventana mediante SmartDefaults.
    - Anuncio seguro al chat respetando el presupuesto de red (Ley III: 255 bytes).
]]--

local addonName, S = ...
S.ReadyChecker = S.ReadyChecker or {}
local RC = S.ReadyChecker

-- Helper canónico de resolución de UnitID de mascota en WotLK 3.3.5a
local function GetPetUnit(unit)
    if unit == "player" then
        return "pet"
    end
    local partyIdx = unit:match("^party(%d+)$")
    if partyIdx then
        return "partypet" .. partyIdx
    end
    local raidIdx = unit:match("^raid(%d+)$")
    if raidIdx then
        return "raidpet" .. raidIdx
    end
    return nil
end

-- ============================================================================
-- VERIFICACIONES ESPECÍFICAS POR CLASE (WotLK 3.3.5a)
-- ============================================================================
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
                local hasOHWeapon = GetInventoryItemLink("player", 17)
                if not hasOHWeapon then return true end
                local _, _, _, _, hasOH = GetWeaponEnchantInfo()
                return hasOH
            end
            return true
        end},
    },
    WARLOCK = {
        {type = "pet", name = "Mascota", check = function(unit)
            local petUnit = GetPetUnit(unit)
            return petUnit and UnitExists(petUnit)
        end},
        {type = "healthstone", name = "Piedra de Salud", check = function(unit)
            if unit == "player" then
                for bag = 0, 4 do
                    for slot = 1, GetContainerNumSlots(bag) do
                        local itemId = GetContainerItemID(bag, slot)
                        if itemId and (itemId == 36892 or itemId == 36893 or itemId == 36894) then
                            return true
                        end
                    end
                end
                return false
            end
            return true
        end},
        {type = "spellstone", name = "Piedra de Hechizo", check = function(unit)
            if unit == "player" then
                local hasMH = GetWeaponEnchantInfo()
                return hasMH
            end
            return true
        end},
    },
    HUNTER = {
        {type = "pet", name = "Mascota", check = function(unit)
            local petUnit = GetPetUnit(unit)
            return petUnit and UnitExists(petUnit)
        end},
        {type = "aspect", name = "Aspecto", check = function(unit)
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
                GetSpellInfo(48263), -- Sangre
                GetSpellInfo(48266), -- Escarcha
                GetSpellInfo(48265), -- Profano
            }
            for _, name in ipairs(presences) do
                if name and UnitBuff(unit, name) then
                    return true
                end
            end
            return false
        end},
        {type = "horn", name = "Cuerno de Invierno", check = function(unit)
            local name = GetSpellInfo(57623)
            return name and UnitBuff(unit, name)
        end},
    },
    PALADIN = {
        {type = "aura", name = "Aura", check = function(unit)
            local auras = {
                GetSpellInfo(48942), -- Devoción
                GetSpellInfo(54043), -- Reprensión
                GetSpellInfo(19746), -- Concentración
                GetSpellInfo(48943), -- Sombras
                GetSpellInfo(48945), -- Escarcha
                GetSpellInfo(48947), -- Fuego
                GetSpellInfo(32223), -- Cruzado
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
                GetSpellInfo(31801), -- Venganza
                GetSpellInfo(20165), -- Luz
                GetSpellInfo(20164), -- Justicia
                GetSpellInfo(20166), -- Sabiduría
                GetSpellInfo(53736), -- Corrupción
                GetSpellInfo(21084), -- Rectitud
                GetSpellInfo(20375), -- Orden
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
                GetSpellInfo(57960), -- Escudo de agua
                GetSpellInfo(49281), -- Escudo de relámpagos
                GetSpellInfo(974),   -- Escudo de tierra
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
                GetSpellInfo(43024), -- Armadura de arrabio
                GetSpellInfo(43046), -- Armadura de mago
                GetSpellInfo(43008), -- Armadura de hielo
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
                GetSpellInfo(47436), -- Grito de batalla
                GetSpellInfo(47440), -- Grito de orden
            }
            for _, name in ipairs(shouts) do
                if name and UnitBuff(unit, name) then
                    return true
                end
            end
            return false
        end},
        {type = "stance", name = "Postura", check = function(unit)
            if unit == "player" then
                return GetShapeshiftForm() > 0
            end
            return true
        end},
    },
    DRUID = {
        {type = "motw", name = "Don de lo Salvaje", check = function(unit)
            local name = GetSpellInfo(48470)  -- Don de lo salvaje
            local name2 = GetSpellInfo(48469) -- Marca de lo salvaje
            return (name and UnitBuff(unit, name)) or (name2 and UnitBuff(unit, name2))
        end},
    },
    PRIEST = {
        {type = "fortitude", name = "Fortaleza", check = function(unit)
            local name = GetSpellInfo(48162)  -- Rezo de entereza
            local name2 = GetSpellInfo(48161) -- Palabra de poder: entereza
            return (name and UnitBuff(unit, name)) or (name2 and UnitBuff(unit, name2))
        end},
        {type = "spirit", name = "Espíritu Divino", check = function(unit)
            local name = GetSpellInfo(48074)  -- Rezo de espíritu
            local name2 = GetSpellInfo(48073) -- Espíritu divino
            return (name and UnitBuff(unit, name)) or (name2 and UnitBuff(unit, name2))
        end},
        {type = "shadow", name = "Protección Sombras", check = function(unit)
            local name = GetSpellInfo(48170)  -- Rezo de Protección contra las Sombras
            local name2 = GetSpellInfo(48169) -- Protección contra las Sombras
            return (name and UnitBuff(unit, name)) or (name2 and UnitBuff(unit, name2))
        end},
    },
}

-- Consumibles a verificar
local ConsumableChecks = {
    {type = "flask", name = "Frasco", buffs = {
        GetSpellInfo(53758), -- Flask of Stoneblood
        GetSpellInfo(53755), -- Flask of the Frost Wyrm
        GetSpellInfo(53760), -- Flask of Endless Rage
        GetSpellInfo(54212), -- Flask of Pure Mojo
        GetSpellInfo(53752), -- Lesser Flask of Toughness
    }},
    {type = "food", name = "Comida", buffs = {
        GetSpellInfo(57399), -- Bien alimentado (Festín)
        GetSpellInfo(57294), -- Bien alimentado
    }},
}

RC.Frame = nil
RC.Results = {}
RC.IsVisible = false

-- ============================================================================
-- HELPER DE CONFIGURACIÓN DEFENSIVA
-- ============================================================================
function RC:GetOption(key)
    if S.ModuleConfig then
        local val = S.ModuleConfig:GetValue("ReadyChecker", key)
        if val ~= nil then return val end
    end
    -- Fallbacks seguros
    if key == "enabled" then return true
    elseif key == "autoCheck" then return false
    elseif key == "checkBuffs" then return true
    elseif key == "checkConsumables" then return true
    elseif key == "checkClass" then return true
    elseif key == "alertSound" then return true
    elseif key == "announceResults" or key == "announce" then return true
    end
    return true
end

function RC:Initialize()
    if self.initialized then return end
    if not self:GetOption("enabled") then return end
    self.initialized = true

    self:CreateFrame()
    self:RegisterEvents()

    if S.Print then
        S:Print("|cFF00FF00[ReadyChecker]|r Módulo de verificación previa a combate activo.")
    end
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

-- ============================================================================
-- INTERFAZ VISUAL
-- ============================================================================
function RC:CreateFrame()
    if self.Frame then return self.Frame end

    local f = CreateFrame("Frame", "SequitoReadyChecker", UIParent)
    f:SetSize(360, 420)
    f:SetPoint("CENTER", UIParent, "CENTER", 0, 0)
    f:SetBackdrop({
        bgFile = "Interface\\Buttons\\WHITE8X8",
        edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
        tile = false, edgeSize = 14,
        insets = {left = 3, right = 3, top = 3, bottom = 3}
    })
    f:SetBackdropColor(0.05, 0.05, 0.08, 0.92)
    f:SetBackdropBorderColor(0.2, 0.7, 0.3, 0.9)
    f:EnableMouse(true)
    f:SetMovable(true)
    f:RegisterForDrag("LeftButton")
    f:SetScript("OnDragStart", f.StartMoving)
    f:SetScript("OnDragStop", function(self)
        self:StopMovingOrSizing()
        if S.SmartDefaults then
            S.SmartDefaults:SavePosition("ReadyChecker", self)
        end
    end)
    f:SetClampedToScreen(true)
    f:Hide()

    -- Título
    local title = f:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
    title:SetPoint("TOP", f, "TOP", 0, -12)
    title:SetText("|cFF00FF00Sequito|r - Ready Check Mejorado")

    -- Botón cerrar
    local closeBtn = CreateFrame("Button", nil, f, "UIPanelCloseButton")
    closeBtn:SetPoint("TOPRIGHT", f, "TOPRIGHT", -4, -4)
    closeBtn:SetScript("OnClick", function() RC:Toggle() end)

    -- Botón de escaneo manual
    local scanBtn = CreateFrame("Button", nil, f, "UIPanelButtonTemplate")
    scanBtn:SetSize(130, 24)
    scanBtn:SetPoint("TOP", f, "TOP", 0, -38)
    scanBtn:SetText("Escanear Banda")
    scanBtn:SetScript("OnClick", function() RC:ScanRaid(false) end)

    -- Scroll frame para resultados
    local scrollFrame = CreateFrame("ScrollFrame", "SequitoRCScroll", f, "UIPanelScrollFrameTemplate")
    scrollFrame:SetPoint("TOPLEFT", f, "TOPLEFT", 12, -70)
    scrollFrame:SetPoint("BOTTOMRIGHT", f, "BOTTOMRIGHT", -32, 48)

    local content = CreateFrame("Frame", nil, scrollFrame)
    content:SetSize(310, 600)
    scrollFrame:SetScrollChild(content)
    f.content = content

    -- Botón anunciar problemas
    local announceBtn = CreateFrame("Button", nil, f, "UIPanelButtonTemplate")
    announceBtn:SetSize(170, 24)
    announceBtn:SetPoint("BOTTOM", f, "BOTTOM", 0, 14)
    announceBtn:SetText("Anunciar Problemas")
    announceBtn:SetScript("OnClick", function() RC:AnnounceProblems(true) end)

    self.Frame = f
    self.Rows = {}

    if S.SmartDefaults then
        S.SmartDefaults:RestorePosition("ReadyChecker")
    end

    return f
end

function RC:CreateResultRow(parent, index)
    local row = CreateFrame("Frame", nil, parent)
    row:SetSize(310, 22)
    row:SetPoint("TOPLEFT", parent, "TOPLEFT", 0, -((index - 1) * 24))

    local statusIcon = row:CreateTexture(nil, "ARTWORK")
    statusIcon:SetSize(16, 16)
    statusIcon:SetPoint("LEFT", row, "LEFT", 2, 0)
    row.statusIcon = statusIcon

    local playerName = row:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    playerName:SetPoint("LEFT", statusIcon, "RIGHT", 4, 0)
    playerName:SetWidth(90)
    playerName:SetJustifyH("LEFT")
    row.playerName = playerName

    local problems = row:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    problems:SetPoint("LEFT", playerName, "RIGHT", 4, 0)
    problems:SetPoint("RIGHT", row, "RIGHT", -4, 0)
    problems:SetJustifyH("LEFT")
    row.problems = problems

    row:Hide()
    return row
end

-- ============================================================================
-- LÓGICA DE ESCANEO PRE-PULL
-- ============================================================================
function RC:ScanRaid(isAutoCheck)
    -- Si el escaneo fue disparado automáticamente por el evento READY_CHECK, respetar autoCheck
    if isAutoCheck and not self:GetOption("autoCheck") then
        return
    end

    self.Results = {}

    local checkBuffs = self:GetOption("checkBuffs")
    local checkConsumables = self:GetOption("checkConsumables")
    local checkClass = self:GetOption("checkClass")

    local function checkPlayer(unit, name, class)
        local result = {
            name = name or UnitName(unit) or "Desconocido",
            class = class or select(2, UnitClass(unit)) or "WARRIOR",
            unit = unit,
            problems = {},
            ready = true
        }

        -- Verificar checks específicos de clase
        if checkClass and class then
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
        end

        -- Verificar consumibles
        if checkConsumables then
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
        end

        -- Verificar salud y maná con blindaje contra división por cero
        local maxHP = UnitHealthMax(unit) or 0
        local curHP = UnitHealth(unit) or 0
        local healthPct = (maxHP > 0) and math.floor((curHP / maxHP) * 100) or 100

        if healthPct < 100 then
            table.insert(result.problems, string.format("Vida: %d%%", healthPct))
            if healthPct < 80 then
                result.ready = false
            end
        end

        local powerType = UnitPowerType(unit)
        if powerType == 0 then -- Maná
            local maxMana = UnitPowerMax(unit, 0) or 0
            local curMana = UnitPower(unit, 0) or 0
            local manaPct = (maxMana > 0) and math.floor((curMana / maxMana) * 100) or 100
            if manaPct < 80 then
                table.insert(result.problems, string.format("Maná: %d%%", manaPct))
                result.ready = false
            end
        end

        -- Verificar si está muerto o fantasma
        if UnitIsDeadOrGhost(unit) then
            result.problems = {"MUERTO"}
            result.ready = false
        -- Verificar si está desconectado
        elseif not UnitIsConnected(unit) then
            result.problems = {"DESCONECTADO"}
            result.ready = false
        -- Verificar si está AFK
        elseif UnitIsAFK(unit) then
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
        local myName = UnitName("player")
        local myClass = select(2, UnitClass("player"))
        checkPlayer("player", myName, myClass)

        for i = 1, numParty do
            local pname = UnitName("party"..i)
            local pclass = select(2, UnitClass("party"..i))
            if pname then
                checkPlayer("party"..i, pname, pclass)
            end
        end
    else
        local myName = UnitName("player")
        local myClass = select(2, UnitClass("player"))
        checkPlayer("player", myName, myClass)
    end

    -- Ordenar: miembros con problemas primero
    table.sort(self.Results, function(a, b)
        if a.ready and not b.ready then return false end
        if not a.ready and b.ready then return true end
        return a.name < b.name
    end)

    self:UpdateDisplay()

    -- Resumen en consola
    local readyCount = 0
    local totalCount = #self.Results
    for _, result in ipairs(self.Results) do
        if result.ready then readyCount = readyCount + 1 end
    end

    local color = (readyCount == totalCount) and "|cFF00FF00" or "|cFFFF5555"
    local summary = string.format("%s[ReadyCheck]|r Verificación: %d/%d listos.", color, readyCount, totalCount)
    if S.Print then
        S:Print(summary)
    else
        DEFAULT_CHAT_FRAME:AddMessage(summary)
    end
end

function RC:UpdateDisplay()
    if not self.Frame or not self.Frame.content then return end

    for _, row in ipairs(self.Rows) do
        row:Hide()
    end

    for i, result in ipairs(self.Results) do
        local row = self.Rows[i]
        if not row then
            row = self:CreateResultRow(self.Frame.content, i)
            self.Rows[i] = row
        end

        if result.ready then
            row.statusIcon:SetTexture("Interface\\RaidFrame\\ReadyCheck-Ready")
        else
            row.statusIcon:SetTexture("Interface\\RaidFrame\\ReadyCheck-NotReady")
        end

        local classColor = (RAID_CLASS_COLORS and RAID_CLASS_COLORS[result.class]) or {r=1, g=1, b=1}
        row.playerName:SetText(string.format("|cFF%02x%02x%02x%s|r",
            classColor.r * 255, classColor.g * 255, classColor.b * 255, result.name))

        if #result.problems > 0 then
            row.problems:SetText("|cFFFF6600" .. table.concat(result.problems, ", ") .. "|r")
        else
            row.problems:SetText("|cFF00FF00Listo|r")
        end

        row:Show()
    end

    self.Frame.content:SetHeight(math.max(#self.Results * 24, 120))
end

-- ============================================================================
-- ANUNCIO SEGURO DE PROBLEMAS AL CHAT
-- ============================================================================
function RC:AnnounceProblems(forceManual)
    if not forceManual and not (self:GetOption("announceResults") or self:GetOption("announce")) then
        return
    end

    local problems = {}
    for _, result in ipairs(self.Results) do
        if not result.ready and #result.problems > 0 then
            table.insert(problems, result.name .. ": " .. table.concat(result.problems, ", "))
        end
    end

    local channel = self:GetGroupChannel()

    if #problems == 0 then
        local msg = "[Sequito] ¡Todos los miembros están listos para el pull!"
        if channel then
            SendChatMessage(msg, channel)
        else
            if S.Print then S:Print(msg) else DEFAULT_CHAT_FRAME:AddMessage(msg) end
        end
        return
    end

    if channel then
        -- Despacho seguro bajo el límite inviolable de 255 bytes (Ley III)
        local header = string.format("[Sequito] %d miembro(s) con faltantes: ", #problems)
        local line = header
        for _, problem in ipairs(problems) do
            if #(line .. problem .. "; ") > 230 then
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
        local title = string.format("|cFFFF3333[Sequito]|r %d miembros con problemas detectados:", #problems)
        if S.Print then S:Print(title) else DEFAULT_CHAT_FRAME:AddMessage(title) end
        for _, problem in ipairs(problems) do
            local line = "  - " .. problem
            if S.Print then S:Print(line) else DEFAULT_CHAT_FRAME:AddMessage(line) end
        end
    end
end

-- ============================================================================
-- EVENTOS DE SERVIDOR
-- ============================================================================
function RC:RegisterEvents()
    local f = CreateFrame("Frame")
    f:RegisterEvent("READY_CHECK")
    f:RegisterEvent("READY_CHECK_FINISHED")
    f:SetScript("OnEvent", function(self, event, ...)
        if event == "READY_CHECK" then
            if RC:GetOption("autoCheck") then
                RC:Show()
                RC:ScanRaid(true)
                if RC:GetOption("alertSound") then
                    PlaySound("ReadyCheck")
                end
            end
        elseif event == "READY_CHECK_FINISHED" then
            if RC:GetOption("autoCheck") and RC:GetOption("announceResults") then
                RC:AnnounceProblems(false)
            end
        end
    end)
    self.eventFrame = f
end

-- ============================================================================
-- MÉTODOS DE CONTROL Y COMANDOS SLASH
-- ============================================================================
function RC:Toggle()
    if not self.Frame then
        self:CreateFrame()
    end
    self.IsVisible = not self.IsVisible
    if self.IsVisible then
        self.Frame:Show()
        self:ScanRaid(false)
    else
        self.Frame:Hide()
    end
end

function RC:Show()
    if not self.Frame then
        self:CreateFrame()
    end
    self.IsVisible = true
    self.Frame:Show()
    self:ScanRaid(false)
end

function RC:Hide()
    if self.Frame then
        self.IsVisible = false
        self.Frame:Hide()
    end
end

SLASH_SEQUITORC1 = "/src"
SLASH_SEQUITORC2 = "/sreadycheck"
SlashCmdList["SEQUITORC"] = function()
    RC:Toggle()
end

-- Inicialización limpia al iniciar sesión
local loader = CreateFrame("Frame")
loader:RegisterEvent("PLAYER_LOGIN")
loader:SetScript("OnEvent", function()
    RC:Initialize()
end)
