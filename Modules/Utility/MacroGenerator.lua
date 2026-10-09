--[[
    SEQUITO - Macro Generator (Necrosis Replication Edition)
    Replica EXACTAMENTE la lógica de macros de Necrosis (Smart Pet, Smart Heal, Smart CC).
    INCLUDES: Rotaciones Inteligentes (Portado de NecrosisBrain.lua + NecrosisUniversal.lua)
    World of Warcraft 3.3.5a
]]--

local addonName, S = ...
S.MacroGen = {}

-- ===========================================================================
-- 1. HELPERS: RACIALS & SPELLS
-- ===========================================================================

S.MacroGen.Races = {
    ["Human"]     = { ID = 59752 }, 
    ["Dwarf"]     = { ID = 20594 }, 
    ["NightElf"]  = { ID = 58984 }, 
    ["Gnome"]     = { ID = 20589 }, 
    ["Draenei"]   = { ID = 59542 }, 
    ["Orc"]       = { ID = 20572 }, 
    ["Scourge"]   = { ID = 7744 },  
    ["Tauren"]    = { ID = 20549 }, 
    ["Troll"]     = { ID = 26297 }, 
    ["BloodElf"]  = { ID = 28730 }, 
}

function S.MacroGen:CreateMacro(name, icon, body, perChar)
    if not name or not body then return nil end
    if #body > 255 then
        body = body:sub(1, 255)
    end
    local isPerChar = perChar or 1
    local macroID = GetMacroIndexByName(name)
    if macroID > 0 then
        EditMacro(macroID, name, icon or 1, body)
        return macroID
    else
        local numAccount, numChar = GetNumMacros()
        if (isPerChar == 1 and numChar < 18) or (isPerChar ~= 1 and numAccount < 36) then
            return CreateMacro(name, icon or 1, body, isPerChar)
        else
            print("|cFFFF0000Jaina Error:|r Espacio de macros lleno. No se pudo crear: " .. tostring(name))
            return nil
        end
    end
end

function S.MacroGen:GetIfKnown(id)
    if not id then return nil end
    local name = GetSpellInfo(id)
    if name and IsSpellKnown(id) then
        return name
    end
    return nil
end

function S.MacroGen:GetSmartSpell(id, defaultName)
    local name = GetSpellInfo(id)
    if name and IsSpellKnown(id) then
        return name
    end
    -- Fallback for specific hardcoded IDs that might be replacers
    return defaultName or name 
end

function S.MacroGen:GetSmartItem(id, defaultName)
    local name = GetItemInfo(id)
    if name then return name end
    return defaultName
end

function S.MacroGen:GetRacialSpell()
    local _, raceEn = UnitRace("player")
    local data = self.Races[raceEn]
    if data then
        return self:GetSmartSpell(data.ID)
    end
    return nil
end

-- ===========================================================================
-- 2. UTILITY GENERATORS (Smart Macros)
-- ===========================================================================

--- 1. Smart Interrupt
function S.MacroGen:GetSmartInterrupt(class)
    local spellId = 0
    if class == "WARRIOR" then spellId = 6552 -- Pummel
    elseif class == "PALADIN" then return nil 
    elseif class == "ROGUE" then spellId = 1766 -- Kick
    elseif class == "PRIEST" then spellId = 15487 -- Silence
    elseif class == "DEATHKNIGHT" then spellId = 47528 -- Mind Freeze
    elseif class == "SHAMAN" then spellId = 57994 -- Wind Shear
    elseif class == "MAGE" then spellId = 2139 -- Counterspell
    elseif class == "WARLOCK" then spellId = 19647 -- Spell Lock
    elseif class == "HUNTER" then spellId = 34490 -- Silencing Shot
    end
    
    if spellId > 0 and IsSpellKnown(spellId) then
        local name = GetSpellInfo(spellId)
        return "#showtooltip " .. name .. "\n/stopcasting\n/cast [mod:shift,@focus,harm,nodead][@mouseover,harm,nodead][] " .. name
    elseif class == "WARLOCK" then
        return "#showtooltip Bloqueo de hechizo\n/cast [mod:shift,@focus,harm,nodead][@mouseover,harm,nodead][] Bloqueo de hechizo"
    end
    return nil
end

-- 2. Smart CC
function S.MacroGen:GetSmartCC(class)
    local spellId = 0
    if class == "WARLOCK" then spellId = 5782 -- Fear
    elseif class == "MAGE" then spellId = 118 -- Polymorph
    elseif class == "PRIEST" then spellId = 9484 -- Shackle Undead
    elseif class == "DRUID" then spellId = 33786 -- Cyclone
    elseif class == "ROGUE" then spellId = 2094 -- Blind
    elseif class == "HUNTER" then spellId = 19503 -- Scatter Shot
    elseif class == "PALADIN" then spellId = 853 -- Hammer of Justice
    end
    
    if spellId > 0 and IsSpellKnown(spellId) then
        local name = GetSpellInfo(spellId)
        return "#showtooltip " .. name .. "\n/cast [mod:ctrl,@mouseover,harm,nodead][mod:shift,@focus,harm,nodead][] " .. name
    end
    return nil
end

-- 3. Smart Mount (Integración real con S.Mounts)
function S.MacroGen:GetSmartMount()
    if S.Mounts and S.Mounts.GenerateMountMacro then
        return S.Mounts:GenerateMountMacro()
    end
    return "#showtooltip\n/dismount [mounted]\n/leavevehicle [vehicleui]"
end

-- ===========================================================================
-- 3. ROTATION BRAIN (The "Intel" Core)
-- ============================================================================
function S.MacroGen:GetNecrosisRotation(class, spec)
    local function GetIfKnown(id)
        return self:GetIfKnown(id)
    end
    
    -- -----------------------------------------------------------------------
    -- 1. WARLOCK (3 Specs)
    -- -----------------------------------------------------------------------
    if class == "WARLOCK" then
        if spec == 1 then -- Affliction
            local haunt = GetIfKnown(48181) -- Poseer
            local ua = GetIfKnown(30108)    -- Aflicción inestable
            local corr = GetIfKnown(172) or "Corrupción"
            local sb = GetIfKnown(686) or "Descarga de las Sombras"
            local drain = GetIfKnown(1120) or "Drenar alma"
            local immo = GetIfKnown(348) or "Inmolar"
            local agony = GetIfKnown(980) or "Maldición de agonía"
            
            local shiftSpell = haunt or ua or immo
            local ctrlSpell = (haunt and ua) or agony or corr
            return string.format("/cast [mod:shift] %s; [mod:ctrl] %s; [mod:alt,nochanneling] %s; %s",
                shiftSpell, ctrlSpell, drain, sb)
        elseif spec == 2 then -- Demonology
            local aura = GetIfKnown(50589) or "Aura de inmolación"
            local immo = GetIfKnown(348) or "Inmolar"
            local sf = GetIfKnown(6353) or "Fuego de alma"
            local incin = GetIfKnown(29722) or GetIfKnown(686) or "Incinerar"
            local corr = GetIfKnown(172) or "Corrupción"
            return string.format("/cast [form:1] %s\n/cast [mod:shift] %s; [mod:ctrl] %s; [mod:alt] %s; %s",
                aura, immo, sf, corr, incin)
        else -- Destruction
            local immo = GetIfKnown(348) or "Inmolar"
            local conflag = GetIfKnown(17962) or "Conflagrar"
            local cb = GetIfKnown(50796) or "Descarga de Caos"
            local incin = GetIfKnown(29722) or GetIfKnown(686) or "Incinerar"
            return string.format("/cast [mod:shift] %s; [mod:ctrl] %s; [mod:alt] %s; %s",
                immo, conflag, cb, incin)
        end
        
    -- -----------------------------------------------------------------------
    -- 2. DEATH KNIGHT (3 Specs)
    -- -----------------------------------------------------------------------
    elseif class == "DEATHKNIGHT" then
        local it = GetIfKnown(45477) or "Toque helado"
        local ps = GetIfKnown(45462) or "Golpe de peste"
        local rs = GetIfKnown(56815)
        local suffix = rs and ("\n/cast !" .. rs) or ""
        
        if spec == 1 then -- Blood
            local hs = GetIfKnown(55050) or GetIfKnown(45902) or "Golpe en el corazón"
            local ds = GetIfKnown(49998) or "Golpe mortal"
            return string.format("/cast [mod:shift] %s; [mod:ctrl] %s; [mod:alt] %s; %s%s",
                it, ps, ds, hs, suffix)
        elseif spec == 2 then -- Frost
            local ob = GetIfKnown(49020) or "Asolar"
            local fs = GetIfKnown(49143) or "Golpe de Escarcha"
            local hb = GetIfKnown(49184)
            local altChoice = hb or fs
            return string.format("/cast [mod:shift] %s; [mod:ctrl] %s; [mod:alt] %s; %s%s",
                it, ps, altChoice, ob, suffix)
        else -- Unholy
            local ss = GetIfKnown(55090) or GetIfKnown(50842) or "Golpe de la Plaga"
            local dc = GetIfKnown(47541) or "Espiral de la muerte"
            return string.format("/cast [mod:shift] %s; [mod:ctrl] %s; [mod:alt] %s; %s%s",
                it, ps, dc, ss, suffix)
        end

    -- -----------------------------------------------------------------------
    -- 3. PALADIN (3 Specs)
    -- -----------------------------------------------------------------------
    elseif class == "PALADIN" then
        if spec == 1 then -- Holy
            local hs = GetIfKnown(20473) or "Choque Sagrado"
            local hl = GetIfKnown(48782) or "Luz Sagrada"
            local fol = GetIfKnown(48785) or "Destello de Luz"
            return string.format("/cast [mod:shift,@mouseover,help][mod:shift] %s; [mod:ctrl,@mouseover,help][mod:ctrl] %s; [@mouseover,help][help][@player] %s",
                hs, hl, fol)
        elseif spec == 2 then -- Protection
            local hotr = GetIfKnown(53595) or "Martillo de rectitud"
            local sor = GetIfKnown(53600) or "Escudo de rectitud"
            local cons = GetIfKnown(26573) or "Consagración"
            local judge = GetIfKnown(53408) or GetIfKnown(20271) or "Sentencia de sabiduría"
            return string.format("/cast [mod:shift] %s; [mod:ctrl] %s; [mod:alt] %s; %s",
                hotr, cons, judge, sor)
        else -- Retribution
            local cs = GetIfKnown(35395) or "Golpe de cruzado"
            local ds = GetIfKnown(53385) or "Tormenta divina"
            local judge = GetIfKnown(53408) or GetIfKnown(20271) or "Sentencia de sabiduría"
            local exo = GetIfKnown(879) or "Exorcismo"
            return string.format("/cast [mod:shift] %s; [mod:ctrl] %s; [mod:alt] %s; %s",
                ds, judge, exo, cs)
        end

    -- -----------------------------------------------------------------------
    -- 4. MAGE (3 Specs)
    -- -----------------------------------------------------------------------
    elseif class == "MAGE" then
        if spec == 1 then -- Arcane
            local ab = GetIfKnown(30451) or "Descarga Arcana"
            local am = GetIfKnown(5143) or "Misiles Arcanos"
            local abarr = GetIfKnown(44425) or "Tromba Arcana"
            return string.format("/cast [mod:shift] %s; [mod:ctrl] %s; %s",
                am, abarr, ab)
        elseif spec == 2 then -- Fire
            local fb = GetIfKnown(133) or "Bola de Fuego"
            local lb = GetIfKnown(44457) or "Bomba viva"
            local pyro = GetIfKnown(11366) or "Piroexplosión"
            local scorch = GetIfKnown(2948) or "Agostar"
            return string.format("/cast [mod:shift] %s; [mod:ctrl] %s; [mod:alt] %s; %s",
                lb, pyro, scorch, fb)
        else -- Frost
            local fb = GetIfKnown(116) or "Descarga de Escarcha"
            local il = GetIfKnown(30455) or "Lanza de hielo"
            local df = GetIfKnown(44572) or "Congelación profunda"
            return string.format("/cast [mod:shift] %s; [mod:ctrl] %s; %s",
                il, df, fb)
        end

    -- -----------------------------------------------------------------------
    -- 5. ROGUE (3 Specs)
    -- -----------------------------------------------------------------------
    elseif class == "ROGUE" then
        if spec == 1 then -- Assassination
            local mut = GetIfKnown(1329) or "Mutilar"
            local env = GetIfKnown(32645) or "Envenenar"
            local hfb = GetIfKnown(63848) or "Hambre de sangre"
            return string.format("/cast [mod:shift] %s; [mod:ctrl] %s; %s",
                env, hfb, mut)
        elseif spec == 2 then -- Combat
            local ss = GetIfKnown(1752) or "Golpe siniestro"
            local evis = GetIfKnown(2098) or "Eviscerar"
            local snd = GetIfKnown(5171) or "Hacer picadillo"
            local ks = GetIfKnown(51690) or "Asesinato múltiple"
            return string.format("/cast [mod:shift] %s; [mod:ctrl] %s; [mod:alt] %s; %s",
                evis, snd, ks, ss)
        else -- Subtlety
            local hemo = GetIfKnown(16511) or "Hemorragia"
            local evis = GetIfKnown(2098) or "Eviscerar"
            local step = GetIfKnown(36554) or "Paso de las Sombras"
            return string.format("/cast [mod:shift] %s; [mod:ctrl] %s; %s",
                evis, step, hemo)
        end

    -- -----------------------------------------------------------------------
    -- 6. HUNTER (3 Specs)
    -- -----------------------------------------------------------------------
    elseif class == "HUNTER" then
        local steady = GetIfKnown(56641) or "Disparo firme"
        local sting = GetIfKnown(1978) or "Picadura de serpiente"
        
        if spec == 1 then -- Beast Mastery
            local bw = GetIfKnown(19574) or "Cólera de las bestias"
            local kc = GetIfKnown(34026) or "Matar"
            return string.format("/cast [mod:shift] %s; [mod:ctrl] %s; [mod:alt] %s; %s\n/cast !Disparo automático",
                bw, kc, sting, steady)
        elseif spec == 2 then -- Marksmanship
            local chim = GetIfKnown(53209) or "Disparo de quimera"
            local aimed = GetIfKnown(19434) or "Disparo de puntería"
            return string.format("/cast [mod:shift] %s; [mod:ctrl] %s; [mod:alt] %s; %s\n/cast !Disparo automático",
                chim, aimed, sting, steady)
        else -- Survival
            local exp = GetIfKnown(53301) or "Disparo explosivo"
            local ba = GetIfKnown(3674) or "Flecha negra"
            return string.format("/cast [mod:shift] %s; [mod:ctrl] %s; [mod:alt] %s; %s\n/cast !Disparo automático",
                exp, ba, sting, steady)
        end

    -- -----------------------------------------------------------------------
    -- 7. WARRIOR (3 Specs)
    -- -----------------------------------------------------------------------
    elseif class == "WARRIOR" then
        local hs = GetIfKnown(78) or "Golpe heroico"
        
        if spec == 1 then -- Arms
            local ms = GetIfKnown(12294) or "Golpe mortal"
            local op = GetIfKnown(7384) or "Abrumar"
            local rend = GetIfKnown(772) or "Desgarrar"
            local exe = GetIfKnown(5308) or "Ejecutar"
            return string.format("/cast [mod:shift] %s; [mod:ctrl] %s; [mod:alt] %s; %s\n/cast !%s",
                rend, op, exe, ms, hs)
        elseif spec == 2 then -- Fury
            local bt = GetIfKnown(23881) or "Sed de sangre"
            local ww = GetIfKnown(1680) or "Torbellino"
            local slam = GetIfKnown(1464) or "Embate"
            return string.format("/cast [mod:shift] %s; [mod:ctrl] %s; %s\n/cast !%s",
                ww, slam, bt, hs)
        else -- Protection
            local ss = GetIfKnown(23922) or "Embate con escudo"
            local rev = GetIfKnown(6572) or "Revancha"
            local shock = GetIfKnown(46968) or "Ola de choque"
            local dev = GetIfKnown(20243) or GetIfKnown(7386) or "Devastar"
            return string.format("/cast [mod:shift] %s; [mod:ctrl] %s; [mod:alt] %s; %s\n/cast !%s",
                ss, rev, shock, dev, hs)
        end

    -- -----------------------------------------------------------------------
    -- 8. SHAMAN (3 Specs)
    -- -----------------------------------------------------------------------
    elseif class == "SHAMAN" then
        if spec == 1 then -- Elemental
            local lv = GetIfKnown(51505) or "Ráfaga de lava"
            local fs = GetIfKnown(8050) or "Choque de llamas"
            local cl = GetIfKnown(421) or "Cadena de relámpagos"
            local lb = GetIfKnown(403) or "Descarga de relámpagos"
            return string.format("/cast [mod:shift] %s; [mod:ctrl] %s; [mod:alt] %s; %s",
                lv, fs, cl, lb)
        elseif spec == 2 then -- Enhancement
            local ss = GetIfKnown(17364) or "Golpe de tormenta"
            local ll = GetIfKnown(60103) or "Látigo de lava"
            local es = GetIfKnown(8042) or "Choque de tierra"
            local lb = GetIfKnown(403) or "Descarga de relámpagos"
            return string.format("/cast [mod:shift] %s; [mod:ctrl] %s; [mod:alt] %s; %s",
                ll, es, lb, ss)
        else -- Restoration
            local ch = GetIfKnown(1064) or "Sanación en cadena"
            local rip = GetIfKnown(61295) or "Mareas vivas"
            local lhw = GetIfKnown(8004) or "Ola de sanación menor"
            return string.format("/cast [mod:shift,@mouseover,help][mod:shift] %s; [mod:ctrl,@mouseover,help][mod:ctrl] %s; [@mouseover,help][help][@player] %s",
                ch, rip, lhw)
        end

    -- -----------------------------------------------------------------------
    -- 9. PRIEST (3 Specs)
    -- -----------------------------------------------------------------------
    elseif class == "PRIEST" then
        if spec == 1 then -- Discipline
            local pws = GetIfKnown(17) or "Palabra de poder: escudo"
            local pen = GetIfKnown(47540) or "Penitencia"
            local fh = GetIfKnown(2061) or "Sanación relámpago"
            local pom = GetIfKnown(33076) or "Rezo de alivio"
            return string.format("/cast [mod:shift,@mouseover,help][mod:shift] %s; [mod:ctrl,@mouseover,help][mod:ctrl] %s; [mod:alt,@mouseover,help][mod:alt] %s; [@mouseover,help][help][@player] %s",
                pws, pen, pom, fh)
        elseif spec == 2 then -- Holy
            local coh = GetIfKnown(34861) or "Círculo de sanación"
            local pom = GetIfKnown(33076) or "Rezo de alivio"
            local renew = GetIfKnown(139) or "Renovar"
            local fh = GetIfKnown(2061) or "Sanación relámpago"
            return string.format("/cast [mod:shift,@mouseover,help][mod:shift] %s; [mod:ctrl,@mouseover,help][mod:ctrl] %s; [mod:alt,@mouseover,help][mod:alt] %s; [@mouseover,help][help][@player] %s",
                coh, pom, renew, fh)
        else -- Shadow
            local mf = GetIfKnown(15407) or "Tortura mental"
            local vt = GetIfKnown(34914) or "Toque vampírico"
            local dp = GetIfKnown(2944) or "Peste devoradora"
            local mb = GetIfKnown(8092) or "Explosión mental"
            return string.format("/cast [mod:shift] %s; [mod:ctrl] %s; [mod:alt] %s; [nochanneling] %s",
                vt, dp, mb, mf)
        end

    -- -----------------------------------------------------------------------
    -- 10. DRUID (3 Specs)
    -- -----------------------------------------------------------------------
    elseif class == "DRUID" then
        if spec == 1 then -- Balance
            local wrath = GetIfKnown(5176) or "Cólera"
            local sf = GetIfKnown(2912) or "Fuego estelar"
            local mf = GetIfKnown(8921) or "Fuego lunar"
            local is = GetIfKnown(5570) or "Enjambre de insectos"
            return string.format("/cast [mod:shift] %s; [mod:ctrl] %s; [mod:alt] %s; %s",
                sf, mf, is, wrath)
        elseif spec == 2 then -- Feral (Bear & Cat Form Support)
            local bearMaul = GetIfKnown(6807) or "Magullar"
            local bearMangle = GetIfKnown(33878) or "Destrozar (oso)"
            local catMangle = GetIfKnown(33876) or "Destrozar (felino)"
            local catRip = GetIfKnown(1079) or "Destripar"
            local catBite = GetIfKnown(22568) or "Mordedura feroz"
            local wrath = GetIfKnown(5176) or "Cólera"
            return string.format("/cast [form:1,mod:shift] %s; [form:1] %s; [form:3,mod:shift] %s; [form:3,mod:ctrl] %s; [form:3] %s; %s",
                bearMangle, bearMaul, catRip, catBite, catMangle, wrath)
        else -- Restoration
            local rej = GetIfKnown(774) or "Rejuvenecimiento"
            local lb = GetIfKnown(33763) or "Flor de vida"
            local wg = GetIfKnown(48438) or GetIfKnown(18562) or "Crecimiento salvaje"
            local reg = GetIfKnown(8936) or "Recrecimiento"
            return string.format("/cast [mod:shift,@mouseover,help][mod:shift] %s; [mod:ctrl,@mouseover,help][mod:ctrl] %s; [mod:alt,@mouseover,help][mod:alt] %s; [@mouseover,help][help][@player] %s",
                rej, lb, wg, reg)
        end
    end
    
    return nil
end

-- ===========================================================================
-- 3. CLASS DATABASE
-- ===========================================================================

function S.MacroGen:GetClassMacros(class, spec)
    local macros = {}

    -- ITEM IDS
    local healthstone = self:GetSmartItem(5512, "Piedra de salud vil")
    local potion = self:GetSmartItem(33447, "Poción de sanación rúnica")
    local hearthstone = self:GetSmartItem(6948, "Piedra de hogar")

    -- Smart Utilities Integration
    local intBody = self:GetSmartInterrupt(class)
    if intBody then table.insert(macros, { Name = "SeqInt", Body = intBody }) end
    
    local ccBody = self:GetSmartCC(class)
    if ccBody then table.insert(macros, { Name = "SeqCC", Body = ccBody }) end
    
    local mntBody = self:GetSmartMount()
    if mntBody then table.insert(macros, { Name = "SeqMount", Body = mntBody }) end

     -- WARLOCK
    if class == "WARLOCK" then
        local opener = self:GetSmartSpell(172, "Corrupción") 
        if spec == 2 then opener = "Metamorfosis" end 
        if spec == 3 then opener = self:GetSmartSpell(348, "Inmolar") end 

        table.insert(macros, { Name = "SeqStart",  Body = "#showtooltip " .. opener .. "\n/cleartarget [dead][help]\n/targetenemy\n/petattack\n/startattack\n/cast " .. opener })
        table.insert(macros, { Name = "SeqHeal",   Body = "#showtooltip " .. healthstone .. "\n/cast [btn:2] Crear piedra de salud\n/cast [mod:shift] Canalizar salud\n/use [nomod] " .. healthstone .. "\n/use [nomod] " .. potion })
        table.insert(macros, { Name = "SeqPet",    Body = "#showtooltip\n/petattack [nomod]\n/petfollow [mod:alt]\n/cast [@mouseover,harm][@focus,harm][] Bloqueo de hechizo\n/cast [@mouseover,harm][@focus,harm][] Seducción\n/cast [@player,mod:shift] Devorar magia\n/cast [mod:shift] Sacrificio" })
        
        local banish = self:GetSmartSpell(710, "Desterrar")
        if banish then table.insert(macros, { Name = "SeqBanish", Body = "#showtooltip " .. banish .. "\n/cast [mod:shift,@focus,harm,nodead][@mouseover,harm,nodead][] " .. banish }) end
        table.insert(macros, { Name = "SeqDispel", Body = "#showtooltip Devorar magia\n/cast [mod:alt,@player][@mouseover,help,nodead][] Devorar magia" })
        
        local meta = self:GetSmartSpell(47241, "Metamorfosis")
        local aura = self:GetSmartSpell(50589, "Aura de inmolación")
        table.insert(macros, { Name = "SeqBurst",  Body = "#showtooltip\n/use 10\n/use 13\n/use 14\n/use Poción de velocidad\n/cast " .. (meta or "Metamorfosis") .. "\n/cast " .. (aura or "Aura de inmolación") })

    -- DEATH KNIGHT
    elseif class == "DEATHKNIGHT" then
        local grip = self:GetSmartSpell(49576, "Atracción letal")
        table.insert(macros, { Name = "SeqGrip", Body = "#showtooltip " .. grip .. "\n/cast [mod:shift,@focus,harm,nodead][@mouseover,harm,nodead][] " .. grip })
        local tap = self:GetSmartSpell(48982, "Transfusión de runa")
        local pact = self:GetSmartSpell(48743, "Pacto de la muerte")
        table.insert(macros, { Name = "SeqHeal", Body = "#showtooltip " .. tap .. "\n/cast " .. tap .. "\n/cast [mod:shift] " .. pact .. "\n/use " .. potion })
        local dnd = self:GetSmartSpell(43265, "Muerte y descomposición")
        local pest = self:GetSmartSpell(50842, "Pestilencia")
        table.insert(macros, { Name = "SeqAoE",  Body = "#showtooltip " .. dnd .. "\n/cast [mod:shift] " .. pest .. "; " .. dnd })
        local strike = self:GetSmartSpell(45477, "Toque helado")
        table.insert(macros, { Name = "SeqStart", Body = "#showtooltip " .. strike .. "\n/startattack\n/petattack\n/cast " .. strike }) 
        
        local army = self:GetSmartSpell(42650, "Ejército de muertos")
        if army then table.insert(macros, { Name = "SeqArmy", Body = "#showtooltip " .. army .. "\n/cast " .. army .. "\n/s ¡Salid mis pequeños! ¡A comer!" }) end

    -- PALADIN
    elseif class == "PALADIN" then
        local bub = self:GetSmartSpell(642, "Escudo divino") 
        table.insert(macros, { Name = "SeqBubble", Body = "#showtooltip " .. bub .. "\n/stopcasting\n/cast [nomod] " .. bub .. "\n/cancelaura [mod:alt] " .. bub })
        if spec == 1 then
             local shock = self:GetSmartSpell(20473, "Choque Sagrado")
             table.insert(macros, { Name = "SeqHeal", Body = "#showtooltip " .. shock .. "\n/cast [@mouseover,help][help][@player] " .. shock })
        end
        if spec == 2 then
             local shield = self:GetSmartSpell(31935, "Escudo de vengador")
             table.insert(macros, { Name = "SeqPull", Body = "#showtooltip " .. shield .. "\n/cast " .. shield .. "\n/s ¡Venid a mí, herejes! (Pull)" })
        end

    -- WARRIOR
    elseif class == "WARRIOR" then
        local wall = self:GetSmartSpell(871, "Muro de escudo")
        table.insert(macros, { Name = "SeqWall", Body = "#showtooltip " .. wall .. "\n/cast [stance:1/3] Actitud defensiva\n/cast " .. wall .. "\n/s ¡Muro de escudo activado!" })
        
    -- HUNTER
    elseif class == "HUNTER" then
        local md = self:GetSmartSpell(34477, "Redirección")
        table.insert(macros, { Name = "SeqMD", Body = "#showtooltip " .. md .. "\n/cast [@focus,help,nodead][@pet,exists,nodead][@mouseover,help,nodead][] " .. md .. "\n/s Redirección sobre %t." })
        
    -- ROGUE
    elseif class == "ROGUE" then
         local tricks = self:GetSmartSpell(57934, "Secretos del oficio")
         table.insert(macros, { Name = "SeqTricks", Body = "#showtooltip " .. tricks .. "\n/cast [@focus,help,nodead][@mouseover,help,nodead][] " .. tricks .. "\n/s Secretos para %t..." })
         
    -- PRIEST
    elseif class == "PRIEST" then
         local hymn = self:GetSmartSpell(64843, "Himno divino")
         table.insert(macros, { Name = "SeqHymn", Body = "#showtooltip " .. hymn .. "\n/cast " .. hymn .. "\n/s ¡Himno divino activo! ¡Sanación masiva!" })
        
    -- SHAMAN
    elseif class == "SHAMAN" then
        local lust = self:GetSmartSpell(2825, "Ansia de sangre")
        if not lust then lust = self:GetSmartSpell(32182, "Heroísmo") end 
        if lust then
             table.insert(macros, { Name = "SeqLust", Body = "#showtooltip " .. lust .. "\n/cast " .. lust .. "\n/y ¡¡FURIA PARA EL SÉQUITO!! (Heroísmo / BL)" })
        end
        if spec == 2 then
             local wolves = self:GetSmartSpell(51533, "Espíritu feral")
             table.insert(macros, { Name = "SeqWolves", Body = "#showtooltip " .. wolves .. "\n/cast " .. wolves .. "\n/cast Ira del chamán\n/s ¡Cazan en manada!" })
        end
        if spec == 3 then
             local tide = self:GetSmartSpell(16190, "Marea de maná")
             table.insert(macros, { Name = "SeqTide", Body = "#showtooltip " .. tide .. "\n/cast " .. tide .. "\n/s ¡Marea de Maná activa! ¡Bebed!" })
        end

    -- MAGE
    elseif class == "MAGE" then
         local tableSpell = self:GetSmartSpell(43987, "Ritual de refrigerio")
         table.insert(macros, { Name = "SeqTable", Body = "#showtooltip " .. tableSpell .. "\n/cast " .. tableSpell .. "\n/y ¡Mesita del Jaina! ¡Comed y bebed!" })
         local remove = self:GetSmartSpell(475, "Eliminar maldición")
         table.insert(macros, { Name = "SeqDecurse", Body = "#showtooltip " .. remove .. "\n/cast [@mouseover,help,nodead][@player] " .. remove })

    -- DRUID
    elseif class == "DRUID" then
         local rez = self:GetSmartSpell(20484, "Renacer")
         local rezText = "¡Levántate, %t! ¡Aún no he terminado contigo!"
         -- Random Speech Integration
         if S.GetRandomSpeech then
              local randomText = S:GetRandomSpeech("Resurrect")
              if randomText then rezText = randomText:gsub("<target>", "%%t") end
         end
         
         table.insert(macros, { Name = "SeqRez", Body = "#showtooltip " .. rez .. "\n/stopcasting\n/cast [@mouseover,help,dead][] " .. rez .. "\n/s " .. rezText })
         local innervate = self:GetSmartSpell(29166, "Estimular")
         table.insert(macros, { Name = "SeqInnervate", Body = "#showtooltip " .. innervate .. "\n/cast [@mouseover,help,nodead][help][@player] " .. innervate })
    end

    -- INTELLIGENT ROTATION MACRO (Covers ALL 10 Classes and 30 Specs)
    local rotBody = self:GetNecrosisRotation(class, spec)
    if rotBody then
        local header = "#showtooltip\n"
        if class == "WARRIOR" or class == "ROGUE" or class == "DEATHKNIGHT" or (class == "PALADIN" and spec ~= 1) or (class == "DRUID" and spec == 2) or (class == "SHAMAN" and spec == 2) then
            header = header .. "/startattack\n"
        elseif class == "HUNTER" then
            header = header .. "/startattack\n"
        end
        if class == "WARLOCK" or class == "HUNTER" or class == "DEATHKNIGHT" then
            header = header .. "/petattack\n"
        end
        table.insert(macros, { Name = "SeqRot", Body = header .. rotBody })
    end

    return macros
end

-- ===========================================================================
-- 4. GENERATIOR CORE
-- ===========================================================================

-- ===========================================================================
-- 4. GENERATOR CORE (SMART SYNC)
-- ===========================================================================

function S.MacroGen:GenerateClassMacros(silent)
    -- Guarda de combate: En WoW 3.3.5a, CreateMacro, EditMacro y DeleteMacro arrojan ADDON_ACTION_BLOCKED en combate
    if InCombatLockdown() then
        self.pendingGeneration = true
        if not silent then
            print("|cFFFFFF00Jaina:|r En combate: las macros se sincronizarán automáticamente al salir de combate.")
        end
        return
    end
    self.pendingGeneration = false

    -- Coalescing / Debounce de 2 segundos para evitar ráfagas de sincronización en eventos sucesivos
    local now = GetTime()
    if self.lastSyncTime and (now - self.lastSyncTime < 2.0) and not self.forceSync then
        return
    end
    self.lastSyncTime = now
    self.forceSync = nil

    local _, class = UnitClass("player")
    local spec = S.Universal and S.Universal:GetSpec() or 1
    
    if not silent then
        print("|cFFFF00FFJaina:|r Sincronizando macros inteligentes para " .. class .. "...")
    end

    -- 1. Generate Desired Macros List (Target State)
    local desired = self:GetClassMacros(class, spec)
    
    -- Add Racial
    local racial = self:GetRacialSpell()
    if racial then
        local rBody = "#showtooltip " .. racial .. "\n/cast " .. racial .. "\n/s ¡Por el Jaina del Terror! (" .. racial .. ")"
        table.insert(desired, { Name = "SeqRacial", Body = rBody })
    end
    
    -- Map desired names for quick lookup
    local desiredNames = {}
    for _, mac in ipairs(desired) do
        desiredNames[mac.Name] = true
    end
    
    -- 2. DELETE Obsolete "Seq" Macros in both Character and Account scopes
    local BASE_MACRO_INDEX = 36
    
    -- Scan Character macros backwards (indices 37..54 in 3.3.5a)
    for i = 18, 1, -1 do
        local absIndex = BASE_MACRO_INDEX + i
        local name = GetMacroInfo(absIndex)
        if name and name:sub(1,3) == "Seq" and not desiredNames[name] then
            if not silent then
                print("|cFF999999Jaina:|r Eliminando macro de personaje obsoleta: " .. name)
            end
            DeleteMacro(absIndex)
        end
    end

    -- Scan Account macros backwards (indices 1..36) to purge leaked or obsolete Seq macros
    for i = 36, 1, -1 do
        local name = GetMacroInfo(i)
        if name and name:sub(1,3) == "Seq" and not desiredNames[name] then
            if not silent then
                print("|cFF999999Jaina:|r Limpiando macro global obsoleta: " .. name)
            end
            DeleteMacro(i)
        end
    end
    
    -- 3. CREATE / UPDATE Desired Macros (Exclusively in Character Scope)
    for _, mac in ipairs(desired) do
        local body = mac.Body
        if #body > 255 then
            body = body:sub(1, 255)
        end
        local macroID = GetMacroIndexByName(mac.Name)
        
        -- If an existing Seq macro is in the Account tab (index <= 36), remove it from account
        -- so it can be cleanly created in the Character tab without account pollution
        if macroID > 0 and macroID <= 36 then
            DeleteMacro(macroID)
            macroID = 0
        end
        
        if macroID > 0 then
            -- Update existing character macro
            EditMacro(macroID, mac.Name, 1, body)
        else
            -- Create new character macro
            local _, numChar = GetNumMacros()
            if numChar < 18 then
                CreateMacro(mac.Name, 1, body, 1) -- 1 = per character
            else
                if not silent then
                    print("|cFFFF0000Jaina Error:|r Espacio de macros específico lleno (" .. numChar .. "/18). No se pudo crear: " .. mac.Name)
                end
            end
        end
    end
    
    if not silent then
        print("|cFF00FF00Jaina:|r Macros sincronizadas y optimizadas.")
    end
end

-- Slash command aliases for direct access
SLASH_SEQUITOMACROS1 = "/smacros"
SlashCmdList["SEQUITOMACROS"] = function()
    S.MacroGen.forceSync = true
    S.MacroGen:GenerateClassMacros(false)
end

local f = CreateFrame("Frame")
f:RegisterEvent("PLAYER_TALENT_UPDATE") 
f:RegisterEvent("LEARNED_SPELL_IN_TAB")
f:RegisterEvent("PLAYER_ENTERING_WORLD")
f:RegisterEvent("PLAYER_REGEN_ENABLED") -- Sincronización diferida al salir de combate
f:SetScript("OnEvent", function(self, event, ...)
    if event == "PLAYER_REGEN_ENABLED" then
        if S.MacroGen.pendingGeneration then
            S.MacroGen:GenerateClassMacros(true)
        end
    elseif S.db and S.db.profile and S.db.profile.AutoMacros then
       if event == "PLAYER_ENTERING_WORLD" then
           C_Timer.After(5, function() S.MacroGen:GenerateClassMacros(true) end)
       else
           S.MacroGen:GenerateClassMacros(true)
       end
    end
end)
