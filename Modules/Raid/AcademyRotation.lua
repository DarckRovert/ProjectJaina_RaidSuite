--[[
    Jaina - Academy Rotation Advisor & HUD
    Sugiere la rotación óptima basada en clase/spec con HUD visual en tiempo real.
    Parte del sistema "Academy Mode" (v9.0)
]]

local addonName, S = ...
S.AcademyRotation = {}
local AR = S.AcademyRotation

-- Catálogo completo de rotaciones para las 10 clases en WoW 3.3.5a
local ROTATIONS = {
    ["WARLOCK"] = {
        [1] = {
            name = "Aflicción",
            background = "WarlockCurses",
            spells = {"Poseer", "Aflicción inestable", "Corrupción", "Maldición de agonía", "Descarga de las Sombras"},
            fallback = {"Haunt", "Unstable Affliction", "Corruption", "Curse of Agony", "Shadow Bolt"}
        },
        [2] = {
            name = "Demonología",
            background = "WarlockSummoning",
            spells = {"Inmolar", "Corrupción", "Metamorfosis", "Fuego de alma", "Incinerar"},
            fallback = {"Immolate", "Corruption", "Metamorphosis", "Soul Fire", "Incinerate"}
        },
        [3] = {
            name = "Destrucción",
            background = "WarlockDestruction",
            spells = {"Inmolar", "Conflagrar", "Descarga de Caos", "Incinerar", "Fuego de alma"},
            fallback = {"Immolate", "Conflagrate", "Chaos Bolt", "Incinerate", "Soul Fire"}
        },
    },
    ["MAGE"] = {
        [1] = {
            name = "Arcano",
            spells = {"Explosión Arcana", "Misiles Arcanos", "Tromba Arcana", "Evocación"},
            fallback = {"Arcane Blast", "Arcane Missiles", "Arcane Barrage", "Evocation"}
        },
        [2] = {
            name = "Fuego",
            spells = {"Bomba viva", "Agostar", "Bola de Fuego", "Piroexplosión", "Combustión"},
            fallback = {"Living Bomb", "Scorch", "Fireball", "Pyroblast", "Combustion"}
        },
        [3] = {
            name = "Escarcha",
            spells = {"Descarga de Escarcha", "Congelación profunda", "Descarga de Pirofrío", "Lanza de hielo"},
            fallback = {"Frostbolt", "Deep Freeze", "Frostfire Bolt", "Ice Lance"}
        },
    },
    ["DEATHKNIGHT"] = {
        [1] = {
            name = "Sangre",
            spells = {"Toque helado", "Golpe de peste", "Golpe en el corazón", "Golpe mortal", "Espiral de la muerte"},
            fallback = {"Icy Touch", "Plague Strike", "Heart Strike", "Death Strike", "Death Coil"}
        },
        [2] = {
            name = "Escarcha",
            spells = {"Toque helado", "Golpe de peste", "Asolar", "Golpe sangriento", "Golpe de Escarcha", "Explosión aullante"},
            fallback = {"Icy Touch", "Plague Strike", "Obliterate", "Blood Strike", "Frost Strike", "Howling Blast"}
        },
        [3] = {
            name = "Profano",
            spells = {"Toque helado", "Golpe de peste", "Golpe de la Plaga", "Golpe sangriento", "Espiral de la muerte"},
            fallback = {"Icy Touch", "Plague Strike", "Scourge Strike", "Blood Strike", "Death Coil"}
        },
    },
    ["PRIEST"] = {
        [1] = {
            name = "Disciplina",
            spells = {"Palabra de poder: escudo", "Penitencia", "Rezo de alivio", "Sanación relámpago"},
            fallback = {"Power Word: Shield", "Penance", "Prayer of Mending", "Flash Heal"}
        },
        [2] = {
            name = "Sagrado",
            spells = {"Círculo de sanación", "Rezo de alivio", "Renovar", "Sanación relámpago", "Espíritu guardián"},
            fallback = {"Circle of Healing", "Prayer of Mending", "Renew", "Flash Heal", "Guardian Spirit"}
        },
        [3] = {
            name = "Sombras",
            spells = {"Toque vampírico", "Palabra de las Sombras: dolor", "Peste devoradora", "Explosión mental", "Tortura mental"},
            fallback = {"Vampiric Touch", "Shadow Word: Pain", "Devouring Plague", "Mind Blast", "Mind Flay"}
        },
    },
    ["WARRIOR"] = {
        [1] = {
            name = "Armas",
            spells = {"Desgarrar", "Golpe mortal", "Abrumar", "Ejecutar", "Torbellino de acero"},
            fallback = {"Rend", "Mortal Strike", "Overpower", "Execute", "Bladestorm"}
        },
        [2] = {
            name = "Furia",
            spells = {"Sed de sangre", "Torbellino", "Embate", "Ejecutar", "Golpe heroico"},
            fallback = {"Bloodthirst", "Whirlwind", "Slam", "Execute", "Heroic Strike"}
        },
        [3] = {
            name = "Protección",
            spells = {"Embate con escudo", "Revancha", "Ola de choque", "Hender armadura", "Bloqueo con escudo"},
            fallback = {"Shield Slam", "Revenge", "Shockwave", "Sunder Armor", "Shield Block"}
        },
    },
    ["PALADIN"] = {
        [1] = {
            name = "Sagrado",
            spells = {"Choque Sagrado", "Destello de Luz", "Luz Sagrada", "Señal de la Luz", "Escudo sacro"},
            fallback = {"Holy Shock", "Flash of Light", "Holy Light", "Beacon of Light", "Sacred Shield"}
        },
        [2] = {
            name = "Protección",
            spells = {"Escudo de rectitud", "Martillo de rectitud", "Consagración", "Escudo sagrado", "Sentencia de luz"},
            fallback = {"Shield of Righteousness", "Hammer of the Righteous", "Consecration", "Holy Shield", "Judgement of Light"}
        },
        [3] = {
            name = "Reprensión",
            spells = {"Sentencia de sabiduría", "Golpe de cruzado", "Tormenta divina", "Consagración", "Exorcismo"},
            fallback = {"Judgement of Wisdom", "Crusader Strike", "Divine Storm", "Consecration", "Exorcism"}
        },
    },
    ["HUNTER"] = {
        [1] = {
            name = "Bestias",
            spells = {"Marca del cazador", "Picadura de serpiente", "Cólera de las bestias", "Matar", "Disparo firme"},
            fallback = {"Hunter's Mark", "Serpent Sting", "Bestial Wrath", "Kill Command", "Steady Shot"}
        },
        [2] = {
            name = "Puntería",
            spells = {"Marca del cazador", "Picadura de serpiente", "Disparo de quimera", "Disparo de puntería", "Disparo mortal", "Disparo firme"},
            fallback = {"Hunter's Mark", "Serpent Sting", "Chimera Shot", "Aimed Shot", "Kill Shot", "Steady Shot"}
        },
        [3] = {
            name = "Supervivencia",
            spells = {"Marca del cazador", "Flecha negra", "Disparo explosivo", "Picadura de serpiente", "Disparo mortal", "Disparo firme"},
            fallback = {"Hunter's Mark", "Black Arrow", "Explosive Shot", "Serpent Sting", "Kill Shot", "Steady Shot"}
        },
    },
    ["ROGUE"] = {
        [1] = {
            name = "Asesinato",
            spells = {"Hambre de sangre", "Hacer picadillo", "Envenenar", "Mutilar"},
            fallback = {"Hunger For Blood", "Slice and Dice", "Envenom", "Mutilate"}
        },
        [2] = {
            name = "Combate",
            spells = {"Golpe siniestro", "Hacer picadillo", "Asesinato múltiple", "Subidón de adrenalina", "Eviscerar"},
            fallback = {"Sinister Strike", "Slice and Dice", "Killing Spree", "Adrenaline Rush", "Eviscerate"}
        },
        [3] = {
            name = "Sutileza",
            spells = {"Paso de las Sombras", "Emboscada", "Hacer picadillo", "Eviscerar", "Hemorragia"},
            fallback = {"Shadowstep", "Ambush", "Slice and Dice", "Eviscerate", "Hemorrhage"}
        },
    },
    ["SHAMAN"] = {
        [1] = {
            name = "Elemental",
            spells = {"Choque de llamas", "Ráfaga de lava", "Cadena de relámpagos", "Descarga de relámpagos", "Maestría elemental"},
            fallback = {"Flame Shock", "Lava Burst", "Chain Lightning", "Lightning Bolt", "Elemental Mastery"}
        },
        [2] = {
            name = "Mejora",
            spells = {"Escudo de relámpagos", "Espíritu feral", "Golpe de tormenta", "Latigazo de lava", "Choque de llamas"},
            fallback = {"Lightning Shield", "Feral Spirit", "Stormstrike", "Lava Lash", "Flame Shock"}
        },
        [3] = {
            name = "Restauración",
            spells = {"Escudo de tierra", "Mareas vivas", "Cadena de sanación", "Ola de sanación", "Tótem Marea de maná"},
            fallback = {"Earth Shield", "Riptide", "Chain Heal", "Healing Wave", "Mana Tide Totem"}
        },
    },
    ["DRUID"] = {
        [1] = {
            name = "Equilibrio",
            spells = {"Fuego feérico", "Fuego lunar", "Enjambre de insectos", "Lluvia de estrellas", "Cólera", "Fuego estelar"},
            fallback = {"Faerie Fire", "Moonfire", "Insect Swarm", "Starfall", "Wrath", "Starfire"}
        },
        [2] = {
            name = "Feral",
            spells = {"Fuego feérico (feral)", "Rugido salvaje", "Arañazo", "Destripar", "Triturar", "Mordedura feroz"},
            fallback = {"Faerie Fire (Feral)", "Savage Roar", "Rake", "Rip", "Shred", "Ferocious Bite"}
        },
        [3] = {
            name = "Restauración",
            spells = {"Flor de vida", "Rejuvenecimiento", "Recrecimiento", "Crecimiento salvaje", "Alivio presto"},
            fallback = {"Lifebloom", "Rejuvenation", "Regrowth", "Wild Growth", "Swiftmend"}
        },
    },
}

function AR:Initialize()
    self:CreateHUD()

    -- Slash commands
    SLASH_SEQUITOROT1 = "/srot"
    SLASH_SEQUITOROT2 = "/srotation"
    SlashCmdList["SEQUITOROT"] = function()
        AR:ToggleHUD()
    end

    -- Register Config
    if S.ModuleConfig then
        S.ModuleConfig:RegisterModule("AcademyRotation", {
            name = "Rotation Advisor",
            description = "HUD dinámico con la prioridad de rotación óptima para tu clase y especialización.",
            category = "general",
            icon = "Interface\\Icons\\Spell_Holy_SealOfRighteousness",
            options = {
                {key = "enabled", type = "checkbox", label = "Habilitar Rotation Advisor", default = true},
            }
        })
    end
end

function AR:GetPlayerSpec()
    -- Heurística basada en puntos invertidos de talentos sincronizada con Dual Spec
    local numTabs = GetNumTalentTabs()
    local maxPoints = -1
    local activeTab = 1
    local activeGroup = _G.GetActiveTalentGroup and _G.GetActiveTalentGroup() or 1

    for i = 1, numTabs do
        local _, _, pointsSpent = GetTalentTabInfo(i, false, false, activeGroup)
        if pointsSpent and pointsSpent > maxPoints then
            maxPoints = pointsSpent
            activeTab = i
        end
    end
    return activeTab
end

function AR:GetActiveRotationData()
    local _, class = UnitClass("player")
    local spec = self:GetPlayerSpec()

    local classTable = ROTATIONS[class]
    if not classTable then return nil end

    -- Búsqueda robusta por nombre o fondo del DBC
    local group = _G.GetActiveTalentGroup and _G.GetActiveTalentGroup() or 1
    local tabName, _, _, background = GetTalentTabInfo(spec, false, false, group)

    if tabName or background then
        for idx, rot in pairs(classTable) do
            if (tabName and (rot.name == tabName or (rot.fallback and tContains(rot.fallback, tabName))))
               or (background and rot.background and rot.background == background) then
                return rot
            end
        end
    end

    return classTable[spec] or classTable[1]
end

-- ============================================================================
-- ROTATION HUD
-- ============================================================================

function AR:CreateHUD()
    if self.HUDFrame then return self.HUDFrame end

    local f = CreateFrame("Frame", "JainaRotationHUD", UIParent)
    f:SetSize(270, 72)
    f:SetPoint("CENTER", UIParent, "CENTER", 0, -180)
    f:SetMovable(true)
    f:EnableMouse(true)
    f:RegisterForDrag("LeftButton")
    f:SetScript("OnDragStart", f.StartMoving)
    f:SetScript("OnDragStop", f.StopMovingOrSizing)
    f:SetFrameStrata("MEDIUM")

    if S.Theme and S.Theme.ApplyPanelBackdrop then
        S.Theme:ApplyPanelBackdrop(f)
    else
        f:SetBackdrop({
            bgFile = "Interface\\Buttons\\WHITE8x8",
            edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
            tile = false, edgeSize = 10,
            insets = { left = 2, right = 2, top = 2, bottom = 2 }
        })
        f:SetBackdropColor(0.06, 0.06, 0.1, 0.85)
        f:SetBackdropBorderColor(0.2, 0.5, 0.8, 0.7)
    end

    local title = f:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    title:SetPoint("TOPLEFT", 8, -6)
    title:SetText("|cFF00CCFFRotación Advisor|r")
    f.title = title

    local close = CreateFrame("Button", nil, f, "UIPanelCloseButton")
    close:SetSize(18, 18)
    close:SetPoint("TOPRIGHT", -2, -2)
    close:SetScript("OnClick", function() f:Hide() end)

    f.slots = {}
    local slotSize = 36
    local maxSlots = 5

    for i = 1, maxSlots do
        local slot = CreateFrame("Frame", nil, f)
        slot:SetSize(slotSize, slotSize)
        slot:SetPoint("BOTTOMLEFT", 10 + (i - 1) * (slotSize + 8), 8)

        local icon = slot:CreateTexture(nil, "ARTWORK")
        icon:SetAllPoints()
        icon:SetTexture("Interface\\Icons\\INV_Misc_QuestionMark")
        slot.icon = icon

        local border = slot:CreateTexture(nil, "OVERLAY")
        border:SetSize(slotSize + 8, slotSize + 8)
        border:SetPoint("CENTER", slot, "CENTER", 0, 0)
        border:SetTexture("Interface\\Buttons\\UI-ActionButton-Border")
        border:SetBlendMode("ADD")
        border:Hide()
        slot.border = border

        local cdText = slot:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
        cdText:SetPoint("CENTER", 0, 0)
        cdText:SetTextColor(1, 0.3, 0.3)
        slot.cdText = cdText

        f.slots[i] = slot
    end

    -- Throttle Update loop (0.2s)
    f.timer = 0
    f:SetScript("OnUpdate", function(self, elapsed)
        self.timer = self.timer + elapsed
        if self.timer >= 0.2 then
            AR:UpdateHUD()
            self.timer = 0
        end
    end)

    self.HUDFrame = f
    f:Hide()
    return f
end

-- ============================================================================
-- PROCS DE COMBATE REACTIVOS (WoW 3.3.5a)
-- ============================================================================
local COMBAT_PROCS = {
    -- Mage
    ["Buena racha"] = "Piroexplosión",
    ["Hot Streak"] = "Pyroblast",
    ["Tromba de proyectiles"] = "Misiles Arcanos",
    ["Missile Barrage"] = "Arcane Missiles",
    ["Dedos de Escarcha"] = "Lanza de hielo",
    ["Fingers of Frost"] = "Ice Lance",
    
    -- Paladin
    ["El arte de la guerra"] = "Exorcismo",
    ["The Art of War"] = "Exorcism",
    
    -- Warrior
    ["Oleada de sangre"] = "Embate",
    ["Bloodsurge"] = "Slam",
    ["Muerte súbita"] = "Ejecutar",
    ["Sudden Death"] = "Execute",
    
    -- Death Knight
    ["Escarcha blanca"] = "Explosión aullante",
    ["Rime"] = "Howling Blast",
    ["Máquina de matar"] = "Golpe de Escarcha",
    ["Killing Machine"] = "Frost Strike",
    
    -- Warlock
    ["Diezmar"] = "Fuego de alma",
    ["Decimation"] = "Soul Fire",
    ["Fricción de lava"] = "Incinerar",
    ["Molten Core"] = "Incinerate",
    
    -- Druid
    ["Eclipse (Lunar)"] = "Fuego estelar",
    ["Eclipse (Solar)"] = "Cólera",
}

function AR:GetActiveProcSpell()
    for i = 1, 40 do
        local name = UnitBuff("player", i)
        if not name then break end
        local procSpell = COMBAT_PROCS[name]
        if procSpell then
            return procSpell, name
        end
    end
    return nil, nil
end

function AR:ResolveSpellTexture(spellName, fallbackName)
    local name, _, icon = GetSpellInfo(spellName)
    if not icon and fallbackName then
        name, _, icon = GetSpellInfo(fallbackName)
    end
    return icon, name or spellName
end

function AR:UpdateHUD()
    if not self.HUDFrame or not self.HUDFrame:IsShown() then return end
    local rotData = self:GetActiveRotationData()
    if not rotData then return end

    local f = self.HUDFrame
    local activeProcSpell, procAuraName = self:GetActiveProcSpell()
    
    if activeProcSpell then
        f.title:SetText(string.format("|cFF00CCFFRotación|r - |cFF00FF00[PROC: %s]|r", procAuraName or activeProcSpell))
    else
        f.title:SetText(string.format("|cFF00CCFFRotación Advisor|r - |cFFFFD700%s|r", rotData.name or "Spec"))
    end

    local firstAvailableFound = false

    for i = 1, #f.slots do
        local slot = f.slots[i]
        local spellName = rotData.spells[i]
        local fallbackName = rotData.fallback and rotData.fallback[i]

        if spellName then
            slot:Show()
            local icon, resolvedName = self:ResolveSpellTexture(spellName, fallbackName)
            if icon then
                slot.icon:SetTexture(icon)
            else
                slot.icon:SetTexture("Interface\\Icons\\INV_Misc_QuestionMark")
            end

            -- Cooldown Check
            local start, duration, enabled = GetSpellCooldown(resolvedName or spellName)
            local onCD = false
            if start and duration and duration > 1.5 then
                local remaining = math.ceil((start + duration) - GetTime())
                if remaining > 0 then
                    onCD = true
                    slot.icon:SetDesaturated(true)
                    slot.cdText:SetText(tostring(remaining) .. "s")
                    slot.border:Hide()
                end
            end

            if not onCD then
                slot.icon:SetDesaturated(false)
                slot.cdText:SetText("")
                
                -- Verificar si este hechizo coincide con un PROC activo de combate
                local isProcMatch = activeProcSpell and (
                    spellName:lower():find(activeProcSpell:lower()) or 
                    (fallbackName and fallbackName:lower():find(activeProcSpell:lower()))
                )

                if isProcMatch then
                    -- Brillo verde esmeralda para destacar PROC instantáneo
                    slot.border:Show()
                    slot.border:SetVertexColor(0.2, 1.0, 0.4, 1.0)
                    slot.cdText:SetText("|cFF00FF00PROC!|r")
                elseif not firstAvailableFound then
                    -- Destacar el siguiente hechizo disponible en la lista de prioridad estándar
                    slot.border:Show()
                    slot.border:SetVertexColor(1, 0.9, 0.2, 0.9)
                    firstAvailableFound = true
                else
                    slot.border:Hide()
                end
            end
        else
            slot:Hide()
        end
    end
end

function AR:ToggleHUD()
    local f = self:CreateHUD()
    if f:IsShown() then
        f:Hide()
    else
        self:UpdateHUD()
        f:Show()
    end
end

function AR:ShowRotation()
    local rotData = self:GetActiveRotationData()
    if not rotData then
        if S.Print then
            S:Print("|cFFFF9900No hay rotación definida para tu clase.|r")
        end
        return
    end

    local list = table.concat(rotData.spells, " > ")
    if S.Print then
        S:Print(string.format("|cFFFFD700[Rotación %s]|r: |cFFFFFFFF%s|r", rotData.name, list))
    else
        print(string.format("|cFFFFD700[Rotación %s]|r: |cFFFFFFFF%s|r", rotData.name, list))
    end
    self:ToggleHUD()
end
