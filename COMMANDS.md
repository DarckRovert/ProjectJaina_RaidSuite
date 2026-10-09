# 💬 Lista Completa de Comandos - Project Jaina RaidSuite

**Versión:** 10.2.0 (Definitive Edition)  
**Autor:** DarckRovert (Ingame: Elnazzareno) & Antigravity (Mythos 5)

---

## 🆕 Comandos v10.2.0 (Definitive Edition)
- `/smacros` (`/jaina macros`) - (Macros) Genera y sincroniza macros inteligentes Necrosis de clase y spec en la pestaña de personaje.
- `/jaina inspect` (`/sinspect`) - (Academy) Inspecciona talentos, GearScore real y encantamientos.
- `/shumor` - (Humor) Controla y prueba las frases cómicas de incursión y actividades de banda.
- `/jaina gallery` - (Gamification) Abre la galería de loot legendario.
- `/jaina sync config` - (Hive Mind) Panel de configuración remota (Solo Oficiales).
- `/jaina sync strat` - (Hive Mind) Enviar estrategia de boss (Solo Oficiales).

---

## 📝 Comandos Principales

Jaina acepta dos prefijos de comando:
- `/jaina [comando]`
- `/jaina [comando]` (atajo)

---

## 🆘 Ayuda e Información

### `/jaina help`
**Alias:** `/jaina help`, `/jaina ?`

**Descripción:** Muestra la lista de comandos disponibles.

**Ejemplo:**
```
/jaina help
```

---

### `/jaina info`
**Alias:** `/jaina info`

**Descripción:** Muestra información sobre tu personaje (clase, raza, especialización, nivel).

**Ejemplo:**
```
/jaina info
```

**Salida:**
```
Clase: Warlock (Brujo)
Raza: Orc (Orco)
Especialización: Affliction
Nivel: 80
Recurso: Mana (15420/18500)
```

---

### `/jaina spec`
**Alias:** `/jaina spec`

**Descripción:** Muestra información detallada de tu especialización actual.

**Ejemplo:**
```
/jaina spec
```

**Salida:**
```
Especialización Activa: 1 (Affliction)
Grupo de Talentos: 1 de 2
Rol: DPS
```

---

## 🔧 Generación de Macros

### `/jaina macros`
**Alias:** `/smacros`, `/jaina macros`, `/jaina macro`

**Descripción:** Genera macros personalizadas estilo **Necrosis** para tu clase y especialización actual.

**Ejemplo:**
```
/jaina macros
```

**Salida:**
```
Jaina: Regenerando macros (Necrosis Edition Final) para WARLOCK...
✅ Macro creada: SeqStart
✅ Macro creada: SeqHeal
✅ Macro creada: SeqPet
✅ Macro creada: SeqDispel
✅ Macro creada: SeqRot
✅ Macro creada: SeqBurst
✅ Macro creada: SeqRacial
✅ Macro creada: SeqMount
Macros generadas exitosamente!
```

**Notas:**
- Las macros se crean con nombres cortos como `SeqStart`, `SeqPet`.
- Si ya existen macros con el mismo nombre, se sobrescribirán.
- **Auto-Update**: Si tienes activado `specauto`, esto ocurre automáticamente al cambiar talentos.

---

### `/jaina specauto`
**Alias:** `/jaina specauto`, `/jaina autospec`

**Descripción:** Activa/desactiva la regeneración automática de macros al cambiar de especialización.

**Ejemplo:**
```
/jaina specauto
```

**Salida:**
```
Auto-actualización de macros: ACTIVADA
```

---

## 👥 Comandos de Raid

### `/jaina raid`
**Alias:** `/jaina raid`, `/jaina r`

**Descripción:** Muestra la composición actual de la raid (clases y especializaciones).

*(Ver USAGE.md para más detalles)*

---

### `/jaina class`
**Alias:** `/jaina class`, `/jaina classes`

**Descripción:** Muestra el conteo de clases en la raid.

---

### `/jaina buffs`
**Alias:** `/jaina buffs`, `/jaina buff`

**Descripción:** Escanea la raid en busca de buffs faltantes.

---

### `/jaina focus [nombre]`
**Alias:** `/jaina focus [nombre]`, `/jaina f [nombre]`

**Descripción:** Envía una orden táctica a la raid para enfocar un objetivo específico.

**Ejemplo:**
```
/jaina focus Ragnaros
```

---

### `/jaina alpha`
**Alias:** `/jaina alpha`, `/jaina burst`

**Descripción:** Envía una orden de "Alpha Strike" (usar todos los cooldowns de DPS).

---

## 📊 Panel de Raid

### `/jaina panel`
**Alias:** `/jaina panel`, `/jaina p`

**Descripción:** Abre/cierra el panel visual de raid.

---

### `/jaina lock`
**Alias:** `/jaina lock`

**Descripción:** Bloquea/desbloquea la posición del panel de raid.

---

### `/jaina reset`
**Alias:** `/jaina reset`

**Descripción:** Restaura TODA la configuración del addon a los valores por defecto y recarga la interfaz.

---

### `/jaina resetpos`
**Alias:** `/jaina resetpos`

**Descripción:** Reinicia solo la posición del panel de raid y la esfera al centro de la pantalla.

---

## 🐎 Sistema de Monturas

### `/jaina mounts`
**Alias:** `/jaina mounts`, `/jaina monturas`

**Descripción:** Lista todas las monturas disponibles y tus monturas favoritas configuradas.

**Ejemplo:**
```
/jaina mounts
```

---

### `/jaina setflying [nombre]` / `/jaina setground [nombre]`
Configura tus monturas favoritas para la macro `SeqMount`.

---

## ⚙️ Configuración

### `/jaina options`
**Alias:** `/jaina options`, `/jaina config`, `/jaina opt`

**Descripción:** Abre el panel de configuración del addon.

---

## 📝 Atajos de Comandos

| Comando Completo | Atajo | Descripción |
|-----------------|-------|-------------|
| `/jaina help` | `/jaina ?` | Ayuda |
| `/jaina info` | `/jaina i` | Info del personaje |
| `/jaina macros` | `/jaina m` | Generar macros |
| `/jaina raid` | `/jaina r` | Composición de raid |
| `/jaina panel` | `/jaina p` | Panel de raid |
| `/jaina focus` | `/jaina f` | Orden de focus |
| `/jaina options` | `/jaina opt` | Configuración |
| `/jaina combat` | `/jaina dps` | Resumen de combate |
| `/jaina version` | `/jaina v` | Versión |

---

## 📊 CooldownMonitor - Monitor de CDs

### `/jaina cooldowns`
**Alias:** `/jaina cd`
**Descripción:** Abre/cierra el panel de cooldowns del raid.

### `/jaina cd bres`
**Descripción:** Anuncia los Battle Res disponibles en el raid.
**Ejemplo de salida:**
```
[Jaina] BRES disponibles: Druid1 (Rebirth), Warlock1 (Soulstone)
```

### `/jaina cd lust`
**Descripción:** Anuncia si Heroism/Bloodlust está disponible.

### `/jaina cd raid`
**Descripción:** Anuncia todos los Raid CDs disponibles.

---

## 🎯 Assignments - Asignaciones

### `/jaina assign`
**Alias:** `/jaina as`
**Descripción:** Abre el panel de asignaciones.

### `/jaina assign interrupts`
**Descripción:** Auto-asigna rotación de interrupts basada en clases disponibles.
**Ejemplo de salida:**
```
[Jaina] Rotación de Interrupts: 1. Shaman1 → 2. Rogue1 → 3. Warrior1
```

### `/jaina assign tanks`
**Descripción:** Abre el panel para asignar tanks a objetivos.

### `/jaina assign announce`
**Descripción:** Anuncia todas las asignaciones actuales al raid.

### `/jaina assign clear`
**Descripción:** Limpia todas las asignaciones.

### `/jaina assign sync`
**Descripción:** Sincroniza asignaciones con otros usuarios de Jaina.

---

## ✅ ReadyChecker - Chequeo Pre-Pull

### `/jaina readycheck`
**Alias:** `/jaina rc`
**Descripción:** Abre el panel de ready check mejorado y escanea el raid.

### `/jaina readycheck full`
**Descripción:** Escanea y anuncia problemas al raid.
**Ejemplo de salida:**
```
[Jaina] Problemas detectados:
  - Rogue1: Veneno MH, Veneno OH
  - Warlock1: Sin Flask
  - Mage1: Mana: 65%
```

### `/jaina readycheck scan`
**Descripción:** Solo escanea sin abrir panel.

---

## 🎯 RaidAssist

### `/jaina ra` o `/jaina raidassist`
**Descripción:** Abre el panel principal de RaidAssist.

### `/jaina raleader`
**Descripción:** Abre el panel compacto de Raid Leader.

### `/jaina pull [segundos]`
**Descripción:** Inicia un pull timer sincronizado.
**Ejemplo:** `/jaina pull 10`

### `/jaina phase [número]`
**Descripción:** Anuncia una fase de boss a todo el raid.
**Ejemplo:** `/jaina phase 2`

### `/jaina checkcons`
**Descripción:** Revisa consumibles (flask/food) de todos los miembros.

### `/jaina wipes`
**Descripción:** Muestra el contador de wipes de la sesión.

### `/jaina resetwipes`
**Descripción:** Reinicia el contador de wipes.

### `/jaina mode [farm/progression]`
**Descripción:** Cambia el modo de operación.

### `/jaina wipehistory`
**Descripción:** Muestra el historial completo de wipes con estadísticas.

### `/jaina clearwipes`
**Descripción:** Borra el historial de wipes guardado.

### `/jaina alert [mensaje]`
**Descripción:** Muestra una alerta de prueba.

### `/jaina alertpos [top/center/bottom]`
**Descripción:** Cambia la posición de las alertas en pantalla.

---

## 🔄 MacroSync - Macros Compartidos

### `/jaina macro share <nombre>`
**Descripción:** Comparte un macro con tu grupo/raid.
**Ejemplo:** `/jaina macro share SeqBurst`

### `/jaina macro list`
**Descripción:** Lista los macros compartidos que has recibido.

### `/jaina macro import <nombre>`
**Descripción:** Importa un macro compartido a tus macros.
**Ejemplo:** `/jaina macro import SeqBurst`

### `/jaina macro library`
**Descripción:** Muestra la biblioteca de macros para tu clase/spec.

### `/jaina macro libraryall`
**Descripción:** Muestra toda la biblioteca de macros para tu clase.

### `/jaina macro getlib <nombre>`
**Descripción:** Importa un macro de la biblioteca.
**Ejemplo:** `/jaina macro getlib SeqDotAll`

### `/jaina macro getall`
**Descripción:** Importa todos los macros de la biblioteca para tu spec.

### `/jaina macro request`
**Descripción:** Solicita la lista de macros disponibles del grupo.

### `/jaina macro get <nombre> <jugador>`
**Descripción:** Solicita un macro específico de otro jugador.
**Ejemplo:** `/jaina macro get SeqBurst Elnazzareno`

---

## ⚔️ TrinketTracker - PvP

### `/jaina trinkets`
**Alias:** `/jaina tt`
**Descripción:** Abre/cierra el panel de tracking de trinkets enemigos.

### `/jaina trinkets clear`
**Descripción:** Limpia todos los datos del tracker.

### `/jaina trinkets announce`
**Descripción:** Anuncia el estado de todos los trinkets enemigos al grupo.
**Ejemplo de salida:**
```
[Jaina] Trinkets en CD: Enemigo1 (1:45), Enemigo2 (0:30)
[Jaina] Trinkets LISTOS: Enemigo3, Enemigo4
```

---

## 💀 WipeAnalyzer - Análisis de Wipes

### `/jaina analyze`
**Alias:** `/jaina wa`
**Descripción:** Muestra el análisis del último wipe detectado.

### `/jaina analyze announce`
**Descripción:** Anuncia el análisis del wipe al raid/party.
**Ejemplo de salida:**
```
[Jaina] === ANÁLISIS DE WIPE ===
Primera muerte: Jugador1 (15.3s) - Shadow Bolt de Boss
Sin poción/healthstone: Jugador2, Jugador3
Total muertes: 8 | Interrupts: 5
```

### `/jaina wipehistory`
**Descripción:** Muestra el historial de wipes de la sesión.

### `/jaina clearwipes`
**Descripción:** Limpia el historial de wipes.

---

## 📊 Tabla de Comandos de Raid

| Comando | Atajo | Descripción |
|---------|-------|-------------|
| `/jaina trinkets` | `/jaina tt` | Panel de trinkets PvP |
| `/jaina trinkets clear` | - | Limpiar tracker |
| `/jaina trinkets announce` | - | Anunciar trinkets |
| `/jaina analyze` | `/jaina wa` | Análisis de wipe |
| `/jaina analyze announce` | - | Anunciar análisis |
| `/jaina wipehistory` | - | Historial de wipes |
| `/jaina clearwipes` | - | Limpiar historial |

---

## ⚔️ Comandos PvP

### `/jaina focus`
**Alias:** `/jaina ff`
**Descripción:** Abre el panel de FocusFire para llamadas de target.

### `/jaina focus call`
**Descripción:** Llama al target actual como objetivo de focus fire.

### `/jaina cc`
**Alias:** `/jaina cc`
**Descripción:** Abre el panel de CCCoordinator.

### `/jaina cc assign <jugador> <target>`
**Descripción:** Asigna un CC a un jugador para un target específico.

### `/jaina healers`
**Alias:** `/jaina ht`
**Descripción:** Abre el panel de HealerTracker.

### `/jaina defensive`
**Alias:** `/jaina def`
**Descripción:** Abre el panel de DefensiveAlerts.

### `/jaina defensive peel`
**Descripción:** Anuncia que necesitas peel.

### `/jaina defensive heal`
**Descripción:** Anuncia que necesitas heal.

---

## 🏰 Comandos Mazmorras

### `/jaina pullguide`
**Alias:** `/jaina pg`
**Descripción:** Abre el panel de PullGuide.

### `/jaina pullguide mark`
**Descripción:** Auto-marca el pack actual.

### `/jaina dungeon`
**Alias:** `/jaina dt`
**Descripción:** Abre el panel de DungeonTimer.

### `/jaina loot`
**Alias:** `/jaina lc`
**Descripción:** Abre el panel de LootCouncil.

### `/jaina loot start`
**Descripción:** Inicia una sesión de loot council.

---

## 👥 Comandos Generales

### `/jaina notes add <jugador> <texto>`
**Alias:** `/jaina pn add`
**Descripción:** Guarda una nota sobre un jugador.

### `/jaina build save <nombre>`
**Descripción:** Guarda tu build actual con un nombre.

### `/jaina build load <nombre>`
**Descripción:** Carga un build guardado.

### `/jaina build share <nombre>`
**Descripción:** Comparte un build con el grupo.

### `/jaina calendar`
**Alias:** `/jaina cal`
**Descripción:** Abre el panel de EventCalendar.

### `/jaina stats`
**Alias:** `/jaina ps`
**Descripción:** Muestra tus estadísticas de rendimiento.

### `/jaina poll "<pregunta>" opcion1 opcion2 ...`
**Alias:** `/jaina vote`
**Descripción:** Crea una votación rápida.
**Ejemplo:**
```
/jaina poll "¿Seguimos o paramos?" Seguir Parar
```

### `/jaina version`
**Alias:** `/jaina ver`
**Descripción:** Verifica versiones de Jaina en el grupo.

### `/jaina whisper <template>`
**Alias:** `/jaina qw`
**Descripción:** Envía un mensaje rápido predefinido.
**Templates disponibles:** inv, afk, summon, ready, brb

---

## 📜 Lista de Comandos - Jaina v10.0
> **Nota:** La mayoría de estas funciones ahora son accesibles desde el **Dashboard** (Icono de Minimapa).

## 🚀 Comandos Principales (v10.0)

| Comando | Descripción |
|---------|-------------|
| `/jaina` | Abre el **Dashboard Unificado** (Config, Raid, Tools). |
| `/jaina report` | Abre **Jaina Connect** (Exportar datos y perfiles). |
| `/jaina options` | (Legacy) Abre la pestaña de configuración directamente. |
| `/jaina panel` | (Legacy) Abre el panel de raid directamente. |

## 🛠️ Herramientas de Raid (Hive Mind)

| Comando | Descripción | Rango Requerido |
|---------|-------------|-----------------|
| `/jaina sync` | Fuerza una sincronización completa con la raid. | Oficial/RL |
| `/jaina sync config` | Abre la ventana de configuración remota. | Oficial/RL |
| `/jaina sync strat` | Abre el editor de estrategias de boss. | Oficial/RL |
| `/jaina veto [jugador]` | Bloquea a un jugador del sistema de sincronización. | Oficial/RL |
| `/jaina pull [seg]` | Inicia una cuenta atrás de pull (ej: 10s). | Cualquiera |
| `/jaina ready` | Inicia una comprobación de listos. | Oficial/RL |

## 🎓 Academy Mode

| Comando | Descripción |
|---------|-------------|
| `/jaina inspect` | Abre el **Inspector de Academia** (Talentos/Gear real de target). |
| `/jaina gallery` | Abre la **Galería de Loot** legendario. |

## ⚔️ Combate, Alertas y PvP

| Comando | Descripción |
|---------|-------------|
| `/jaina spy` | Alterna la interfaz de **JainaSpy** (detección de sigilo y enemigos). |
| `/jaina focusfire` (o `/jaina ff`) | Abre el panel de Focus Fire sincronizado. |
| `/jaina ff call` | Llama y marca con calavera al objetivo actual. |
| `/jaina overlord` (o `/jaina hud`) | Abre el configurador del HUD **The Overlord**. |
| `/jaina alert [mensaje]` | Muestra una alerta táctica de prueba en pantalla. |
| `/jaina alertpos [TOP/CENTER/BOTTOM]` | Modifica la posición en pantalla de las alertas de banda. |
| `/jaina checkbuffs` (o `/jaina checkcons`) | Genera y muestra el reporte de consumibles y buffs de raid. |
| `/jaina combatclear` | Limpia el historial de daño y sanación del CombatTracker. |
| `/jaina mode [FARM/PROGRESSION]` | Alterna el modo operativo de la raid (Farmeo vs Progresión). |
| `/jaina phase [número/nombre]` | Anuncia un cambio de fase del jefe de banda. |

## 🐎 Gestión de Monturas Favoritas

| Comando | Descripción |
|---------|-------------|
| `/jaina mounts` (o `/jaina monturas`) | Lista las monturas registradas del personaje. |
| `/jaina setflying [nombre]` | Define la montura voladora preferida para macros. |
| `/jaina setground [nombre]` | Define la montura terrestre preferida para macros. |
| `/jaina setaquatic [nombre]` | Define la montura acuática preferida para macros. |

## ⚙️ Utilidades y Mantenimiento

| Comando | Descripción |
|---------|-------------|
| `/jaina version` (o `/jaina vs`) | Muestra y compara versiones del addon en la banda. |
| `/jaina sync` | Solicita o transmite el estado de sincronización. |
| `/jaina whisper [1/2/3]` | Envía plantillas de susurro rápido o abre el panel. |
| `/jaina notes` | Administrador de notas persistentes sobre jugadores. |
| `/jaina build` | Gestor de árboles de talentos y configuraciones de glifos. |
| `/jaina reset` (o `/jaina resetpos`) | Restablece la posición centrada de la esfera principal. |
| `/jaina lock` | Bloquea o desbloquea la posición de la esfera en pantalla. |
| `/smacros` (o `/jaina macros`) | Genera y sincroniza las macros Necrosis inteligentes de clase/spec. |
| `/shumor` | Muestra la ayuda y estado del módulo de Frases Cómicas de Incursión. |
| `/shumor toggle` | Activa o desactiva las frases cómicas en actividades. |
| `/shumor channel [SAY/PARTY/RAID/YELL]` | Establece el canal de chat para la emisión de frases. |
| `/shumor test [CATEGORIA]` | Prueba una frase cómica en el chat (ej. `SUMMON`, `BATTLE_REZ`). |
| `/rl` | Recarga la interfaz del juego (`ReloadUI()`). |

---

**Creado por DarckRovert (Ingame: Elnazzareno) & Antigravity (Mythos 5)**
