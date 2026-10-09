# 🛡️ Política de Seguridad - Project Jaina RaidSuite

**Versión:** 10.2.0 (Definitive Edition)  
**Fecha:** Septiembre de 2026  
**Responsable:** DarckRovert (Ingame: Elnazzareno) & Project Jaina Team

---

## 1. Versiones Soportadas

Actualmente, solo la rama principal del addon (`main`) recibe parches de seguridad y estabilidad para el cliente oficial de World of Warcraft 3.3.5a.

| Versión | Cliente WoW | Estado de Soporte |
| :--- | :--- | :--- |
| **v10.x (Última Release)** | 3.3.5a (Build 12340) | :white_check_mark: Soportada activamente |
| **< v10.0** | 3.3.5a | :x: No soportada |
| **Versiones de Retail / Cataclysm / Classic** | 4.x - 11.x | :x: Incompatible |

---

## 2. Modelo de Amenazas en World of Warcraft 3.3.5a

El entorno de ejecución de la interfaz de World of Warcraft presenta vectores de riesgo específicos que el equipo de Jaina mitiga activamente:

### 2.1. Manipulación y Desbordamiento de Mensajería de Addon (Addon Channel Flooding)
- **Riesgo:** El uso indiscriminado de `SendAddonMessage` en canales `RAID`, `PARTY` o `GUILD` puede provocar desconexiones masivas por desbordamiento de búfer del servidor o cliente (*packet flooding*), o mensajes maliciosos que alteren contadores de votos o perfiles de botín.
- **Mitigación en Jaina:** 
  - Todo mensaje recibido por `RaidSync` y `VotingSystem` se valida mediante firmas de comando, verificación de prefijos (`SEQUITO_RS`, `SEQUITO_VOTE`) y comprobación de permisos de líder o asistente de banda (`UnitIsRaidOfficer` / `UnitIsPartyLeader`).
  - Lógica de descarte silencioso y eliminación de difusiones redundantes o descontroladas (e.g. en comandos `END` de votaciones).

### 2.2. Aislamiento Seguro y Prevención de "UI Taint"
- **Riesgo:** La invocación de APIs seguras o la alteración de variables globales compartidas con la interfaz de Blizzard durante el bloqueo de combate (`InCombatLockdown()`) provoca errores fatales de ejecución que inhabilitan barras de acción o marcos de unidad.
- **Mitigación en Jaina:**
  - El núcleo visual (`JainaSphere`) utiliza `PostClick` y botones seguros nativos de Blizzard (`SecureActionButtonTemplate`) con macros preconfiguradas, garantizando cero contaminación (*Zero Taint*) al entrar y salir del combate.
  - El registro de macros dinámicas o actualización de satélites se posterga automáticamente ante eventos `PLAYER_REGEN_DISABLED` y se procesa en `PLAYER_REGEN_ENABLED`.

### 2.3. Sanitización de Cadenas e Hipervínculos
- **Riesgo:** Cadenas no saneadas con secuencias de escape no válidas (`|c...|H...|h...|r`) o tokens de formateo mal estructurados pueden generar cuelgues del cliente de juego C++.
- **Mitigación en Jaina:** Todos los enlaces de objetos y cadenas de chat son procesados y validados antes de ser emitidos a los canales del juego.

---

## 3. Reporte Responsable de Vulnerabilidades

Si descubres una vulnerabilidad de seguridad, un vector de exploit en el sistema de sincronización o un fallo de taint crítico que pueda ser abusado para perjudicar la experiencia de juego de una banda:

1. **NO publiques el problema en un GitHub Issue público** ni en foros comunitarios.
2. Envía un correo detallado a:
   - **Email:** [darckrovert@gmail.com](mailto:darckrovert@gmail.com)
   - **Asunto:** `[SECURITY] Reporte de Vulnerabilidad - Jaina`
3. Incluye en tu reporte:
   - Descripción técnica de la vulnerabilidad.
   - Pasos exactos o script de prueba para reproducir el fallo.
   - Impacto potencial en el cliente, servidor o banda.
   - Entorno de prueba (Servidor, cliente esMX/enUS).

---

## 4. Compromiso de Respuesta

- **Acuse de recibo:** En un plazo máximo de 48 horas tras la recepción del reporte.
- **Evaluación y Mitigación:** Se evaluará la severidad y se desarrollará un parche en una rama privada en un plazo razonable (generalmente menos de 7 días).
- **Publicación:** Una vez publicado el parche y la nueva versión, se otorgará el debido crédito al investigador (si así lo desea).
