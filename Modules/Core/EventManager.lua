--[[
    SEQUITO - Event Manager
    Handles game events to trigger speech and visuals.
]]--

local addonName, S = ...
S.Events = {}

-- Helper para obtener configuración
function S.Events:GetOption(key)
    if S.ModuleConfig then
        return S.ModuleConfig:GetValue("EventManager", key)
    end
    return true
end

local f = CreateFrame("Frame")
f:RegisterEvent("UNIT_SPELLCAST_SUCCEEDED")
f:RegisterEvent("UNIT_AURA") -- WotLK: replaces PLAYER_MOUNT_DISPLAY_CHANGED (Legion 7.2.5+)
f:RegisterEvent("COMBAT_LOG_EVENT_UNFILTERED")

local wasMounted = false -- Track mount state transitions

f:SetScript("OnEvent", function(self, event, ...)
    if event == "UNIT_SPELLCAST_SUCCEEDED" then
        -- WotLK 3.3.5a: args are (unit, spellName, rank, lineID) -- NO spellID!
        local unit, spellName = ...
        if unit == "player" and spellName then
            S.Events:OnSpellCast(spellName)
        end
    elseif event == "UNIT_AURA" then
        local unit = ...
        if unit == "player" then
            local mounted = IsMounted()
            if mounted and not wasMounted then
                -- Just mounted! 30% chance to speak
                if math.random() < 0.3 then
                    S:Speak("Mount")
                end
            end
            wasMounted = mounted
        end
    elseif event == "COMBAT_LOG_EVENT_UNFILTERED" then
        local timestamp, subEvent, sourceGUID, sourceName, sourceFlags, destGUID, destName, destFlags, spellId, spellName = ...
        
        -- ============================================
        -- PROC ALERTS (Aura applied to player)
        -- ============================================
        if subEvent == "SPELL_AURA_APPLIED" and destGUID == UnitGUID("player") then
            -- === WARLOCK ===
            if spellName == "Shadow Trance" or spellName == "Trance de las Sombras" or spellId == 17941 then
                PlaySound("RaidWarning")
                RaidNotice_AddMessage(RaidWarningFrame, "¡OCASO! (SHADOW TRANCE)", ChatTypeInfo["RAID_WARNING"])
                S:Speak("Nightfall")
            elseif spellName == "Backlash" or spellName == "Contragolpe" or spellId == 34936 then
                PlaySound("RaidWarning")
                RaidNotice_AddMessage(RaidWarningFrame, "¡CONTRAGOLPE! (BACKLASH)", ChatTypeInfo["RAID_WARNING"])
                S:Speak("Backlash")
            elseif spellName == "Molten Core" or spellName == "Núcleo de Magma" or spellId == 71165 then
                PlaySound("RaidWarning")
                RaidNotice_AddMessage(RaidWarningFrame, "¡NÚCLEO DE MAGMA!", ChatTypeInfo["RAID_WARNING"])
            elseif spellName == "Decimation" or spellName == "Exterminación" or spellId == 63167 then
                PlaySound("RaidWarning")
                RaidNotice_AddMessage(RaidWarningFrame, "¡EXTERMINACIÓN!", ChatTypeInfo["RAID_WARNING"])
            end
        end
        
        -- ============================================
        -- CC / ABILITY SPEECH (Player casts on target)
        -- ============================================
        if sourceGUID == UnitGUID("player") and subEvent == "SPELL_CAST_SUCCESS" then
            -- === WARLOCK ===
            if spellName == "Banish" or spellName == "Desterrar" then
                S:Speak("Banish", destName)
            elseif spellName == "Enslave Demon" or spellName == "Esclavizar demonio" then
                S:Speak("Enslave", destName)
            elseif spellName == "Fear" or spellName == "Miedo" then
                S:Speak("Fear", destName)
            -- === DEATH KNIGHT ===
            elseif spellName == "Death Grip" or spellName == "Garra de la muerte" then
                S:Speak("DeathGrip", destName)
            elseif spellName == "Raise Dead" or spellName == "Alzar a los muertos" then
                S:Speak("RaiseDead")
            elseif spellName == "Army of the Dead" or spellName == "Ejército de los muertos" then
                S:Speak("ArmyOfDead")
            elseif spellName == "Anti-Magic Shell" or spellName == "Caparazón antimagia" then
                S:Speak("AntiMagic")
            -- === MAGE ===
            elseif spellName == "Polymorph" or spellName == "Polimorfia"
                or spellName == "Polymorph: Pig" or spellName == "Polymorph: Turtle"
                or spellName == "Polymorph: Cat" or spellName == "Polymorph: Rabbit" then
                S:Speak("Polymorph", destName)
            elseif spellName == "Ice Block" or spellName == "Bloque de hielo" then
                S:Speak("IceBlock")
            -- === ROGUE ===
            elseif spellName == "Tricks of the Trade" or spellName == "Trucos del oficio" then
                S:Speak("TricksOfTrade", destName)
            elseif spellName == "Vanish" or spellName == "Esfumarse" then
                S:Speak("Vanish")
            elseif spellName == "Sap" or spellName == "Golpe incapacitante" then
                S:Speak("Sap", destName)
            -- === WARRIOR ===
            elseif spellName == "Intervene" or spellName == "Interceder" then
                S:Speak("Intervene", destName)
            elseif spellName == "Taunt" or spellName == "Provocar" then
                if math.random() < 0.3 then S:Speak("Taunt") end -- 30% chance (too frequent otherwise)
            -- === PRIEST ===
            elseif spellName == "Mass Dispel" or spellName == "Disipación de masas" then
                S:Speak("MassDispel")
            elseif spellName == "Power Infusion" or spellName == "Infusión de poder" then
                S:Speak("PowerInfusion", destName)
            elseif spellName == "Guardian Spirit" or spellName == "Espíritu guardián" then
                S:Speak("GuardianSpirit", destName)
            -- === HUNTER ===
            elseif spellName == "Misdirection" or spellName == "Dirección errónea" then
                S:Speak("Misdirection", destName)
            elseif spellName == "Feign Death" or spellName == "Hacerse el muerto" then
                S:Speak("FeignDeath")
            -- === SHAMAN ===
            elseif spellName == "Heroism" or spellName == "Heroísmo"
                or spellName == "Bloodlust" or spellName == "Ansia de sangre" then
                S:Speak("Heroism")
            end
        end
    end
end)

function S.Events:OnSpellCast(spellName)
    if not self:GetOption("enabled") then return end
    if not spellName then return end
    
    -- WotLK 3.3.5a: UNIT_SPELLCAST_SUCCEEDED has no spellID, use spell names
    
    -- === WARLOCK ===
    if spellName == "Ritual of Summoning" or spellName == "Ritual de invocación" then 
        S:Speak("Summon")
    elseif spellName:find("Piedra de la resurrección") or spellName:find("Soulstone Resurrection")
        or spellName:find("Piedra del alma") or spellName:find("Soulstone") then 
        S:Speak("Soulstone", UnitName("target"))
    
    -- === ALL CLASSES: Resurrection ===
    elseif spellName == "Rebirth" or spellName == "Renacer"
        or spellName == "Redemption" or spellName == "Redención"
        or spellName == "Resurrection" or spellName == "Resurrección"
        or spellName == "Ancestral Spirit" or spellName == "Espíritu Ancestral"
        or spellName == "Raise Ally" or spellName == "Revivir aliado" then 
        S:Speak("Resurrect", UnitName("target"))
    
    -- === PALADIN ===
    elseif spellName == "Lay on Hands" or spellName == "Imposición de manos" then
        S:Speak("LayOnHands", UnitName("target"))
    elseif spellName == "Divine Shield" or spellName == "Escudo divino" then
        S:Speak("DivineShield")
    elseif spellName == "Hand of Protection" or spellName == "Mano de protección" then
        S:Speak("HandOfProtection", UnitName("target"))
    
    -- === DRUID ===
    elseif spellName == "Innervate" or spellName == "Estimular" then
        S:Speak("Innervate", UnitName("target"))
    elseif spellName == "Tranquility" or spellName == "Tranquilidad" then
        S:Speak("Tranquility")
    
    -- === SHAMAN ===
    elseif spellName == "Reincarnation" or spellName == "Reencarnación" then
        S:Speak("Ankh")
    end
end

function S:Speak(category, target)

    if not S.db.profile.ShowSpeech then return end -- Global toggle check
    
    local msg = S:GetRandomSpeech(category)
    if msg then
        if target then
             msg = msg:gsub("<target>", target)
        else
             msg = msg:gsub("<target>", "alguien")
        end
        
        -- Replace <pet> (Warlock specific flavor)
        if UnitExists("pet") then
            msg = msg:gsub("<pet>", UnitName("pet"))
        else
            msg = msg:gsub("<pet>", "esbirro")
        end
        
        -- Send to Chat
        local chatType = S.Events:GetOption("chatChannel")
        if type(chatType) ~= "string" or chatType == "" then
            chatType = "SAY"
        end
        
        -- Validate channel based on group status
        local inRaid = GetNumRaidMembers() > 0
        local inParty = GetNumPartyMembers() > 0
        local instanceType = select(2, IsInInstance())
        local isPvP = (instanceType == "pvp" or instanceType == "arena")

        if isPvP then
            if chatType == "SAY" or chatType == "RAID" or chatType == "PARTY" then
                chatType = "BATTLEGROUND"
            end
        else
            if chatType == "RAID" and not inRaid then
                chatType = inParty and "PARTY" or "SAY"
            elseif chatType == "PARTY" and not inParty then
                chatType = "SAY"
            end
        end

        if #msg > 240 then msg = msg:sub(1, 237) .. "..." end
        SendChatMessage(msg, chatType)
    end
end

-- Registrar en ModuleConfig
if S.ModuleConfig then
    S.ModuleConfig:RegisterModule("EventManager", {
        name = "Event Manager",
        description = "Maneja eventos del juego para activar diálogos y efectos visuales automáticamente.",
        category = "utility",
        icon = "Interface\\Icons\\Spell_Holy_PrayerOfHealing",
        options = {
            {
                key = "enabled",
                type = "checkbox",
                label = "Habilitar Event Manager",
                tooltip = "Activa el sistema de eventos automáticos",
                default = true
            },
            {
                key = "chatChannel",
                type = "dropdown",
                label = "Canal de Anuncio",
                tooltip = "Canal donde se anuncian los eventos",
                options = {
                    {text = "Decir (SAY)", value = "SAY"},
                    {text = "Grupo (PARTY)", value = "PARTY"},
                    {text = "Banda (RAID)", value = "RAID"},
                },
                default = "SAY"
            }
        }
    })
end
