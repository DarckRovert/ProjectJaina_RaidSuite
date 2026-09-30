# WoW Perú RaidSuite Changelog

**Versión Actual:** 11.1.0 (Architecture & Network Stabilization)
**Autor:** DarckRovert (Ingame: Elnazzareno) & WoW Perú Team

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
- Proyecto renombrado de **SEQUITO** a **WoWPeru_RaidSuite** (branding oficial).
- 17 archivos Lua internos renombrados de `Sequito*.lua` a `RaidSuite_*.lua`.
- Tabla global `_G.Sequito` retenida intencionalmente para compatibilidad con 40+ módulos y `SavedVariables` existentes.
- Nuevos slash commands: `/raidsuite`, `/wprs` (además de los originales `/sequito`, `/seq`).

### 🌉 EcosystemBridge (Core/EcosystemBridge.lua)
- **Puente BattlePass:** Detecta kills de jefes y mazmorras completadas, reporta via `BP_QUEST_PROGRESS` al servidor Eluna de `WoWPeru_BattlePass` (Season 2, IDs 201-203).
- **Puente GameModes:** Lee `WoWPeru_GameModes_CharDB.selectedMode` para adaptar comportamiento:
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
