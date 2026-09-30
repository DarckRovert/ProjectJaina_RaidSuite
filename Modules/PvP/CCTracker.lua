--[[
    Sequito - CC Tracker
    Rastreo de Crowd Control (Polymorph, Fear, Banish, Shackle, Freezing Trap, etc.)
    Version: 8.5.0 (WotLK 3.3.5a Build 12340)
    
    Características:
    - Zero Heap Thrashing: Pool virtual reciclable de StatusBars.
    - Catálogo maestro bilingüe indexado por SpellID y resuelto por GetSpellInfo.
    - Detección de PvP clamp (Tope de 10s en jugadores).
    - Ticker OnUpdate con throttling (0.05s) y auto-pausa cuando no hay CC activo.
    - Compatibilidad estricta WotLK 3.3.5a: texturas WHITE8X8 con SetVertexColor.
    - Integración bidireccional con SmartDefaults y ModuleConfig.
    - Comandos slash /cct y /cctracker con modo de prueba (/cct test).
]]--

local addonName, S = ...
S.CCTracker = S.CCTracker or {}
local CC = S.CCTracker

-- Constantes y Canales
local COMBATLOG_OBJECT_TYPE_PLAYER = COMBATLOG_OBJECT_TYPE_PLAYER or 0x00000400

-- ============================================================================
-- CATÁLOGO MAESTRO DE HECHIZOS DE CONTROL (WOTLK 3.3.5a)
-- [spellID] = { pve = seg, pvp = seg, class = CLASS }
-- ============================================================================
local MASTER_CC_SPELLS = {
    -- Mage
    [118]   = { pve = 50, pvp = 10, class = "MAGE" },    -- Polymorph Rank 1
    [12824] = { pve = 50, pvp = 10, class = "MAGE" },    -- Polymorph Rank 2
    [12825] = { pve = 50, pvp = 10, class = "MAGE" },    -- Polymorph Rank 3
    [12826] = { pve = 50, pvp = 10, class = "MAGE" },    -- Polymorph Rank 4
    [28272] = { pve = 50, pvp = 10, class = "MAGE" },    -- Polymorph (Pig)
    [28271] = { pve = 50, pvp = 10, class = "MAGE" },    -- Polymorph (Turtle)
    [61305] = { pve = 50, pvp = 10, class = "MAGE" },    -- Polymorph (Black Cat)
    [61721] = { pve = 50, pvp = 10, class = "MAGE" },    -- Polymorph (Rabbit)
    [61780] = { pve = 50, pvp = 10, class = "MAGE" },    -- Polymorph (Turkey)
    -- Warlock
    [5782]  = { pve = 20, pvp = 10, class = "WARLOCK" }, -- Fear Rank 1
    [6213]  = { pve = 20, pvp = 10, class = "WARLOCK" }, -- Fear Rank 2
    [6215]  = { pve = 20, pvp = 10, class = "WARLOCK" }, -- Fear Rank 3
    [5484]  = { pve = 15, pvp = 10, class = "WARLOCK" }, -- Howl of Terror Rank 1
    [17928] = { pve = 15, pvp = 10, class = "WARLOCK" }, -- Howl of Terror Rank 2
    [6358]  = { pve = 15, pvp = 10, class = "WARLOCK" }, -- Seduction (Succubus)
    [710]   = { pve = 30, pvp = 30, class = "WARLOCK" }, -- Banish Rank 1
    [18647] = { pve = 30, pvp = 30, class = "WARLOCK" }, -- Banish Rank 2
    [1098]  = { pve = 300, pvp = 300, class = "WARLOCK" }, -- Enslave Demon Rank 1
    [11725] = { pve = 300, pvp = 300, class = "WARLOCK" }, -- Enslave Demon Rank 2
    [11726] = { pve = 300, pvp = 300, class = "WARLOCK" }, -- Enslave Demon Rank 3
    [61191] = { pve = 300, pvp = 300, class = "WARLOCK" }, -- Enslave Demon Rank 4
    -- Priest
    [9484]  = { pve = 50, pvp = 10, class = "PRIEST" },  -- Shackle Undead Rank 1
    [9485]  = { pve = 50, pvp = 10, class = "PRIEST" },  -- Shackle Undead Rank 2
    [10955] = { pve = 50, pvp = 10, class = "PRIEST" },  -- Shackle Undead Rank 3
    [605]   = { pve = 8,  pvp = 8,  class = "PRIEST" },  -- Mind Control
    [8122]  = { pve = 8,  pvp = 8,  class = "PRIEST" },  -- Psychic Scream Rank 1
    [8124]  = { pve = 8,  pvp = 8,  class = "PRIEST" },  -- Psychic Scream Rank 2
    [10888] = { pve = 8,  pvp = 8,  class = "PRIEST" },  -- Psychic Scream Rank 3
    [10890] = { pve = 8,  pvp = 8,  class = "PRIEST" },  -- Psychic Scream Rank 4
    [64044] = { pve = 3,  pvp = 3,  class = "PRIEST" },  -- Psychic Horror
    -- Rogue
    [6770]  = { pve = 60, pvp = 10, class = "ROGUE" },   -- Sap Rank 1
    [2070]  = { pve = 60, pvp = 10, class = "ROGUE" },   -- Sap Rank 2
    [11297] = { pve = 60, pvp = 10, class = "ROGUE" },   -- Sap Rank 3
    [51724] = { pve = 60, pvp = 10, class = "ROGUE" },   -- Sap Rank 4
    [2094]  = { pve = 10, pvp = 10, class = "ROGUE" },   -- Blind
    [1776]  = { pve = 4,  pvp = 4,  class = "ROGUE" },   -- Gouge Rank 1
    [1777]  = { pve = 4,  pvp = 4,  class = "ROGUE" },   -- Gouge Rank 2
    [8629]  = { pve = 4,  pvp = 4,  class = "ROGUE" },   -- Gouge Rank 3
    [11285] = { pve = 4,  pvp = 4,  class = "ROGUE" },   -- Gouge Rank 4
    [11286] = { pve = 4,  pvp = 4,  class = "ROGUE" },   -- Gouge Rank 5
    [38764] = { pve = 4,  pvp = 4,  class = "ROGUE" },   -- Gouge Rank 6
    -- Hunter
    [3355]  = { pve = 60, pvp = 10, class = "HUNTER" },  -- Freezing Trap Effect Rank 1
    [14308] = { pve = 60, pvp = 10, class = "HUNTER" },  -- Freezing Trap Effect Rank 2
    [14309] = { pve = 60, pvp = 10, class = "HUNTER" },  -- Freezing Trap Effect Rank 3
    [60192] = { pve = 60, pvp = 10, class = "HUNTER" },  -- Freezing Arrow Effect
    [19386] = { pve = 30, pvp = 10, class = "HUNTER" },  -- Wyvern Sting Rank 1
    [24132] = { pve = 30, pvp = 10, class = "HUNTER" },  -- Wyvern Sting Rank 2
    [24133] = { pve = 30, pvp = 10, class = "HUNTER" },  -- Wyvern Sting Rank 3
    [27068] = { pve = 30, pvp = 10, class = "HUNTER" },  -- Wyvern Sting Rank 4
    [49011] = { pve = 30, pvp = 10, class = "HUNTER" },  -- Wyvern Sting Rank 5
    [49012] = { pve = 30, pvp = 10, class = "HUNTER" },  -- Wyvern Sting Rank 6
    [1513]  = { pve = 20, pvp = 10, class = "HUNTER" },  -- Scare Beast Rank 1
    [14326] = { pve = 20, pvp = 10, class = "HUNTER" },  -- Scare Beast Rank 2
    [14327] = { pve = 20, pvp = 10, class = "HUNTER" },  -- Scare Beast Rank 3
    -- Druid
    [2637]  = { pve = 40, pvp = 10, class = "DRUID" },   -- Hibernate Rank 1
    [18657] = { pve = 40, pvp = 10, class = "DRUID" },   -- Hibernate Rank 2
    [18658] = { pve = 40, pvp = 10, class = "DRUID" },   -- Hibernate Rank 3
    [339]   = { pve = 30, pvp = 10, class = "DRUID" },   -- Entangling Roots Rank 1
    [1062]  = { pve = 30, pvp = 10, class = "DRUID" },   -- Entangling Roots Rank 2
    [5195]  = { pve = 30, pvp = 10, class = "DRUID" },   -- Entangling Roots Rank 3
    [5196]  = { pve = 30, pvp = 10, class = "DRUID" },   -- Entangling Roots Rank 4
    [9852]  = { pve = 30, pvp = 10, class = "DRUID" },   -- Entangling Roots Rank 5
    [9853]  = { pve = 30, pvp = 10, class = "DRUID" },   -- Entangling Roots Rank 6
    [26989] = { pve = 30, pvp = 10, class = "DRUID" },   -- Entangling Roots Rank 7
    [53308] = { pve = 30, pvp = 10, class = "DRUID" },   -- Entangling Roots Rank 8
    [33786] = { pve = 6,  pvp = 6,  class = "DRUID" },   -- Cyclone
    -- Paladin
    [20066] = { pve = 60, pvp = 10, class = "PALADIN" }, -- Repentance
    [853]   = { pve = 6,  pvp = 6,  class = "PALADIN" }, -- Hammer of Justice Rank 1
    [5588]  = { pve = 6,  pvp = 6,  class = "PALADIN" }, -- Hammer of Justice Rank 2
    [5589]  = { pve = 6,  pvp = 6,  class = "PALADIN" }, -- Hammer of Justice Rank 3
    [10308] = { pve = 6,  pvp = 6,  class = "PALADIN" }, -- Hammer of Justice Rank 4
    [10326] = { pve = 20, pvp = 10, class = "PALADIN" }, -- Turn Evil
    -- Shaman
    [51514] = { pve = 30, pvp = 8,  class = "SHAMAN" },  -- Hex
    -- Death Knight
    [49203] = { pve = 10, pvp = 10, class = "DEATHKNIGHT" }, -- Hungering Cold
    -- Warrior
    [5246]  = { pve = 8,  pvp = 8,  class = "WARRIOR" }, -- Intimidating Shout
}

-- Tablas dinámicas de resolución bilingüe
CC.SpellsByID = MASTER_CC_SPELLS
CC.SpellsByName = {}

function CC:BuildSpellCatalog()
    wipe(self.SpellsByName)
    for spellID, data in pairs(self.SpellsByID) do
        local name = GetSpellInfo(spellID)
        if name and name ~= "" then
            self.SpellsByName[name] = data
        end
    end
    -- Alias manuales defensivos en español e inglés
    local aliases = {
        ["Polimorfia"] = { pve = 50, pvp = 10 },
        ["Polymorph"] = { pve = 50, pvp = 10 },
        ["Miedo"] = { pve = 20, pvp = 10 },
        ["Fear"] = { pve = 20, pvp = 10 },
        ["Desterrar"] = { pve = 30, pvp = 30 },
        ["Banish"] = { pve = 30, pvp = 30 },
        ["Seducción"] = { pve = 15, pvp = 10 },
        ["Seduction"] = { pve = 15, pvp = 10 },
        ["Esclavizar demonio"] = { pve = 300, pvp = 300 },
        ["Enslave Demon"] = { pve = 300, pvp = 300 },
        ["Encadenar no-muerto"] = { pve = 50, pvp = 10 },
        ["Shackle Undead"] = { pve = 50, pvp = 10 },
        ["Efecto de trampa congelante"] = { pve = 60, pvp = 10 },
        ["Freezing Trap Effect"] = { pve = 60, pvp = 10 },
        ["Trampa congelante"] = { pve = 60, pvp = 10 },
        ["Freezing Trap"] = { pve = 60, pvp = 10 },
        ["Porrazo"] = { pve = 60, pvp = 10 },
        ["Sap"] = { pve = 60, pvp = 10 },
        ["Ceguera"] = { pve = 10, pvp = 10 },
        ["Blind"] = { pve = 10, pvp = 10 },
        ["Gubia"] = { pve = 4, pvp = 4 },
        ["Gouge"] = { pve = 4, pvp = 4 },
        ["Trabazón con raíces"] = { pve = 30, pvp = 10 },
        ["Entangling Roots"] = { pve = 30, pvp = 10 },
        ["Hibernar"] = { pve = 40, pvp = 10 },
        ["Hibernate"] = { pve = 40, pvp = 10 },
        ["Ciclón"] = { pve = 6, pvp = 6 },
        ["Cyclone"] = { pve = 6, pvp = 6 },
        ["Maleficio"] = { pve = 30, pvp = 8 },
        ["Hex"] = { pve = 30, pvp = 8 },
        ["Arrepentimiento"] = { pve = 60, pvp = 10 },
        ["Repentance"] = { pve = 60, pvp = 10 },
    }
    for aliasName, data in pairs(aliases) do
        if not self.SpellsByName[aliasName] then
            self.SpellsByName[aliasName] = data
        end
    end
end

-- ============================================================================
-- GESTIÓN DE CONFIGURACIÓN DEFENSIVA
-- ============================================================================
function CC:GetOption(key)
    if S.ModuleConfig then
        local val = S.ModuleConfig:GetValue("CCTracker", key)
        if val ~= nil then return val end
    end
    -- Fallbacks seguros en caso de claves no persistidas
    if key == "enabled" then return true
    elseif key == "showBars" then return true
    elseif key == "playSound" then return true
    elseif key == "announceBreak" then return false
    elseif key == "warningTime" then return 5
    elseif key == "barHeight" then return 20
    end
    return true
end

-- ============================================================================
-- INICIALIZACIÓN DEL MÓDULO
-- ============================================================================
function CC:Initialize()
    if self.initialized then return end
    if not self:GetOption("enabled") then return end
    self.initialized = true

    -- Estructuras de datos para Zero Heap Thrashing
    self.BarPool = {}
    self.ActiveTimers = {} -- [guid_spellID] = timerData
    self.ActiveList = {}   -- Lista indexada de timerData
    self.ActiveBars = {}   -- [timerData] = barFrame

    self:BuildSpellCatalog()
    self:CreateAnchor()
    self:CreateTicker()
    self:RegisterEvents()

    if S.Print then
        S:Print("|cFF9966FF[CCTracker]|r Módulo de control de masas activo.")
    end
end

-- ============================================================================
-- ANCLAJE Y COMPATIBILIDAD CON SMARTDEFAULTS
-- ============================================================================
function CC:CreateAnchor()
    if self.Anchor then return self.Anchor end

    local f = CreateFrame("Frame", "SequitoCCAnchor", UIParent)
    f:SetSize(220, 24)
    f:SetPoint("CENTER", UIParent, "CENTER", 0, 120)
    f:SetMovable(true)
    f:EnableMouse(true)
    f:RegisterForDrag("LeftButton")
    f:SetClampedToScreen(true)

    f.bg = f:CreateTexture(nil, "BACKGROUND")
    f.bg:SetAllPoints()
    f.bg:SetTexture("Interface\\Buttons\\WHITE8X8")
    f.bg:SetVertexColor(0.1, 0.05, 0.2, 0.7)

    f.border = CreateFrame("Frame", nil, f)
    f.border:SetAllPoints()
    f.border:SetBackdrop({
        edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
        edgeSize = 10,
        insets = { left = 2, right = 2, top = 2, bottom = 2 }
    })
    f.border:SetBackdropBorderColor(0.7, 0.3, 1.0, 0.8)

    f.text = f:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    f.text:SetPoint("CENTER", 0, 0)
    f.text:SetText("|cFFCC88FF[CCTracker Anchor - Arrastra]|r")

    f:SetScript("OnDragStart", function(self)
        if not (S.db and S.db.profile and S.db.profile.Locked) then
            self:StartMoving()
        end
    end)
    f:SetScript("OnDragStop", function(self)
        self:StopMovingOrSizing()
        if S.SmartDefaults then
            S.SmartDefaults:SavePosition("CCTracker", self)
        end
    end)

    -- Visibilidad por defecto: oculto para no estorbar, visible en /cct toggle o test
    f.bg:Hide()
    f.border:Hide()
    f.text:Hide()

    self.Anchor = f
    self.Frame = f -- Exposición canónica para SmartDefaults:HookModuleFrame

    if S.SmartDefaults then
        S.SmartDefaults:RestorePosition("CCTracker")
    end

    return f
end

function CC:ToggleAnchor(show)
    if not self.Anchor then self:CreateAnchor() end
    if show == nil then
        show = not self.Anchor.bg:IsShown()
    end
    if show then
        self.Anchor.bg:Show()
        self.Anchor.border:Show()
        self.Anchor.text:Show()
        if S.Print then
            S:Print("|cFF9966FF[CCTracker]|r Ancla desbloqueada. Arrastra con clic izquierdo.")
        end
    else
        self.Anchor.bg:Hide()
        self.Anchor.border:Hide()
        self.Anchor.text:Hide()
        if S.Print then
            S:Print("|cFF9966FF[CCTracker]|r Ancla bloqueada.")
        end
    end
end

-- ============================================================================
-- POOL VIRTUAL RECICLABLE DE STATUSBARS (LEY IV: ZERO HEAP THRASHING)
-- ============================================================================
function CC:AcquireBar()
    local bar = table.remove(self.BarPool)
    if not bar then
        local barHeight = tonumber(self:GetOption("barHeight")) or 20
        bar = CreateFrame("StatusBar", nil, UIParent)
        bar:SetSize(220, barHeight)
        bar:SetStatusBarTexture("Interface\\TargetingFrame\\UI-StatusBar")
        bar:SetMinMaxValues(0, 1)

        -- Fondo sólido estrictamente compatible con WotLK 3.3.5a
        bar.bg = bar:CreateTexture(nil, "BACKGROUND")
        bar.bg:SetAllPoints()
        bar.bg:SetTexture("Interface\\Buttons\\WHITE8X8")
        bar.bg:SetVertexColor(0.08, 0.08, 0.08, 0.85)

        -- Icono del hechizo
        bar.icon = bar:CreateTexture(nil, "ARTWORK")
        bar.icon:SetSize(barHeight, barHeight)
        bar.icon:SetPoint("RIGHT", bar, "LEFT", -3, 0)
        bar.icon:SetTexCoord(0.07, 0.93, 0.07, 0.93)

        -- Borde del icono
        bar.iconBorder = bar:CreateTexture(nil, "OVERLAY")
        bar.iconBorder:SetSize(barHeight + 4, barHeight + 4)
        bar.iconBorder:SetPoint("CENTER", bar.icon, "CENTER", 0, 0)
        bar.iconBorder:SetTexture("Interface\\Buttons\\UI-ActionButton-Border")
        bar.iconBorder:SetBlendMode("ADD")
        bar.iconBorder:SetVertexColor(0.8, 0.4, 1.0, 0.7)

        -- Etiqueta del objetivo y hechizo
        bar.label = bar:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
        bar.label:SetPoint("LEFT", bar, "LEFT", 5, 0)
        bar.label:SetPoint("RIGHT", bar, "RIGHT", -45, 0)
        bar.label:SetJustifyH("LEFT")

        -- Contador de tiempo restante
        bar.time = bar:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
        bar.time:SetPoint("RIGHT", bar, "RIGHT", -5, 0)
        bar.time:SetJustifyH("RIGHT")
    else
        local barHeight = tonumber(self:GetOption("barHeight")) or 20
        bar:SetHeight(barHeight)
        bar.icon:SetSize(barHeight, barHeight)
        bar.iconBorder:SetSize(barHeight + 4, barHeight + 4)
    end

    bar:Show()
    return bar
end

function CC:ReleaseBar(bar)
    if not bar then return end
    bar:Hide()
    bar:ClearAllPoints()
    table.insert(self.BarPool, bar)
end

-- ============================================================================
-- TICKER ONUPDATE DINÁMICO CON THROTTLING
-- ============================================================================
function CC:CreateTicker()
    if self.TickerFrame then return self.TickerFrame end

    local f = CreateFrame("Frame", nil, UIParent)
    f.elapsed = 0
    f:SetScript("OnUpdate", function(ticker, dt)
        ticker.elapsed = ticker.elapsed + dt
        if ticker.elapsed < 0.05 then return end
        ticker.elapsed = 0
        CC:OnUpdate()
    end)
    f:Hide() -- Oculto mientras no haya CCs activos
    self.TickerFrame = f
    return f
end

function CC:OnUpdate()
    local now = GetTime()
    local count = #self.ActiveList
    local warningTime = tonumber(self:GetOption("warningTime")) or 5
    local needLayout = false

    for i = count, 1, -1 do
        local timer = self.ActiveList[i]
        local remaining = timer.endTime - now

        if remaining <= 0 then
            -- Expirado naturalmente
            self:StopTimer(timer.guid, timer.spellID, false)
            needLayout = true
        else
            local bar = self.ActiveBars[timer]
            if bar then
                local progress = remaining / timer.duration
                if progress > 1 then progress = 1 elseif progress < 0 then progress = 0 end
                bar:SetValue(progress)

                if remaining >= 60 then
                    bar.time:SetText(string.format("%d:%02d", math.floor(remaining / 60), math.floor(remaining % 60)))
                elseif remaining >= 10 then
                    bar.time:SetText(string.format("%.0fs", remaining))
                else
                    bar.time:SetText(string.format("%.1fs", remaining))
                end

                -- Alerta visual: rojo si queda menos de warningTime
                if remaining <= warningTime then
                    bar:SetStatusBarColor(1.0, 0.2, 0.2, 1.0)
                else
                    bar:SetStatusBarColor(0.9, 0.5, 0.1, 1.0)
                end
            end
        end
    end

    if needLayout then
        self:LayoutBars()
    end
end

-- ============================================================================
-- REPOSICIONAMIENTO Y LAYOUT DE BARRAS
-- ============================================================================
function CC:LayoutBars()
    local count = #self.ActiveList
    if count == 0 then
        if self.TickerFrame then self.TickerFrame:Hide() end
        return
    end

    if self.TickerFrame and not self.TickerFrame:IsShown() then
        self.TickerFrame:Show()
    end

    local barHeight = tonumber(self:GetOption("barHeight")) or 20
    local spacing = barHeight + 4
    local anchor = self.Anchor or self:CreateAnchor()

    for index, timer in ipairs(self.ActiveList) do
        local bar = self.ActiveBars[timer]
        if bar then
            bar:ClearAllPoints()
            bar:SetPoint("TOP", anchor, "BOTTOM", 0, -((index - 1) * spacing + 4))
        end
    end
end

-- ============================================================================
-- REGISTRO Y GESTIÓN DE EVENTOS CLEU
-- ============================================================================
function CC:RegisterEvents()
    if S.CLEU and S.CLEU.Register then
        local function onCLEU(...)
            CC:OnCombatLog(...)
        end
        S.CLEU:Register("SPELL_AURA_APPLIED", onCLEU)
        S.CLEU:Register("SPELL_AURA_REFRESH", onCLEU)
        S.CLEU:Register("SPELL_AURA_REMOVED", onCLEU)
    else
        local f = CreateFrame("Frame")
        f:RegisterEvent("COMBAT_LOG_EVENT_UNFILTERED")
        f:SetScript("OnEvent", function(_, _, ...)
            CC:OnCombatLog(...)
        end)
    end
end

function CC:OnCombatLog(...)
    local timestamp, eventType, sourceGUID, sourceName, sourceFlags, destGUID, destName, destFlags, spellID, spellName = ...

    -- Filtrar solo auras originadas por el jugador o su mascota
    if sourceGUID ~= UnitGUID("player") and sourceGUID ~= UnitGUID("pet") then
        return
    end

    local spellData = (spellID and self.SpellsByID[spellID]) or (spellName and self.SpellsByName[spellName])
    if not spellData then return end

    if eventType == "SPELL_AURA_APPLIED" or eventType == "SPELL_AURA_REFRESH" then
        local isPlayer = destFlags and (bit.band(destFlags, COMBATLOG_OBJECT_TYPE_PLAYER) > 0)
        local duration = isPlayer and spellData.pvp or spellData.pve
        self:StartTimer(destGUID, destName or "Objetivo", spellID or 0, spellName or "CC", duration)
    elseif eventType == "SPELL_AURA_REMOVED" then
        self:StopTimer(destGUID, spellID or 0, true)
    end
end

-- ============================================================================
-- ARRANQUE Y PARADA DE TEMPORIZADORES
-- ============================================================================
function CC:StartTimer(guid, targetName, spellID, spellName, duration)
    if self:GetOption("showBars") == false then return end
    if not guid or not duration or duration <= 0 then return end

    local timerKey = guid .. "_" .. tostring(spellID)
    local timer = self.ActiveTimers[timerKey]

    if not timer then
        timer = {
            key = timerKey,
            guid = guid,
            targetName = targetName or "Desconocido",
            spellID = spellID,
            spellName = spellName or "CC",
            duration = duration,
            endTime = GetTime() + duration,
        }
        self.ActiveTimers[timerKey] = timer
        table.insert(self.ActiveList, timer)

        local bar = self:AcquireBar()
        self.ActiveBars[timer] = bar

        local _, _, icon = GetSpellInfo(spellID)
        bar.icon:SetTexture(icon or "Interface\\Icons\\Spell_Frost_FreezingBreath")
        bar.label:SetText(timer.targetName .. " (" .. timer.spellName .. ")")
        bar:SetStatusBarColor(0.9, 0.5, 0.1, 1.0)
    else
        -- Refresco del temporizador existente
        timer.targetName = targetName or timer.targetName
        timer.duration = duration
        timer.endTime = GetTime() + duration
    end

    if self:GetOption("playSound") then
        PlaySound("igPVPUpdate")
    end

    self:LayoutBars()
end

function CC:StopTimer(guid, spellID, alertBreak)
    local timerKey = guid .. "_" .. tostring(spellID)
    local timer = self.ActiveTimers[timerKey]

    -- Fallback si spellID no coincide exactamente (búsqueda por GUID)
    if not timer and guid then
        for _, t in ipairs(self.ActiveList) do
            if t.guid == guid then
                timer = t
                timerKey = t.key
                break
            end
        end
    end

    if timer then
        local remaining = timer.endTime - GetTime()
        if alertBreak and remaining > 3.0 then
            self:BreakAlert(timer.targetName, timer.spellName)
        end

        local bar = self.ActiveBars[timer]
        if bar then
            self.ActiveBars[timer] = nil
            self:ReleaseBar(bar)
        end

        self.ActiveTimers[timerKey] = nil
        for i, t in ipairs(self.ActiveList) do
            if t == timer then
                table.remove(self.ActiveList, i)
                break
            end
        end

        self:LayoutBars()
    end
end

function CC:BreakAlert(target, spell)
    if not self:GetOption("announceBreak") then return end

    if self:GetOption("playSound") then
        PlaySound("RaidWarning")
    end

    local msg = string.format("¡SE ROMPIÓ %s en %s!", string.upper(spell or "CC"), target or "Objetivo")

    if RaidWarningFrame then
        RaidNotice_AddMessage(RaidWarningFrame, msg, {r=1, g=0.2, b=0.2})
    end

    -- Anuncio seguro en el canal de grupo activo
    local chan = (GetNumRaidMembers() > 0 and "RAID") or (GetNumPartyMembers() > 0 and "PARTY") or nil
    if chan then
        SendChatMessage(msg, chan)
    else
        if S.Print then
            S:Print("|cFFFF0000[CCTracker]|r " .. msg)
        else
            DEFAULT_CHAT_FRAME:AddMessage("|cFFFF0000[CCTracker]|r " .. msg)
        end
    end
end

function CC:ClearAll()
    for timer, bar in pairs(self.ActiveBars) do
        self:ReleaseBar(bar)
    end
    wipe(self.ActiveBars)
    wipe(self.ActiveTimers)
    wipe(self.ActiveList)
    if self.TickerFrame then self.TickerFrame:Hide() end
    if S.Print then
        S:Print("|cFF9966FF[CCTracker]|r Todas las barras de CC han sido eliminadas.")
    end
end

-- ============================================================================
-- MODO DE PRUEBA Y COMANDOS SLASH
-- ============================================================================
function CC:TestMode()
    self:ClearAll()
    self:ToggleAnchor(true)

    local testTargets = {
        { name = "Arthas",   spellID = 118,   spellName = "Polymorph",     duration = 10 },
        { name = "Illidan",  spellID = 5782,  spellName = "Fear",          duration = 15 },
        { name = "Kel'Thuzad", spellID = 3355, spellName = "Freezing Trap", duration = 20 },
    }

    for i, data in ipairs(testTargets) do
        self:StartTimer("TEST_GUID_" .. i, data.name, data.spellID, data.spellName, data.duration)
    end

    if S.Print then
        S:Print("|cFF9966FF[CCTracker]|r Modo de prueba activado con 3 barras simuladas.")
    end
end

function CC:SlashCommand(msg)
    local cmd = msg and msg:lower():match("^%s*(%S+)") or ""
    if cmd == "test" then
        self:TestMode()
    elseif cmd == "toggle" or cmd == "anchor" or cmd == "move" then
        self:ToggleAnchor()
    elseif cmd == "lock" then
        self:ToggleAnchor(false)
    elseif cmd == "reset" then
        if S.SmartDefaults then
            S.SmartDefaults:ResetPosition("CCTracker")
        end
        if self.Anchor then
            self.Anchor:ClearAllPoints()
            self.Anchor:SetPoint("CENTER", UIParent, "CENTER", 0, 120)
        end
        if S.Print then
            S:Print("|cFF9966FF[CCTracker]|r Posición reiniciada al centro.")
        end
    elseif cmd == "clear" then
        self:ClearAll()
    else
        self:ToggleAnchor()
    end
end

SLASH_CCTRACKER1 = "/cct"
SLASH_CCTRACKER2 = "/cctracker"
SlashCmdList["CCTRACKER"] = function(msg)
    CC:SlashCommand(msg)
end

-- Inicialización en carga de juego
local loader = CreateFrame("Frame")
loader:RegisterEvent("PLAYER_LOGIN")
loader:SetScript("OnEvent", function()
    CC:Initialize()
end)
