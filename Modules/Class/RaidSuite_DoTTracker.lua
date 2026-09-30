--[[
    SEQUITO - DoT Tracker (Necrosis Style)
    Rastrea tus DoTs en el objetivo actual con iconos, temporizadores y acumulaciones.
    Compatibilidad: WotLK 3.3.5a (Build 12340) | Soporte Multi-Brujo
]]--

local addonName, S = ...
S.DoTTracker = {}
local DT = S.DoTTracker

-- Configuración de Spells a rastrear (Por prioridad de rotación WotLK)
DT.Spells = {
    { id = 172,   name = "Corruption",           icon = "Interface\\Icons\\Spell_Shadow_AbominationExplosion" }, -- Corrupción
    { id = 348,   name = "Immolate",             icon = "Interface\\Icons\\Spell_Fire_Immolation" },            -- Inmolar
    { id = 30108, name = "Unstable Affliction",  icon = "Interface\\Icons\\Spell_Shadow_UnstableAffliction_3" }, -- Aflicción inestable
    { id = 980,   name = "Curse of Agony",       icon = "Interface\\Icons\\Spell_Shadow_CurseOfSargeras" },     -- Agonía
    { id = 603,   name = "Curse of Doom",        icon = "Interface\\Icons\\Spell_Shadow_AuraOfDarkness" },       -- Apocalipsis
    { id = 1490,  name = "Curse of the Elements",icon = "Interface\\Icons\\Spell_Shadow_ChillTouch" },          -- Elementos
    { id = 702,   name = "Curse of Weakness",    icon = "Interface\\Icons\\Spell_Shadow_CurseOfMannoroth" },    -- Debilidad
    { id = 1714,  name = "Curse of Tongues",     icon = "Interface\\Icons\\Spell_Shadow_CurseOfTounges" },      -- Lenguas
    { id = 48181, name = "Haunt",                icon = "Interface\\Icons\\Ability_Warlock_Haunt" },            -- Poseer
    { id = 27243, name = "Seed of Corruption",   icon = "Interface\\Icons\\Spell_Shadow_SeedOfDestruction" },   -- Semilla
}

DT.SpellMap = {}
DT.tickerActive = false
DT.tickerElapsed = 0

function DT:GetOption(key)
    if S.ModuleConfig then
        return S.ModuleConfig:GetValue("DoTTracker", key)
    end
    return true
end

function DT:Initialize()
    if self.initialized then return end
    local _, class = UnitClass("player")
    if class ~= "WARLOCK" then return end

    if not self:GetOption("enabled") then
        return
    end
    self.initialized = true

    self:BuildSpellMap()
    self:CreateAnchor()
    self:CreateIcons()
    self:RegisterEvents()

    if S.SmartDefaults then
        S.SmartDefaults:RestorePosition("DoTTracker")
    end

    if S.Print then
        S:Print("|cFF9900FFDoT Tracker|r inicializado.")
    end
end

function DT:BuildSpellMap()
    for _, data in ipairs(self.Spells) do
        local name, _, icon = GetSpellInfo(data.id)
        if name then
            self.SpellMap[name] = { id = data.id, icon = icon or data.icon }
        end
    end
end

function DT:CreateAnchor()
    local f = CreateFrame("Frame", "SequitoDoTAnchor", UIParent)
    f:SetSize(200, 40)
    f:SetPoint("CENTER", UIParent, "CENTER", 0, -200)
    f:SetMovable(true)
    f:EnableMouse(true)
    f:RegisterForDrag("LeftButton")

    f.bg = f:CreateTexture(nil, "BACKGROUND")
    f.bg:SetAllPoints()
    f.bg:SetTexture("Interface\\Buttons\\WHITE8X8")
    f.bg:SetVertexColor(0, 0, 0, 0.4)
    f.bg:Hide()

    f.text = f:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    f.text:SetPoint("CENTER")
    f.text:SetText("DoT Tracker (Arrastrar)")
    f.text:Hide()

    f:SetScript("OnDragStart", function(self)
        if not (S.db and S.db.profile and S.db.profile.Locked) then
            self:StartMoving()
        end
    end)
    f:SetScript("OnDragStop", function(self)
        self:StopMovingOrSizing()
        if S.SmartDefaults then
            S.SmartDefaults:SavePosition("DoTTracker", self)
        end
    end)

    f:SetScript("OnEnter", function(self)
        if not (S.db and S.db.profile and S.db.profile.Locked) then
            self.bg:Show()
            self.text:Show()
        end
    end)
    f:SetScript("OnLeave", function(self)
        self.bg:Hide()
        self.text:Hide()
    end)

    self.Anchor = f
    self.frame = f  -- Exposición canónica para compatibilidad con SmartDefaults
end

function DT:CreateIcons()
    self.Icons = {}
    local prev = nil

    for i, data in ipairs(self.Spells) do
        local name, _, icon = GetSpellInfo(data.id)
        icon = icon or data.icon

        local btn = CreateFrame("Frame", "SequitoDoTIcon"..i, self.Anchor)
        btn:SetSize(32, 32)

        if prev then
            btn:SetPoint("LEFT", prev, "RIGHT", 4, 0)
        else
            btn:SetPoint("LEFT", self.Anchor, "LEFT", 0, 0)
        end

        btn.icon = btn:CreateTexture(nil, "ARTWORK")
        btn.icon:SetAllPoints()
        btn.icon:SetTexture(icon)
        btn.icon:SetDesaturated(true)
        btn.icon:SetAlpha(0.4)

        btn.cd = CreateFrame("Cooldown", "SequitoDoTCD"..i, btn, "CooldownFrameTemplate")
        btn.cd:SetAllPoints()
        btn.cd:Hide()

        -- Texto de tiempo restante (dígitos grandes)
        btn.timeText = btn:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
        btn.timeText:SetPoint("BOTTOM", 0, -12)
        btn.timeText:SetText("")

        -- Contador de cargas (ej. Semilla de corrupción / stacks)
        btn.countText = btn:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
        btn.countText:SetPoint("TOPRIGHT", btn, "TOPRIGHT", 2, 2)
        btn.countText:SetText("")

        btn.spellName = name
        btn.expirationTime = 0
        btn:Show()

        self.Icons[i] = btn
        prev = btn
    end

    self.Anchor:SetSize(#self.Spells * 36, 36)
end

function DT:RegisterEvents()
    local f = CreateFrame("Frame")
    f:RegisterEvent("PLAYER_TARGET_CHANGED")
    f:RegisterEvent("UNIT_AURA")

    f:SetScript("OnEvent", function(_, event, unit)
        if event == "PLAYER_TARGET_CHANGED" then
            DT:UpdateAll()
        elseif event == "UNIT_AURA" and unit == "target" then
            DT:UpdateAll()
        end
    end)
end

function DT:UpdateAll()
    if not UnitExists("target") then
        self:ResetIcons()
        return
    end

    -- Mapeo estricto de debuffs aplicados EXCLUSIVAMENTE por el jugador local
    local activeDebuffs = {}
    for i = 1, 40 do
        local name, _, _, count, _, duration, expirationTime, unitCaster = UnitDebuff("target", i, "PLAYER")
        if not name then break end
        activeDebuffs[name] = {
            count = count or 0,
            duration = duration or 0,
            expirationTime = expirationTime or 0,
        }
    end

    local hasActive = false

    for _, btn in ipairs(self.Icons) do
        local debuff = btn.spellName and activeDebuffs[btn.spellName]
        if debuff then
            hasActive = true
            btn.icon:SetDesaturated(false)
            btn.icon:SetAlpha(1.0)
            btn.expirationTime = debuff.expirationTime

            if debuff.duration > 0 and debuff.expirationTime > 0 then
                btn.cd:Show()
                btn.cd:SetCooldown(debuff.expirationTime - debuff.duration, debuff.duration)
            else
                btn.cd:Hide()
            end

            if debuff.count > 1 then
                btn.countText:SetText(debuff.count)
            else
                btn.countText:SetText("")
            end
        else
            btn.icon:SetDesaturated(true)
            btn.icon:SetAlpha(0.4)
            btn.cd:Hide()
            btn.expirationTime = 0
            btn.timeText:SetText("")
            btn.countText:SetText("")
        end
    end

    if hasActive then
        self:StartTicker()
    else
        self:StopTicker()
    end
end

function DT:StartTicker()
    if self.tickerActive then return end
    self.tickerActive = true
    self.tickerElapsed = 0

    -- Ticker OnUpdate con intervalo de 0.1s: cero gasto de heap y cancelación obligatoria
    self.Anchor:SetScript("OnUpdate", function(_, dt)
        DT.tickerElapsed = DT.tickerElapsed + dt
        if DT.tickerElapsed < 0.1 then return end
        DT.tickerElapsed = 0

        local now = GetTime()
        local stillRunning = false

        for _, btn in ipairs(DT.Icons) do
            if btn.expirationTime and btn.expirationTime > now then
                stillRunning = true
                local rem = btn.expirationTime - now
                if rem > 60 then
                    btn.timeText:SetText(string.format("%dm", math.ceil(rem / 60)))
                    btn.timeText:SetTextColor(1, 1, 1)
                elseif rem > 3.0 then
                    btn.timeText:SetText(string.format("%d", math.ceil(rem)))
                    btn.timeText:SetTextColor(1, 1, 1)
                else
                    -- Ventana crítica de refresco (Pandemic WotLK < 3s): Alerta roja
                    btn.timeText:SetText(string.format("%.1f", rem))
                    btn.timeText:SetTextColor(1, 0.25, 0.25)
                end
            elseif btn.expirationTime and btn.expirationTime > 0 then
                -- El DoT expiró
                btn.expirationTime = 0
                btn.timeText:SetText("")
                btn.countText:SetText("")
                btn.icon:SetDesaturated(true)
                btn.icon:SetAlpha(0.4)
                btn.cd:Hide()
            end
        end

        if not stillRunning then
            DT:StopTicker()
        end
    end)
end

function DT:StopTicker()
    if not self.tickerActive then return end
    self.tickerActive = false
    self.Anchor:SetScript("OnUpdate", nil)
end

function DT:ResetIcons()
    self:StopTicker()
    for _, btn in ipairs(self.Icons) do
        btn.icon:SetDesaturated(true)
        btn.icon:SetAlpha(0.4)
        btn.cd:Hide()
        btn.expirationTime = 0
        btn.timeText:SetText("")
        btn.countText:SetText("")
    end
end

if S.ModuleConfig then
    S.ModuleConfig:RegisterModule("DoTTracker", {
        name = "DoT Tracker",
        description = "Barra de Iconos para rastrear DoTs en el objetivo.",
        category = "class",
        icon = "Interface\\Icons\\Spell_Shadow_AbominationExplosion",
        options = {
            {key = "enabled", type = "checkbox", label = "Habilitar DoT Tracker", default = true}
        }
    })
end
