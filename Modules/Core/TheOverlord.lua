--[[
    Sequito - The Overlord (HUD)
    Sistema de alertas visuales y barras de recursos
    para todas las clases de WotLK 3.3.5a
    Version: 8.0.0 (WotLK 3.3.5a Build 12340)
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
-- DATOS DE PROCS POR CLASE (WotLK 3.3.5a Bilingüe)
-- ============================================
local PROC_DATA = {
    -- Warlock
    ["Shadow Trance"]         = {text = "¡OCASO!", color = {0.6, 0.2, 1.0}, icon = "Interface\\Icons\\Spell_Shadow_Twilight"},
    ["Trance de las Sombras"] = {text = "¡OCASO!", color = {0.6, 0.2, 1.0}, icon = "Interface\\Icons\\Spell_Shadow_Twilight"},
    ["Backlash"]              = {text = "¡CONTRAGOLPE!", color = {1.0, 0.5, 0.0}, icon = "Interface\\Icons\\Spell_Fire_Fireball"},
    ["Contragolpe"]           = {text = "¡CONTRAGOLPE!", color = {1.0, 0.5, 0.0}, icon = "Interface\\Icons\\Spell_Fire_Fireball"},
    ["Molten Core"]           = {text = "¡NÚCLEO DE MAGMA!", color = {1.0, 0.3, 0.0}, icon = "Interface\\Icons\\Ability_Warlock_MoltenCore"},
    ["Núcleo de Magma"]       = {text = "¡NÚCLEO DE MAGMA!", color = {1.0, 0.3, 0.0}, icon = "Interface\\Icons\\Ability_Warlock_MoltenCore"},
    ["Decimation"]            = {text = "¡EXTERMINACIÓN!", color = {0.8, 0.0, 0.0}, icon = "Interface\\Icons\\Ability_Warlock_Decimation"},
    ["Exterminación"]         = {text = "¡EXTERMINACIÓN!", color = {0.8, 0.0, 0.0}, icon = "Interface\\Icons\\Ability_Warlock_Decimation"},
    
    -- Paladin
    ["The Art of War"]        = {text = "¡ARTE DE LA GUERRA!", color = {1.0, 0.8, 0.0}, icon = "Interface\\Icons\\Ability_Paladin_ArtOfWar"},
    ["El Arte de la Guerra"]  = {text = "¡ARTE DE LA GUERRA!", color = {1.0, 0.8, 0.0}, icon = "Interface\\Icons\\Ability_Paladin_ArtOfWar"},
    ["El arte de la guerra"]  = {text = "¡ARTE DE LA GUERRA!", color = {1.0, 0.8, 0.0}, icon = "Interface\\Icons\\Ability_Paladin_ArtOfWar"},
    ["Infusion of Light"]     = {text = "¡INFUSIÓN DE LUZ!", color = {1.0, 1.0, 0.4}, icon = "Interface\\Icons\\Ability_Paladin_InfusionOfLight"},
    ["Infusión de Luz"]       = {text = "¡INFUSIÓN DE LUZ!", color = {1.0, 1.0, 0.4}, icon = "Interface\\Icons\\Ability_Paladin_InfusionOfLight"},
    ["Infusión de luz"]       = {text = "¡INFUSIÓN DE LUZ!", color = {1.0, 1.0, 0.4}, icon = "Interface\\Icons\\Ability_Paladin_InfusionOfLight"},
    ["Judgements of the Pure"]= {text = "¡SENTENCIAS DE LOS PUROS!", color = {1.0, 0.9, 0.3}, icon = "Interface\\Icons\\Ability_Paladin_JudgementsofthePure"},
    
    -- DK
    ["Rime"]                  = {text = "¡ESCARCHA!", color = {0.3, 0.7, 1.0}, icon = "Interface\\Icons\\Spell_Frost_FreezingBreath"},
    ["Escarcha"]              = {text = "¡ESCARCHA!", color = {0.3, 0.7, 1.0}, icon = "Interface\\Icons\\Spell_Frost_FreezingBreath"},
    ["Killing Machine"]       = {text = "¡MÁQUINA MORTAL!", color = {0.8, 0.2, 0.2}, icon = "Interface\\Icons\\INV_Sword_122"},
    ["Máquina de matar"]      = {text = "¡MÁQUINA MORTAL!", color = {0.8, 0.2, 0.2}, icon = "Interface\\Icons\\INV_Sword_122"},
    ["Máquina mortal"]        = {text = "¡MÁQUINA MORTAL!", color = {0.8, 0.2, 0.2}, icon = "Interface\\Icons\\INV_Sword_122"},
    
    -- Warrior
    ["Sword and Board"]       = {text = "¡ESPADA Y TABLA!", color = {0.7, 0.5, 0.2}, icon = "Interface\\Icons\\Ability_Warrior_SwordandBoard"},
    ["Espada y tabla"]        = {text = "¡ESPADA Y TABLA!", color = {0.7, 0.5, 0.2}, icon = "Interface\\Icons\\Ability_Warrior_SwordandBoard"},
    ["Overpower"]             = {text = "¡SUPERAR!", color = {1.0, 0.6, 0.0}, icon = "Interface\\Icons\\Ability_MeleeDamage"},
    ["Superar"]               = {text = "¡SUPERAR!", color = {1.0, 0.6, 0.0}, icon = "Interface\\Icons\\Ability_MeleeDamage"},
    ["Bloodsurge"]            = {text = "¡OLEADA DE SANGRE!", color = {0.9, 0.2, 0.2}, icon = "Interface\\Icons\\Ability_Warrior_Bloodsurge"},
    ["Oleada de sangre"]      = {text = "¡OLEADA DE SANGRE!", color = {0.9, 0.2, 0.2}, icon = "Interface\\Icons\\Ability_Warrior_Bloodsurge"},
    ["Sudden Death"]          = {text = "¡MUERTE SÚBITA!", color = {0.8, 0.1, 0.1}, icon = "Interface\\Icons\\Ability_Warrior_ImprovedDisciplines"},
    ["Muerte súbita"]         = {text = "¡MUERTE SÚBITA!", color = {0.8, 0.1, 0.1}, icon = "Interface\\Icons\\Ability_Warrior_ImprovedDisciplines"},
    
    -- Mage
    ["Missile Barrage"]       = {text = "¡BOMBARDEO DE MISILES!", color = {0.4, 0.6, 1.0}, icon = "Interface\\Icons\\Ability_Mage_MissileBarrage"},
    ["Bombardeo de misiles"]  = {text = "¡BOMBARDEO DE MISILES!", color = {0.4, 0.6, 1.0}, icon = "Interface\\Icons\\Ability_Mage_MissileBarrage"},
    ["Hot Streak"]            = {text = "¡BUENA RACHA!", color = {1.0, 0.4, 0.0}, icon = "Interface\\Icons\\Ability_Mage_HotStreak"},
    ["Buena racha"]           = {text = "¡BUENA RACHA!", color = {1.0, 0.4, 0.0}, icon = "Interface\\Icons\\Ability_Mage_HotStreak"},
    ["Racha caliente"]        = {text = "¡BUENA RACHA!", color = {1.0, 0.4, 0.0}, icon = "Interface\\Icons\\Ability_Mage_HotStreak"},
    ["Brain Freeze"]          = {text = "¡CONGELACIÓN CEREBRAL!", color = {0.2, 0.6, 1.0}, icon = "Interface\\Icons\\Ability_Mage_BrainFreeze"},
    ["Congelación cerebral"]  = {text = "¡CONGELACIÓN CEREBRAL!", color = {0.2, 0.6, 1.0}, icon = "Interface\\Icons\\Ability_Mage_BrainFreeze"},
    ["Fingers of Frost"]      = {text = "¡DEDOS DE ESCARCHA!", color = {0.3, 0.7, 1.0}, icon = "Interface\\Icons\\Ability_Mage_Winterscill"},
    ["Dedos de Escarcha"]     = {text = "¡DEDOS DE ESCARCHA!", color = {0.3, 0.7, 1.0}, icon = "Interface\\Icons\\Ability_Mage_Winterscill"},
    ["Dedos de escarcha"]     = {text = "¡DEDOS DE ESCARCHA!", color = {0.3, 0.7, 1.0}, icon = "Interface\\Icons\\Ability_Mage_Winterscill"},
    ["Firestarter"]           = {text = "¡PIRÓMANO!", color = {1.0, 0.4, 0.0}, icon = "Interface\\Icons\\Ability_Mage_FireStarter"},
    
    -- Priest
    ["Surge of Light"]        = {text = "¡OLEADA DE LUZ!", color = {1.0, 1.0, 0.6}, icon = "Interface\\Icons\\Spell_Holy_SurgeOfLight"},
    ["Oleada de Luz"]         = {text = "¡OLEADA DE LUZ!", color = {1.0, 1.0, 0.6}, icon = "Interface\\Icons\\Spell_Holy_SurgeOfLight"},
    ["Oleada de luz"]         = {text = "¡OLEADA DE LUZ!", color = {1.0, 1.0, 0.6}, icon = "Interface\\Icons\\Spell_Holy_SurgeOfLight"},
    ["Serendipity"]           = {text = "¡SERENDIPIA!", color = {1.0, 0.9, 0.5}, icon = "Interface\\Icons\\Spell_Holy_Serendipity"},
    ["Serendipia"]            = {text = "¡SERENDIPIA!", color = {1.0, 0.9, 0.5}, icon = "Interface\\Icons\\Spell_Holy_Serendipity"},
    
    -- Shaman
    ["Maelstrom Weapon"]      = {text = "¡ARMA DE VORÁGINE (x5)!", color = {0.2, 0.4, 1.0}, icon = "Interface\\Icons\\Ability_Shaman_MaelstromWeapon"},
    ["Arma de vorágine"]      = {text = "¡ARMA DE VORÁGINE (x5)!", color = {0.2, 0.4, 1.0}, icon = "Interface\\Icons\\Ability_Shaman_MaelstromWeapon"},
    ["Arma vorágine"]         = {text = "¡ARMA DE VORÁGINE (x5)!", color = {0.2, 0.4, 1.0}, icon = "Interface\\Icons\\Ability_Shaman_MaelstromWeapon"},
    
    -- Hunter
    ["Lock and Load"]         = {text = "¡BLOQUEAR Y CARGAR!", color = {1.0, 0.5, 0.0}, icon = "Interface\\Icons\\Ability_Hunter_LockAndLoad"},
    ["Bloquear y cargar"]     = {text = "¡BLOQUEAR Y CARGAR!", color = {1.0, 0.5, 0.0}, icon = "Interface\\Icons\\Ability_Hunter_LockAndLoad"},
    ["Cargar y bloquear"]     = {text = "¡BLOQUEAR Y CARGAR!", color = {1.0, 0.5, 0.0}, icon = "Interface\\Icons\\Ability_Hunter_LockAndLoad"},
    ["Fire!"]                 = {text = "¡FUEGO!", color = {1.0, 0.4, 0.1}, icon = "Interface\\Icons\\Ability_Hunter_RunningShot"},
    ["¡Fuego!"]               = {text = "¡FUEGO!", color = {1.0, 0.4, 0.1}, icon = "Interface\\Icons\\Ability_Hunter_RunningShot"},
    
    -- Druid
    ["Eclipse (Lunar)"]       = {text = "¡ECLIPSE LUNAR!", color = {0.3, 0.6, 1.0}, icon = "Interface\\Icons\\Ability_Druid_Eclipse"},
    ["Eclipse (Solar)"]       = {text = "¡ECLIPSE SOLAR!", color = {1.0, 0.8, 0.2}, icon = "Interface\\Icons\\Ability_Druid_Eclipse2"},
    ["Omen of Clarity"]       = {text = "¡AUGURIO DE CLARIDAD!", color = {0.2, 0.9, 0.4}, icon = "Interface\\Icons\\Spell_Nature_CrystalBall"},
    ["Augurio de claridad"]   = {text = "¡AUGURIO DE CLARIDAD!", color = {0.2, 0.9, 0.4}, icon = "Interface\\Icons\\Spell_Nature_CrystalBall"},
    ["Predatory Strikes"]     = {text = "¡GOLPES DEPREDADORES!", color = {1.0, 0.6, 0.2}, icon = "Interface\\Icons\\Ability_Hunter_Pet_Cat"},
    ["Golpes depredadores"]   = {text = "¡GOLPES DEPREDADORES!", color = {1.0, 0.6, 0.2}, icon = "Interface\\Icons\\Ability_Hunter_Pet_Cat"},
    
    -- Rogue
    ["Riposte"]               = {text = "¡RÉPLICA!", color = {0.9, 0.7, 0.2}, icon = "Interface\\Icons\\Ability_Warrior_Challange"},
    ["Réplica"]               = {text = "¡RÉPLICA!", color = {0.9, 0.7, 0.2}, icon = "Interface\\Icons\\Ability_Warrior_Challange"},
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
            return GetItemCount(6265) or 0
        end,
        max = 32,
    },
    ROGUE = {
        name = "Combo Points",
        icon = "Interface\\Icons\\Ability_Rogue_Eviscerate",
        color = {1.0, 0.8, 0.0},
        getCount = function() return GetComboPoints("player", "target") or 0 end,
        max = 5,
    },
    DEATHKNIGHT = {
        name = "Runic Power",
        icon = "Interface\\Icons\\INV_Sword_62",
        color = {0.0, 0.8, 1.0},
        getCount = function() return UnitPower("player", 6) or 0 end, -- SPELL_POWER_RUNIC_POWER
        max = function()
            local m = UnitPowerMax("player", 6)
            return (m and m > 0) and m or 100
        end,
    },
    DRUID = {
        name = "Combo Points",
        icon = "Interface\\Icons\\Ability_Druid_Rake",
        color = {1.0, 0.6, 0.0},
        getCount = function() return GetComboPoints("player", "target") or 0 end,
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
    if self:GetOption("showResource") then
        self:CreateResourceBar()
    end
    if self:GetOption("showPetHealth") then
        self:CreatePetHealthBar()
    end
    
    self:RegisterEvents()
    self:ApplyOpacity()
end

function O:GetOption(key)
    if S.ModuleConfig then
        return S.ModuleConfig:GetValue("Overlord", key)
    end
    if key == "enabled" then return true end
    if key == "showProcs" then return true end
    if key == "showResource" then return true end
    if key == "showPetHealth" then return true end
    if key == "opacity" then return 0.8 end
    return true
end

function O:ApplyOpacity()
    local opacity = self:GetOption("opacity")
    if type(opacity) == "number" then
        if self.ResourceFrame then self.ResourceFrame:SetAlpha(opacity) end
        if self.PetFrame then self.PetFrame:SetAlpha(opacity) end
    end
end

-- ============================================
-- BARRA DE RECURSO SECUNDARIO
-- ============================================

function O:CreateResourceBar()
    if self.ResourceFrame then return end

    local _, class = UnitClass("player")
    local config = RESOURCE_CONFIG[class]
    if not config then return end -- Clase sin recurso especial
    
    local f = CreateFrame("Frame", "SequitoOverlordResource", UIParent)
    f:SetSize(200, 28)
    f:SetPoint("CENTER", UIParent, "CENTER", 0, -80)
    f:SetMovable(true)
    f:EnableMouse(true)
    f:SetClampedToScreen(true)
    f:RegisterForDrag("LeftButton")
    f:SetScript("OnDragStart", function(frame)
        if not InCombatLockdown() then frame:StartMoving() end
    end)
    f:SetScript("OnDragStop", function(frame) 
        frame:StopMovingOrSizing()
        if S.SmartDefaults then S.SmartDefaults:SavePosition("OverlordResource", frame) end
    end)
    
    -- Restaurar posición
    if S.SmartDefaults then S.SmartDefaults:RestorePosition("OverlordResource") end
    
    -- Fondo seguro en 3.3.5a (Ley II)
    f.bg = f:CreateTexture(nil, "BACKGROUND")
    f.bg:SetAllPoints()
    f.bg:SetTexture("Interface\\Buttons\\WHITE8X8")
    local r, g, b, a = 0.05, 0.05, 0.05, 0.8
    if S.Theme and S.Theme.GetColor then
        r, g, b, a = S.Theme:GetColor("background")
    end
    f.bg:SetVertexColor(r or 0.05, g or 0.05, b or 0.05, a or 0.8)
    
    -- Borde
    f.border = CreateFrame("Frame", nil, f)
    f.border:SetAllPoints()
    f.border:SetBackdrop({
        edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
        edgeSize = 12,
    })
    local br, bg2, bb = 0.3, 0.3, 0.3
    if S.Theme and S.Theme.GetColor then
        br, bg2, bb = S.Theme:GetColor("border")
    end
    f.border:SetBackdropBorderColor(br or 0.3, bg2 or 0.3, bb or 0.3, 0.8)
    
    -- Icono pequeño del recurso
    f.icon = f:CreateTexture(nil, "ARTWORK")
    f.icon:SetSize(20, 20)
    f.icon:SetPoint("LEFT", f, "LEFT", 4, 0)
    f.icon:SetTexture(config.icon)
    f.icon:SetTexCoord(0.07, 0.93, 0.07, 0.93)
    
    -- Barra de progreso
    local maxVal = type(config.max) == "function" and config.max() or config.max
    maxVal = (maxVal and maxVal > 0) and maxVal or 100

    f.bar = CreateFrame("StatusBar", nil, f)
    f.bar:SetSize(140, 14)
    f.bar:SetPoint("LEFT", f.icon, "RIGHT", 6, 0)
    f.bar:SetStatusBarTexture("Interface\\TargetingFrame\\UI-StatusBar")
    f.bar:SetStatusBarColor(config.color[1], config.color[2], config.color[3])
    f.bar:SetMinMaxValues(0, maxVal)
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
    
    -- OnUpdate para actualizar valores (Throttled)
    f.elapsed = 0
    f:SetScript("OnUpdate", function(frame, elapsed)
        frame.elapsed = frame.elapsed + elapsed
        if frame.elapsed < 0.2 then return end -- 5 FPS
        frame.elapsed = 0
        O:UpdateResource()
    end)
    
    self.ResourceFrame = f
    self.ResourceConfig = config
end

function O:UpdateResource()
    if not self.ResourceFrame or not self.ResourceConfig then return end
    
    local config = self.ResourceConfig
    local count = config.getCount() or 0
    local maxVal = type(config.max) == "function" and config.max() or config.max
    maxVal = (maxVal and maxVal > 0) and maxVal or 100
    
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
    if self.PetFrame then return end

    local _, class = UnitClass("player")
    -- Solo para clases con pets permanentes o invocables
    if class ~= "WARLOCK" and class ~= "HUNTER" and class ~= "DEATHKNIGHT" and class ~= "MAGE" then
        return
    end
    
    local f = CreateFrame("Frame", "SequitoOverlordPet", UIParent)
    f:SetSize(160, 20)
    f:SetPoint("CENTER", UIParent, "CENTER", 0, -110)
    f:SetMovable(true)
    f:EnableMouse(true)
    f:SetClampedToScreen(true)
    f:RegisterForDrag("LeftButton")
    f:SetScript("OnDragStart", function(frame)
        if not InCombatLockdown() then frame:StartMoving() end
    end)
    f:SetScript("OnDragStop", function(frame) 
        frame:StopMovingOrSizing()
        if S.SmartDefaults then S.SmartDefaults:SavePosition("OverlordPet", frame) end
    end)
    
    -- Restaurar posición
    if S.SmartDefaults then S.SmartDefaults:RestorePosition("OverlordPet") end
    f:Hide() -- Ocultar hasta que haya pet activa
    
    -- Fondo seguro en 3.3.5a (Ley II)
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
    
    -- OnUpdate throttled
    f.elapsed = 0
    f:SetScript("OnUpdate", function(frame, elapsed)
        frame.elapsed = frame.elapsed + elapsed
        if frame.elapsed < 0.25 then return end
        frame.elapsed = 0
        O:UpdatePetHealth()
    end)
    
    self.PetFrame = f
end

function O:UpdatePetHealth()
    if not self.PetFrame then return end
    
    if not UnitExists("pet") or UnitIsDead("pet") then
        self.PetFrame:Hide()
        return
    end
    
    self.PetFrame:Show()
    
    local hp = UnitHealth("pet") or 0
    local maxHp = UnitHealthMax("pet") or 1
    if maxHp <= 0 then maxHp = 1 end
    local pct = (hp / maxHp) * 100
    
    self.PetFrame.bar:SetValue(pct)
    self.PetFrame.text:SetText(math.floor(pct) .. "%")
    
    -- Color basado en salud
    if pct < 20 then
        self.PetFrame.bar:SetStatusBarColor(1, 0, 0)
        local pulse = 0.3 + 0.4 * math.abs(math.sin(GetTime() * 3))
        self.PetFrame.glow:SetAlpha(pulse)
    elseif pct < 50 then
        self.PetFrame.bar:SetStatusBarColor(1, 0.6, 0)
        self.PetFrame.glow:SetAlpha(0)
    else
        self.PetFrame.bar:SetStatusBarColor(0, 0.8, 0.2)
        self.PetFrame.glow:SetAlpha(0)
    end
    
    -- Actualizar icono del pet contextualmente
    local petIcon = O.GetPetIcon()
    if petIcon then
        self.PetFrame.icon:SetTexture(petIcon)
    end
end

-- ============================================
-- EVENTOS Y ALERTAS
-- ============================================

function O:RegisterEvents()
    if S.CLEU and S.CLEU.Register then
        S.CLEU:Register("SPELL_AURA_APPLIED", function(...)
            if not O:GetOption("showProcs") then return end
            
            local _, _, _, _, _, destGUID, _, _, _, spellName = ...
            if destGUID == UnitGUID("player") then
                local procInfo = PROC_DATA[spellName]
                if procInfo then
                    -- Para Maelstrom Weapon, solo alertar en dosis 5
                    if spellName ~= "Maelstrom Weapon" and spellName ~= "Arma de vorágine" and spellName ~= "Arma vorágine" then
                        if S.ShowAlert then
                            S:ShowAlert(procInfo.text, "INFO", procInfo.icon, procInfo.color)
                        end
                    end
                end
            end
        end)

        S.CLEU:Register("SPELL_AURA_APPLIED_DOSE", function(...)
            if not O:GetOption("showProcs") then return end
            
            local _, _, _, _, _, destGUID, _, _, _, spellName = ...
            if destGUID == UnitGUID("player") then
                if spellName == "Maelstrom Weapon" or spellName == "Arma de vorágine" or spellName == "Arma vorágine" then
                    local _, _, amount = select(11, ...)
                    if amount == 5 then
                        local procInfo = PROC_DATA[spellName]
                        if procInfo and S.ShowAlert then
                            S:ShowAlert(procInfo.text, "INFO", procInfo.icon, procInfo.color)
                        end
                    end
                end
            end
        end)
    end

    local f = CreateFrame("Frame", "SequitoOverlordEventFrame", UIParent)
    if not (S.CLEU and S.CLEU.Register) then
        f:RegisterEvent("COMBAT_LOG_EVENT_UNFILTERED")
    end
    f:RegisterEvent("UNIT_PET")
    f:RegisterEvent("PLAYER_ENTERING_WORLD")
    
    f:SetScript("OnEvent", function(self, event, ...)
        if event == "COMBAT_LOG_EVENT_UNFILTERED" then
            if not O:GetOption("showProcs") then return end
            
            local _, subEvent, _, _, _, destGUID, _, _, _, spellName = ...
            
            if subEvent == "SPELL_AURA_APPLIED" and destGUID == UnitGUID("player") then
                local procInfo = PROC_DATA[spellName]
                if procInfo then
                    if spellName == "Maelstrom Weapon" or spellName == "Arma de vorágine" or spellName == "Arma vorágine" then
                        return
                    end
                    if S.ShowAlert then
                        S:ShowAlert(procInfo.text, "INFO", procInfo.icon, procInfo.color)
                    end
                end
            elseif subEvent == "SPELL_AURA_APPLIED_DOSE" and destGUID == UnitGUID("player") then
                if spellName == "Maelstrom Weapon" or spellName == "Arma de vorágine" or spellName == "Arma vorágine" then
                    local _, _, amount = select(11, ...)
                    if amount == 5 then
                        local procInfo = PROC_DATA[spellName]
                        if procInfo and S.ShowAlert then
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

-- Helper: Obtener icono de la mascota contextualmente
function O.GetPetIcon()
    if not UnitExists("pet") then return nil end
    
    local _, class = UnitClass("player")
    if class == "MAGE" then
        return "Interface\\Icons\\Spell_Frost_SummonWaterElemental"
    elseif class == "DEATHKNIGHT" then
        return "Interface\\Icons\\Spell_DeathKnight_GhoulFrenzy"
    elseif class == "WARLOCK" then
        local family = UnitCreatureFamily("pet")
        local icons = {
            ["Imp"]                  = "Interface\\Icons\\Spell_Shadow_SummonImp",
            ["Diablillo"]            = "Interface\\Icons\\Spell_Shadow_SummonImp",
            ["Voidwalker"]           = "Interface\\Icons\\Spell_Shadow_SummonVoidWalker",
            ["Abisario"]             = "Interface\\Icons\\Spell_Shadow_SummonVoidWalker",
            ["Succubus"]             = "Interface\\Icons\\Spell_Shadow_SummonSuccubus",
            ["Súcubo"]               = "Interface\\Icons\\Spell_Shadow_SummonSuccubus",
            ["Felhunter"]            = "Interface\\Icons\\Spell_Shadow_SummonFelHunter",
            ["Manáfago"]             = "Interface\\Icons\\Spell_Shadow_SummonFelHunter",
            ["Felguard"]             = "Interface\\Icons\\Spell_Shadow_SummonFelGuard",
            ["Guardia Apocalíptico"] = "Interface\\Icons\\Spell_Shadow_SummonFelGuard",
            ["Guardia vil"]          = "Interface\\Icons\\Spell_Shadow_SummonFelGuard",
            ["Infernal"]             = "Interface\\Icons\\Spell_Shadow_SummonInfernal",
        }
        return (family and icons[family]) or "Interface\\Icons\\Spell_Shadow_SummonImp"
    elseif class == "HUNTER" then
        if GetSpellTexture then
            local callIcon = GetSpellTexture("Call Pet") or GetSpellTexture("Llamar a mascota")
            if callIcon then return callIcon end
        end
        return "Interface\\Icons\\Ability_Hunter_BeastCall"
    end
    
    return "Interface\\Icons\\Ability_Hunter_Pet_Bear"
end

-- ============================================
-- COMANDOS SLASH
-- ============================================

function O:Toggle()
    if self.ResourceFrame then
        if self.ResourceFrame:IsShown() then
            self.ResourceFrame:Hide()
        else
            self.ResourceFrame:Show()
        end
    end
    if self.PetFrame and UnitExists("pet") then
        if self.PetFrame:IsShown() then
            self.PetFrame:Hide()
        else
            self.PetFrame:Show()
        end
    end
end

function O:SlashCommand(msg)
    msg = msg and msg:lower():gsub("^%s*(.-)%s*$", "%1") or ""
    
    if msg == "toggle" then
        self:Toggle()
    elseif msg == "resource" then
        if self.ResourceFrame then
            if self.ResourceFrame:IsShown() then self.ResourceFrame:Hide() else self.ResourceFrame:Show() end
        end
    elseif msg == "pet" then
        if self.PetFrame then
            if self.PetFrame:IsShown() then self.PetFrame:Hide() else self.PetFrame:Show() end
        end
    elseif msg == "config" or msg == "options" then
        if S.ModuleConfig then
            S.ModuleConfig:OpenCategory("Overlord")
        end
    else
        print("|cFF00FFFF[The Overlord HUD]|r Comandos:")
        print("  |cFFFFFFFF/overlord toggle|r - Alternar visibilidad de las barras")
        print("  |cFFFFFFFF/overlord resource|r - Alternar barra de recursos secundarios")
        print("  |cFFFFFFFF/overlord pet|r - Alternar barra de salud de mascota")
        print("  |cFFFFFFFF/overlord config|r - Abrir panel de opciones")
    end
end

SLASH_OVERLORD1 = "/overlord"
SLASH_OVERLORD2 = "/hud"
SLASH_OVERLORD3 = "/seqhud"
SlashCmdList["OVERLORD"] = function(msg)
    O:SlashCommand(msg)
end

-- ============================================
-- REGISTRO EN MODULECONFIG
-- ============================================
if S.ModuleConfig then
    S.ModuleConfig:RegisterModule("Overlord", {
        name = "The Overlord HUD",
        description = "Alertas visuales de procs, barra de recursos secundarios y salud de mascota.",
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

local loader = CreateFrame("Frame")
loader:RegisterEvent("PLAYER_LOGIN")
loader:SetScript("OnEvent", function()
    O:Initialize()
end)
