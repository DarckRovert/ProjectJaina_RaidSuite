# Project Jaina RaidSuite Changelog

**Versión Actual:** 11.3.0 (Ecosystem Synchronization & Protocol Hardening)
**Autor:** DarckRovert (Ingame: Elnazzareno) & Project Jaina Team

---

## v11.3.0 "Ecosystem Synchronization & Protocol Hardening"
**Release Date:** 2026-10-04

### 🛡️ Auditoría de Sincronización, Red y Lógica de Banda (Fixes #6 a #19)
- **`Modules/Raid/CombatTracker.lua` (Fix #6):**
  - Solucionado crash por nil-index en `CLEU` para eventos de daño ambiental/caída sin `spellId` (`ENVIRONMENTAL_DAMAGE`, etc.). Implementado guardia estricto en tablas de métricas.
- **`Modules/Raid/Assignments.lua` (Fix #8):**
  - Resuelto bug en asignaciones multi-perfil donde cambios de rol no persistían en perfiles secundarios al recargar la interfaz.
- **`Core/EcosystemBridge.lua` (Fix #9):**
  - Eliminado registro de evento fantasma de Vanilla (`PLAYER_PET_CHANGED`) que generaba advertencias en consola de WoW 3.3.5a. Reemplazado por hooks canónicos de WotLK.
- **`Modules/Raid/RaidSuite_LootGallery.lua` (Fix #10):**
  - Reparado fallo de resolución de hipervínculos de ítems que dejaba la galería vacía al inspeccionar jefes antes del cacheo local del cliente.
- **`Core/Constants.lua` & `Modules/Raid/VotingSystem.lua` (Fix #12):**
  - Polyfill `UnitIsRaidOfficer` corregido para respetar permisos de asistente y líder en bandas de 10/25 sin otorgar privilegios no autorizados a miembros ordinarios.
- **`Modules/Class/RaidSuite_Coven.lua` (Fix #13):**
  - Blindada emisión a `RAID_WARNING`: miembros ordinarios sin rango de oficial son desviados a chat de banda o impresión local para evitar errores de Lua en Ritual de la Perdición.
- **`Modules/Raid/PullGuide.lua` (Fix #14):**
  - Añadido `CHAT_MARK_TOKENS` ({star}, {circle}, etc.) en reemplazo de secuencias de escape `|TInterface\...|t` en canales de texto. Agregada verificación estricta de oficial en `CanMarkTargets`, `ClearMarks` y `MarkTarget`.
- **`Modules/Raid/RaidSync.lua` (Fix #15):**
  - Implementado método faltante `OnReadyCheck` (eliminando nil-call crash en Ready Checks). Reescrito `IsOfficer` eliminando el bypass ciego `name == UnitName("player")`, protegiendo `FOCUS`, `ALPHA` y `STRAT`.
- **`Modules/Raid/ReadyChecker.lua` (Fix #16):**
  - Erradicada tormenta de spam masivo en `READY_CHECK_FINISHED`: solo el líder o los asistentes de banda anuncian el resumen general al canal grupal; los miembros ordinarios reciben el informe en su consola local.
- **`Modules/PvP/CCCoordinator.lua` (Fix #17):**
  - Corregida extracción de parámetros en `SPELL_AURA_BROKEN_SPELL` (args 12-13 `extraSpellId`/`extraSpellName` para el CC roto en lugar de args 9-10 del hechizo agresor).
  - Añadido desregistro inmediato por `UNIT_DIED` para evitar CCs huérfanos.
  - Protección de oficial en `AnnounceAssignments`.
- **`Modules/Raid/RaidAssist.lua` (Fix #18):**
  - Erradicada tormenta de red en `INTERRUPT_USED`: implementación de `RecordInterrupt` deduplicada e idempotente; solo el lanzador local emite por red si es necesario.
  - Eliminado spam cada 2s en `OnUpdate`: `CheckUnitConsumables` emite `CONSUMABLE_STATUS` únicamente ante cambios de estado (`lastSentConsumables`); `TrackCooldowns` emite únicamente en transiciones de inicio/reinicio de CD con cómputo temporal local en `GetAvailableCooldowns`.
- **`Modules/PvP/SpecWatcher.lua` & `Modules/Raid/AcademyRotation.lua` (Fix #19):**
  - Parametrizado `GetTalentTabInfo(i, false, false, activeGroup)` con `GetActiveTalentGroup()` en ambos módulos. Resuelta ceguera de Dual Spec donde el cambio a la segunda especialización continuaba leyendo los talentos de la primera.

---

### 🔴 Causa Raíz de Desaparición de Componentes (Root-Cause Analysis)
- **Restauración de 6 Módulos Core no Registrados en `ModuleConfig`:**
  - `TheOverlord`: El HUD de recursos (maná, furia, energía, runas, combo points), pet health bar y alertas de procs mayores (`Ocaso`, `Decimation`, etc.) abortaban silenciosamente al inicializar porque `ModuleConfig:GetValue("Overlord", "enabled")` retornaba `nil`. Módulo registrado formalmente con esquema completo de opciones.
  - `DoTTracker`: El rastreador de DoTs en objetivo para Brujos abortaba silenciosamente. Registrado formalmente y con fallback defensivo.
  - `Universal`: Motor central de detección de rol, spec y clase registrado con fallback seguro para no bloquear la propagación de datos al resto de módulos.
  - `SoulEngine`, `Spy`, `EventManager`: Registrados formalmente con fallbacks activos para telemetría y vigilancia PvP.
- **Resiliencia en `MC:GetValue`:** Añadido fallback arquitectónico para que cualquier consulta de la clave `enabled` retorne `true` por defecto si no ha sido explícitamente desactivada por el usuario.
- **Normalización de `GetOption` en todos los módulos:** Cada módulo comprueba `val ~= nil` antes de retornar, evitando que fallbacks predeterminados sean ignorados cuando el perfil esté vacío.

### 🛠️ Corrección Crítica de Atajos (Ley II — WotLK 3.3.5a)
- **Reubicación de `Bindings.xml` a la raíz del addon:**
  - En WoW 3.3.5a, `Bindings.xml` debe ubicarse en la raíz del addon y **no** debe listarse en el archivo `.toc`.
  - La inclusión previa como `Core\Bindings.xml` en el `.toc` causaba 25 errores de tipo `Unknown frame type: Binding` en `FrameXML.log` e impedía que los atajos de teclado se registraran en el menú nativo de WoW.
  - Eliminado del `.toc` y movido a la raíz; atajos restaurados al 100%.

---

## v11.2.0 "Full 3.3.5a Animation Engine Audit"
**Release Date:** 2026-09-30

### 🔴 Correcciones Críticas de Compatibilidad (Ley II — WoW 3.3.5a Build 12340)

#### Erradicación Total de `AnimationGroup` con `BOUNCE`
`SetLooping("BOUNCE")` no existe en WotLK 3.3.5a y causa crash silencioso del cliente. Todos los usos fueron reemplazados por osciladores `OnUpdate` nativos basados en `math.sin`:

- **`Core/AlertHub.lua`** — Motor fade-in/hold/fade-out de 3 fases con `holdDuration` dinámico configurable por tipo de alerta. `FlashScreen` reescrito con ticker propio sin `AnimationGroup`.
- **`Core/GUI.lua`** — `BuffMonitor` BOUNCE eliminado; oscilador `math.sin` incrustado en el icono de textura con flag `flashing`, purga de `anim:IsPlaying()` huérfana.
- **`Modules/Raid/RaidSync.lua`** — Alerta táctica `ShowFocusAlert` reescrita con oscilador de parpadeo + ticker auto-hide de 6s nativo, sin `C_Timer.After` redundante ni `ag:Stop()`.
- **`Modules/Raid/RaidSuite_Achievements.lua`** — Toast de logros reescrito con motor 3-fases: fade-in 0.4s → hold 3.5s → fade-out 0.8s, `OnUpdate` limpiado al completarse.

#### Corrección de Rutas de Textura (Cuádruple Slash)
Iconos en tablas `RegisterModule` tenían `\\\\` (4 barras) en lugar de `\\` (2 barras), causando que los iconos no cargasen:
- `Modules/Utility/Runes.lua`, `Modules/PvP/SpecWatcher.lua`, `Modules/Raid/CombatTracker.lua`, `Modules/Raid/RaidIntel.lua`, `Modules/Raid/RaidSync.lua`

#### Normalización de Claves de Opciones en `ModuleConfig`
`Modules/Utility/Runes.lua` usaba `name`/`description` en lugar de `label`/`tooltip` — los controles de la UI de opciones no renderizaban el texto correcto.

#### Módulos con `Visuals.lua` (Bug #22)
- Oscilador proc overlay completo con `math.sin` reemplazando `AnimationGroup:BOUNCE`.
- `SoulSiphon` restringido exclusivamente a clase `WARLOCK`.
- Opciones normalizadas a `label`/`tooltip`.
- Comandos slash: `/visuals`, `/fx`, `/seqvisuals`.

### ✅ Infraestructura de Validación
- Auditoría `deep_audit.py` ejecutada sobre los 79 archivos del addon, clasificando 61 falsos positivos cubiertos por polyfills de `Constants.lua` vs. bugs reales corregidos.
- Suite `validate_suite.py`: 100% PASS — 79 refs TOC, 78 Lua sintaxis, 0 APIs Retail prohibidas, localización íntegra.

---

## v11.1.0 "Architecture & Network Stabilization"
**Release Date:** 2026-09-30

### 🛡️ 3.3.5a Client & Engine Strict Compliance (Ley II & Ley IV)
- **Eliminación Total de Texturas Numéricas:** Reemplazados todos los llamados erróneos a `SetTexture(r, g, b, a)` por `SetTexture("Interface\\Buttons\\WHITE8X8")` y `SetVertexColor()` a lo largo de 18 módulos (DungeonTimer, LootCouncil, Assignments, PullGuide, HealerTracker, CCCoordinator, BuildManager, Mounts, FocusFire, Soulstones, etc.).
- **Canal de Red Unificado 3.3.5a:** Erradicadas llamadas Retail inexistentes (`IsInRaid()`, `IsInGroup()`) reemplazándolas con resolución nativa de canales (`BATTLEGROUND`, `RAID`, `PARTY`).
- **Presupuesto de Red & Límite 255 Bytes (Ley III):** Protección y troceo a <= 240 bytes en reportes y anuncios de ReadyChecker, WipeAnalyzer, VotingSystem, HealerTracker, VersionSync y CooldownMonitor.
- **Prevención de Desconexiones:** Cola de transmisión progresiva a 20 paquetes/segundo en `RaidSuite_Connect` con purga de scripts `OnUpdate` al vaciarse la cola.
- **Desacoplamiento de Heap & Garbage Collection:** Eliminada creación de clausuras dinámicas en bucles `OnUpdate` y ticks de 2s en Soulstones y CooldownMonitor.
- **Inicialización Idempotente:** Añadidas banderas de guardia `self.initialized` en todos los módulos principales para evitar duplicación de eventos y listeners CLEU.
- **Seguridad Sandbox:** Ejecución aislada de configuraciones remotas mediante entorno seguro `setfenv` en `RaidSuite_Connect`.

---

## v11.0.0 "Ecosystem Edition"
**Release Date:** 2026-09-28

### 🌟 Renaming & Branding
- Proyecto renombrado de **SEQUITO** a **Wanos_RaidSuite** (branding oficial).
- 17 archivos Lua internos renombrados de `Sequito*.lua` a `RaidSuite_*.lua`.
- Tabla global `_G.Sequito` retenida intencionalmente para compatibilidad con 40+ módulos y `SavedVariables` existentes.
- Nuevos slash commands: `/raidsuite`, `/wprs` (además de los originales `/sequito`, `/seq`).

### 🌉 EcosystemBridge (Core/EcosystemBridge.lua)
- **Puente BattlePass:** Detecta kills de jefes y mazmorras completadas, reporta via `BP_QUEST_PROGRESS` al servidor Eluna de `Jaina_BattlePass` (Season 2, IDs 201-203).
- **Puente GameModes:** Lee `Wanos_GameModes_CharDB.selectedMode` para adaptar comportamiento:
  - Modo Hardcore/Ironman: `DefensiveAlerts.aggressionLevel = 2`, `WipeAnalyzer` auto-record activado.
  - Badge de modo en mensajes del sistema (`|cFFFF3333[HARDCORE]|r`).
- **API pública:** `Bridge:NotifyBossKill(name)`, `Bridge:NotifyDungeonComplete()` para módulos internos.
- **Seguridad de red:** Payload < 240 bytes, cooldown anti-spam de 30s por tipo de misión, WHISPER a jugador propio.

### ⚙️ CI/CD GitHub Actions (.github/workflows/validate.yml)
- **Job 1:** `luacheck` sobre Lua 5.1 en cada push/PR.
- **Job 2:** `validate_suite.py` — verificación estructural del addon.
- **Job 3:** Build automático del ZIP de release al crear un tag `vX.Y.Z`, publicado como GitHub Release.

### 🏷️ Release
- Primer release oficial etiquetado `v1.0.0` en GitHub.

---

## v10.2.0 "The Next Level"
**Release Date:** 2026-02-11

### 🌟 New Features

#### Unified Alert HUB (`AlertHub`)
- **Centralized Alerts**: Replaces scattered alert systems from `TheOverlord` and `Spy` with a single, consistent UI.
- **Visual Styles**: Supports "Toast", "Critical" (Red Flash), and "Success" notification types.
- **Movable**: The main alert frame can now be moved and its position is saved automatically.
- **Class Colors**: Alerts retain class-specific colors (e.g., Purple for Warlock Procs) while using the new system.

#### Profile System (`ProfileManager`)
- **Multi-Profile Support**: Create, rename, delete, and switch between different configuration profiles (e.g., "Raid", "PvP", "Solo").
- **Smart Migration**: Automatically migrates your existing global settings to the "Default" profile upon first login.
- **GUI Management**: Complete management interface integrated into the addon options panel.

#### Sequito Plates (`SequitoPlates`)
- **New Module**: Lightweight nameplate enhancements designed for 3.3.5.
- **CC Tracking**: Displays Crowd Control icons (Sheep, Fear, Stun) directly above enemy nameplates.
- **Threat Indicator**: Visual glow/color change based on threat status.

#### Cooldown Monitor 2.0
- **Timeline Mode**: Smoother animation and cleaner look for cooldown bars.
- **Compact Mode**: New option for a smaller footprint, ideal for 40-man raids.
- **Visual Options**: Added configuration for colors (Class vs Type) and bar styles.

#### Guild Sync (Beta)
- **AutoSync Upgrade**: Extended to support `GUILD` channel events.
- **Note Sync**: Infrastructure added for synchronizing guild notes (Officer/Public) across the roster.
- **Loot History**: Foundation laid for sharing loot distribution history.

### 🛠 Improvements & Fixes
- **The Overlord**: Refactored to be lighter; visual alerts now delegated to `AlertHub`.
- **Spy**: Refactored to use `AlertHub` for stealth detection, maintaining the critical screen flash effect.
- **SmartDefaults**: Updated to support saving positions for new modules (`AlertHub`, `CooldownMonitor`).
- **ModuleConfig**: Added configuration panels for `SequitoPlates` and updated `CooldownMonitor`.

### ⚠️ Known Issues
- **Localization**: Some new strings in 10.2.0 might still be in English/Spanish mix; full localization pending next minor patch.
- **Nameplates**: Due to 3.3.5 API limitations, duplicate unit names (e.g. two "Orc Grunt") may show identical CC icons if one is CC'd.

---
_Sequito Dev Team_
