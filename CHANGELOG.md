# WoW Perú RaidSuite Changelog

**Versión Actual:** 10.2.0 (Definitive Edition)  
**Autor:** DarckRovert (Ingame: Elnazzareno) & WoW Perú Team

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
