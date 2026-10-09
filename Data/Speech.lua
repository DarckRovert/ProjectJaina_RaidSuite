--[[
    SEQUITO - Speech Database (Flavor Text)
]]--

local addonName, S = ...
S.Data = S.Data or {}
S.Data.Speech = {}

-- Basic Flavors
S.Data.Speech.Summon = {
    "¡Taxi Arcano! Por favor, dadle click al portal o no nos vamos nunca.",
    "Abriendo un agujero en el espacio-tiempo...",
    "¡Venid a mí, esbirros! (Click en el portal)",
    "Servicio de invocación 'Jaina Express' activo.",
    "Invocando a los perezosos. ¡Haced click en el armario!",
    "No tengo todo el día, tocad el portal.",
    "He traído el portal. Traed las galletas.",
    "¡Por el poder del vacío, os invoco!",
    "Ritual de pereza iniciado. Click, por favor.",
}

S.Data.Speech.Soulstone = {
    "He guardado el alma de <target>. Ya puedes morir tranquilo.",
    "<target> tiene una Piedra del Alma. ¡Aprovechadla!",
    "No te preocupes <target>, la muerte es solo el principio.",
    "¡Tu alma es mía, <target>! (Guardada por si acaso)",
    "Contrato firmado: <target> tiene permiso para morir una vez.",
    "¡<target> ha sido respaldado en la nube!",
    "Seguro de vida activado para <target>.",
    "Si mueres, <target>, recuerda que yo te salvé.",
}

S.Data.Speech.Mount = {
    "¡A cabalgar!",
    "¡Por la Horda! (O la Alianza, lo que sea...)",
    "Invocando montura de la muerte...",
    "Me voy, mi planeta me necesita.",
    "¡Corred, insensatos!",
    "Activando modo turbo...",
    "¡Yihaaa!",
}

S.Data.Speech.Resurrect = {
    "¡Levántate, <target>! ¡Aún no he terminado contigo!",
    "¡Vuelve a la vida, gusano!",
    "La muerte te rechaza, <target>.",
    "Arriba, <target>, que el suelo está frío.",
    "¡<target> vive! (Más o menos).",
    "¡No te hagas el muerto, <target>!",
    "Desfibrilador mágico... ¡YA!",
}

S.Data.Speech.Nightfall = {
    "¡Las sombras responden! ¡OCASO!",
    "¡El vacío me bendice! ¡Shadow Bolt gratis!",
    "¡La oscuridad me favorece!",
    "¡Proc de Ocaso! ¡A darle!",
    "¡Las estrellas se alinean... SHADOW BOLT!",
}

S.Data.Speech.Backlash = {
    "¡Contragolpe activado! ¡Tu error, mi ganancia!",
    "¡Me golpeas y gano poder! ¡BACKLASH!",
    "¡Gracias por el proc, idiota!",
    "¡Shadow Bolt instantáneo cortesía del enemigo!",
}

S.Data.Speech.Banish = {
    "¡Al vacío contigo, <target>!",
    "¡Desterrado! No vuelvas hasta que yo diga.",
    "¡<target> ha sido enviado al rincón de pensar!",
    "¡Fuera de mi vista, <target>!",
    "¡<target> necesita un tiempo fuera!",
}

S.Data.Speech.Enslave = {
    "¡Ahora eres mío, <target>! ¡Obedece!",
    "¡<target> trabaja para mí ahora!",
    "¡Esclavizado! Bienvenido al equipo, <target>.",
    "¡Tu voluntad ya no es tuya, <target>!",
}

S.Data.Speech.Fear = {
    "¡Corre, <target>! ¡CORRE!",
    "¡El miedo te consume, <target>!",
    "¡Huye mientras puedas, <target>!",
    "¡<target> ha visto cosas que no debería!",
    "¡Boo! ¿Asustado, <target>?",
}

-- ============================================
-- DEATH KNIGHT
-- ============================================
S.Data.Speech.RaiseDead = {
    "¡Levántate, mi sirviente! ¡Sirve a tu amo!",
    "¡De las tumbas os invoco! ¡Alzaos!",
    "¡La muerte no es el final... es el comienzo del servicio!",
    "¡Otro más para mi ejército de no-muertos!",
    "¡Ghoul, a mis órdenes!",
}

S.Data.Speech.ArmyOfDead = {
    "¡EJÉRCITO DE LA MUERTE! ¡ALZAOS, SOLDADOS CAÍDOS!",
    "¡Temed mi ejército! ¡Cada tumba es un recluta!",
    "¡La tierra tiembla! ¡Los muertos responden a mi llamada!",
    "¡Legión de cadáveres, marchad! ¡DESTRUID!",
    "¡Os presento a mis amigos... vienen de abajo!",
}

S.Data.Speech.DeathGrip = {
    "¡VEN AQUÍ, <target>!",
    "¡No escaparás de mí, <target>!",
    "¡Te tengo, <target>! ¡A mis pies!",
    "¡La muerte te reclama, <target>!",
    "¡<target> ha sido convocado ante mí!",
}

S.Data.Speech.AntiMagic = {
    "¡Tu magia no me afecta!",
    "¡Caparazón Anti-Magia activado! ¡Soy inmune!",
    "¡Lanzadme lo que queráis! ¡No me toca nada!",
    "¡La magia rebota en mí como en una pared!",
}

-- ============================================
-- PALADIN
-- ============================================
S.Data.Speech.LayOnHands = {
    "¡LA LUZ TE LLENA, <target>! ¡Imposición de Manos!",
    "¡No morirás hoy, <target>! ¡Vida completa!",
    "¡El poder de la Luz restaura a <target>!",
    "¡Imposición de Manos! ¡<target> ha renacido!",
    "¡Curación TOTAL para <target>! ¡Gracias a la Luz!",
}

S.Data.Speech.DivineShield = {
    "¡BURBUJA! ¡Soy invencible!",
    "¡Escudo Divino activado! ¡No me tocáis!",
    "¡La Luz me protege! ¡Ni un rasguño!",
    "¡Burbuja activada! (Momento de comer pollo)",
    "¡Intocable! ¡La Luz es mi escudo!",
}

S.Data.Speech.HandOfProtection = {
    "¡Mano de Protección sobre <target>! ¡Estás a salvo!",
    "¡<target> está protegido por la Luz! ¡No le toques!",
    "¡Burbuja para <target>! De nada.",
    "¡<target> es inmune al daño físico! ¡Aguanta!",
}

-- ============================================
-- PRIEST
-- ============================================
S.Data.Speech.MassDispel = {
    "¡Disipación masiva! ¡Fuera buffs!",
    "¡PURIFICACIÓN EN ÁREA! ¡Nada se salva!",
    "¡He limpiado toda la zona! De nada.",
    "¡Mass Dispel! ¿Burbujas? ¿Cuáles burbujas?",
}

S.Data.Speech.PowerInfusion = {
    "¡Infusión de Poder para <target>! ¡A TOPE!",
    "¡<target> está potenciado! ¡Velocidad máxima de casteo!",
    "¡<target> acaba de recibir la turbo! ¡DALE!",
    "¡Power Infusion en <target>! ¡Aprovéchalo!",
}

S.Data.Speech.GuardianSpirit = {
    "¡Espíritu Guardián protege a <target>! ¡No puedes morir!",
    "¡<target> tiene un ángel guardián! Literalmente.",
    "¡Si <target> baja a 0... ¡REVIVE automáticamente!",
    "¡Espíritu Guardián activado! <target> es inmortal (por 10 seg).",
}

-- ============================================
-- HUNTER
-- ============================================
S.Data.Speech.Misdirection = {
    "¡Dirección Errónea en <target>! ¡Todo el aggro para ti!",
    "¡<target>, te regalo el aggro! Disfrútalo.",
    "¡Misdirection! El tank no sabe lo que le espera...",
    "¡<target>, prepárate! ¡Va todo para ti!",
    "¡Le he pasado la factura del aggro a <target>!",
}

S.Data.Speech.FeignDeath = {
    "¡Me hago el muerto! (Profesionalmente)",
    "¡No estoy muerto! ¡Solo... descansando!",
    "¡Hacerse el muerto es un arte! Y yo soy Picasso.",
    "¡Los muertos no generan aggro! *guiño*",
}

-- ============================================
-- MAGE
-- ============================================
S.Data.Speech.Polymorph = {
    "¡<target> es ahora una oveja! ¡NO LA TOQUÉIS!",
    "¡Metamorfosis en <target>! ¡Beeee!",
    "¡<target> necesitaba un cambio de look!",
    "¡Polimorfia! <target> dice: Beeee.",
    "¡CC en <target>! ¡Si alguien lo rompe, lo vuelvo oveja a él!",
}

S.Data.Speech.IceBlock = {
    "¡BLOQUE DE HIELO! ¡Tiempo fuera!",
    "¡Estoy congelado por elección! ¡No entren en pánico!",
    "¡Hielo, hielo, baby! ¡Inmune total!",
    "¡Refrigeración activada! ¡Estoy a bajo cero!",
    "¡Frozen! (No la peli, el hechizo)",
}

-- ============================================
-- ROGUE
-- ============================================
S.Data.Speech.TricksOfTrade = {
    "¡Trucos del Oficio en <target>! ¡Dale duro que el aggro es suyo!",
    "¡<target>, te he regalado mi amenaza! Úsala bien.",
    "¡Tricks en <target>! ¡A reventar DPS!",
    "¡Traspaso de amenaza a <target>! ¡De nada, tank!",
}

S.Data.Speech.Vanish = {
    "¡ESFUMARSE! ¡Ahora me ves... ahora no!",
    "¡He desaparecido! ¡Como mi DPS cuando wipeamos!",
    "¡Vanish! ¡El aggro es problema de otro!",
    "¡Humo ninja activado! ¡Adiós, problemas!",
    "¡Poof! ¿Me echabais de menos?",
}

S.Data.Speech.Sap = {
    "¡<target> ha sido noqueado! ¡Silencio!",
    "¡Sap en <target>! ¡NO LO DESPIERTEN!",
    "¡<target> se ha ido a dormir! Shhhh...",
    "¡Golpe Certero! <target> descansa en paz... temporalmente.",
}

-- ============================================
-- WARRIOR
-- ============================================
S.Data.Speech.Intervene = {
    "¡INTERCEDER por <target>! ¡Yo recibo el golpe!",
    "¡No toques a <target>! ¡El golpe es para mí!",
    "¡Me interpongo! ¡<target> está bajo mi protección!",
    "¡Intervención! Porque los tanks somos así de heroicos.",
}

S.Data.Speech.Taunt = {
    "¡Provocar! ¡EH, TÚ! ¡MÍRAME A MÍ!",
    "¡Tu madre era un murloc y tu padre olía a gnomo!",
    "¡VEN AQUÍ! ¡Soy más interesante que el healer!",
    "¡Taunt! ¡Deja de pegar al mago, animal!",
    "¡OYE, BICHO FEO! ¡Pégame a mí!",
}

-- ============================================
-- DRUID
-- ============================================
S.Data.Speech.Innervate = {
    "¡Estimular en <target>! ¡Maná infinito por 10 segundos!",
    "¡<target>, disfruta el maná gratis! Cortesía de la naturaleza.",
    "¡Innervate para <target>! ¡Castea como si no hubiera mañana!",
    "¡<target> ha sido recargado! ¡Batería al 100%!",
}

S.Data.Speech.Tranquility = {
    "¡TRANQUILIDAD! ¡Curación masiva activada!",
    "¡Todos cálmense! ¡La naturaleza nos sana!",
    "¡Canal de curación AoE! ¡No me interrumpan!",
    "¡Tranquility! ¡Lluvia de vida para todos!",
    "¡CURACIÓN PARA TODOS! ¡Naturaleza, haz lo tuyo!",
}

-- ============================================
-- SHAMAN
-- ============================================
S.Data.Speech.Heroism = {
    "¡HEROÍSMO! ¡TODOS A TOPE! ¡¡DALE DALE DALE!!",
    "¡BLOODLUST! ¡30 SEGUNDOS DE GLORIA! ¡A REVENTAR!",
    "¡HEROÍSMO ACTIVADO! ¡DPS A MÁXIMA POTENCIA!",
    "¡¡LUUUUST!! ¡Pégale como si debiera oro!",
    "¡HÉROE MODE: ON! ¡A romper medidores!",
}

S.Data.Speech.Ankh = {
    "¡He vuelto de la muerte! ¡Reencarnación!",
    "¡Ankh usado! ¡La muerte es solo un inconveniente menor!",
    "¡Resurjo como el fénix! (Bueno, como un chamán)",
    "¡Auto-resurrect! ¡Los espíritus me aman!",
    "¡No me esperaban de vuelta tan pronto, ¿eh?!",
}

-- Helpers
function S:GetRandomSpeech(category)
    local tbl = S.Data.Speech[category]
    if tbl then
        return tbl[math.random(#tbl)]
    end
    return nil
end
