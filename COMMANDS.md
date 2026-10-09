# 💬 Lista Completa de Comandos - Project Jaina RaidSuite

**Versión:** 10.2.0 (Definitive Edition)  
**Autor:** DarckRovert (Ingame: Elnazzareno) & Project Jaina Team

---

## 🆕 Comandos v10.2.0 (Definitive Edition)
- `/smacros` (`/sequito macros`) - (Macros) Genera y sincroniza macros inteligentes Necrosis de clase y spec en la pestaña de personaje.
- `/sequito inspect` (`/sinspect`) - (Academy) Inspecciona talentos, GearScore real y encantamientos.
- `/shumor` - (Humor) Controla y prueba las frases cómicas de incursión y actividades de banda.
- `/sequito gallery` - (Gamification) Abre la galería de loot legendario.
- `/sequito sync config` - (Hive Mind) Panel de configuración remota (Solo Oficiales).
- `/sequito sync strat` - (Hive Mind) Enviar estrategia de boss (Solo Oficiales).

---

## 📝 Comandos Principales

Jaina acepta dos prefijos de comando:
- `/sequito [comando]`
- `/seq [comando]` (atajo)

---

## 🆘 Ayuda e Información

### `/sequito help`
**Alias:** `/seq help`, `/sequito ?`

**Descripción:** Muestra la lista de comandos disponibles.

**Ejemplo:**
```
/sequito help
```

---

### `/sequito info`
**Alias:** `/seq info`

**Descripción:** Muestra información sobre tu personaje (clase, raza, especialización, nivel).

**Ejemplo:**
```
/sequito info
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

### `/sequito spec`
**Alias:** `/seq spec`

**Descripción:** Muestra información detallada de tu especialización actual.

**Ejemplo:**
```
/sequito spec
```

**Salida:**
```
Especialización Activa: 1 (Affliction)
Grupo de Talentos: 1 de 2
Rol: DPS
```

---

## 🔧 Generación de Macros

### `/sequito macros`
**Alias:** `/smacros`, `/seq macros`, `/sequito macro`

**Descripción:** Genera macros personalizadas estilo **Necrosis** para tu clase y especialización actual.

**Ejemplo:**
```
/sequito macros
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

### `/sequito specauto`
**Alias:** `/seq specauto`, `/sequito autospec`

**Descripción:** Activa/desactiva la regeneración automática de macros al cambiar de especialización.

**Ejemplo:**
```
/sequito specauto
```

**Salida:**
```
Auto-actualización de macros: ACTIVADA
```

---

## 👥 Comandos de Raid

### `/sequito raid`
**Alias:** `/seq raid`, `/sequito r`

**Descripción:** Muestra la composición actual de la raid (clases y especializaciones).

*(Ver USAGE.md para más detalles)*

---

### `/sequito class`
**Alias:** `/seq class`, `/sequito classes`

**Descripción:** Muestra el conteo de clases en la raid.

---

### `/sequito buffs`
**Alias:** `/seq buffs`, `/sequito buff`

**Descripción:** Escanea la raid en busca de buffs faltantes.

---

### `/sequito focus [nombre]`
**Alias:** `/seq focus [nombre]`, `/sequito f [nombre]`

**Descripción:** Envía una orden táctica a la raid para enfocar un objetivo específico.

**Ejemplo:**
```
/sequito focus Ragnaros
```

---

### `/sequito alpha`
**Alias:** `/seq alpha`, `/sequito burst`

**Descripción:** Envía una orden de "Alpha Strike" (usar todos los cooldowns de DPS).

---

## 📊 Panel de Raid

### `/sequito panel`
**Alias:** `/seq panel`, `/sequito p`

**Descripción:** Abre/cierra el panel visual de raid.

---

### `/sequito lock`
**Alias:** `/seq lock`

**Descripción:** Bloquea/desbloquea la posición del panel de raid.

---

### `/sequito reset`
**Alias:** `/seq reset`

**Descripción:** Restaura TODA la configuración del addon a los valores por defecto y recarga la interfaz.

---

### `/sequito resetpos`
**Alias:** `/seq resetpos`

**Descripción:** Reinicia solo la posición del panel de raid y la esfera al centro de la pantalla.

---

## 🐎 Sistema de Monturas

### `/sequito mounts`
**Alias:** `/seq mounts`, `/sequito monturas`

**Descripción:** Lista todas las monturas disponibles y tus monturas favoritas configuradas.

**Ejemplo:**
```
/sequito mounts
```

---

### `/sequito setflying [nombre]` / `/sequito setground [nombre]`
Configura tus monturas favoritas para la macro `SeqMount`.

---

## ⚙️ Configuración

### `/sequito options`
**Alias:** `/seq options`, `/sequito config`, `/seq opt`

**Descripción:** Abre el panel de configuración del addon.

---

## 📝 Atajos de Comandos

| Comando Completo | Atajo | Descripción |
|-----------------|-------|-------------|
| `/sequito help` | `/seq ?` | Ayuda |
| `/sequito info` | `/seq i` | Info del personaje |
| `/sequito macros` | `/seq m` | Generar macros |
| `/sequito raid` | `/seq r` | Composición de raid |
| `/sequito panel` | `/seq p` | Panel de raid |
| `/sequito focus` | `/seq f` | Orden de focus |
| `/sequito options` | `/seq opt` | Configuración |
| `/sequito combat` | `/seq dps` | Resumen de combate |
| `/sequito version` | `/seq v` | Versión |

---

## 📊 CooldownMonitor - Monitor de CDs

### `/sequito cooldowns`
**Alias:** `/seq cd`
**Descripción:** Abre/cierra el panel de cooldowns del raid.

### `/sequito cd bres`
**Descripción:** Anuncia los Battle Res disponibles en el raid.
**Ejemplo de salida:**
```
[Jaina] BRES disponibles: Druid1 (Rebirth), Warlock1 (Soulstone)
```

### `/sequito cd lust`
**Descripción:** Anuncia si Heroism/Bloodlust está disponible.

### `/sequito cd raid`
**Descripción:** Anuncia todos los Raid CDs disponibles.

---

## 🎯 Assignments - Asignaciones

### `/sequito assign`
**Alias:** `/seq as`
**Descripción:** Abre el panel de asignaciones.

### `/sequito assign interrupts`
**Descripción:** Auto-asigna rotación de interrupts basada en clases disponibles.
**Ejemplo de salida:**
```
[Jaina] Rotación de Interrupts: 1. Shaman1 → 2. Rogue1 → 3. Warrior1
```

### `/sequito assign tanks`
**Descripción:** Abre el panel para asignar tanks a objetivos.

### `/sequito assign announce`
**Descripción:** Anuncia todas las asignaciones actuales al raid.

### `/sequito assign clear`
**Descripción:** Limpia todas las asignaciones.

### `/sequito assign sync`
**Descripción:** Sincroniza asignaciones con otros usuarios de Jaina.

---

## ✅ ReadyChecker - Chequeo Pre-Pull

### `/sequito readycheck`
**Alias:** `/seq rc`
**Descripción:** Abre el panel de ready check mejorado y escanea el raid.

### `/sequito readycheck full`
**Descripción:** Escanea y anuncia problemas al raid.
**Ejemplo de salida:**
```
[Jaina] Problemas detectados:
  - Rogue1: Veneno MH, Veneno OH
  - Warlock1: Sin Flask
  - Mage1: Mana: 65%
```

### `/sequito readycheck scan`
**Descripción:** Solo escanea sin abrir panel.

---

## 🎯 RaidAssist

### `/sequito ra` o `/sequito raidassist`
**Descripción:** Abre el panel principal de RaidAssist.

### `/sequito raleader`
**Descripción:** Abre el panel compacto de Raid Leader.

### `/sequito pull [segundos]`
**Descripción:** Inicia un pull timer sincronizado.
**Ejemplo:** `/sequito pull 10`

### `/sequito phase [número]`
**Descripción:** Anuncia una fase de boss a todo el raid.
**Ejemplo:** `/sequito phase 2`

### `/sequito checkcons`
**Descripción:** Revisa consumibles (flask/food) de todos los miembros.

### `/sequito wipes`
**Descripción:** Muestra el contador de wipes de la sesión.

### `/sequito resetwipes`
**Descripción:** Reinicia el contador de wipes.

### `/sequito mode [farm/progression]`
**Descripción:** Cambia el modo de operación.

### `/sequito wipehistory`
**Descripción:** Muestra el historial completo de wipes con estadísticas.

### `/sequito clearwipes`
**Descripción:** Borra el historial de wipes guardado.

### `/sequito alert [mensaje]`
**Descripción:** Muestra una alerta de prueba.

### `/sequito alertpos [top/center/bottom]`
**Descripción:** Cambia la posición de las alertas en pantalla.

---

## 🔄 MacroSync - Macros Compartidos

### `/sequito macro share <nombre>`
**Descripción:** Comparte un macro con tu grupo/raid.
**Ejemplo:** `/sequito macro share SeqBurst`

### `/sequito macro list`
**Descripción:** Lista los macros compartidos que has recibido.

### `/sequito macro import <nombre>`
**Descripción:** Importa un macro compartido a tus macros.
**Ejemplo:** `/sequito macro import SeqBurst`

### `/sequito macro library`
**Descripción:** Muestra la biblioteca de macros para tu clase/spec.

### `/sequito macro libraryall`
**Descripción:** Muestra toda la biblioteca de macros para tu clase.

### `/sequito macro getlib <nombre>`
**Descripción:** Importa un macro de la biblioteca.
**Ejemplo:** `/sequito macro getlib SeqDotAll`

### `/sequito macro getall`
**Descripción:** Importa todos los macros de la biblioteca para tu spec.

### `/sequito macro request`
**Descripción:** Solicita la lista de macros disponibles del grupo.

### `/sequito macro get <nombre> <jugador>`
**Descripción:** Solicita un macro específico de otro jugador.
**Ejemplo:** `/sequito macro get SeqBurst Elnazzareno`

---

## ⚔️ TrinketTracker - PvP

### `/sequito trinkets`
**Alias:** `/seq tt`
**Descripción:** Abre/cierra el panel de tracking de trinkets enemigos.

### `/sequito trinkets clear`
**Descripción:** Limpia todos los datos del tracker.

### `/sequito trinkets announce`
**Descripción:** Anuncia el estado de todos los trinkets enemigos al grupo.
**Ejemplo de salida:**
```
[Jaina] Trinkets en CD: Enemigo1 (1:45), Enemigo2 (0:30)
[Jaina] Trinkets LISTOS: Enemigo3, Enemigo4
```

---

## 💀 WipeAnalyzer - Análisis de Wipes

### `/sequito analyze`
**Alias:** `/seq wa`
**Descripción:** Muestra el análisis del último wipe detectado.

### `/sequito analyze announce`
**Descripción:** Anuncia el análisis del wipe al raid/party.
**Ejemplo de salida:**
```
[Jaina] === ANÁLISIS DE WIPE ===
Primera muerte: Jugador1 (15.3s) - Shadow Bolt de Boss
Sin poción/healthstone: Jugador2, Jugador3
Total muertes: 8 | Interrupts: 5
```

### `/sequito wipehistory`
**Descripción:** Muestra el historial de wipes de la sesión.

### `/sequito clearwipes`
**Descripción:** Limpia el historial de wipes.

---

## 📊 Tabla de Comandos de Raid

| Comando | Atajo | Descripción |
|---------|-------|-------------|
| `/sequito trinkets` | `/seq tt` | Panel de trinkets PvP |
| `/sequito trinkets clear` | - | Limpiar tracker |
| `/sequito trinkets announce` | - | Anunciar trinkets |
| `/sequito analyze` | `/seq wa` | Análisis de wipe |
| `/sequito analyze announce` | - | Anunciar análisis |
| `/sequito wipehistory` | - | Historial de wipes |
| `/sequito clearwipes` | - | Limpiar historial |

---

## ⚔️ Comandos PvP

### `/sequito focus`
**Alias:** `/seq ff`
**Descripción:** Abre el panel de FocusFire para llamadas de target.

### `/sequito focus call`
**Descripción:** Llama al target actual como objetivo de focus fire.

### `/sequito cc`
**Alias:** `/seq cc`
**Descripción:** Abre el panel de CCCoordinator.

### `/sequito cc assign <jugador> <target>`
**Descripción:** Asigna un CC a un jugador para un target específico.

### `/sequito healers`
**Alias:** `/seq ht`
**Descripción:** Abre el panel de HealerTracker.

### `/sequito defensive`
**Alias:** `/seq def`
**Descripción:** Abre el panel de DefensiveAlerts.

### `/sequito defensive peel`
**Descripción:** Anuncia que necesitas peel.

### `/sequito defensive heal`
**Descripción:** Anuncia que necesitas heal.

---

## 🏰 Comandos Mazmorras

### `/sequito pullguide`
**Alias:** `/seq pg`
**Descripción:** Abre el panel de PullGuide.

### `/sequito pullguide mark`
**Descripción:** Auto-marca el pack actual.

### `/sequito dungeon`
**Alias:** `/seq dt`
**Descripción:** Abre el panel de DungeonTimer.

### `/sequito loot`
**Alias:** `/seq lc`
**Descripción:** Abre el panel de LootCouncil.

### `/sequito loot start`
**Descripción:** Inicia una sesión de loot council.

---

## 👥 Comandos Generales

### `/sequito notes add <jugador> <texto>`
**Alias:** `/seq pn add`
**Descripción:** Guarda una nota sobre un jugador.

### `/sequito build save <nombre>`
**Descripción:** Guarda tu build actual con un nombre.

### `/sequito build load <nombre>`
**Descripción:** Carga un build guardado.

### `/sequito build share <nombre>`
**Descripción:** Comparte un build con el grupo.

### `/sequito calendar`
**Alias:** `/seq cal`
**Descripción:** Abre el panel de EventCalendar.

### `/sequito stats`
**Alias:** `/seq ps`
**Descripción:** Muestra tus estadísticas de rendimiento.

### `/sequito poll "<pregunta>" opcion1 opcion2 ...`
**Alias:** `/seq vote`
**Descripción:** Crea una votación rápida.
**Ejemplo:**
```
/sequito poll "¿Seguimos o paramos?" Seguir Parar
```

### `/sequito version`
**Alias:** `/seq ver`
**Descripción:** Verifica versiones de Jaina en el grupo.

### `/sequito whisper <template>`
**Alias:** `/seq qw`
**Descripción:** Envía un mensaje rápido predefinido.
**Templates disponibles:** inv, afk, summon, ready, brb

---

## 📜 Lista de Comandos - Jaina v10.0
> **Nota:** La mayoría de estas funciones ahora son accesibles desde el **Dashboard** (Icono de Minimapa).

## 🚀 Comandos Principales (v10.0)

| Comando | Descripción |
|---------|-------------|
| `/sequito` | Abre el **Dashboard Unificado** (Config, Raid, Tools). |
| `/sequito report` | Abre **Jaina Connect** (Exportar datos y perfiles). |
| `/sequito options` | (Legacy) Abre la pestaña de configuración directamente. |
| `/sequito panel` | (Legacy) Abre el panel de raid directamente. |

## 🛠️ Herramientas de Raid (Hive Mind)

| Comando | Descripción | Rango Requerido |
|---------|-------------|-----------------|
| `/sequito sync` | Fuerza una sincronización completa con la raid. | Oficial/RL |
| `/sequito sync config` | Abre la ventana de configuración remota. | Oficial/RL |
| `/sequito sync strat` | Abre el editor de estrategias de boss. | Oficial/RL |
| `/sequito veto [jugador]` | Bloquea a un jugador del sistema de sincronización. | Oficial/RL |
| `/sequito pull [seg]` | Inicia una cuenta atrás de pull (ej: 10s). | Cualquiera |
| `/sequito ready` | Inicia una comprobación de listos. | Oficial/RL |

## 🎓 Academy Mode

| Comando | Descripción |
|---------|-------------|
| `/sequito inspect` | Abre el **Inspector de Academia** (Talentos/Gear real de target). |
| `/sequito gallery` | Abre la **Galería de Loot** legendario. |

## ⚔️ Combate, Alertas y PvP

| Comando | Descripción |
|---------|-------------|
| `/sequito spy` | Alterna la interfaz de **JainaSpy** (detección de sigilo y enemigos). |
| `/sequito focusfire` (o `/seq ff`) | Abre el panel de Focus Fire sincronizado. |
| `/sequito ff call` | Llama y marca con calavera al objetivo actual. |
| `/sequito overlord` (o `/seq hud`) | Abre el configurador del HUD **The Overlord**. |
| `/sequito alert [mensaje]` | Muestra una alerta táctica de prueba en pantalla. |
| `/sequito alertpos [TOP/CENTER/BOTTOM]` | Modifica la posición en pantalla de las alertas de banda. |
| `/sequito checkbuffs` (o `/seq checkcons`) | Genera y muestra el reporte de consumibles y buffs de raid. |
| `/sequito combatclear` | Limpia el historial de daño y sanación del CombatTracker. |
| `/sequito mode [FARM/PROGRESSION]` | Alterna el modo operativo de la raid (Farmeo vs Progresión). |
| `/sequito phase [número/nombre]` | Anuncia un cambio de fase del jefe de banda. |

## 🐎 Gestión de Monturas Favoritas

| Comando | Descripción |
|---------|-------------|
| `/sequito mounts` (o `/seq monturas`) | Lista las monturas registradas del personaje. |
| `/sequito setflying [nombre]` | Define la montura voladora preferida para macros. |
| `/sequito setground [nombre]` | Define la montura terrestre preferida para macros. |
| `/sequito setaquatic [nombre]` | Define la montura acuática preferida para macros. |

## ⚙️ Utilidades y Mantenimiento

| Comando | Descripción |
|---------|-------------|
| `/sequito version` (o `/seq vs`) | Muestra y compara versiones del addon en la banda. |
| `/sequito sync` | Solicita o transmite el estado de sincronización. |
| `/sequito whisper [1/2/3]` | Envía plantillas de susurro rápido o abre el panel. |
| `/sequito notes` | Administrador de notas persistentes sobre jugadores. |
| `/sequito build` | Gestor de árboles de talentos y configuraciones de glifos. |
| `/sequito reset` (o `/seq resetpos`) | Restablece la posición centrada de la esfera principal. |
| `/sequito lock` | Bloquea o desbloquea la posición de la esfera en pantalla. |
| `/smacros` (o `/seq macros`) | Genera y sincroniza las macros Necrosis inteligentes de clase/spec. |
| `/shumor` | Muestra la ayuda y estado del módulo de Frases Cómicas de Incursión. |
| `/shumor toggle` | Activa o desactiva las frases cómicas en actividades. |
| `/shumor channel [SAY/PARTY/RAID/YELL]` | Establece el canal de chat para la emisión de frases. |
| `/shumor test [CATEGORIA]` | Prueba una frase cómica en el chat (ej. `SUMMON`, `BATTLE_REZ`). |
| `/rl` | Recarga la interfaz del juego (`ReloadUI()`). |

---

**Creado por DarckRovert (Ingame: Elnazzareno) & Project Jaina Team**
