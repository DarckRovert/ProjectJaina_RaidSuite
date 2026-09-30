--[[
    Sequito - The Overlord (HUD)
    Sistema de alertas visuales y barras de recursos
    para todas las clases de WotLK 3.3.5a
]]--

local addonName, S = ...
S.Overlord = {}
local O = S.Overlord

-- Estado
O.ProcFrame = nil
O.ResourceFrame = nil
O.PetFrame = nil
O.ActiveAlert = nil
O.AlertTimer = 0
O.ProcAlphaTarget = 0
O.ProcFadeSpeed = 2.0

-- ============================================
-- DATOS DE PROCS POR CLASE
-- ============================================
local PROC_DATA = {
    -- Warlock
    ["Shadow Trance"]        = {text = "¡OCASO!", color = {0.6, 0.2, 1.0}, icon = "Interface\\Icons\\Spell_Shadow_Twilight"},
    ["Trance de las Sombras"]= {text = "¡OCASO!", color = {0.6, 0.2, 1.0}, icon = "Interface\\Icons\\Spell_Shadow_Twilight"},
    ["Backlash"]             = {text = "¡CONTRAGOLPE!", color = {1.0, 0.5, 0.0}, icon = "Interface\\Icons\\Spell_Fire_Fireball"},
    ["Contragolpe"]          = {text = "¡CONTRAGOLPE!", color = {1.0, 0.5, 0.0}, icon = "Interface\\Icons\\Spell_Fire_Fireball"},
    ["Molten Core"]          = {text = "¡NÚCLEO DE MAGMA!", color = {1.0, 0.3, 0.0}, icon = "Interface\\Icons\\Ability_Warlock_MoltenCore"},
    ["Núcleo de Magma"]      = {text = "¡NÚCLEO DE MAGMA!", color = {1.0, 0.3, 0.0}, icon = "Interface\\Icons\\Ability_Warlock_MoltenCore"},
    ["Decimation"]           = {text = "¡EXTERMINACIÓN!", color = {0.8, 0.0, 0.0}, icon = "Interface\\Icons\\Ability_Warlock_Decimation"},
    ["Exterminación"]        = {text = "¡EXTERMINACIÓN!", color = {0.8, 0.0, 0.0}, icon = "Interface\\Icons\\Ability_Warlock_Decimation"},
    -- Paladin
    ["The Art of War"]       = {text = "¡ARTE DE LA GUERRA!", color = {1.0, 0.8, 0.0}, icon = "Interface\\Icons\\Ability_Paladin_ArtOfWar"},
    ["El Arte de la Guerra"] = {text = "¡ARTE DE LA GUERRA!", color = {1.0, 0.8, 0.0}, icon = "Interface\\Icons\\Ability_Paladin_ArtOfWar"},
    ["Infusion of Light"]    = {text = "¡INFUSIÓN DE LUZ!", color = {1.0, 1.0, 0.4}, icon = "Interface\\Icons\\Ability_Paladin_InfusionOfLight"},
    -- DK
    ["Rime"]                 = {text = "¡ESCARCHA!", color = {0.3, 0.7, 1.0}, icon = "Interface\\Icons\\Spell_Frost_FreezingBreath"},
    ["Escarcha"]             = {text = "¡ESCARCHA!", color = {0.3, 0.7, 1.0}, icon = "Interface\\Icons\\Spell_Frost_FreezingBreath"},
    ["Killing Machine"]      = {text = "¡MÁQUINA MORTAL!", color = {0.8, 0.2, 0.2}, icon = "Interface\\Icons\\INV_Sword_122"},
    ["Máquina de matar"]     = {text = "¡MÁQUINA MORTAL!", color = {0.8, 0.2, 0.2}, icon = "Interface\\Icons\\INV_Sword_122"},
    -- Warrior
    ["Sword and Board"]      = {text = "¡ESPADA Y TABLA!", color = {0.7, 0.5, 0.2}, icon = "Interface\\Icons\\Ability_Warrior_SwordandBoard"},
    ["Overpower"]            = {text = "¡SUPERAR!", color = {1.0, 0.6, 0.0}, icon = "Interface\\Icons\\Ability_MeleeDamage"},
    ["Superar"]              = {text = "¡SUPERAR!", color = {1.0, 0.6, 0.0}, icon = "Interface\\Icons\\Ability_MeleeDamage"},
    -- Mage
    ["Missile Barrage"]      = {text = "¡BOMBARDEO DE MISILES!", color = {0.4, 0.6, 1.0}, icon = "Interface\\Icons\\Ability_Mage_MissileBarrage"},
    ["Hot Streak"]           = {text = "¡RACHA CALIENTE!", color = {1.0, 0.4, 0.0}, icon = "Interface\\Icons\\Ability_Mage_HotStreak"},
    ["Brain Freeze"]         = {text = "¡CONGELACIÓN CEREBRAL!", color = {0.2, 0.6, 1.0}, icon = "Interface\\Icons\\Ability_Mage_BrainFreeze"},
    -- Priest
    ["Surge of Light"]       = {text = "¡OLEADA DE LUZ!", color = {1.0, 1.0, 0.6}, icon = "Interface\\Icons\\Spell_Holy_SurgeOfLight"},
    -- Shaman
    ["Maelstrom Weapon"]     = {text = "¡ARMA DE VORÁGINE (x5)!", color = {0.2, 0.4, 1.0}, icon = "Interface\\Icons\\Ability_Shaman_MaelstromWeapon"},
    ["Arma de vorágine"]     = {text = "¡ARMA DE VORÁGINE (x5)!", color = {0.2, 0.4, 1.0}, icon = "Interface\\Icons\\Ability_Shaman_MaelstromWeapon"},
    -- Rogue
    ["Riposte"]              = {text = "¡RÉPLICA!", color = {0.9, 0.7, 0.2}, icon = "Interface\\Icons\\Ability_Warrior_Challange"},
    ["Réplica"]              = {text = "¡RÉPLICA!", color = {0.9, 0.7, 0.2}, icon = "Interface\\Icons\\Ability_Warrior_Challange"},
}

-- ============================================
-- RECURSOS SECUNDARIOS POR CLASE
-- ============================================
local RESOURCE_CONFIG = {
    WARLOCK = {
        name = "Soul Shards",
        icon = "Interface\\Icons\\INV_Misc_Gem_Amethyst_02",
        color = {0.6, 0.2, 0.8},
        getCount = function()
            return GetItemCount(6265)
        end,
        max = 32,
    },
    ROGUE = {
        name = "Combo Points",
        icon = "Interface\\Icons\\Ability_Rogue_Eviscerate",
        color = {1.0, 0.8, 0.0},
        getCount = function() return GetComboPoints("player", "target") end,
        max = 5,
    },
    DEATHKNIGHT = {
        name = "Runic Power",
        icon = "Interface\\Icons\\INV_Sword_62",
        color = {0.0, 0.8, 1.0},
        getCount = function() return UnitPower("player", 6) end, -- SPELL_POWER_RUNIC_POWER
        max = function() return UnitPowerMax("player", 6) end,
    },
    DRUID = {
        name = "Combo Points",
        icon = "Interface\\Icons\\Ability_Druid_Rake",
        color = {1.0, 0.6, 0.0},
        getCount = function() return GetComboPoints("player", "target") end,
        max = 5,
    },
}

-- ============================================
-- INICIALIZACIÓN
-- ============================================

function O:Initialize()
    if self.initialized then return end
    if not self:GetOption("enabled") then return end
    self.initialized = true
    
    -- Crear HUD según opciones del usuario
    if self:GetOption("showProcs") then
        self:CreateProcAlert()
    end
    if self:GetOption("showResource") then
        self:CreateResourceBar()
    end
    if self:GetOption("showPetHealth") then
        self:CreatePetHealthBar()
    end
    self:RegisterEvents()
    
    -- Aplicar opacidad global
    local opacity = self:GetOption("opacity")
    if type(opacity) == "number" then
        if self.ProcFrame then self.ProcFrame:SetAlpha(opacity) end
        if self.ResourceFrame then self.ResourceFrame:SetAlpha(opacity) end
        if self.PetFrame then self.PetFrame:SetAlpha(opacity) end
    end
    
    -- print("|cFF00FFFFSequito|r: [Overlord] HUD iniciado.")
end

function O:GetOption(key)
    if S.ModuleConfig then
        return S.ModuleConfig:GetValue("Overlord", key)
    end
    return true
end

-- ============================================
-- FRAME DE ALERTA DE PROC
-- ============================================

-- Legacy ProcAlert eliminado en favor de AlertHub
function O:CreateProcAlert()
    -- Deprecated
end

function O:ShowProcAlert(spellName)
   -- Deprecated
end
-- Legacy Code Cleanup

-- ============================================
-- BARRA DE RECURSO SECUNDARIO
-- ============================================

function O:CreateResourceBar()
    local _, class = UnitClass("player")
    local config = RESOURCE_CONFIG[class]
    if not config then return end -- Clase sin recurso especial
    
    local f = CreateFrame("Frame", "SequitoOverlordResource", UIParent)
    f:SetSize(200, 28)
    f:SetPoint("CENTER", UIParent, "CENTER", 0, -80)
    f:SetMovable(true)
    f:EnableMouse(true)
    f:RegisterForDrag("LeftButton")
    f:SetScript("OnDragStart", function(frame) frame:StartMoving() end)
    f:SetScript("OnDragStop", function(frame) 
        frame:StopMovingOrSizing()
        if S.SmartDefaults then S.SmartDefaults:SavePosition("OverlordResource", frame) end
    end)
    -- Restaurar posición
    if S.SmartDefaults then S.SmartDefaults:RestorePosition("OverlordResource") end
    
    -- Fondo
    f.bg = f:CreateTexture(nil, "BACKGROUND")
    f.bg:SetAllPoints()
    local r, g, b, a = 0.05, 0.05, 0.05, 0.8
    if S.Theme then r, g, b, a = S.Theme:GetColor("background") end
    f.bg:SetTexture(r, g, b, a)
    
    -- Borde
    f.border = CreateFrame("Frame", nil, f)
    f.border:SetAllPoints()
    f.border:SetBackdrop({
        edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
        edgeSize = 12,
    })
    local br, bg2, bb = 0.3, 0.3, 0.3
    if S.Theme then br, bg2, bb = S.Theme:GetColor("border") end
    f.border:SetBackdropBorderColor(br, bg2, bb, 0.8)
    
    -- Icono pequeño del recurso
    f.icon = f:CreateTexture(nil, "ARTWORK")
    f.icon:SetSize(20, 20)
    f.icon:SetPoint("LEFT", f, "LEFT", 4, 0)
    f.icon:SetTexture(config.icon)
    f.icon:SetTexCoord(0.07, 0.93, 0.07, 0.93)
    
    -- Barra de progreso
    f.bar = CreateFrame("StatusBar", nil, f)
    f.bar:SetSize(140, 14)
    f.bar:SetPoint("LEFT", f.icon, "RIGHT", 6, 0)
    f.bar:SetStatusBarTexture("Interface\\TargetingFrame\\UI-StatusBar")
    f.bar:SetStatusBarColor(config.color[1], config.color[2], config.color[3])
    f.bar:SetMinMaxValues(0, type(config.max) == "function" and config.max() or config.max)
    f.bar:SetValue(0)
    
    -- Fondo de la barra
    f.bar.bg = f.bar:CreateTexture(nil, "BACKGROUND")
    f.bar.bg:SetAllPoints()
    f.bar.bg:SetTexture("Interface\\Buttons\\WHITE8X8")
    f.bar.bg:SetVertexColor(0.1, 0.1, 0.1, 0.6)
    
    -- Texto de la barra
    f.bar.text = f.bar:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    f.bar.text:SetPoint("CENTER", f.bar, "CENTER", 0, 0)
    f.bar.text:SetText("0")
    
    -- Label
    f.label = f:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    f.label:SetPoint("BOTTOM", f, "TOP", 0, 2)
    f.label:SetText("|cFFFFFFFF" .. config.name .. "|r")
    f.label:SetFont("Fonts\\FRIZQT__.TTF", 10, "OUTLINE")
    
    -- OnUpdate para actualizar valores
    f.elapsed = 0
    f:SetScript("OnUpdate", function(frame, elapsed)
        frame.elapsed = frame.elapsed + elapsed
        if frame.elapsed < 0.2 then return end -- Throttle a 5 FPS
        frame.elapsed = 0
        O:UpdateResource()
    end)
    
    self.ResourceFrame = f
    self.ResourceConfig = config
end

function O:UpdateResource()
    if not self.ResourceFrame or not self.ResourceConfig then return end
    
    local config = self.ResourceConfig
    local count = config.getCount()
    local maxVal = type(config.max) == "function" and config.max() or config.max
    
    self.ResourceFrame.bar:SetMinMaxValues(0, maxVal)
    self.ResourceFrame.bar:SetValue(count)
    self.ResourceFrame.bar.text:SetText(count)
    
    -- Color intensidad basada en cantidad
    if maxVal > 0 then
        local pct = count / maxVal
        local r = config.color[1] * (0.5 + 0.5 * pct)
        local g = config.color[2] * (0.5 + 0.5 * pct)
        local b = config.color[3] * (0.5 + 0.5 * pct)
        self.ResourceFrame.bar:SetStatusBarColor(r, g, b)
    end
end

-- ============================================
-- BARRA DE SALUD DEL PET
-- ============================================

function O:CreatePetHealthBar()
    local _, class = UnitClass("player")
    -- Solo para clases con pets permanentes
    if class ~= "WARLOCK" and class ~= "HUNTER" and class ~= "DEATHKNIGHT" and class ~= "MAGE" then
        return
    end
    
    local f = CreateFrame("Frame", "SequitoOverlordPet", UIParent)
    f:SetSize(160, 20)
    f:SetPoint("CENTER", UIParent, "CENTER", 0, -110)
    f:SetMovable(true)
    f:EnableMouse(true)
    f:RegisterForDrag("LeftButton")
    f:SetScript("OnDragStart", function(frame) frame:StartMoving() end)
    f:SetScript("OnDragStop", function(frame) 
        frame:StopMovingOrSizing()
        if S.SmartDefaults then S.SmartDefaults:SavePosition("OverlordPet", frame) end
    end)
    -- Restaurar posición
    if S.SmartDefaults then S.SmartDefaults:RestorePosition("OverlordPet") end
    f:Hide() -- Ocultar hasta que haya pet
    
    -- Fondo
    f.bg = f:CreateTexture(nil, "BACKGROUND")
    f.bg:SetAllPoints()
    f.bg:SetTexture("Interface\\Buttons\\WHITE8X8")
    f.bg:SetVertexColor(0.05, 0.05, 0.05, 0.8)
    
    -- Barra de vida
    f.bar = CreateFrame("StatusBar", nil, f)
    f.bar:SetSize(120, 12)
    f.bar:SetPoint("LEFT", f, "LEFT", 24, 0)
    f.bar:SetStatusBarTexture("Interface\\TargetingFrame\\UI-StatusBar")
    f.bar:SetStatusBarColor(0, 1, 0)
    f.bar:SetMinMaxValues(0, 100)
    f.bar:SetValue(100)
    
    -- Fondo de barra
    f.bar.bg = f.bar:CreateTexture(nil, "BACKGROUND")
    f.bar.bg:SetAllPoints()
    f.bar.bg:SetTexture("Interface\\Buttons\\WHITE8X8")
    f.bar.bg:SetVertexColor(0.15, 0.15, 0.15, 0.7)
    
    -- Icono de pet
    f.icon = f:CreateTexture(nil, "ARTWORK")
    f.icon:SetSize(16, 16)
    f.icon:SetPoint("LEFT", f, "LEFT", 4, 0)
    f.icon:SetTexture("Interface\\Icons\\Spell_Shadow_SummonImp")
    f.icon:SetTexCoord(0.07, 0.93, 0.07, 0.93)
    
    -- Texto de %
    f.text = f.bar:CreateFontString(nil, "OVERLAY")
    f.text:SetFont("Fonts\\FRIZQT__.TTF", 10, "OUTLINE")
    f.text:SetPoint("CENTER", f.bar, "CENTER", 0, 0)
    f.text:SetText("100%")
    
    -- Glow frame para alertas de vida baja
    f.glow = f:CreateTexture(nil, "OVERLAY")
    f.glow:SetSize(168, 28)
    f.glow:SetPoint("CENTER", f, "CENTER", 0, 0)
    f.glow:SetTexture("Interface\\Buttons\\UI-ActionButton-Border")
    f.glow:SetBlendMode("ADD")
    f.glow:SetVertexColor(1, 0, 0)
    f.glow:SetAlpha(0)
    
    -- OnUpdate
    f.elapsed = 0
    f:SetScript("OnUpdate", function(frame, elapsed)
        frame.elapsed = frame.elapsed + elapsed
        if frame.elapsed < 0.3 then return end -- Throttle
        frame.elapsed = 0
        O:UpdatePetHealth()
    end)
    
    self.PetFrame = f
end

function O:UpdatePetHealth()
    if not self.PetFrame then return end
    
    if not UnitExists("pet") then
        self.PetFrame:Hide()
        return
    end
    
    self.PetFrame:Show()
    
    local hp = UnitHealth("pet")
    local maxHp = UnitHealthMax("pet")
    if maxHp == 0 then maxHp = 1 end
    local pct = (hp / maxHp) * 100
    
    self.PetFrame.bar:SetValue(pct)
    self.PetFrame.text:SetText(math.floor(pct) .. "%")
    
    -- Color basado en salud
    if pct < 20 then
        self.PetFrame.bar:SetStatusBarColor(1, 0, 0)
        -- Glow pulsante rojo
        local pulse = 0.3 + 0.4 * math.abs(math.sin(GetTime() * 3))
        self.PetFrame.glow:SetAlpha(pulse)
    elseif pct < 50 then
        self.PetFrame.bar:SetStatusBarColor(1, 0.6, 0)
        self.PetFrame.glow:SetAlpha(0)
    else
        self.PetFrame.bar:SetStatusBarColor(0, 0.8, 0.2)
        self.PetFrame.glow:SetAlpha(0)
    end
    
    -- Actualizar icono del pet
    local petIcon = O.GetPetIcon()
    if petIcon then
        self.PetFrame.icon:SetTexture(petIcon)
    end
end

-- ============================================
-- EVENTOS
-- ============================================

function O:RegisterEvents()
    if S.CLEU and S.CLEU.Register then
        S.CLEU:Register("SPELL_AURA_APPLIED", function(...)
            local _, _, _, _, _, destGUID, _, _, _, spellName = ...
            if destGUID == UnitGUID("player") then
                local procInfo = PROC_DATA[spellName]
                if procInfo then
                    if spellName ~= "Maelstrom Weapon" and spellName ~= "Arma de vorágine" then
                        S:ShowAlert(procInfo.text, "INFO", procInfo.icon, procInfo.color)
                    end
                end
            end
        end)
        S.CLEU:Register("SPELL_AURA_APPLIED_DOSE", function(...)
            local _, _, _, _, _, destGUID, _, _, _, spellName = ...
            if destGUID == UnitGUID("player") then
                if spellName == "Maelstrom Weapon" or spellName == "Arma de vorágine" then
                    local _, _, amount = select(11, ...)
                    if amount == 5 then
                        local procInfo = PROC_DATA[spellName]
                        if procInfo then
                            S:ShowAlert(procInfo.text, "INFO", procInfo.icon, procInfo.color)
                        end
                    end
                end
            end
        end)
    end

    local f = CreateFrame("Frame")
    if not (S.CLEU and S.CLEU.Register) then
        f:RegisterEvent("COMBAT_LOG_EVENT_UNFILTERED")
    end
    f:RegisterEvent("UNIT_PET")
    f:RegisterEvent("PLAYER_ENTERING_WORLD")
    
    f:SetScript("OnEvent", function(self, event, ...)
        if event == "COMBAT_LOG_EVENT_UNFILTERED" then
            local _, subEvent, _, _, _, destGUID, _, _, _, spellName, _, auraType = ...
            
            -- Solo procs en el jugador
            if subEvent == "SPELL_AURA_APPLIED" and destGUID == UnitGUID("player") then
                local procInfo = PROC_DATA[spellName]
                if procInfo then
                    -- Para Maelstrom Weapon, solo alertar en 5 stacks
                    if spellName == "Maelstrom Weapon" or spellName == "Arma de vorágine" then
                        -- Se maneja con SPELL_AURA_APPLIED_DOSE
                        return
                    end
                    -- USAR ALERTHUB
                    S:ShowAlert(procInfo.text, "INFO", procInfo.icon, procInfo.color)
                end
            end
            
            -- Maelstrom: alertar solo en stack 5
            if subEvent == "SPELL_AURA_APPLIED_DOSE" and destGUID == UnitGUID("player") then
                if spellName == "Maelstrom Weapon" or spellName == "Arma de vorágine" then
                    -- Obtener stacks del buff
                    local _, _, amount = select(11, ...) -- 11:school, 12:type, 13:amount
                    if amount == 5 then
                        local procInfo = PROC_DATA[spellName]
                        if procInfo then
                            S:ShowAlert(procInfo.text, "INFO", procInfo.icon, procInfo.color)
                        end
                    end
                end
            end
            
        elseif event == "UNIT_PET" or event == "PLAYER_ENTERING_WORLD" then
            if O.PetFrame then
                O:UpdatePetHealth()
            end
        end
    end)
end

-- Helper: Obtener icono del pet (local al módulo)
function O.GetPetIcon()
    if not UnitExists("pet") then return nil end
    
    local family = UnitCreatureFamily("pet")
    local icons = {
        ["Imp"]       = "Interface\\Icons\\Spell_Shadow_SummonImp",
        ["Diablillo"] = "Interface\\Icons\\Spell_Shadow_SummonImp",
        ["Voidwalker"] = "Interface\\Icons\\Spell_Shadow_SummonVoidWalker",
        ["Abisario"]   = "Interface\\Icons\\Spell_Shadow_SummonVoidWalker",
        ["Succubus"]   = "Interface\\Icons\\Spell_Shadow_SummonSuccubus",
        ["Súcubo"]     = "Interface\\Icons\\Spell_Shadow_SummonSuccubus",
        ["Felhunter"]  = "Interface\\Icons\\Spell_Shadow_SummonFelHunter",
        ["Manáfago"]   = "Interface\\Icons\\Spell_Shadow_SummonFelHunter",
        ["Felguard"]   = "Interface\\Icons\\Spell_Shadow_SummonFelGuard",
        ["Guardia Apocalíptico"] = "Interface\\Icons\\Spell_Shadow_SummonFelGuard",
    }
    
    return icons[family] or "Interface\\Icons\\Ability_Hunter_Pet_Bear"
end

-- ============================================
-- REGISTRO EN MODULECONFIG
-- ============================================
if S.ModuleConfig then
    S.ModuleConfig:RegisterModule("Overlord", {
        name = "The Overlord HUD",
        description = "Alertas visuales de procs, barra de recursos y salud de mascota.",
        category = "interface",
        icon = "Interface\\Icons\\Spell_Shadow_Skull",
        options = {
            {key = "enabled", type = "checkbox", label = "Habilitar Overlord HUD", default = true},
            {key = "showProcs", type = "checkbox", label = "Mostrar Alertas de Proc", default = true},
            {key = "showResource", type = "checkbox", label = "Mostrar Barra de Recurso", default = true},
            {key = "showPetHealth", type = "checkbox", label = "Mostrar Salud de Mascota", default = true},
            {key = "opacity", type = "slider", label = "Opacidad", min = 0.1, max = 1.0, step = 0.1, default = 0.8},
        }
    })
end
