--[[
    SEQUITO - Macro Sync System
    Sincronización de macros entre usuarios de Sequito
    Incluye biblioteca de macros por clase
    World of Warcraft 3.3.5a
]]--

local addonName, S = ...
S.MacroSync = {}
S.MacroSync.Prefix = "SEQ_MACRO"
S.MacroSync.SharedMacros = {} -- Macros recibidos de otros usuarios
S.MacroSync.MacroLibrary = {} -- Biblioteca local de macros por clase

-- ===========================================================================
-- BIBLIOTECA DE MACROS POR CLASE
-- ===========================================================================
S.MacroSync.ClassLibrary = {
    -- WARLOCK
    ["WARLOCK"] = {
        {
            name = "SeqDotAll",
            desc = "DoTs en múltiples objetivos",
            body = [[#showtooltip Corrupción
/targetenemy [noexists][dead]
/cast Corrupción
/targetenemy
/cast Corrupción
/targetenemy
/cast Corrupción
/targetlasttarget]],
            spec = 1, -- Affliction
            author = "Sequito",
            rating = 5
        },
        {
            name = "SeqWarlockCurse",
            desc = "Maldición rápida (Agonía / Elementos)",
            body = [[#showtooltip
/cast [mod:shift] Maldición de los elementos; Maldición de agonía]],
            spec = 1,
            author = "Sequito",
            rating = 5
        },
        {
            name = "SeqMetaBurst",
            desc = "Burst de Demonología",
            body = [[#showtooltip Metamorfosis
/use 10
/use 13
/use 14
/cast Metamorfosis
/cast Aura de inmolación]],
            spec = 2, -- Demonology
            author = "Sequito",
            rating = 5
        },
        {
            name = "SeqChaosBolt",
            desc = "Combo Destrucción",
            body = [[#showtooltip Descarga de caos
/cast [mod:shift] Conflagrar
/cast [nomod] Descarga de caos]],
            spec = 3, -- Destruction
            author = "Sequito",
            rating = 4
        },
    },
    
    -- DEATH KNIGHT
    ["DEATHKNIGHT"] = {
        {
            name = "SeqDKPull",
            desc = "Pull con Grip + Cadenas",
            body = [[#showtooltip Atracción letal
/cast [target=mouseover,harm,exists] Atracción letal; Atracción letal
/cast Cadenas de hielo]],
            spec = 0, -- All specs
            author = "Sequito",
            rating = 5
        },
        {
            name = "SeqDKTaunt",
            desc = "Taunt con anuncio",
            body = [[#showtooltip Orden oscura
/cast Orden oscura
/s ¡TAUNT en %t! ¡Cuidado healers!]],
            spec = 1, -- Blood
            author = "Sequito",
            rating = 4
        },
        {
            name = "SeqDKAoE",
            desc = "AoE Frost DK",
            body = [[#showtooltip Explosión aullante
/cast [mod:shift] Muerte y descomposición; Explosión aullante]],
            spec = 2, -- Frost
            author = "Sequito",
            rating = 5
        },
        {
            name = "SeqGhoulFrenzy",
            desc = "Ghoul + Frenzy",
            body = [[#showtooltip Frenesí necrófago
/cast Frenesí necrófago
/cast [pet] Salto necrófago]],
            spec = 3, -- Unholy
            author = "Sequito",
            rating = 4
        },
    },
    
    -- PALADIN
    ["PALADIN"] = {
        {
            name = "SeqPalaBubble",
            desc = "Burbuja + Hearth",
            body = [[#showtooltip Escudo divino
/stopcasting
/cast Escudo divino
/s ¡Inmunidad Diplomática!
/use Piedra de hogar]],
            spec = 0,
            author = "Sequito",
            rating = 5
        },
        {
            name = "SeqPalaHeal",
            desc = "Heal inteligente Holy",
            body = [[#showtooltip Destello de Luz
/cast [mod:shift,target=player] Destello de Luz
/cast [target=mouseover,help,exists] Destello de Luz
/cast [help] Destello de Luz
/cast [target=player] Destello de Luz]],
            spec = 1, -- Holy
            author = "Sequito",
            rating = 5
        },
        {
            name = "SeqPalaTank",
            desc = "Rotación Prot 969",
            body = [[#showtooltip
/castsequence reset=combat Martillo de rectitud, Escudo de rectitud, Sentencia de sabiduría, Consagración]],
            spec = 2, -- Protection
            author = "Sequito",
            rating = 5
        },
        {
            name = "SeqPalaRet",
            desc = "Burst Retribution",
            body = [[#showtooltip Cólera vengadora
/use 10
/use 13
/use 14
/cast Cólera vengadora
/cast Juicio de Luz]],
            spec = 3, -- Retribution
            author = "Sequito",
            rating = 5
        },
    },
    
    -- MAGE
    ["MAGE"] = {
        {
            name = "SeqMageSpellsteal",
            desc = "Robar hechizo focus/mouseover",
            body = [[#showtooltip Robar hechizo
/cast [target=focus,exists,harm] Robar hechizo
/cast [target=mouseover,exists,harm] Robar hechizo
/cast Robar hechizo]],
            spec = 0,
            author = "Sequito",
            rating = 5
        },
        {
            name = "SeqMageCS",
            desc = "Counterspell inteligente",
            body = [[#showtooltip Contrahechizo
/stopcasting
/cast [target=focus,exists,harm] Contrahechizo
/cast [target=mouseover,exists,harm] Contrahechizo
/cast Contrahechizo]],
            spec = 0,
            author = "Sequito",
            rating = 5
        },
        {
            name = "SeqMageArcane",
            desc = "Burst Arcano",
            body = [[#showtooltip Poder Arcano
/use 10
/use 13
/use 14
/cast Poder Arcano
/cast Presencia mental
/cast Explosión Arcana]],
            spec = 1, -- Arcane
            author = "Sequito",
            rating = 5
        },
        {
            name = "SeqMageCombust",
            desc = "Combustión Fire",
            body = [[#showtooltip Combustión
/cast Combustión
/cast Bola de Fuego]],
            spec = 2, -- Fire
            author = "Sequito",
            rating = 4
        },
    },
    
    -- HUNTER
    ["HUNTER"] = {
        {
            name = "SeqHunterMD",
            desc = "Misdirection inteligente",
            body = [[#showtooltip Redirección
/cast [target=focus,help,exists] Redirección
/cast [target=pet,exists] Redirección
/s Redirigiendo amenaza...]],
            spec = 0,
            author = "Sequito",
            rating = 5
        },
        {
            name = "SeqHunterTrap",
            desc = "Trampa + Separación",
            body = [[#showtooltip Trampa congelante
/cast Trampa congelante
/cast [mod:shift] Separación]],
            spec = 0,
            author = "Sequito",
            rating = 4
        },
        {
            name = "SeqHunterPet",
            desc = "Control de mascota",
            body = [[#showtooltip
/petattack [nomod]
/petfollow [mod:shift]
/petpassive [mod:ctrl]
/cast [mod:alt] Intimidación]],
            spec = 0,
            author = "Sequito",
            rating = 5
        },
    },
    
    -- ROGUE
    ["ROGUE"] = {
        {
            name = "SeqRogueTricks",
            desc = "Tricks of the Trade",
            body = [[#showtooltip Secretos del oficio
/cast [target=focus,help,exists] Secretos del oficio
/cast [target=targettarget,help] Secretos del oficio
/s Secretos para %t...]],
            spec = 0,
            author = "Sequito",
            rating = 5
        },
        {
            name = "SeqRogueKick",
            desc = "Kick inteligente",
            body = [[#showtooltip Patada
/stopcasting
/cast [target=focus,exists,harm] Patada
/cast [target=mouseover,exists,harm] Patada
/cast Patada]],
            spec = 0,
            author = "Sequito",
            rating = 5
        },
        {
            name = "SeqRogueStealth",
            desc = "Stealth + Premeditation",
            body = [[#showtooltip Sigilo
/cast [nostealth] Sigilo
/cast [stealth] Premeditación
/cast [stealth] Paso de las sombras]],
            spec = 0,
            author = "Sequito",
            rating = 4
        },
    },
    
    -- PRIEST
    ["PRIEST"] = {
        {
            name = "SeqPriestDispel",
            desc = "Dispel inteligente",
            body = [[#showtooltip Disipar magia
/cast [target=mouseover,help,exists] Suprimir enfermedad
/cast [target=mouseover,harm,exists] Disipar magia
/cast [help] Suprimir enfermedad
/cast [harm] Disipar magia]],
            spec = 0,
            author = "Sequito",
            rating = 5
        },
        {
            name = "SeqPriestShield",
            desc = "Escudo mouseover",
            body = [[#showtooltip Palabra de poder: escudo
/cast [target=mouseover,help,exists] Palabra de poder: escudo
/cast [help] Palabra de poder: escudo
/cast [target=player] Palabra de poder: escudo]],
            spec = 1, -- Discipline
            author = "Sequito",
            rating = 5
        },
        {
            name = "SeqPriestShadow",
            desc = "DoT Shadow",
            body = [[#showtooltip
/castsequence reset=target Toque vampírico, Palabra de las Sombras: dolor, Peste devoradora, Tortura mental]],
            spec = 3, -- Shadow
            author = "Sequito",
            rating = 4
        },
    },
    
    -- WARRIOR
    ["WARRIOR"] = {
        {
            name = "SeqWarriorCharge",
            desc = "Charge/Intercept/Intervene combo",
            body = [[#showtooltip
/cast [stance:1] Cargar
/cast [stance:2] Intervenir
/cast [stance:3] Interceptar]],
            spec = 0,
            author = "Sequito",
            rating = 5
        },
        {
            name = "SeqWarriorTaunt",
            desc = "Taunt con anuncio",
            body = [[#showtooltip Mofa
/cast Mofa
/s ¡TAUNT en %t!]],
            spec = 2, -- Protection
            author = "Sequito",
            rating = 4
        },
        {
            name = "SeqWarriorPummel",
            desc = "Interrupción de hechizo inteligente",
            body = [[#showtooltip Zurrar
/stopcasting
/cast [target=focus,exists,harm] Zurrar
/cast [target=mouseover,exists,harm] Zurrar
/cast Zurrar]],
            spec = 0,
            author = "Sequito",
            rating = 5
        },
    },
    
    -- SHAMAN
    ["SHAMAN"] = {
        {
            name = "SeqShamanLust",
            desc = "Bloodlust/Heroism con anuncio",
            body = [[#showtooltip
/cast Ansia de sangre
/cast Heroísmo
/y ¡¡LUST/HERO!! ¡A QUEMAR!]],
            spec = 0,
            author = "Sequito",
            rating = 5
        },
        {
            name = "SeqShamanPurge",
            desc = "Purge inteligente",
            body = [[#showtooltip Purgar
/cast [target=focus,exists,harm] Purgar
/cast [target=mouseover,exists,harm] Purgar
/cast Purgar]],
            spec = 0,
            author = "Sequito",
            rating = 5
        },
        {
            name = "SeqShamanHeal",
            desc = "Heal Chain mouseover",
            body = [[#showtooltip Sanación en cadena
/cast [target=mouseover,help,exists] Sanación en cadena
/cast [help] Sanación en cadena
/cast [target=player] Sanación en cadena]],
            spec = 3, -- Restoration
            author = "Sequito",
            rating = 5
        },
    },
    
    -- DRUID
    ["DRUID"] = {
        {
            name = "SeqDruidBrez",
            desc = "Battle Rez con anuncio",
            body = [[#showtooltip Renacer
/cast [target=mouseover,help,dead] Renacer
/cast [help,dead] Renacer
/s ¡Resucitando a %t! ¡Acepta rápido!]],
            spec = 0,
            author = "Sequito",
            rating = 5
        },
        {
            name = "SeqDruidInnervate",
            desc = "Innervate inteligente",
            body = [[#showtooltip Estimular
/cast [target=mouseover,help,exists] Estimular
/cast [help] Estimular
/cast [target=player] Estimular
/s ¡Innervate en %t!]],
            spec = 0,
            author = "Sequito",
            rating = 5
        },
        {
            name = "SeqDruidFeral",
            desc = "Feral Combo",
            body = [[#showtooltip
/cast [nostealth,nocombat] Acechar
/cast [stealth] Devastar
/cast [nostealth,combo:5] Mordedura feroz
/cast [nostealth] Triturar]],
            spec = 2, -- Feral
            author = "Sequito",
            rating = 4
        },
        {
            name = "SeqDruidMoonkin",
            desc = "Moonkin Burst",
            body = [[#showtooltip Fuerza de la Naturaleza
/use 10
/use 13
/use 14
/cast Fuerza de la Naturaleza
/cast Fuego estelar]],
            spec = 1, -- Balance
            author = "Sequito",
            rating = 5
        },
    },
}

-- ===========================================================================
-- INICIALIZACIÓN
-- ===========================================================================

-- Helper para obtener configuración
function S.MacroSync:GetOption(key)
    if S.ModuleConfig then
        return S.ModuleConfig:GetValue("MacroSync", key)
    end
    return true
end

function S.MacroSync:Initialize()
    if not self:GetOption("enabled") then
        return
    end
    
    -- Registrar prefijo de addon
    if RegisterAddonMessagePrefix then
        RegisterAddonMessagePrefix(self.Prefix)
    end
    
    -- Frame de eventos
    local frame = CreateFrame("Frame")
    frame:RegisterEvent("CHAT_MSG_ADDON")
    frame:RegisterEvent("PLAYER_ENTERING_WORLD")
    
    frame:SetScript("OnEvent", function(self, event, ...)
        S.MacroSync:OnEvent(event, ...)
    end)
    
    -- Cargar macros guardados
    self:LoadSavedMacros()
    
    print("|cFFFF00FFSequito|r: [MacroSync] Sistema de macros compartidos iniciado.")
end

function S.MacroSync:OnEvent(event, ...)
    if event == "CHAT_MSG_ADDON" then
        local prefix, msg, channel, sender = ...
        if prefix == self.Prefix then
            if sender == UnitName("player") then return end
            if S.ReceiveChunkedAddonMessage then
                S:ReceiveChunkedAddonMessage(prefix, msg, sender, function(completeMsg, sdr)
                    S.MacroSync:ParseMessage(completeMsg, sdr)
                end)
            else
                self:ParseMessage(msg, sender)
            end
        end
    elseif event == "PLAYER_ENTERING_WORLD" then
        -- Delay para asegurar que DB esté cargada
        local frame = CreateFrame("Frame")
        frame.elapsed = 0
        frame:SetScript("OnUpdate", function(self, elapsed)
            self.elapsed = self.elapsed + elapsed
            if self.elapsed >= 3 then
                S.MacroSync:LoadSavedMacros()
                self:SetScript("OnUpdate", nil)
            end
        end)
    end
end

-- ===========================================================================
-- COMUNICACIÓN
-- ===========================================================================
function S.MacroSync:Broadcast(msg)
    if S.SendChunkedAddonMessage then
        if GetNumRaidMembers() > 0 then
            S:SendChunkedAddonMessage(self.Prefix, msg, "RAID")
        elseif GetNumPartyMembers() > 0 then
            S:SendChunkedAddonMessage(self.Prefix, msg, "PARTY")
        end
    else
        if GetNumRaidMembers() > 0 then
            SendAddonMessage(self.Prefix, msg, "RAID")
        elseif GetNumPartyMembers() > 0 then
            SendAddonMessage(self.Prefix, msg, "PARTY")
        end
    end
end

function S.MacroSync:SendWhisper(msg, target)
    if S.SendChunkedAddonMessage then
        S:SendChunkedAddonMessage(self.Prefix, msg, "WHISPER", target)
    else
        SendAddonMessage(self.Prefix, msg, "WHISPER", target)
    end
end

function S.MacroSync:ParseMessage(msg, sender)
    local cmd, payload = strsplit(":", msg, 2)
    
    if cmd == "SHARE" then
        self:OnMacroReceived(payload, sender)
    elseif cmd == "REQUEST" then
        self:OnMacroRequest(payload, sender)
    elseif cmd == "LIST" then
        self:OnListRequest(sender)
    elseif cmd == "LISTRESPONSE" then
        self:OnListResponse(payload, sender)
    end
end

-- ===========================================================================
-- COMPARTIR MACROS
-- ===========================================================================
function S.MacroSync:ShareMacro(macroName)
    local macroID = GetMacroIndexByName(macroName)
    if macroID == 0 then
        print("|cFFFF0000Sequito|r: Macro '" .. macroName .. "' no encontrado.")
        return
    end
    
    local name, icon, body = GetMacroInfo(macroID)
    if not body then return end
    
    -- Codificar el macro (nombre|body)
    -- Reemplazar | por §§ para evitar conflictos
    local encodedBody = body:gsub("|", "§§")
    local msg = string.format("SHARE:%s|%s", name, encodedBody)
    
    self:Broadcast(msg)
    print("|cFFFF00FFSequito|r: Macro '" .. name .. "' compartido con el grupo.")
end

function S.MacroSync:OnMacroReceived(payload, sender)
    local name, encodedBody = strsplit("|", payload, 2)
    if not name or not encodedBody then return end
    
    -- Decodificar
    local body = encodedBody:gsub("§§", "|")
    
    -- Guardar en SharedMacros
    self.SharedMacros[name] = {
        body = body,
        sender = sender,
        timestamp = time()
    }
    
    -- Guardar en DB
    self:SaveSharedMacro(name, body, sender)
    
    print(string.format("|cFF00FF00Sequito|r: Macro '%s' recibido de %s. Usa /sequito macro import %s", 
        name, sender, name))
end

-- ===========================================================================
-- IMPORTAR/EXPORTAR
-- ===========================================================================
function S.MacroSync:ImportMacro(macroName)
    local data = self.SharedMacros[macroName]
    if not data then
        print("|cFFFF0000Sequito|r: Macro '" .. macroName .. "' no encontrado en macros compartidos.")
        return
    end
    
    -- Crear el macro
    if S.MacroGen and S.MacroGen.CreateMacro then
        S.MacroGen:CreateMacro(macroName, 1, data.body)
    else
        CreateMacro(macroName, 1, data.body, 1)
    end
    print("|cFF00FF00Sequito|r: Macro '" .. macroName .. "' importado exitosamente.")
end

function S.MacroSync:ListSharedMacros()
    print("|cFFFF00FF=== Macros Compartidos ===|r")
    local count = 0
    for name, data in pairs(self.SharedMacros) do
        count = count + 1
        print(string.format("  %d. |cFF00FFFF%s|r (de %s)", count, name, data.sender))
    end
    if count == 0 then
        print("  No hay macros compartidos.")
    end
end

-- ===========================================================================
-- BIBLIOTECA DE MACROS
-- ===========================================================================
function S.MacroSync:GetClassMacros(class)
    return self.ClassLibrary[class] or {}
end

function S.MacroSync:ListLibraryMacros(class, spec)
    local _, playerClass = UnitClass("player")
    class = class or playerClass
    
    local macros = self:GetClassMacros(class)
    if #macros == 0 then
        print("|cFFFF0000Sequito|r: No hay macros en la biblioteca para " .. class)
        return
    end
    
    print("|cFFFF00FF=== Biblioteca de Macros: " .. class .. " ===|r")
    for i, macro in ipairs(macros) do
        local specText = macro.spec == 0 and "Todas" or ("Spec " .. macro.spec)
        local stars = string.rep("★", macro.rating)
        
        -- Filtrar por spec si se especifica
        if not spec or spec == 0 or macro.spec == 0 or macro.spec == spec then
            print(string.format("  %d. |cFF00FFFF%s|r - %s [%s] %s", 
                i, macro.name, macro.desc, specText, stars))
        end
    end
end

function S.MacroSync:ImportFromLibrary(macroName)
    local _, class = UnitClass("player")
    local macros = self:GetClassMacros(class)
    
    for _, macro in ipairs(macros) do
        if macro.name == macroName then
            if S.MacroGen and S.MacroGen.CreateMacro then
                S.MacroGen:CreateMacro(macro.name, 1, macro.body)
            else
                CreateMacro(macro.name, 1, macro.body, 1)
            end
            print("|cFF00FF00Sequito|r: Macro '" .. macro.name .. "' importado de la biblioteca.")
            return
        end
    end
    
    print("|cFFFF0000Sequito|r: Macro '" .. macroName .. "' no encontrado en la biblioteca.")
end

function S.MacroSync:ImportAllFromLibrary(spec)
    local _, class = UnitClass("player")
    local macros = self:GetClassMacros(class)
    local count = 0
    
    for _, macro in ipairs(macros) do
        if not spec or spec == 0 or macro.spec == 0 or macro.spec == spec then
            if S.MacroGen and S.MacroGen.CreateMacro then
                S.MacroGen:CreateMacro(macro.name, 1, macro.body)
                count = count + 1
            else
                CreateMacro(macro.name, 1, macro.body, 1)
                count = count + 1
            end
        end
    end
    
    print(string.format("|cFF00FF00Sequito|r: %d macros importados de la biblioteca.", count))
end

-- ===========================================================================
-- PERSISTENCIA
-- ===========================================================================
function S.MacroSync:LoadSavedMacros()
    if S.db and S.db.profile and S.db.profile.SharedMacros then
        self.SharedMacros = S.db.profile.SharedMacros
    end
end

function S.MacroSync:SaveSharedMacro(name, body, sender)
    if not S.db or not S.db.profile then return end
    
    S.db.profile.SharedMacros = S.db.profile.SharedMacros or {}
    S.db.profile.SharedMacros[name] = {
        body = body,
        sender = sender,
        timestamp = time()
    }
end

-- ===========================================================================
-- SOLICITAR MACROS
-- ===========================================================================
function S.MacroSync:RequestMacroList()
    self:Broadcast("LIST:")
    print("|cFFFF00FFSequito|r: Solicitando lista de macros del grupo...")
end

function S.MacroSync:OnListRequest(sender)
    -- Enviar lista de nuestros macros Seq*
    local macroList = {}
    local numAccount, numChar = GetNumMacros()
    
    for i = 121, 120 + numChar do
        local name = GetMacroInfo(i)
        if name and name:sub(1,3) == "Seq" then
            table.insert(macroList, name)
        end
    end
    
    if #macroList > 0 then
        local msg = "LISTRESPONSE:" .. table.concat(macroList, ",")
        self:SendWhisper(msg, sender)
    end
end

function S.MacroSync:OnListResponse(payload, sender)
    local macros = {strsplit(",", payload)}
    print(string.format("|cFF00FFFFSequito|r: Macros de %s:", sender))
    for i, name in ipairs(macros) do
        print(string.format("  %d. %s", i, name))
    end
    print("|cFFFFFF00Usa /sequito macro request <nombre> <jugador> para solicitar uno.|r")
end

function S.MacroSync:RequestMacro(macroName, target)
    local msg = "REQUEST:" .. macroName
    self:SendWhisper(msg, target)
    print("|cFFFF00FFSequito|r: Solicitando macro '" .. macroName .. "' a " .. target)
end

function S.MacroSync:OnMacroRequest(macroName, sender)
    local macroID = GetMacroIndexByName(macroName)
    if macroID == 0 then return end
    
    local name, icon, body = GetMacroInfo(macroID)
    if not body then return end
    
    local encodedBody = body:gsub("|", "§§")
    local msg = string.format("SHARE:%s|%s", name, encodedBody)
    self:SendWhisper(msg, sender)
    
    print("|cFFFF00FFSequito|r: Macro '" .. name .. "' enviado a " .. sender)
end

-- ===========================================================================
-- REGISTRO EN MODULECONFIG
-- ===========================================================================
if S.ModuleConfig then
    S.ModuleConfig:RegisterModule("MacroSync", {
        name = "Sincronización de Macros",
        description = "Comparte y sincroniza macros con otros jugadores de Sequito. Incluye biblioteca de macros por clase.",
        category = "utility",
        icon = "Interface\\Icons\\INV_Misc_Book_11",
        options = {
            {
                key = "enabled",
                type = "checkbox",
                label = "Habilitar MacroSync",
                tooltip = "Activa el sistema de sincronización de macros",
                default = true
            },
            {
                key = "autoShare",
                type = "checkbox",
                label = "Compartir automáticamente",
                tooltip = "Comparte automáticamente macros nuevos con el grupo",
                default = false
            },
            {
                key = "announceReceived",
                type = "checkbox",
                label = "Anunciar macros recibidos",
                tooltip = "Muestra mensaje cuando recibes un macro compartido",
                default = true
            },
            {
                key = "importToCharacter",
                type = "checkbox",
                label = "Importar a macros de personaje",
                tooltip = "Importa macros recibidos a macros de personaje en lugar de cuenta",
                default = true
            },
            {
                key = "showLibrary",
                type = "checkbox",
                label = "Mostrar biblioteca de clase",
                tooltip = "Muestra la biblioteca de macros recomendados para tu clase",
                default = true
            }
        }
    })
end

-- ===========================================================================
-- INICIALIZACIÓN AUTOMÁTICA
-- ===========================================================================
local initFrame = CreateFrame("Frame")
initFrame:RegisterEvent("ADDON_LOADED")
initFrame:SetScript("OnEvent", function(self, event, addon)
    if addon == addonName then
        -- Delay para asegurar que S.db esté disponible
        local delayFrame = CreateFrame("Frame")
        delayFrame.elapsed = 0
        delayFrame:SetScript("OnUpdate", function(self, elapsed)
            self.elapsed = self.elapsed + elapsed
            if self.elapsed >= 2 then
                S.MacroSync:Initialize()
                self:SetScript("OnUpdate", nil)
            end
        end)
    end
end)
