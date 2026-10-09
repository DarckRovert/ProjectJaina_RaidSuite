--[[
    SEQUITO - Pet Manager (Universal & Contextual)
    Control táctico y monitorización avanzada de mascotas (Hunter/Warlock/DK/Mage).
    Incluye alertas de Taunt en mazmorra/raid, felicidad, pacto de muerte y combate.
]]--

local addonName, S = ...
S.PetManager = {}
local PM = S.PetManager

-- Helper para obtener configuración
function PM:GetOption(key)
    if S.ModuleConfig then
        return S.ModuleConfig:GetValue("PetManager", key)
    end
    return true
end

function PM:Initialize()
    if not self:GetOption("enabled") then
        return
    end
    
    self:CreatePetButton()
    self:RegisterEvents()
    print("|cFFFF00FFJaina|r: [Pets] Gestor táctico de mascotas activo.")
end

function PM:CreatePetButton()
    if self.Button then return end
    
    -- Botón orbital (Satélite especial conectado a S.Sphere)
    local btn = CreateFrame("Button", "JainaPetBtn", S.Sphere, "SecureActionButtonTemplate")
    btn:SetSize(36, 36)
    btn:SetPoint("CENTER", S.Sphere, "CENTER", 0, -58)
    
    -- Textura del Icono
    btn.icon = btn:CreateTexture(nil, "BACKGROUND")
    btn.icon:SetAllPoints()
    btn.icon:SetTexture("Interface\\Icons\\Ability_Hunter_BeastCall")
    
    -- Borde de Salud
    btn.border = btn:CreateTexture(nil, "OVERLAY")
    btn.border:SetAllPoints()
    btn.border:SetTexture("Interface\\Buttons\\UI-ActionButton-Border")
    btn.border:SetBlendMode("ADD")
    btn.border:SetVertexColor(0, 1, 0)
    btn.border:Hide()
    
    -- Lógica de Click Seguro (WoW 3.3.5a Protected Actions)
    btn:RegisterForClicks("AnyUp")
    btn:SetAttribute("type1", "macro") -- Left Click: Atacar
    btn:SetAttribute("macrotext1", "/petattack")
    
    btn:SetAttribute("type2", "macro") -- Right Click: Seguir
    btn:SetAttribute("macrotext2", "/petfollow")
    
    btn:SetAttribute("type3", "macro") -- Middle Click: Quedarse (Stay)
    btn:SetAttribute("macrotext3", "/petstay")

    -- Scripts visuales & Tooltip táctico
    btn:SetScript("OnEnter", function(self)
        GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
        if UnitExists("pet") then
            GameTooltip:SetUnit("pet")
            GameTooltip:AddLine(" ")
            GameTooltip:AddLine("|cFF00FF00Click Izquierdo:|r Atacar Objetivo", 1, 1, 1)
            GameTooltip:AddLine("|cFF00FFFFClick Derecho:|r Seguir al Amo", 1, 1, 1)
            GameTooltip:AddLine("|cFFFFD700Click Central:|r Quedarse en Posición (Stay)", 1, 1, 1)
            
            local _, class = UnitClass("player")
            if class == "HUNTER" and GetPetHappiness then
                local happiness = GetPetHappiness()
                local status = (happiness == 3 and "|cFF00FF00Feliz (+25% daño)|r") or
                               (happiness == 2 and "|cFFFFD700Contenta (100% daño)|r") or
                               "|cFFFF0000Infeliz (-25% daño - ¡Aliméntala!)|r"
                GameTooltip:AddLine("Felicidad: " .. status)
            end
        else
            GameTooltip:AddLine("Sin Mascota Invocada", 0.8, 0.8, 0.8)
        end
        GameTooltip:Show()
    end)
    btn:SetScript("OnLeave", function() GameTooltip:Hide() end)
    
    -- OnUpdate throttled a 0.25s para monitorizar salud sin impacto en FPS
    local throttleTimer = 0
    btn:SetScript("OnUpdate", function(self, elapsed)
        throttleTimer = throttleTimer + (elapsed or 0)
        if throttleTimer >= 0.25 then
            throttleTimer = 0
            PM:UpdateHealth()
        end
    end)
    
    self.Button = btn
    self:UpdateVisibility()
end

function PM:RegisterEvents()
    local f = CreateFrame("Frame")
    f:RegisterEvent("UNIT_PET")
    f:RegisterEvent("PLAYER_ENTERING_WORLD")
    f:RegisterEvent("ZONE_CHANGED_NEW_AREA")
    f:RegisterEvent("PET_BAR_UPDATE")
    f:RegisterEvent("PLAYER_REGEN_DISABLED")
    f:RegisterEvent("UNIT_HEALTH")
    
    f:SetScript("OnEvent", function(self, event, ...)
        if event == "UNIT_PET" or event == "PLAYER_ENTERING_WORLD" then
            PM:UpdateVisibility()
            PM:UpdateIcon()
            PM:CheckPetTauntInGroup()
            PM:CheckHunterHappiness()
        elseif event == "ZONE_CHANGED_NEW_AREA" or event == "PET_BAR_UPDATE" then
            PM:CheckPetTauntInGroup()
        elseif event == "PLAYER_REGEN_DISABLED" then
            PM:Speak("COMBAT")
            PM:CheckMissingPetInCombat()
        elseif event == "UNIT_HEALTH" then
            local unit = ...
            if unit == "pet" then
                local hp = UnitHealth("pet") or 0
                local max = UnitHealthMax("pet") or 1
                if max > 0 and (hp / max) < 0.2 then
                    PM:Speak("LOW_HP")
                end
            elseif unit == "player" then
                PM:CheckDeathPactAlert()
            end
        end
    end)

    if S.CLEU and S.CLEU.Register then
        S.CLEU:Register("PARTY_KILL", function(timestamp, event, sourceGUID)
            if sourceGUID == UnitGUID("pet") then
                PM:Speak("KILL")
            end
        end)
    else
        f:RegisterEvent("COMBAT_LOG_EVENT_UNFILTERED")
        f:HookScript("OnEvent", function(self, event, ...)
            if event == "COMBAT_LOG_EVENT_UNFILTERED" then
                local _, subEvent, sourceGUID = ...
                if subEvent == "PARTY_KILL" and sourceGUID == UnitGUID("pet") then
                    PM:Speak("KILL")
                end
            end
        end)
    end
end

-- ===========================================================================
-- REGLAS DE ESCENARIOS Y MASCOTAS (TAUNT, HUNTER HAPPINESS, DEATH PACT)
-- ===========================================================================

function PM:CheckPetTauntInGroup()
    if not UnitExists("pet") then return end
    
    -- Solo aplica si estamos dentro de mazmorra de 5 o banda
    local inInstance, instanceType = IsInInstance()
    if not inInstance or (instanceType ~= "party" and instanceType ~= "raid") then
        return
    end

    -- Throttle para no spammear alertas
    if self.lastTauntWarn and (GetTime() - self.lastTauntWarn < 30) then
        return
    end

    for i = 1, 10 do
        local name, subtext, texture, isToken, isActive, autoCastAllowed, autoCastEnabled = GetPetActionInfo(i)
        if name and autoCastAllowed and autoCastEnabled then
            local lower = string.lower(name)
            -- Bramido (Hunter) o Atormentar (Warlock Voidwalker)
            if lower == "bramido" or lower == "growl" or lower == "atormentar" or lower == "torment" then
                self.lastTauntWarn = GetTime()
                if S.Alerts and S.Alerts.Show then
                    S.Alerts:Show("¡DESACTIVA EL TAUNT DE TU MASCOTA! (" .. name .. ")", "WARNING")
                end
                if S.Print then
                    S:Print("|cFFFF0000[Alerta Mascota]|r ¡Peligro de wipe! Tu mascota tiene |cFFFFD700" .. name .. "|r en autocasteo. ¡Desactívalo con clic derecho para no robarle agro al Tanque!")
                end
                PlaySound("RaidWarning")
                break
            end
        end
    end
end

function PM:CheckHunterHappiness()
    local _, class = UnitClass("player")
    if class ~= "HUNTER" or not UnitExists("pet") then return end
    
    if GetPetHappiness then
        local happiness = GetPetHappiness()
        if happiness == 1 then
            if not self.lastHungerWarn or (GetTime() - self.lastHungerWarn > 60) then
                self.lastHungerWarn = GetTime()
                if S.Alerts and S.Alerts.Show then
                    S.Alerts:Show("¡Mascota Infeliz! Aliméntala (-25% daño)", "WARNING")
                end
                if S.Print then
                    S:Print("|cFFFF9900[Alerta Mascota]|r Tu mascota está descontenta/hambrienta. Su daño se reduce 25%. ¡Usa Alimentar Mascota!")
                end
            end
        end
    end
end

function PM:CheckMissingPetInCombat()
    local _, class = UnitClass("player")
    if class == "HUNTER" or class == "WARLOCK" then
        if not UnitExists("pet") or UnitIsDead("pet") then
            if S.Alerts and S.Alerts.Show then
                S.Alerts:Show("¡Combate iniciado sin Mascota!", "WARNING")
            end
            if S.Print then
                S:Print("|cFFFF0000[Alerta Mascota]|r ¡Entraste en combate sin mascota o tu mascota está muerta!")
            end
        end
    end
end

function PM:CheckDeathPactAlert()
    local _, class = UnitClass("player")
    if class == "DEATHKNIGHT" and UnitExists("pet") and not UnitIsDead("pet") then
        local hp = UnitHealth("player") or 0
        local max = UnitHealthMax("player") or 1
        if max > 0 and (hp / max) < 0.25 then
            if not self.lastPactWarn or (GetTime() - self.lastPactWarn > 15) then
                self.lastPactWarn = GetTime()
                if S.Alerts and S.Alerts.Show then
                    S.Alerts:Show("¡Pacto de la Muerte Disponible! (Cura 40%)", "CRITICAL")
                end
                if S.Print then
                    S:Print("|cFF00FF00[Pacto de la Muerte]|r ¡Vida crítica! Sacrifica a tu esbirro con Pacto de la Muerte para sanarte un 40% de vida.")
                end
            end
        end
    end
end

-- ===========================================================================
-- VISIBILIDAD Y CONTROL VISUAL
-- ===========================================================================

function PM:UpdateVisibility()
    if not self.Button then return end
    
    local raBtn = _G["JainaRaidAssistBtn"]
    
    if UnitExists("pet") then
        self.Button:Show()
        self:UpdateIcon()
        
        if raBtn then
            raBtn:ClearAllPoints()
            raBtn:SetPoint("TOP", self.Button, "BOTTOM", 0, -5)
        end
    else
        self.Button:Hide()
        
        if raBtn and S.Sphere then
            raBtn:ClearAllPoints()
            raBtn:SetPoint("TOP", S.Sphere, "BOTTOM", 0, -5)
        end
    end
end

function PM:UpdateIcon()
    if not self.Button then return end
    
    local icon = "Interface\\Icons\\Ability_Hunter_BeastCall"
    local _, class = UnitClass("player")
    
    if class == "WARLOCK" then
        local creatureFamily = UnitCreatureFamily("pet")
        if creatureFamily == "Imp" or creatureFamily == "Diablillo" then
            icon = "Interface\\Icons\\Spell_Shadow_SummonImp"
        elseif creatureFamily == "Voidwalker" or creatureFamily == "Abisario" then
            icon = "Interface\\Icons\\Spell_Shadow_SummonVoidWalker"
        elseif creatureFamily == "Succubus" or creatureFamily == "Súcubo" then
            icon = "Interface\\Icons\\Spell_Shadow_SummonSuccubus"
        elseif creatureFamily == "Felhunter" or creatureFamily == "Manáfago" then
            icon = "Interface\\Icons\\Spell_Shadow_SummonFelHunter"
        elseif creatureFamily == "Felguard" or creatureFamily == "Guardia Apocalíptico" then
            icon = "Interface\\Icons\\Spell_Shadow_SummonFelGuard"
        else
            icon = "Interface\\Icons\\Spell_Nature_RemoveCurse"
        end
    elseif class == "HUNTER" then
         icon = GetSpellTexture("Call Pet") or "Interface\\Icons\\Ability_Hunter_BeastCall"
    elseif class == "MAGE" then
         icon = "Interface\\Icons\\Spell_Frost_SummonWaterElemental"
    elseif class == "DEATHKNIGHT" then
         icon = "Interface\\Icons\\Spell_DeathKnight_GhoulFrenzy"
    end
    
    self.Button.icon:SetTexture(icon)
end

function PM:UpdateHealth()
    if not self.Button or not UnitExists("pet") then return end
    
    if not self:GetOption("showHealth") then
        self.Button.border:Hide()
        return
    end
    
    local hp = UnitHealth("pet") or 0
    local max = UnitHealthMax("pet") or 0
    if max <= 0 then
        if self.Button and self.Button.border then
            self.Button.border:Hide()
        end
        return
    end
    local pct = (hp / max) * 100
    local threshold = self:GetOption("healthThreshold") or 60
    
    if pct < 30 then
        self.Button.border:SetVertexColor(1, 0, 0) -- Rojo Crítico
        self.Button.border:Show()
    elseif pct < threshold then
        self.Button.border:SetVertexColor(1, 1, 0) -- Amarillo Warning
        self.Button.border:Show()
    else
        self.Button.border:Hide()
    end
end

-- ===========================================================================
-- PET SPEECH (Flavor)
-- ===========================================================================
PM.Speeches = {
    ["DEFAULT"] = {
        COMBAT = {"¡A por ellos!", "¡Muere!", "¡Ataque!"},
        LOW_HP = {"¡Ayuda!", "¡Me muero!", "¡Cúrame!"},
        KILL = {"¡Muerto!", "¡Jaja!", "¡Uno menos!"}
    },
    ["IMP"] = {
        COMBAT = {"¿Podemos quemarlo ya?", "¡Fuego, fuego!", "¡Esto me gusta!", "¡Sí, amo!"},
        LOW_HP = {"¡Oye, que me pegan!", "¡Ayuda, inútil!", "¡No quiero morir!", "¡Cúrame o no disparo!"},
        KILL = {"¡Quemado!", "¡Jajaja, mira como arde!", "¡Demasiado fácil!", "¡Siguiente!"}
    },
    ["VOIDWALKER"] = {
        COMBAT = {"Enviadlos al vacío...", "Tu orden es mi voluntad...", "No me gusta este lugar...", "Protejo..."},
        LOW_HP = {"Me desvanezco...", "La oscuridad me llama...", "No aguanto mucho más...", "¡Socoorro...!"},
        KILL = {"Uno más al vacío...", "Consumido...", "Silencio...", "Adiós..."}
    },
    ["SUCCUBUS"] = {
        COMBAT = {"¿Quién quiere un beso?", "¡No toques las mercancías!", "¡Ven aquí, grandullón!", "¡Dolor y placer!"},
        LOW_HP = {"¡Me estás estropeando el maquillaje!", "¡Ayuda a la dama!", "¡No dejes que me peguen!", "¡Ahhh!"},
        KILL = {"Mmm, delicioso...", "Pobrecito...", "¿Ya terminaste?", "Qué aburrido..."}
    },
    ["FELHUNTER"] = {
        COMBAT = {"¡Magia...!", "¡Comer...!", "*Gruñido*", "¡Sniff sniff!"},
        LOW_HP = {"*Gemido*", "¡Dolor...!", "¡Amo... ayuda!", "*Aullido*"},
        KILL = {"*Masticar*", "¡Rico!", "¡Más magia!", "*Eructo*"}
    },
    ["FELGUARD"] = {
        COMBAT = {"¡POR LA LEGIÓN!", "¡MORIRÁS!", "¡MI HACHA TIENE SED!", "¡DESTRUCCIÓN!"},
        LOW_HP = {"¡ESTAS HERIDAS NO SON NADA!", "¡MÉDICO!", "¡NO CAERÉ!", "¡AAGHH!"},
        KILL = {"¡APLASTADO!", "¡VICTORIA!", "¡DÉBIL!", "¡OTRO MENOS!"}
    }
}

function PM:Speak(trigger)
    if not self:GetOption("enableSpeech") then return end
    if not S.db or not S.db.profile or not S.db.profile.ShowSpeech then return end
    if not UnitExists("pet") then return end
    
    if math.random() > 0.2 then return end
    
    local family = UnitCreatureFamily("pet")
    local type = "DEFAULT"
    
    if family == "Imp" or family == "Diablillo" then type = "IMP"
    elseif family == "Voidwalker" or family == "Abisario" then type = "VOIDWALKER"
    elseif family == "Succubus" or family == "Súcubo" then type = "SUCCUBUS"
    elseif family == "Felhunter" or family == "Manáfago" then type = "FELHUNTER"
    elseif family == "Felguard" or family == "Guardia Apocalíptico" then type = "FELGUARD"
    end
    
    local list = self.Speeches[type] and self.Speeches[type][trigger] or self.Speeches["DEFAULT"][trigger]
    if list then
        local msg = list[math.random(#list)]
        SendChatMessage(msg, "SAY")
    end
end

-- ===========================================================================
-- REGISTRO EN MODULECONFIG
-- ===========================================================================
if S.ModuleConfig then
    S.ModuleConfig:RegisterModule("PetManager", {
        name = "Gestor Táctico de Mascotas",
        description = "Control inteligente, alertas de Taunt indebido en mazmorras, felicidad y sacrificio para Hunter, Warlock, DK y Mage.",
        category = "class",
        icon = "Interface\\Icons\\Ability_Hunter_BeastCall",
        options = {
            {
                key = "enabled",
                type = "checkbox",
                label = "Habilitar PetManager",
                tooltip = "Activa el botón orbital y el sistema de alertas de mascota",
                default = true
            },
            {
                key = "showHealth",
                type = "checkbox",
                label = "Monitor de Salud",
                tooltip = "Borde luminoso con alerta de color según la vida de la mascota",
                default = true
            },
            {
                key = "enableSpeech",
                type = "checkbox",
                label = "Charla de Mascota",
                tooltip = "Comentarios contextuales en combate según la familia del demonio o bestia",
                default = true
            },
            {
                key = "healthThreshold",
                type = "slider",
                label = "Umbral de Salud Baja (%)",
                tooltip = "Porcentaje de vida para alerta amarilla",
                min = 10,
                max = 50,
                step = 5,
                default = 30
            }
        }
    })
end
