# 📋 Registro de Cambios — ProjectJaina_RaidSuite

Todos los cambios notables de este proyecto están documentados en este archivo siguiendo el estándar [Keep a Changelog](https://keepachangelog.com/es-ES/1.0.0/).

---

## [11.2.2] — 2026-11-10
### Blindaje de Modos de Alto Riesgo, Silenciamiento en Duelos y Localización de Auditoría (Hito #341 / Bug #7)
- **Puente de Ecosistema Ampliado (`Core/EcosystemBridge.lua`):** Añadidos `NormalizeMode` e `IsHighRiskMode()`, reconociendo `DIE_AND_RISE` y `SLOW_X1` además de `HARDCORE` e `IRONMAN`.
- **Guarda Anti-Spam en Duelos & Mundo Abierto (`Modules/Raid/RaidSuite_Performance.lua`):** Registro de `DUEL_FINISHED`, supresión de reportes en mundo abierto fuera de estancias y silenciamiento automático cuando no hay interrupciones ni muertes registradas.
- **Comandos & Localización (`RaidSuite_Init.lua`, `Locales/enUS.lua`, `Locales/esMX.lua`):** Unificados comandos de ayuda `/suite` (incluyendo `/suite macro get <nombre> <jugador>`) y claves de localización del auditor de rendimiento (`NO_INTERRUPTS`, etc.).

---

## [11.2.1] — 2026-10-10
### Estabilización de Ecosistema y Gobernanza Oficial (Project Jaina)
- **Normalización de UI y Gráficos:** Alineación cuadrada 1:1 en logotipo de RaidSuite Dashboard (36x36), validación estricta de permisos de líder antes de emitir alertas y guardia de protección ante eventos CLEU sin spellId.
- **Homologación Documental:** Incorporación y actualización formal de `GOVERNANCE.md`, `LICENSE`, `NOTICE.md` y `SECURITY.md`.
- **Licencia Canónica:** Consolidación de licencia MIT 2026 bajo titularidad de DarckRovert & Project Jaina Team.
- **Validación de Runtime:** Verificado al 100% con compilador sintáctico `lua52_compiler.exe -p` con 0 errores y 0 warnings.

---

## [1.0.0] — 2026-10-04
### Lanzamiento Inicial — Ecosistema Project Jaina WotLK 3.3.5a
- Implementación de la arquitectura base para Project Jaina Raid Suite.
- Registro de comandos slash: `/rs, /raidsuite`.
- Persistencia de configuración en `ProjectJaina_RaidSuiteDB`.
- Compatibilidad certificada con cliente WotLK 3.3.5a (Build 12340) y directiva `Interface: 30300`.
