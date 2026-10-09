# ❄️ Project Jaina - RaidSuite (v11.2.1 Definitive Edition)

**Versión:** 11.2.1 (Definitive Edition)  
**Autor:** DarckRovert (Ingame: Elnazzareno) & Antigravity (Mythos 5)  
**Servidor Destino:** [Project Jaina](https://darckrovert.github.io/ProjectJaina_Web/)  
**Cliente Compatible:** World of Warcraft 3.3.5a (Build 12340)

---

[![WoW Client](https://img.shields.io/badge/WoW%20Client-3.3.5a%20(Build%2012340)-blue.svg)](https://darckrovert.github.io/ProjectJaina_Web/)
[![Servidor](https://img.shields.io/badge/Servidor-Project%20Jaina-gold.svg)](https://darckrovert.github.io/ProjectJaina_Web/)
[![Version](https://img.shields.io/badge/version-11.2.1-blue.svg)](https://github.com/DarckRovert/ProjectJaina_RaidSuite/releases)
[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](LICENSE)

---

## 🌟 ¿Qué es Jaina?

**Jaina** es una plataforma integral de combate, gestión de bandas y colaboración en vivo para World of Warcraft 3.3.5a. Inspirado originalmente en el legendario espíritu visual de *Necrosis*, Jaina evoluciona para dar cobertura a **las 10 clases del juego y sus 30 especializaciones**, proporcionando herramientas reales y automatizaciones tácticas que resuelven las necesidades de jugadores individuales, grupos de mazmorra y hermandades enteras.

```
┌─────────────────────────────────────────────────────────────┐
│                    EL ECOSISTEMA SEQUITO                    │
├─────────────────┬─────────────────────────┬─────────────────┤
│ 🔮 ESFERA       │ 🖥️ DASHBOARD            │ ⚡ HUD ROTACIÓN  │
│ Menú radial     │ Ventana central         │ Prioridades y   │
│ y acceso rápido │ Resumen, Logros,        │ alertas de PROC │
│ al hacer clic   │ Rotación y Botín        │ en tiempo real  │
├─────────────────┼─────────────────────────┼─────────────────┤
│ 📜 MACROS INTEL │ ⚖️ LOOT COUNCIL         │ 💀 WIPE COACH   │
│ 30 Specs con    │ Detección automática    │ Diagnóstico de  │
│ modificadores   │ y captura de /azar 100  │ muertes y DPS   │
└─────────────────┴─────────────────────────┴─────────────────┘
```

---

## 🚀 Pilares del Ecosistema

### 1. 🖥️ Dashboard Central (`/sdash` o Clic en Esfera)
Una ventana moderna de alta definición que centraliza todo lo que necesitas sin comandos complicados:
- **Resumen del Cónclave:** Monitor en tiempo real de tu personaje, rol y composición de grupo/banda.
- **Logros de Hermandad:** Sistema interno de gamificación con proezas de raid exclusivas.
- **Asesor de Rotación:** Vista rápida de la cadena de prioridades óptima de tu especialización.
- **Galería de Botín:** Registro histórico de piezas épicas y legendarias obtenidas por la hermandad.

### 2. 📜 Motor de Macros Adaptativo de 30 Especializaciones (`SeqRot`)
Elimina definitivamente las secuencias congeladas (`/castsequence`). Jaina genera una macro inteligente (`SeqRot`) con modificadores (`Shift`, `Ctrl`, `Alt`, `@mouseover`, `[form:1/3]` de Druida) que se recalcula automáticamente cuando cambias de talentos o compras dual spec, sin tocar tus macros personales.

### 3. 🌐 Malla de Clan en Vivo (`ClanMesh`)
Sincronización continua a través del canal de hermandad (`GUILD`), además de grupo y banda. Los miembros de la hermandad pueden compartir estrategias de jefes, notas de oficiales y avisos tácticos estés en Dalaran, explorando el mundo o dentro de ICC. Incluye protección contra desconexiones (*leaky-bucket throttling*).

### 4. 🎓 Modo Academia (`Academy Mode`)
- **Inspector de Oficiales (`/sinspect`):** Inspección asíncrona robusta vía `INSPECT_TALENT_READY`, cálculo de **GearScore real de WotLK 3.3.5a** y auditoría de piezas sin encantar.
- **HUD Reactivo de Rotación (`/srot`):** Pequeña barra flotante con cooldowns y **resaltado instantáneo de PROCS** en verde esmeralda (`Buena racha`, `Arte de la guerra`, `Oleada de sangre`, `Escarcha blanca`, `Diezmar`, `Eclipses`).

### 5. ⚖️ Concilio de Botín Híbrido (`Loot Council` - `/sloot`)
- **Cola de Botín Automática (Loot Queue):** Encola automáticamente todas las piezas épicas del jefe y pasa de una a otra sin intervención manual.
- **Entrega Directa en el Juego (`GiveMasterLoot`):** Botón `[Dar]` en la interfaz para que el Maestro Despojador asigne el ítem directamente a la mochila del ganador.
- **Respuestas WotLK:** Declaración de necesidad con botones de `Main Spec (MS)`, `Off Spec (OS)`, `Mejora` y `Pasar`.
- **Auditoría de Idoneidad y Tier Tokens:** Valida si el candidato puede usar la armadura y si la Marca de Santificación corresponde a su clase (*Vencedor*, *Protector*, *Conquistador*).
- **Temporizador Visual y Desempate:** Cuenta regresiva en pantalla con auto-aviso de expiración y desempate automático por dados.
- **Inclusión de jugadores sin addon:** Intercepta tiradas convencionales (`/azar 100` o `/roll`) por chat general y las incorpora a la tabla de candidatos con su puntuación numérica.

### 6. 💀 Auditoría de Combate y Análisis de Wipes (`/sstats` y `/swipe`)
- Parser de combate (`CLEU`) que extrae con exactitud matemática el daño realizado y la sanación efectiva neta.
- Autopsia de wipes: descubre quién murió primero, con qué habilidad del jefe, si usó poción/piedra de salud y qué cortes de casteo fallaron.

---

## ⌨️ Comandos Principales

| Comando | Alias | Descripción |
|---------|-------|-------------|
| `/raidsuite` | `/wprs`, `/jaina`, `/seq` | Abre el menú interactivo o el Dashboard central |
| `/sdash` | `/jaina dashboard` | Abre/cierra el Dashboard de 4 pestañas |
| `/smacros` | `/jaina macros` | Genera y sincroniza macros inteligentes |
| `/srot` | `/srotation` | Activa/desactiva el HUD flotante de rotación reactiva |
| `/sinspect` | `/seqinspect` | Inspecciona al objetivo (Talentos, GS real y encantamientos) |
| `/sloot` | `/jaina lc` | Abre el panel de gestión de Loot Council |
| `/sstats` | `/jaina stats` | Muestra estadísticas de DPS/HPS en combate |
| `/swipe` | `/jaina wipe` | Despliega el análisis post-wipe del último combate |
| `/sbuffs` | `/jaina buffs` | Escanea y reporta buffs faltantes en la banda |
| `/sfocus [Nombre]` | `/jaina focus` | Envía orden de target prioritario a toda la banda |
| `/sready` | `/jaina ready` | Inicia comprobación de listos táctica |

---

## 📖 Índice de Documentación Completa

Para conocer todos los detalles de cada subsistema, consulta las guías dedicadas:

* 📚 [Guía de Uso del Ecosistema (USAGE.md)](USAGE.md) — Manual integral paso a paso para el usuario final.
* 📜 [Guía de Macros Inteligentes (MACROS.md)](MACROS.md) — Desglose de macros para las 10 clases y 30 especializaciones.
* ⌨️ [Referencia Completa de Comandos (COMMANDS.md)](COMMANDS.md) — Lista de todos los comandos y alias disponibles.
* 📦 [Guía de Instalación (INSTALL.md)](INSTALL.md) — Instrucciones paso a paso para instalar en Project Jaina 3.3.5a.
* ❓ [Preguntas Frecuentes (FAQ.md)](FAQ.md) — Respuestas a dudas habituales sobre rendimiento, macros y raid.
* ⚙️ [Documentación de Módulos (MODULES.md)](MODULES.md) — Detalle técnico de los 77 componentes del addon.
* 💻 [Especificación de API (API.md)](API.md) — Arquitectura de eventos y funciones públicas para desarrolladores.
* 🛡️ [Seguridad (SECURITY.md)](SECURITY.md) — Políticas de reporte de vulnerabilidades y seguridad de datos.
* 🤝 [Gobernanza del Proyecto (GOVERNANCE.md)](GOVERNANCE.md) — Estructura de toma de decisiones y roles.
* 🌐 [Registro de Ecosistema (ECOSYSTEM_REGISTRY.md)](ECOSYSTEM_REGISTRY.md) — Mapeo de prefijos, tablas y convivencia con otros sistemas de Project Jaina.
* 🤖 [Reglas de Agentes IA (AGENTS.md)](AGENTS.md) — Directivas y restricciones de arquitectura para desarrollo asistido.
* ⚖️ [Licencia MIT (LICENSE)](LICENSE) — Términos legales de distribución y uso.
* 📝 [Historial de Versiones (CHANGELOG.md)](CHANGELOG.md) — Registro cronológico de cambios y optimizaciones.
* 🤝 [Guía de Contribución (CONTRIBUTING.md)](CONTRIBUTING.md) — Normas de estilo y flujo de pull requests.

---

---

## 📄 Licencia

Este proyecto está licenciado bajo los términos de la **Licencia MIT**. Consulta el archivo [LICENSE](LICENSE) para conocer el texto legal completo.

## 📺 Soporte y Comunidad

¡Únete a la comunidad de **Project Jaina**!

- 💜 **Twitch:** [twitch.tv/darckrovert](https://www.twitch.tv/darckrovert)
- 💚 **Kick:** [kick.com/darckrovert](https://kick.com/darckrovert)
- ☕ **Donaciones:** [PayPal](https://www.paypal.com/donate/?hosted_button_id=DF243KQBGMS3L)
- 🎵 **SoundAlerts:** [soundalerts.com/@darckrovert](https://soundalerts.com/@darckrovert)

---

*Desarrollado por DarckRovert (Ingame: Elnazzareno) & Antigravity (Mythos 5).*  
*World of Warcraft® es una marca registrada de Blizzard Entertainment, Inc.*
