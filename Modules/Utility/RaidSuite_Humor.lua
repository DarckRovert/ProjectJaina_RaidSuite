--[[
    SEQUITO - JainaHumor (Frases Cómicas y Diálogos de Incursión)
    Versión: 10.2.0 (Definitive Edition)
    Autor: DarckRovert (Ingame: Elnazzareno) & Project Jaina Team
    Servidor: Project Jaina - Project Jaina (projectjaina.com)
    
    Proporciona frases cómicas, ocurrentes y temáticas de hermandad
    cuando el jugador realiza actividades clave en mazmorras y bandas
    (invocaciones, pozos de almas, mesas de comida, resurrecciones,
    heroísmo, intervenciones divinas, festines y reparaciones).
]]--

local addonName, S = ...
S.Humor = S.Humor or {}
local H = S.Humor

-- Configuración por defecto
H.Defaults = {
    enabled = true,
    channel = "SAY", -- "SAY", "PARTY", "RAID", "YELL"
    cooldown = 12,    -- Enfriamiento anti-spam en segundos
    enableSummon = true,
    enableSoulwell = true,
    enableDoom = true,
    enableMageTable = true,
    enablePortal = true,
    enableBattleRez = true,
    enableNormalRez = true,
    enableBloodlust = true,
    enableDivineIntervention = true,
    enableMisdirection = true,
    enableFeast = true,
    enableRepair = true,
}

-- Timers para anti-spam por categoría
H.LastTimes = {}
H.LastTarget = nil

-- ============================================================================
-- BANCO DE FRASES CÓMICAS
-- ============================================================================
H.Quotes = {
    SUMMON = {
        "¡Abriendo portal para %t! Necesito 2 personas que no tengan lag mental para dar clic.",
        "Invocando a %t desde Dalaran... porque tomar el barco o volar 30 segundos le daba ansiedad.",
        "¡Uber del Vacío llegando! Denle clic al portal que el brujo no es taxista gratis.",
        "Portal listo para %t. Un clic para invocarlo, cero clics para dejarlo botado en Dalaran.",
        "El armario de invocación está abierto. Dos voluntarios para dar clic antes de que empiece a cobrar 50 de oro.",
    },
    SOULWELL = {
        "¡Puse el armario de almas! Agarren sus piedras de salud antes de morir y echarle la culpa al healer.",
        "¡Caramelos verdes gratis con sabor a azufre y condenación! Coman que no muerden (mucho).",
        "Dispensador de vida de emergencia instalado. Si alguien muere con la piedra en la bolsa, hay tabla.",
        "¡Piedras de salud listas! Tienen un botón verde en la barra, sirve para no morir, pruébenlo.",
        "Puse piedras. Agárrenlas ahora o no lloren cuando el boss los mire feo.",
    },
    DOOM = {
        "¡RULETA RUSA INICIADA! Uno de ustedes será el almuerzo del demonio. ¡Hagan sus apuestas!",
        "Necesito 4 almas valientes (o distraídas) para dar clic. Que el lag elija al sacrificado.",
        "Dando clic al ritual... si me muero yo, fue culpa del tanque.",
        "Un sacrificio voluntario (a la fuerza) para el Guardia Apocalíptico. ¡Den clic!",
    },
    MAGE_TABLE = {
        "¡Bufé libre de carbohidratos mágicos! Coman y beban que el maná no se regenera por fotosíntesis.",
        "Mesa servida con amor y escarcha. Agarren pan y agua antes de que me arrepienta y cobre entrada.",
        "Pan de cero calorías y agua pura de manantial arcano. Cortesía del mago de la casa.",
        "¡A desayunar se ha dicho! Coman rápido antes de que el tanque haga pull sin avisar.",
        "Puse mesa. Lleven provisiones que luego andan pidiendo agua a mitad de boss.",
    },
    PORTAL = {
        "Portal abierto... Si caen al vacío o en el Cráter de Dalaran, fue un accidente no intencionado.",
        "Taxi interdimensional listo. Acepto propinas en frascos, pociones o amor fraternal.",
        "¡Entren al portal! El destino es 99% seguro. El otro 1% es alimento para dragones.",
        "Portal de regreso a la civilización listo. Cuidado con tropezar al cruzar.",
    },
    BATTLE_REZ = {
        "¡Levántate, %t! El suelo de la raid no es un hotel cinco estrellas para tomar siestas.",
        "BRez lanzado en %t... Tu suscripción a la vida ha sido renovada. ¡Por favor NO pises el fuego otra vez!",
        "Gasté un BRez en ti, %t. Si te mueres en los próximos 10 segundos, me debes 500g de reparación.",
        "Resucitando a %t en combate... Di que fue lag, nosotros te cubrimos la coartada.",
        "¡De pie, %t! Hay jefes que matar y wipes que evitar.",
    },
    NORMAL_REZ = {
        "Despertando a %t... Limpiaste el piso con la armadura, pero ya es hora del botín.",
        "Resucitando a %t. Solo estaba 'mayormente' muerto, todavía tenía pulso de maná.",
        "Levántate, %t. Los muertos no tiran dados por los ítems épicos.",
        "Resurrección en camino para %t. Cobro 10 de oro por cada golpe que te metieron.",
        "Despierta, %t... ya pasó el peligro (o eso creemos).",
    },
    BLOODLUST = {
        "¡¡¡HEROÍSMO / ANSIA ACTIVADA!!! ¡Tiren hasta los mocos y los CDs que el boss no se va a morir con abrazos!",
        "¡METAN DEDO! ¡Heroismo on! Si el medidor de DPS no echa humo, están pegando con flores.",
        "¡SANGRE Y GLORIA! ¡Todos los cooldowns afuera ahora mismo o nos vamos al cementerio!",
        "¡TAMBORES DE GUERRA AL MÁXIMO! A romper los botones del teclado se ha dicho.",
    },
    DIVINE_INTERVENTION = {
        "¡Me sacrifico por ti, %t! Disfruta la burbuja dorada, ahorra reparación y no me olvides en tu testamento.",
        "¡Adiós mundo cruel! Muero para que tú vivas, %t... revíveme cuando se pase el peligro.",
        "¡Burbuja salvadora en %t! Yo me voy con el ángel de la resurrección, tú quédate rezando.",
    },
    MISDIRECTION = {
        "Pasándole todo mi agro a %t... ¡Si el boss viene corriendo hacia ti, pon cara de malo!",
        "Toma agro gratis, %t. Todo el amor de mis críticos va directo a tu cuenta.",
        "Poniéndole Secretos a %t... ¡Ahora eres tú el que le debe explicaciones al jefe!",
    },
    FEAST = {
        "¡Festín de pescado servido! Coman rápido que huele a puerto de Tuercespina y caduca en 5 minutos.",
        "¡Pescado fresco del Jaina! Tienen 30 segundos para sentarse y masticar antes del pull.",
        "Puse festín. Si alguien hace pull con la comida a medio masticar, lo tiramos por el balcón de ICC.",
    },
    REPAIR = {
        "¡Jeeves invocado! Vengan a empeñar sus riñones para pagar las armaduras rotas por pisar fuego.",
        "Robot de reparación en el piso. Hora de vaciar la alcancía por culpa del último wipe.",
        "A reparar antes del siguiente intento. Que no se diga que la hermandad no tiene presupuesto.",
    }
}

-- Mapeo de IDs de hechizos a categorías
H.SpellMap = {
    -- Invocación Brujo
    [698] = "SUMMON",
    -- Pozo de Almas Brujo
    [29893] = "SOULWELL",
    [58887] = "SOULWELL",
    -- Ritual de la Perdición
    [18540] = "DOOM",
    -- Mesa de Mago
    [43987] = "MAGE_TABLE",
    [58659] = "MAGE_TABLE",
    -- Portales Mago
    [53142] = "PORTAL", -- Dalaran
    [10059] = "PORTAL", -- Ventormenta
    [11416] = "PORTAL", -- Forjaz
    [11417] = "PORTAL", -- Darnassus
    [32266] = "PORTAL", -- Exodar
    [11419] = "PORTAL", -- Orgrimmar
    [11420] = "PORTAL", -- Cima del Trueno
    [11418] = "PORTAL", -- Entrañas
    [32267] = "PORTAL", -- Lunargenta
    [33691] = "PORTAL", -- Shattrath A
    [35717] = "PORTAL", -- Shattrath H
    [49361] = "PORTAL", -- Stonard
    [49360] = "PORTAL", -- Theramore
    -- Resurrección en combate (BRez)
    [20484] = "BATTLE_REZ", -- Druida Rebirth R1
    [20739] = "BATTLE_REZ",
    [20742] = "BATTLE_REZ",
    [20747] = "BATTLE_REZ",
    [20748] = "BATTLE_REZ",
    [26994] = "BATTLE_REZ",
    [48477] = "BATTLE_REZ", -- Druida Rebirth R7
    [20707] = "BATTLE_REZ", -- Brujo Piedra de alma R1
    [20762] = "BATTLE_REZ",
    [20763] = "BATTLE_REZ",
    [20764] = "BATTLE_REZ",
    [20765] = "BATTLE_REZ",
    [27239] = "BATTLE_REZ",
    [47883] = "BATTLE_REZ", -- Brujo Piedra de alma R7
    -- Resurrecciones normales
    [2006] = "NORMAL_REZ",  -- Priest Resurrección R1
    [2014] = "NORMAL_REZ",
    [2015] = "NORMAL_REZ",
    [20770] = "NORMAL_REZ",
    [25435] = "NORMAL_REZ",
    [48949] = "NORMAL_REZ", -- Priest Resurrección R7
    [7328] = "NORMAL_REZ",  -- Paladín Redención R1
    [10322] = "NORMAL_REZ",
    [10324] = "NORMAL_REZ",
    [20772] = "NORMAL_REZ",
    [20773] = "NORMAL_REZ",
    [48950] = "NORMAL_REZ", -- Paladín Redención R7
    [2008] = "NORMAL_REZ",  -- Chamán Espíritu ancestral R1
    [20609] = "NORMAL_REZ",
    [20610] = "NORMAL_REZ",
    [20776] = "NORMAL_REZ",
    [20777] = "NORMAL_REZ",
    [49277] = "NORMAL_REZ", -- Chamán Espíritu ancestral R7
    -- Heroísmo / Ansia de sangre
    [2825] = "BLOODLUST",   -- Ansia de sangre
    [32182] = "BLOODLUST",  -- Heroísmo
    -- Intervención Divina
    [19752] = "DIVINE_INTERVENTION",
    -- Redirección / Secretos
    [34477] = "MISDIRECTION", -- Redirección Cazador
    [57934] = "MISDIRECTION", -- Secretos del Oficio Pícaro
    -- Festín
    [57301] = "FEAST", -- Gran festín
    [57426] = "FEAST", -- Festín de pescado
    -- Reparación
    [67826] = "REPAIR", -- Jeeves
    [54711] = "REPAIR", -- Robot de chatarra
    [22700] = "REPAIR", -- Robot 74A
    [44389] = "REPAIR", -- Robot 110G
}

-- Mapeo por nombre localizado como fallback
H.SpellNameMap = {
    ["ritual de invocación"] = "SUMMON",
    ["ritual of summoning"] = "SUMMON",
    ["ritual de almas"] = "SOULWELL",
    ["ritual of souls"] = "SOULWELL",
    ["ritual de la perdición"] = "DOOM",
    ["ritual of doom"] = "DOOM",
    ["ritual de refrigerio"] = "MAGE_TABLE",
    ["ritual of refreshment"] = "MAGE_TABLE",
    ["renacer"] = "BATTLE_REZ",
    ["rebirth"] = "BATTLE_REZ",
    ["piedra de alma"] = "BATTLE_REZ",
    ["soulstone"] = "BATTLE_REZ",
    ["crear piedra de alma"] = "BATTLE_REZ",
    ["resurrección"] = "NORMAL_REZ",
    ["resurrection"] = "NORMAL_REZ",
    ["redención"] = "NORMAL_REZ",
    ["redemption"] = "NORMAL_REZ",
    ["espíritu ancestral"] = "NORMAL_REZ",
    ["ancestral spirit"] = "NORMAL_REZ",
    ["ansia de sangre"] = "BLOODLUST",
    ["bloodlust"] = "BLOODLUST",
    ["heroísmo"] = "BLOODLUST",
    ["heroism"] = "BLOODLUST",
    ["intervención divina"] = "DIVINE_INTERVENTION",
    ["divine intervention"] = "DIVINE_INTERVENTION",
    ["redirección"] = "MISDIRECTION",
    ["misdirection"] = "MISDIRECTION",
    ["secretos del oficio"] = "MISDIRECTION",
    ["tricks of the trade"] = "MISDIRECTION",
    ["festín de pescado"] = "FEAST",
    ["fish feast"] = "FEAST",
    ["gran festín"] = "FEAST",
    ["great feast"] = "FEAST",
    ["jeeves"] = "REPAIR",
}

-- ============================================================================
-- INICIALIZACIÓN
-- ============================================================================
function H:Initialize()
    -- Cargar configuraciones guardadas
    if S.db and S.db.profile then
        S.db.profile.Humor = S.db.profile.Humor or {}
        for k, v in pairs(H.Defaults) do
            if S.db.profile.Humor[k] == nil then
                S.db.profile.Humor[k] = v
            end
        end
        H.Config = S.db.profile.Humor
    else
        H.Config = H.Defaults
    end

    -- Marco de captura de eventos
    H.Frame = CreateFrame("Frame", "JainaHumorFrame")
    H.Frame:RegisterEvent("UNIT_SPELLCAST_SENT")
    H.Frame:RegisterEvent("UNIT_SPELLCAST_SUCCEEDED")

    H.Frame:SetScript("OnEvent", function(self, event, ...)
        if event == "UNIT_SPELLCAST_SENT" then
            H:OnSpellSent(...)
        elseif event == "UNIT_SPELLCAST_SUCCEEDED" then
            H:OnSpellSucceeded(...)
        end
    end)

    -- Slash commands
    SLASH_SEQUITOHUMOR1 = "/shumor"
    SlashCmdList["SEQUITOHUMOR"] = function(msg)
        H:HandleSlash(msg)
    end

    -- Registrar configuración en ModuleConfig
    if S.ModuleConfig then
        S.ModuleConfig:RegisterModule("Humor", {
            id = "Humor",
            name = "Frases y Humor de Incursión",
            description = "Frases cómicas e inmersivas automáticas para actividades de hermandad.",
            category = "utility",
            icon = "Interface\\Icons\\Spell_Shadow_Charm",
            options = {
                {key = "enabled", type = "checkbox", label = "Habilitar Frases Cómicas", default = true},
                {key = "enableSummon", type = "checkbox", label = "Invocaciones de Brujo", default = true},
                {key = "enableSoulwell", type = "checkbox", label = "Armario / Pozo de Almas", default = true},
                {key = "enableDoom", type = "checkbox", label = "Ritual de la Perdición (Ruleta)", default = true},
                {key = "enableMageTable", type = "checkbox", label = "Mesa de Refrigerio de Mago", default = true},
                {key = "enablePortal", type = "checkbox", label = "Portales a Capitales", default = true},
                {key = "enableBattleRez", type = "checkbox", label = "Resurrección en Combate (BRez)", default = true},
                {key = "enableNormalRez", type = "checkbox", label = "Resurrecciones Normales", default = true},
                {key = "enableBloodlust", type = "checkbox", label = "Heroísmo / Ansia de Sangre", default = true},
                {key = "enableDivineIntervention", type = "checkbox", label = "Intervención Divina", default = true},
                {key = "enableMisdirection", type = "checkbox", label = "Redirección y Secretos", default = true},
                {key = "enableFeast", type = "checkbox", label = "Festines de Comida", default = true},
                {key = "enableRepair", type = "checkbox", label = "Jeeves / Reparación", default = true},
            }
        })
    end
end

-- ============================================================================
-- MANEJADORES DE EVENTOS
-- ============================================================================

function H:OnSpellSent(unit, spellName, rank, target)
    if unit ~= "player" then return end
    if target and target ~= "" then
        H.LastTarget = target
    else
        H.LastTarget = UnitName("target") or nil
    end
end

function H:OnSpellSucceeded(unit, spellName, rank, lineId, spellId)
    if unit ~= "player" then return end
    if not H.Config or not H.Config.enabled then return end

    -- Identificar categoría
    local category = H.SpellMap[spellId]
    if not category and spellName then
        local lowerName = string.lower(spellName)
        category = H.SpellNameMap[lowerName]
        -- Comprobar si es un portal por coincidencia parcial
        if not category and string.find(lowerName, "portal") then
            category = "PORTAL"
        end
    end

    if not category then return end

    -- Verificar si la categoría está activa en opciones
    local optKey = "enable" .. category:sub(1,1):upper() .. category:sub(2):lower()
    -- Mapeo especial para camelCase
    if category == "MAGE_TABLE" then optKey = "enableMageTable"
    elseif category == "BATTLE_REZ" then optKey = "enableBattleRez"
    elseif category == "NORMAL_REZ" then optKey = "enableNormalRez"
    elseif category == "DIVINE_INTERVENTION" then optKey = "enableDivineIntervention"
    end

    if H.Config[optKey] == false then return end

    -- Control anti-spam
    local now = GetTime()
    local lastTime = H.LastTimes[category] or 0
    local cooldown = H.Config.cooldown or 12
    if (now - lastTime) < cooldown then
        return
    end
    H.LastTimes[category] = now

    -- Disparar frase
    H:TriggerQuote(category, H.LastTarget)
    H.LastTarget = nil
end

-- ============================================================================
-- EMISIÓN Y FORMATO DE MENSAJES
-- ============================================================================

function H:TriggerQuote(category, targetName)
    local list = H.Quotes[category]
    if not list or #list == 0 then return end

    local text = list[math.random(#list)]
    if not text then return end

    -- Reemplazar comodín %t
    local tName = targetName or UnitName("target") or "compañero"
    text = string.gsub(text, "%%t", tName)

    -- Determinar canal seguro
    local channel = H.Config.channel or "SAY"
    local numRaid = GetNumRaidMembers()
    local numParty = GetNumPartyMembers()

    if channel == "RAID" then
        if numRaid == 0 then
            channel = (numParty > 0) and "PARTY" or "SAY"
        end
    elseif channel == "PARTY" then
        if numParty == 0 and numRaid == 0 then
            channel = "SAY"
        elseif numRaid > 0 and numParty == 0 then
            channel = "RAID"
        end
    elseif channel == "YELL" then
        channel = "YELL"
    else
        channel = "SAY"
    end

    SendChatMessage(text, channel)
end

-- ============================================================================
-- GESTIÓN POR SLASH COMMAND
-- ============================================================================

function H:HandleSlash(msg)
    msg = string.lower(string.trim(msg or ""))
    local cmd, arg = string.match(msg, "^(%S+)%s*(.*)$")

    if cmd == "test" then
        local cat = string.upper(arg or "")
        if cat == "" then cat = "SUMMON" end
        if H.Quotes[cat] then
            H:TriggerQuote(cat, UnitName("target") or "Elnazzareno")
            if S.Print then
                S:Print("|cFF00FF00[JainaHumor]|r Probando frase de categoría: " .. cat)
            end
        else
            if S.Print then
                S:Print("|cFFFF0000[JainaHumor]|r Categoría desconocida. Opciones: SUMMON, SOULWELL, DOOM, MAGE_TABLE, PORTAL, BATTLE_REZ, NORMAL_REZ, BLOODLUST, DIVINE_INTERVENTION, MISDIRECTION, FEAST, REPAIR")
            end
        end
    elseif cmd == "toggle" then
        H.Config.enabled = not H.Config.enabled
        local state = H.Config.enabled and "|cFF00FF00ACTIVADO|r" or "|cFFFF0000DESACTIVADO|r"
        if S.Print then
            S:Print("|cFF00FF00[JainaHumor]|r Modo Humor: " .. state)
        end
    elseif cmd == "channel" then
        local chan = string.upper(arg or "")
        if chan == "SAY" or chan == "PARTY" or chan == "RAID" or chan == "YELL" then
            H.Config.channel = chan
            if S.Print then
                S:Print("|cFF00FF00[JainaHumor]|r Canal configurado a: " .. chan)
            end
        else
            if S.Print then
                S:Print("|cFFFF0000[JainaHumor]|r Canales válidos: SAY, PARTY, RAID, YELL")
            end
        end
    else
        if S.Print then
            S:Print("|cFF00FFFF=== Comandos de JainaHumor ===|r")
            S:Print("/shumor toggle - Activa o desactiva las frases cómicas")
            S:Print("/shumor channel [SAY|PARTY|RAID|YELL] - Cambia el canal de emisión")
            S:Print("/shumor test [CATEGORIA] - Prueba una frase en el chat")
            S:Print("Categorías: SUMMON, SOULWELL, DOOM, MAGE_TABLE, PORTAL, BATTLE_REZ, NORMAL_REZ, BLOODLUST, DIVINE_INTERVENTION, MISDIRECTION, FEAST, REPAIR")
        end
    end
end

-- Registro global
if S.RegisterModule then
    S:RegisterModule("Humor", H)
end
