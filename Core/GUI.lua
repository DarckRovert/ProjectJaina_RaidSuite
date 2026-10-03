--[[
    SEQUITO - GUI Engine
    Handles the Sphere and button creation.
]]--

local addonName, S = ...
S.GUI = {}

-- Iconos de esfera por clase
local ClassSphereIcons = {
    ["WARLOCK"] = "Interface\\Icons\\Spell_Shadow_SoulGem",
    ["DEATHKNIGHT"] = "Interface\\Icons\\Spell_Deathknight_DeathStrike",
    ["MAGE"] = "Interface\\Icons\\Spell_Frost_FrostBolt02",
    ["PRIEST"] = "Interface\\Icons\\Spell_Holy_PowerWordShield",
    ["DRUID"] = "Interface\\Icons\\Spell_Nature_Regeneration",
    ["PALADIN"] = "Interface\\Icons\\Spell_Holy_SealOfMight",
    ["SHAMAN"] = "Interface\\Icons\\Spell_Nature_Lightning",
    ["HUNTER"] = "Interface\\Icons\\Ability_Hunter_BeastCall",
    ["ROGUE"] = "Interface\\Icons\\Ability_Stealth",
    ["WARRIOR"] = "Interface\\Icons\\Ability_Warrior_BattleShout",
}

-- Helper para obtener configuración
function S.GUI:GetOption(key)
    if S.ModuleConfig then
        local val = S.ModuleConfig:GetValue("GUI", key)
        if val ~= nil then return val end
    end
    return true
end

function S.GUI:Initialize()
    if not self:GetOption("enabled") then
        return
    end
    
    if not S.Sphere then
        self:CreateSphere()
    end
    if not self.MinimapBtn then
        self:CreateMinimapButton()
    end
    -- RaidAssist Integration (v7.1.0)
    if not self.RaidAssistBtn then
        self:CreateRaidAssistButton()
    end
    if not self.RaidStatusIndicator then
        self:CreateRaidStatusIndicator()
    end
end

function S.GUI:CreateSphere()
    if S.Sphere or _G["SequitoSphere"] then
        return
    end
    
    local db = S.db.profile
    
    local f = CreateFrame("Button", "SequitoSphere", UIParent, "SecureActionButtonTemplate")
    f:SetSize(64, 64)
    
    if not db.Position then db.Position = {point="CENTER", relativeTo="UIParent", relativePoint="CENTER", x=0, y=0} end
    
    local finalScale = db.SphereScale or db.Scale or 1.0
    if finalScale <= 0 then finalScale = 1.0 end
    f:SetScale(finalScale)
    f:SetPoint(db.Position.point, db.Position.relativeTo, db.Position.relativePoint, db.Position.x, db.Position.y)
    
    f:SetMovable(true)
    f:EnableMouse(true)
    f:RegisterForDrag("LeftButton")
    
    -- Dynamic texture based on class
    local _, playerClass = UnitClass("player")
    local sphereIcon = ClassSphereIcons[playerClass] or "Interface\\Icons\\INV_Misc_QuestionMark"
    f:SetNormalTexture(sphereIcon) 
    f:SetPushedTexture(sphereIcon)
    f:SetHighlightTexture("Interface\\Buttons\\ButtonHilight-Square")
    
    -- Aesthetic Ring (Makes the square icon look round)
    f.ring = f:CreateTexture(nil, "OVERLAY")
    f.ring:SetSize(75, 75)
    f.ring:SetPoint("CENTER", f, "CENTER", 0, 0)
    f.ring:SetTexture("Interface\\Minimap\\MiniMap-TrackingBorder")
    
    if db.ShowSphere then
        f:Show()
    else
        f:Hide()
    end
    
    f:SetScript("OnDragStart", function(self)
        if not S.db.profile.Locked then self:StartMoving() end
    end)
    f:SetScript("OnDragStop", function(self)
        self:StopMovingOrSizing()
        local point, _, relativePoint, x, y = self:GetPoint()
        S.db.profile.Position = {point=point, relativeTo="UIParent", relativePoint=relativePoint, x=x, y=y}
    end)
    
    f.countText = f:CreateFontString(nil, "OVERLAY", "GameFontNormalHuge")
    f.countText:SetPoint("CENTER", f, "CENTER", 0, 7) -- Move up slightly
    f.countText:SetTextColor(1, 1, 1, 1)
    f.countText:SetShadowOffset(1, -1) -- Better visibility
    f.countText:SetText("")
    
    f:SetAttribute("type1", "macro")
    
    local mountMacro = ""
    if S.Mounts and S.Mounts.GenerateMountMacro then
        mountMacro = S.Mounts:GenerateMountMacro()
    else
        mountMacro = "/castrandom [nocombat] Caballo, Kodo, Lobo"
    end
    
    local finalMacro = "/cleartarget [dead]\n/targetenemy [noexists][dead]\n/cast [combat] !Auto Attack\n" .. mountMacro
    f:SetAttribute("macrotext1", finalMacro)
    
    f:RegisterForClicks("AnyUp")
    f:SetScript("PostClick", function(self, button)
        if button == "RightButton" then
            if S.Menu then
                S.Menu:Toggle()
            end
        elseif button == "MiddleButton" then
            if S.Radial then
                S.Radial:Toggle()
            end
        end
    end)
    
    local timer = 0
    f:SetScript("OnUpdate", function(self, elapsed)
        if not S.db.profile.ShowSphere then 
             if self:IsShown() then self:Hide() end
             return
        end

        timer = timer + elapsed
        if timer >= 0.2 then
            timer = 0
            
            if S.Universal and S.db.profile.SphereText then
                local count, ctype = S.Universal:GetResourceCount()
                if count then
                    self.countText:SetText(count)
                    
                    if ctype == "SHARD" then
                        if count < 3 then
                            self.countText:SetTextColor(1, 0, 0) -- Red (Alert)
                        elseif count < 10 then
                            self.countText:SetTextColor(1, 1, 0) -- Yellow
                        else
                            self.countText:SetTextColor(0.8, 0.5, 1) -- Purple (Classy)
                        end
                    elseif ctype == "COMBO" then
                         self.countText:SetTextColor(1, 0.2, 0)
                    else
                         self.countText:SetTextColor(1, 1, 1)
                    end
                else
                    self.countText:SetText("")
                end
                
                -- Sphere Percentage (Necrosis Style)
                if S.db.profile.SpherePercent then
                    local p = 0
                    if UnitPowerMax("player") > 0 then
                        p = math.floor((UnitPower("player") / UnitPowerMax("player")) * 100)
                    end
                    if not self.percentText then
                        self.percentText = self:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
                        self.percentText:SetPoint("CENTER", self, "CENTER", 0, -10) -- Move down to center bottom
                    end
                    self.percentText:SetText(p .. "%")
                    self.percentText:SetTextColor(0, 0.8, 1) -- Mana Color
                end
            else
                self.countText:SetText("")
                if self.percentText then self.percentText:SetText("") end
            end
        end
    end)
    
    S.Sphere = f
    
    self:CreateSatellites()
    self:CreateBuffMonitor() -- New
    -- RaidAssist buttons are created in Initialize() to avoid duplicates
end

function S.GUI:CreateBuffMonitor()
    if self.BuffMonitor then return end
    
    local monitor = CreateFrame("Frame", "SequitoBuffMonitor", S.Sphere)
    monitor:SetSize(24, 24)
    monitor:SetPoint("CENTER", S.Sphere, "CENTER", 0, 0) -- Center overlay
    
    local texture = monitor:CreateTexture(nil, "OVERLAY")
    texture:SetAllPoints(monitor)
    texture:SetTexture("Interface\\Icons\\Spell_Shadow_DemonBreath") -- Warning Icon
    
    -- Oscilador de parpadeo 3.3.5a (sin AnimationGroup/BOUNCE)
    monitor.flashTimer = 0
    monitor.flashing = false
    monitor.texture = texture
    
    -- Exponer interfaz retrocompatible (self.BuffMonitor.icon apunta al Frame contenedor)
    self.BuffMonitor = {
        frame = monitor,
        icon = monitor,
        texture = texture,
        anim = monitor,
    }
    monitor:Hide()
    
    -- Oscilador único con math.sin en el frame
    monitor:SetScript("OnUpdate", function(frame, elapsed)
        if not frame.flashing then return end
        frame.flashTimer = frame.flashTimer + elapsed
        local sine = (math.sin(frame.flashTimer * 4) + 1) / 2
        frame:SetAlpha(0.3 + sine * 0.7)
    end)
    
    -- Check loop (1s interval)
    local f = CreateFrame("Frame")
    f:SetScript("OnUpdate", function(self, elapsed)
        self.timer = (self.timer or 0) + elapsed
        if self.timer > 1.0 then
            S.GUI:CheckBuffs()
            self.timer = 0
        end
    end)
end

function S.GUI:CheckBuffs()
    if not self.BuffMonitor or not S.db.profile.ShowSphere then return end
    
    local _, class = UnitClass("player")
    local missing = false
    
    -- Class-specific buff checks
    if class == "WARLOCK" then
        -- Check Armor (Demon Skin / Demon Armor / Fel Armor)
        local hasArmor = false
        local armorBuffs = {
            "Piel de demonio", "Demon Skin",
            "Armadura demoníaca", "Demon Armor",
            "Armadura vil", "Fel Armor"
        }
        
        for i=1, 40 do
            local name = UnitBuff("player", i)
            if not name then break end
            for _, buff in ipairs(armorBuffs) do
                if name == buff then hasArmor = true break end
            end
            if hasArmor then break end
        end
        if not hasArmor then missing = true end
        
        -- Check Pet in Combat
        if InCombatLockdown() and not UnitExists("pet") then
            missing = true
        end
    elseif class == "DEATHKNIGHT" then
        -- Check Presence
        local hasPresence = false
        local presenceBuffs = {
            "Presencia de sangre", "Blood Presence",
            "Presencia de Escarcha", "Frost Presence",
            "Presencia profana", "Unholy Presence"
        }
        for i=1, 40 do
            local name = UnitBuff("player", i)
            if not name then break end
            for _, buff in ipairs(presenceBuffs) do
                if name == buff then hasPresence = true break end
            end
            if hasPresence then break end
        end
        if not hasPresence then missing = true end
    elseif class == "MAGE" then
        -- Check Armor
        local hasArmor = false
        local armorBuffs = {
            "Armadura de hielo", "Ice Armor",
            "Armadura de mago", "Mage Armor",
            "Armadura de arrabio", "Molten Armor"
        }
        for i=1, 40 do
            local name = UnitBuff("player", i)
            if not name then break end
            for _, buff in ipairs(armorBuffs) do
                if name == buff then hasArmor = true break end
            end
            if hasArmor then break end
        end
        if not hasArmor then missing = true end
    end
    -- Add more classes as needed
    
    -- Legacy code cleaned up - class checks handled above
    
    if missing then
        self.BuffMonitor.icon:Show()
        self.BuffMonitor.icon.flashing = true
        self.BuffMonitor.icon.flashTimer = 0
    else
        self.BuffMonitor.icon.flashing = false
        self.BuffMonitor.icon:SetAlpha(1)
        self.BuffMonitor.icon:Hide()
    end
end

-- Helper: Verifica si el jugador conoce un hechizo
local function IsSpellLearned(spellID)
    local name = GetSpellInfo(spellID)
    if not name then return false end
    
    -- Metodo 1: Buscar por nombre en el spellbook del jugador
    local i = 1
    while true do
        local spellName, spellRank = GetSpellName(i, BOOKTYPE_SPELL)
        if not spellName then break end
        if spellName == name then
            return true
        end
        i = i + 1
    end
    
    -- Metodo 2: Verificar si IsPlayerSpell existe (algunas versiones de WotLK)
    if IsPlayerSpell and IsPlayerSpell(spellID) then
        return true
    end
    
    -- Metodo 3: Verificar si el hechizo esta usable (IsUsableSpell)
    -- Si retorna true, significa que el jugador lo conoce
    local usable, nomana = IsUsableSpell(name)
    if usable or nomana then
        return true
    end
    
    return false
end

function S.GUI:CreateSatellites()
    local _, class = UnitClass("player")
    local config = S.Data.Classes[class]
    if not config then return end
    
    local r = 58 -- Increased radius for better spacing
    local angles = {135, 45, -45, -135} 
    
    for i=1, 4 do
        local spellData = config[i]
        if spellData then
            -- NUEVO: Seleccionar el primer hechizo aprendido del array
            local spellID = nil
            if type(spellData) == "table" then
                -- Es un array de opciones, buscar el primero que el jugador conoce
                for _, candidateID in ipairs(spellData) do
                    if IsSpellLearned(candidateID) then
                        spellID = candidateID
                        break
                    end
                end
                -- Si no conoce ninguno, usar el primero del array (se mostrara oscurecido)
                if not spellID then
                    spellID = spellData[1]
                end
            else
                -- Es un ID unico (no array)
                spellID = spellData
            end
            
            if spellID then
                local btnName = "SequitoBtn"..i
                local btn = _G[btnName]
                if not btn then
                    btn = CreateFrame("Button", btnName, S.Sphere, "SecureActionButtonTemplate")
                    btn:SetSize(32, 32)
                    
                    local rad = math.rad(angles[i])
                    local x = math.cos(rad) * r
                    local y = math.sin(rad) * r
                    btn:SetPoint("CENTER", S.Sphere, "CENTER", x, y)
                    
                    local cd = CreateFrame("Cooldown", btnName.."Cooldown", btn, "CooldownFrameTemplate")
                    cd:SetAllPoints()
                    btn.cooldown = cd
                end
                
                btn.spellID = spellID
                btn.spellOptions = spellData -- Guardar el array completo para actualizaciones
                
                local name, _, icon = GetSpellInfo(spellID)
                if name then
                    btn:SetNormalTexture(icon)
                    btn:SetAttribute("type", "spell")
                    btn:SetAttribute("spell", name)
                    
                    -- Verificar si el jugador conoce el hechizo
                    local isKnown = IsSpellLearned(spellID)
                    if isKnown then
                        btn:SetAlpha(1.0)
                        btn:EnableMouse(true)
                    else
                        -- Hechizo no aprendido: mostrar oscurecido y deshabilitado
                        btn:SetAlpha(0.3)
                        btn:EnableMouse(false)
                    end
                    
                    btn:SetScript("OnEnter", function(self)
                        GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
                        local link = GetSpellLink(spellID)
                        if link then
                            GameTooltip:SetHyperlink(link)
                        else
                            GameTooltip:SetText(name, 1, 1, 1)
                        end
                        if not IsSpellLearned(spellID) then
                            GameTooltip:AddLine("No aprendido", 1, 0, 0)
                        end
                        GameTooltip:Show()
                    end)
                    btn:SetScript("OnLeave", function() GameTooltip:Hide() end)
                else
                     btn:SetNormalTexture("Interface\\Icons\\INV_Misc_QuestionMark")
                     btn:SetAlpha(0.3)
                     btn:EnableMouse(false)
                end
            end
        end
    end
    
    self:RegisterCooldownUpdates()
    self:RegisterPetUpdates() -- New
    self:RegisterSpellLearnUpdates() -- Nuevo: actualizar cuando aprende hechizos
end

-- Registrar eventos para actualizar cuando el jugador aprende nuevos hechizos
function S.GUI:RegisterSpellLearnUpdates()
    local f = self.SpellLearnFrame or CreateFrame("Frame")
    self.SpellLearnFrame = f
    f:RegisterEvent("LEARNED_SPELL_IN_TAB")
    f:RegisterEvent("SPELLS_CHANGED")
    f:RegisterEvent("PLAYER_LEVEL_UP")
    
    f:SetScript("OnEvent", function(self, event)
        if InCombatLockdown() then
            S.GUI.PendingSpellUpdate = true
            return
        end
        S.GUI:RefreshSatelliteStates()
    end)
end

-- Actualizar estado de los botones satelite segun hechizos aprendidos
function S.GUI:RefreshSatelliteStates()
    if InCombatLockdown() then
        self.PendingSpellUpdate = true
        return
    end
    
    for i=1, 4 do
        local btn = _G["SequitoBtn"..i]
        if btn and btn.spellOptions then
            -- NUEVO: Si tiene opciones multiples, buscar el mejor hechizo aprendido
            local newSpellID = nil
            if type(btn.spellOptions) == "table" then
                for _, candidateID in ipairs(btn.spellOptions) do
                    if IsSpellLearned(candidateID) then
                        newSpellID = candidateID
                        break
                    end
                end
                if not newSpellID then
                    newSpellID = btn.spellOptions[1]
                end
            else
                newSpellID = btn.spellOptions
            end
            
            -- Si cambio el hechizo, actualizar el boton
            if newSpellID ~= btn.spellID then
                btn.spellID = newSpellID
                local name, _, icon = GetSpellInfo(newSpellID)
                if name then
                    btn:SetNormalTexture(icon)
                    btn:SetAttribute("spell", name)
                end
            end
            
            -- Actualizar estado (aprendido/no aprendido)
            local isKnown = IsSpellLearned(btn.spellID)
            if isKnown then
                btn:SetAlpha(1.0)
                btn:EnableMouse(true)
            else
                btn:SetAlpha(0.3)
                btn:EnableMouse(false)
            end
        end
    end
end

function S.GUI:RegisterPetUpdates()
    local f = self.PetUpdateFrame or CreateFrame("Frame")
    self.PetUpdateFrame = f
    f:RegisterEvent("UNIT_PET")
    f:RegisterEvent("PLAYER_ENTERING_WORLD")
    f:RegisterEvent("PLAYER_REGEN_ENABLED") -- Retry if combat blocked
    
    f:SetScript("OnEvent", function(self, event, ...)
        if event == "PLAYER_REGEN_ENABLED" then
            if S.GUI.PendingPetUpdate then
                S.GUI:UpdateSatellites()
                S.GUI.PendingPetUpdate = false
            end
            if S.GUI.PendingSpellUpdate then
                S.GUI:RefreshSatelliteStates()
                S.GUI.PendingSpellUpdate = false
            end
        else
            S.GUI:UpdateSatellites()
        end
    end)
    
    -- Initial check
    self:UpdateSatellites()
end

function S.GUI:UpdateSatellites()
    if InCombatLockdown() then
        self.PendingPetUpdate = true
        return
    end
    
    local _, class = UnitClass("player")
    
    -- Only Warlock and Hunter have dynamic pet slots
    if class ~= "WARLOCK" and class ~= "HUNTER" then return end
    
    -- Slot 4 is the dynamic slot (Bottom Left -135deg)
    local btn = _G["SequitoBtn4"]
    if not btn then return end
    
    local petSpellID = nil
    
    -- Check Pet (Warlock demons, Hunter pets)
    if UnitExists("pet") then
        local family = UnitCreatureFamily("pet")
        if S.Data.PetSpells and S.Data.PetSpells[family] then
            petSpellID = S.Data.PetSpells[family]
        end
    end
    
    -- If no pet spell, revert to default class spell
    if not petSpellID then
        local config = S.Data.Classes[class]
        if config then
            local spellData = config[4]
            -- NUEVO: Seleccionar el primer hechizo aprendido del array
            if type(spellData) == "table" then
                for _, candidateID in ipairs(spellData) do
                    if IsSpellLearned(candidateID) then
                        petSpellID = candidateID
                        break
                    end
                end
                if not petSpellID then
                    petSpellID = spellData[1]
                end
            else
                petSpellID = spellData
            end
        end
    end
    
    if petSpellID then
        local name, _, icon = GetSpellInfo(petSpellID)
        if name then
            btn:SetNormalTexture(icon)
            btn:SetAttribute("type", "spell")
            btn:SetAttribute("spell", name)
            btn.spellID = petSpellID
            
            -- Verificar si el hechizo esta aprendido
            local isKnown = IsSpellLearned(petSpellID)
            if isKnown then
                btn:SetAlpha(1.0)
                btn:EnableMouse(true)
            else
                btn:SetAlpha(0.3)
                btn:EnableMouse(false)
            end
            
            -- Update tooltip hook
            btn:SetScript("OnEnter", function(self)
                GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
                local link = GetSpellLink(self.spellID)
                if link then
                    GameTooltip:SetHyperlink(link)
                else
                    GameTooltip:SetText(name, 1, 1, 1)
                end
                if not IsSpellLearned(self.spellID) then
                    GameTooltip:AddLine("No aprendido", 1, 0, 0)
                end
                GameTooltip:Show()
            end)
        end
    end
    
    -- Actualizar estados de todos los botones
    self:RefreshSatelliteStates()
end

function S.GUI:RegisterCooldownUpdates()
    local f = self.CooldownFrame or CreateFrame("Frame")
    self.CooldownFrame = f
    f:RegisterEvent("SPELL_UPDATE_COOLDOWN")
    f:SetScript("OnEvent", function()
        S.GUI:UpdateCooldowns()
    end)
    self:UpdateCooldowns() 
end

function S.GUI:UpdateCooldowns()
    local _, class = UnitClass("player")
    local config = S.Data.Classes[class]
    if not config then return end
    
    for i=1, 4 do
        local btn = _G["SequitoBtn"..i]
        if btn and btn.spellID and btn.cooldown then
            local start, duration, enabled = GetSpellCooldown(btn.spellID)
            if enabled == 1 and start > 0 and duration > 0 then
                btn.cooldown:SetCooldown(start, duration)
            else
                btn.cooldown:Hide()
            end
        end
    end
end

function S.GUI:CreateMinimapButton()
    if self.MinimapBtn or _G["SequitoMinimapButton"] then
        return
    end
    
    local db = S.db.profile
    
    local btn = CreateFrame("Button", "SequitoMinimapButton", Minimap)
    btn:SetSize(31, 31)
    btn:SetFrameStrata("MEDIUM")
    btn:SetToplevel(true)
    btn:SetHighlightTexture("Interface\\Minimap\\UI-Minimap-ZoomButton-Highlight")
    
    local overlay = btn:CreateTexture(nil, "OVERLAY")
    overlay:SetSize(53, 53)
    overlay:SetTexture("Interface\\Minimap\\MiniMap-TrackingBorder")
    overlay:SetPoint("TOPLEFT", 0, 0)
    
    local icon = btn:CreateTexture(nil, "BACKGROUND")
    icon:SetSize(20, 20)
    icon:SetTexture("Interface\\Icons\\Ability_Racial_Cannibalize")
    icon:SetPoint("CENTER", 0, 1)
    
    local angle = 45
    local radius = 80
    
    local function UpdatePosition()
        local r = 80
        local x = math.cos(math.rad(angle)) * r
        local y = math.sin(math.rad(angle)) * r
        btn:SetPoint("CENTER", Minimap, "CENTER", x, y)
    end
    
    UpdatePosition()
    
    btn:SetMovable(true)
    btn:RegisterForDrag("LeftButton")
    btn:SetScript("OnDragStart", function(self) self:LockHighlight() self:SetScript("OnUpdate", function(self)
        local mx, my = Minimap:GetCenter()
        local cx, cy = GetCursorPosition()
        local scale = Minimap:GetEffectiveScale()
        cx, cy = cx / scale, cy / scale
        angle = math.deg(math.atan2(cy - my, cx - mx))
        UpdatePosition()
    end) end)
    
    btn:SetScript("OnDragStop", function(self) self:UnlockHighlight() self:SetScript("OnUpdate", nil) end)
    
    btn:SetScript("OnClick", function(self, button)
        if button == "RightButton" then
            if S.Options then S.Options:Toggle() end
        else
            if S.Menu then S.Menu:Toggle() end
        end
    end)
    
    btn:SetScript("OnEnter", function(self)
        GameTooltip:SetOwner(self, "ANCHOR_LEFT")
        GameTooltip:SetText("Sequito", 1, 0, 1)
        GameTooltip:AddLine("Click Izquierdo: Menu Esfera", 1, 1, 1)
        GameTooltip:AddLine("Click Derecho: Opciones", 1, 1, 1)
        GameTooltip:Show()
    end)
    btn:SetScript("OnLeave", function() GameTooltip:Hide() end)
    
    self.MinimapBtn = btn
    
    if db.ShowMinimap == false then
        btn:Hide()
    else
        btn:Show() 
    end
end

function S.GUI:UpdateMinimap()
    if not self.MinimapBtn then return end
    if S.db.profile.ShowMinimap then
        self.MinimapBtn:Show()
    else
        self.MinimapBtn:Hide()
    end
end

-- ============================================
-- RAID ASSIST INTEGRATION
-- ============================================

function S.GUI:CreateRaidAssistButton()
    if self.RaidAssistBtn or _G["SequitoRaidAssistBtn"] then
        return
    end
    
    local btn = CreateFrame("Button", "SequitoRaidAssistBtn", S.Sphere)
    btn:SetSize(28, 28)
    
    -- Posición: abajo de la esfera
    btn:SetPoint("TOP", S.Sphere, "BOTTOM", 0, -5)
    
    -- Icono de raid
    btn:SetNormalTexture("Interface\\Icons\\Achievement_Dungeon_GlsOculus_Heroic")
    btn:SetHighlightTexture("Interface\\Buttons\\ButtonHilight-Square")
    
    -- Borde
    local border = btn:CreateTexture(nil, "OVERLAY")
    border:SetTexture("Interface\\Minimap\\MiniMap-TrackingBorder")
    border:SetSize(42, 42)
    border:SetPoint("CENTER", 10, -10)
    
    btn:SetScript("OnClick", function(self, button)
        if button == "RightButton" then
            -- Click derecho: Panel de líder
            if S.RaidAssistUI and S.RaidAssistUI.ShowLeaderPanel then
                S.RaidAssistUI:ShowLeaderPanel()
            end
        else
            -- Click izquierdo: Panel principal
            if S.RaidAssistUI and S.RaidAssistUI.Toggle then
                S.RaidAssistUI:Toggle()
            end
        end
    end)
    
    btn:SetScript("OnEnter", function(self)
        GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
        GameTooltip:SetText("|cFF00FFFFRaid Assist|r", 1, 1, 1)
        GameTooltip:AddLine(" ")
        GameTooltip:AddLine("Click Izquierdo: Panel Principal", 0.8, 0.8, 0.8)
        GameTooltip:AddLine("Click Derecho: Panel de Líder", 0.8, 0.8, 0.8)
        if S.RaidAssist then
            GameTooltip:AddLine(" ")
            GameTooltip:AddLine("Modo: |cFFFFFF00" .. (S.RaidAssist.mode or "FARM") .. "|r", 1, 1, 1)
            GameTooltip:AddLine("Wipes: |cFFFF6666" .. (S.RaidAssist.wipeCount or 0) .. "|r", 1, 1, 1)
            local userCount = 0
            if S.RaidAssist.users then
                for _ in pairs(S.RaidAssist.users) do userCount = userCount + 1 end
            end
            GameTooltip:AddLine("Usuarios Sequito: |cFF66FF66" .. userCount .. "|r", 1, 1, 1)
        end
        GameTooltip:Show()
    end)
    btn:SetScript("OnLeave", function() GameTooltip:Hide() end)
    
    btn:RegisterForClicks("AnyUp")
    
    self.RaidAssistBtn = btn
    
    -- Solo mostrar si está en grupo/raid
    self:UpdateRaidAssistButton()
end

function S.GUI:UpdateRaidAssistButton()
    if not self.RaidAssistBtn then return end
    
    local inGroup = (GetNumRaidMembers() > 0) or (GetNumPartyMembers() > 0)
    
    if inGroup and S.db.profile.raidAssistEnabled ~= false then
        self.RaidAssistBtn:Show()
    else
        -- Siempre mostrar pero con alpha reducido si no está en grupo
        self.RaidAssistBtn:Show()
        self.RaidAssistBtn:SetAlpha(inGroup and 1.0 or 0.5)
    end
end

function S.GUI:CreateRaidStatusIndicator()
    if self.RaidStatusIndicator then return end
    
    -- Indicador pequeño en la esquina de la esfera
    local indicator = S.Sphere:CreateTexture("SequitoRaidIndicator", "OVERLAY")
    indicator:SetSize(12, 12)
    indicator:SetPoint("TOPRIGHT", S.Sphere, "TOPRIGHT", 2, 2)
    indicator:SetTexture("Interface\\RAIDFRAME\\ReadyCheck-Ready")
    indicator:Hide()
    
    self.RaidStatusIndicator = indicator
    
    -- Frame para actualizar el indicador
    local updateFrame = CreateFrame("Frame")
    updateFrame:RegisterEvent("RAID_ROSTER_UPDATE")
    updateFrame:RegisterEvent("PARTY_MEMBERS_CHANGED")
    updateFrame:RegisterEvent("PLAYER_ENTERING_WORLD")
    updateFrame:SetScript("OnEvent", function()
        S.GUI:UpdateRaidStatusIndicator()
        S.GUI:UpdateRaidAssistButton()
    end)
end

function S.GUI:UpdateRaidStatusIndicator()
    if not self.RaidStatusIndicator then return end
    
    local inRaid = GetNumRaidMembers() > 0
    local inParty = GetNumPartyMembers() > 0
    
    if inRaid then
        self.RaidStatusIndicator:SetTexture("Interface\\RAIDFRAME\\ReadyCheck-Ready")
        self.RaidStatusIndicator:Show()
    elseif inParty then
        self.RaidStatusIndicator:SetTexture("Interface\\RAIDFRAME\\ReadyCheck-Waiting")
        self.RaidStatusIndicator:Show()
    else
        self.RaidStatusIndicator:Hide()
    end
end

-- Combat Status Update (Called from Sequito.lua main events)
function S.GUI:UpdateCombatStatus(inCombat)
    if not S.Sphere then return end
    
    if inCombat then
        -- Visual feedback: Red glow or border during combat
        if S.Sphere.ring then
            S.Sphere.ring:SetVertexColor(1, 0.3, 0.3, 1)
        end
    else
        -- Reset to normal
        if S.Sphere.ring then
            S.Sphere.ring:SetVertexColor(1, 1, 1, 1)
        end
    end
end

-- Wrapper function for Bindings.xml keybinds
function S.GUI:OnSphereClick(button)
    if button == "RightButton" then
        if S.Menu then
            S.Menu:Toggle()
        end
    else
        -- Left click - try to use mount or execute sphere action
        if S.Mounts then
            S.Mounts:MountUp()
        end
    end
end
