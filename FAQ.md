# ❓ Preguntas Frecuentes (FAQ) - Project Jaina RaidSuite

**Versión:** 10.2.0 (Definitive Edition)  
**Autor:** DarckRovert (Ingame: Elnazzareno) & Project Jaina Team  
**Servidor Destino:** [Project Jaina](https://projectjaina.com/) - Project Jaina  
**Cliente:** World of Warcraft 3.3.5a (Build 12340)

---

## 📚 Índice Rápido

1. [General y Filosofía del Ecosistema](#1-general-y-filosofía-del-ecosistema)
2. [Instalación y Configuración Inicial](#2-instalación-y-configuración-inicial)
3. [La Esfera Central y el Dashboard (/sdash)](#3-la-esfera-central-y-el-dashboard-sdash)
4. [El Motor de Macros Inteligente (SeqRot)](#4-el-motor-de-macros-inteligente-seqrot)
5. [Modo Academia y Alertas de PROC (/srot, /sinspect)](#5-modo-academia-y-alertas-de-proc-srot-sinspect)
6. [Concilio de Botín (Loot Council) e Inclusión de Pugs](#6-concilio-de-botín-loot-council-e-inclusión-de-pugs)
7. [Malla de Clan en Vivo (ClanMesh) y Seguridad de Red](#7-malla-de-clan-en-vivo-clanmesh-y-seguridad-de-red)
8. [Auditoría de Combate y Análisis de Wipes (/sstats, /swipe)](#8-auditoría-de-combate-y-análisis-de-wipes-sstats-swipe)
9. [Rendimiento, Memoria y FPS](#9-rendimiento-memoria-y-fps)
10. [Compatibilidad con Otros Addons y Servidores](#10-compatibilidad-con-otros-addons-y-servidores)
11. [Solución de Problemas (Troubleshooting)](#11-solución-de-problemas-troubleshooting)

---

## 1. General y Filosofía del Ecosistema

### ¿Qué es exactamente el ecosistema Jaina?
Jaina no es un simple medidor de DPS ni un botón aislado. Es una **suite modular integral** diseñada para WoW 3.3.5a que unifica:
- Un **Dashboard central** de 4 pestañas (/sdash) con resumen del cónclave, logros, rotación y galería de tesoros.
- Una **Esfera Central flotante** con menú radial interactivo.
- Un **motor de macros inteligente** para las 10 clases y 30 especializaciones de Wrath of the Lich King.
- Un **Modo Academia** con cálculo nativo de GearScore 3.3.5a, auditoría de encantamientos y HUD con alertas de **PROC** en verde esmeralda.
- Un **Concilio de Botín híbrido** que detecta automáticamente caídas épicas e integra las tiradas de dados (/azar 100 o /roll) de jugadores que no tengan el addon.
- **Malla de Clan (ClanMesh)** que sincroniza a toda la hermandad en vivo por canal GUILD, RAID o PARTY.
- **Analítica de Wipes** y métricas de rendimiento en combate (CLEU).

### ¿Jaina automatiza las habilidades de mi personaje o es considerado trampa?
**NO.** Jaina **no es un bot ni automatiza hechizos**. Cumple al 100% con la política y términos de servicio de Blizzard y servidores privados:
- No ejecuta hechizos automáticamente en el juego.
- Genera macros legales nativas de WoW que **tú debes pulsar manualmente con tu teclado o ratón**.
- Muestra sugerencias visuales de prioridades y alertas de buffs/procs que tú decides cuándo activar.

### ¿Quién creó el addon y a qué servidor pertenece?
El proyecto fue creado y desarrollado por **DarckRovert (en el juego: Elnazzareno)** y el equipo técnico de **Project Jaina** para el servidor oficial [Project Jaina](https://projectjaina.com/) (Project Jaina).

---

## 2. Instalación y Configuración Inicial

### ¿Dónde debo colocar la carpeta del addon?
La carpeta debe llamarse exactamente `Wanos_RaidSuite` y residir en la ruta de addons de tu cliente:
```
Interface\AddOns\ProjectJaina_RaidSuite\
```
Asegúrate de que el archivo Wanos_RaidSuite.toc esté directamente dentro de Interface\AddOns\ProjectJaina_RaidSuite\ y no dentro de subcarpetas anidadas como Wanos_RaidSuite\Wanos_RaidSuite\.

### ¿El addon funciona de inmediato al entrar o requiere configuración compleja?
Funciona **de inmediato**. Al iniciar sesión, Jaina:
1. Detecta automáticamente tu clase, talentos y especialización activa.
2. Inicializa la Esfera Central flotante y el icono del minimapa.
3. Conecta con los canales de hermandad y grupo disponibles.
4. Genera o sincroniza las macros óptimas para tu personaje.

---

## 3. La Esfera Central y el Dashboard (/sdash)

### ¿Cómo abro el Dashboard principal?
Puedes abrirlo de dos formas muy sencillas:
1. Haciendo **clic izquierdo sobre la Esfera Central flotante**.
2. Escribiendo en el chat: /sdash (o /sequito).

### ¿Cómo muevo la Esfera Central si me tapa parte de la pantalla?
Mantén presionada la tecla **Shift**, haz **clic izquierdo sobre la esfera y arrástrala** con el ratón a la posición que más te guste. Jaina recordará la ubicación exacta incluso tras cerrar el juego o hacer /reload.

### ¿Para qué sirve el clic derecho en la Esfera?
El **clic derecho** despliega el **Menú Radial**, ofreciéndote accesos rápidos en abanico para invocar monturas, activar utilidades de clase, abrir profesiones o iniciar comprobaciones de banda.

### ¿Qué encuentro en las 4 pestañas del Dashboard?
1. **Resumen:** Estado de tu personaje (rol, talentos, spec) y del cónclave de banda (jugadores conectados, salud promedio, distribución de clases y botones de chequeo rápido).
2. **Logros:** Galería de proezas y metas de hermandad alcanzadas en raids de WotLK (Naxxramas, Ulduar, Sagrario Obsidiana, Sagrario Rubí, ICC).
3. **Rotación:** Guía de prioridades de tu especialización y botón de activación del HUD flotante.
4. **Tesoros:** Catálogo de piezas de botín de alto valor obtenidas y registradas por el clan.

---

## 4. El Motor de Macros Inteligente (SeqRot)

### ¿Por qué Jaina no utiliza /castsequence en sus macros?
Las macros clásicas de /castsequence son rígidas y propensas a bloquearse. Si un objetivo se sale de rango o una habilidad no conecta, la secuencia completa queda congelada impidiéndote lanzar cualquier otro ataque.

Jaina soluciona esto mediante un **motor de prioridades con teclas modificadoras ([mod:shift], [mod:ctrl], [mod:alt])**:
- **Pulsación directa (sin modificador):** Ejecuta tu ataque primario o habilidad de relleno (iller), activa el ataque automático (/startattack) y ordena el ataque de tu mascota (/petattack).
- **Shift:** Lanza DoTs de apertura, finishers o daño explosivo (*burst*).
- **Ctrl:** Lanza tu habilidad secundaria de alta prioridad o recarga rápida.
- **Alt:** Habilidad de fase de ejecución (como *Ejecutar* o *Drenar alma*), área o cooldown mayor.

### ¿Cómo obtengo la macro SeqRot en mi barra de acción?
1. Escribe /sequito macros en el chat (o pulsa el botón en el Dashboard).
2. Abre tu panel de macros presionando Escape -> Macros o escribiendo /m.
3. Selecciona la pestaña **Macros de [Nombre de tu Personaje]**.
4. Arrastra la macro llamada **SeqRot** a tu botón de combate principal (por ejemplo, la tecla 1).

### ¿Qué ocurre cuando cambio a mi Especialización Dual o cambio talentos?
El sistema detecta el evento del cliente inmediatamente y **actualiza el contenido de SeqRot en tiempo real** para adaptarse a tu nuevo rol, sin necesidad de que borres ni reorganices tus barras de acción.

### ¿Cómo benefician las macros a los Sanadores (Healers)?
Las macros de sanador integran automáticamente condiciones de cursor inteligente ([@mouseover,help] [@target,help] [@player]):
- Si pasas el cursor sobre el marco de banda de un compañero, le lanzará la cura directamente sin quitar tu objetivo actual del jefe.
- Si no hay nadie bajo el cursor, curará a tu objetivo seleccionado o a ti mismo.

### ¿Cómo funcionan las macros para Druidas Ferales (Oso y Gato)?
Integran condiciones de postura automáticas:
- Si estás en **Forma de Oso ([form:1])**, la macro adopta las prioridades de tanqueo (*Magullar*, *Destrozar oso*, *Lacerar*).
- Si estás en **Forma Felina ([form:3])**, la macro adopta la rotación de daño (*Destrozar gato*, *Destripar*, *Mordedura feroz*).

### ¿Qué macros complementarias genera Jaina?
- **SeqInt:** Interrupción de casteo en tu objetivo; si mantienes **Shift**, interrumpe a tu objetivo en **Foco** sin deseleccionar a tu objetivo principal.
- **SeqCC:** Habilidad de control de masas (*Polimorfia*, *Miedo*, *Ceguera*, *Ciclón*, etc.) con soporte de cursor o foco.
- **SeqMount:** Invoca automáticamente montura voladora en zonas que lo admiten (Rasganorte/Terrallende), montura terrestre en interiores/mazmorras, o te desmonta al instante si estás en montura.
- **SeqRacial:** Tu habilidad racial con un grito inmersivo del Jaina.

---

## 5. Modo Academia y Alertas de PROC (/srot, /sinspect)

### ¿Cómo abro el Asesor de Rotación flotante?
Escribe /srot o /srotation. Aparecerá una barra delgada y elegante con los iconos de tus habilidades principales y sus tiempos de reutilización.

### ¿Qué son las alertas de PROC y cómo identificarlas?
Cuando un talento clave se activa en combate (como *Buena racha* en Magos, *El arte de la guerra* en Paladines, *Oleada de sangre* en Guerreros, *Escarcha blanca* en DKs, o *Diezmar* en Brujos):
- El marco de la habilidad se enciende con un **borde brillante de color verde esmeralda**.
- Aparece la etiqueta **PROC!** sobre el icono.
- Esto te avisa al instante de que dispones de un lanzamiento instantáneo o bonificado que no debes desperdiciar.

### ¿Cómo funciona el Inspector de Academia (/sinspect)?
Selecciona a cualquier jugador y escribe /sinspect:
1. **Inspección asíncrona:** Solicita los talentos del jugador al servidor sin colgarse por lag (INSPECT_TALENT_READY).
2. **GearScore 3.3.5a oficial:** Calcula el puntaje de equipo ponderado respetando los multiplicadores nativos de Wrath of the Lich King (armas principales x2, piezas mayores x1, accesorios x0.56).
3. **Auditoría de Encantamientos:** Revisa si la armadura del jugador carece de encantamientos en ranuras cruciales (cabeza, hombros, pecho, piernas, pies, muñecas, manos, capa y armas), facilitando a los oficiales auditar a los reclutas antes de entrar a raid.

---

## 6. Concilio de Botín (Loot Council) e Inclusión de Pugs

### ¿Cómo se inicia una sesión de Concilio de Botín?
- **Automática:** Al matar a un jefe y abrir su ventana de despojo (`LOOT_OPENED`), Jaina escanea el botín y **encola automáticamente todas las piezas épicas o legendarias**.
- **Cola de Botín:** Al finalizar de votar un objeto, el concilio pasa de inmediato a la siguiente pieza en cola sin necesidad de reabrir el cadáver ni escribir comandos.
- **Manual:** Los oficiales pueden abrir el panel en cualquier momento con `/sloot` o `/sequito lc`.

### ¿Cómo responden los miembros de la banda?
La ventana ofrece 4 botones dedicados:
- **Main Spec (MS):** Para tu especialización y rol principal.
- **Off Spec (OS):** Para tu segunda especialización.
- **Mejora:** Para mejoras secundarias.
- **Pasar:** Si no necesitas el objeto.

### ¿Cómo ayuda el addon a los oficiales a no equivocarse de clase o armadura?
- **Auditoría de Armadura:** Detecta si la pieza es Placas, Malla, Cuero o Tela y la contrasta con la clase del jugador, señalando `[Armadura Óptima]`, `[Equipable]` o `[No Equipable]`.
- **Marcas de Santificación (Tier Tokens):** Valida si la marca corresponde a la clase del aspirante (*Vencedor*, *Protector*, *Conquistador*), previniendo despojos erróneos de piezas de tier en ICC y ToC.

### ¿Cómo entrega el botín el Maestro Despojador?
El Maestro Despojador dispone de un botón verde **`[Dar]`** en la fila de cada candidato. Al presionarlo, Jaina invoca directamente la API de Blizzard `GiveMasterLoot`, pasando el ítem a la mochila del ganador en un solo clic si el cadáver sigue abierto.

### ¿Qué pasa si un jugador del grupo o pug NO tiene Jaina instalado?
**No hay ningún problema.** Jaina está diseñado para la convivencia total en la comunidad:
- El addon escucha de fondo el canal del juego (`CHAT_MSG_SYSTEM`).
- Cuando un jugador escribe `/azar 100` o `/roll` en el chat (soportando clientes en español o inglés), Jaina intercepta su tirada numérica y **lo añade automáticamente a la lista de candidatos con su número exacto obtenido**.
- De este modo, los oficiales pueden tomar decisiones justas considerando a toda la banda, tengan o no el addon instalado.

### ¿Cómo se garantiza la transparencia y qué pasa en caso de empate?
- Solo los oficiales con rango verificado (`rank >= 1`) pueden emitir votos.
- Cada oficial cuenta con **un único voto por objeto**. Si pulsa sobre otro candidato, su voto anterior se retira automáticamente y se traslada al nuevo.
- **Desempate Automático:** Si dos candidatos quedan empatados en votos oficiales, Jaina compara sus tiradas de dados para desempatar con imparcialidad.
- **Temporizador Visual:** Cuenta regresiva en pantalla de 60s (ajustable) con anuncio de tiempo agotado.

---

## 7. Malla de Clan en Vivo (ClanMesh) y Seguridad de Red

### ¿Cómo funciona la sincronización si los miembros están en sitios distintos?
A diferencia de addons convencionales que solo sincronizan dentro de la misma banda, Jaina utiliza el canal de hermandad (GUILD):
- Los avisos estratégicos de jefes, notas de oficiales y marcaciones tácticas se transmiten a todos los miembros conectados de la hermandad.
- Puedes estar comprando suministros en Dalaran o completando misiones diarias y seguir recibiendo la sincronización táctica de tu clan.

### ¿Por qué Jaina nunca provoca desconexiones por exceso de mensajes (*flood kick*)?
El cliente de WoW 3.3.5a desconecta a los jugadores si un addon envía demasiados mensajes en un mismo instante.  
Jaina incorpora un algoritmo de **transmisión por goteo con cubeta de fugas (*leaky bucket*)**:
- Los mensajes grandes se dividen en fragmentos de tamaño seguro.
- Cada paquete se transmite con una pausa de 80 milisegundos.
- Esto garantiza una tasa de transferencia continua y segura, previniendo al 100% las caídas por saturación de red.

### ¿Cuáles son las órdenes tácticas de banda?
- /sfocus [Nombre] o /sequito focus: Marca un objetivo prioritario para que toda la banda cambie de foco de ataque al unísono.
- /salpha o /sequito alpha: Orden de desatar habilidades de daño máximo (*Burst/Cooldowns*).
- /sready o /sequito ready: Comprobación de listos con verificación de frascos y comida.

---

## 8. Auditoría de Combate y Análisis de Wipes (/sstats, /swipe)

### ¿Cómo veo el rendimiento en combate?
Escribe /sstats o /sequito stats. Muestra el daño por segundo (DPS) y la sanación neta efectiva (HPS), descontando la sobresanación (*overhealing*) gracias al motor de procesamiento de eventos de combate (COMBAT_LOG_EVENT_UNFILTERED).

### ¿Qué información entrega el Analizador de Wipes (/swipe)?
Cuando la banda es derrotada, Jaina registra una autopsia precisa del enfrentamiento:
- **Primera Muerte:** Quién fue el primer jugador en morir y qué habilidad o golpe del jefe causó su deceso.
- **Uso de Recursos Defensivos:** Señala si el jugador murió conservando su Poción de Vida o Piedra de Salud disponible en inventario.
- **Cortes de Casteo:** Reporta si hubo habilidades mortales del jefe que no fueron interrumpidas a tiempo.
- **Alertas de Patrón:** Si un jugador muere repetidamente por la misma mecánica en varios intentos consecutivos, el sistema emite una recomendación para corregir la posición o mecánica.

---

## 9. Rendimiento, Memoria y FPS

### ¿Jaina consume mucha memoria o provocará caídas de FPS en raids de 25 personas?
**Absolutamente no.** Jaina está construido bajo estrictos estándares de ingeniería para clientes de 32 bits:
- Consumo medio de memoria RAM: inferior a 3.5 MB.
- Las funciones de actualización periódica no se ejecutan en cada cuadro de dibujo (*frame rate* a 144 Hz), sino que cuentan con acumuladores de tiempo restringidos a **20 Hz** (cada 0.05 a 0.2 segundos según el módulo).
- Todas las tablas de eventos de combate limpian automáticamente los registros de combates anteriores para evitar acumulación de memoria.

---

## 10. Compatibilidad con Otros Addons y Servidores

### ¿Puedo usar Jaina junto con DBM (Deadly Boss Mods), Recount, Skada o Details?
**Sí, perfectamente.** Jaina ha sido diseñado como un ciudadano respetuoso del entorno de WoW:
- No sobrescribe variables globales de otros addons.
- Sus marcos y HUDs están aislados en sus propios estratos de interfaz.
- Complementa la labor de DBM aportando analítica de hermandad y macros que DBM no provee.

### ¿En qué servidores y clientes de WoW funciona Jaina?
Está optimizado principalmente para **Project Jaina (Project Jaina)**, y es 100% compatible con cualquier servidor privado basado en el cliente **World of Warcraft 3.3.5a (Build 12340)**, incluyendo Warmane, Dalaran-WoW, ChromieCraft, etc.

---

## 11. Solución de Problemas (Troubleshooting)

### La Esfera o alguna ventana quedó fuera de la pantalla. ¿Cómo la recupero?
Escribe en el chat:
`
/sequito reset
`
Este comando reubica la Esfera Central y todos los paneles flotantes en el centro exacto de tu monitor.

### El comando /sequito macros indica que no hay espacio suficiente.
El cliente de WoW 3.3.5a posee un límite rígido de 18 macros específicas por personaje.  
Si tienes tu panel de macros lleno con 18 macros previas:
1. Escribe /macro o /m.
2. Revisa la pestaña de tu personaje y elimina las macros viejas que ya no uses.
3. Vuelve a ejecutar /sequito macros.

### ¿Dónde puedo reportar un error o proponer una idea?
Si encuentras un comportamiento anómalo o deseas sugerir una funcionalidad:
- Contacta a **DarckRovert** (Ingame: **Elnazzareno**) en Project Jaina.
- Abre un issue o pull request en el repositorio oficial de GitHub:  
  [https://github.com/DarckRovert/Wanos_RaidSuite](https://github.com/DarckRovert/Wanos_RaidSuite)

---

*¡Por Project Jaina - Project Jaina!*
