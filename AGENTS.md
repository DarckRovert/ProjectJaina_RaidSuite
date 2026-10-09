# 🤖 Reglas de Contexto y Memoria para Agentes de IA - Wanos_RaidSuite

> **Repositorio Oficial:** [DarckRovert/Wanos_RaidSuite](https://github.com/DarckRovert/Wanos_RaidSuite)  
> **Líder del Proyecto:** DarckRovert (Ingame: `Elnazzareno`)  
> **Servidor Destino:** [Project Jaina](https://worldofwanos.com/) - Project Jaina  
> **Entorno:** WotLK 3.3.5a (Build 12340) | Cliente Oficial 3.3.5a  

---

## 1. Directivas Inviolables para Agentes de IA

1. **Empirismo Estricto:** Antes de editar código o proponer cambios, inspeccionar los archivos reales con `view_file` o `grep_search`. Prohibido asumir que existen librerías de Retail o funciones de versiones posteriores a WotLK 3.3.5a.

2. **Preservación Inmutable de SavedVariables:**
   - La base de datos persistente del addon utiliza las variables `SequitoDB`, `SequitoPlayerNotesDB`, `SequitoBuildDB`, `SequitoQuickWhisperDB`, `SequitoStatsDB`, `SequitoPositionsDB`, y `SequitoLootDB`.
   - **Queda estrictamente prohibido alterar o renombrar estos identificadores en el motor Lua o en el archivo `.toc`.** Renombrarlos destruiría todas las configuraciones, perfiles y notas guardadas de los jugadores en la carpeta `WTF/`.

3. **Restricciones del Cliente 3.3.5a:**
   - **`## Interface: 30300`:** El build 12340 de WotLK requiere exactamente `30300`. `30350` corresponde a MoP y marca el addon como incompatible.
   - **Sin `SetColorTexture()`:** Usar `SetTexture("Interface\\Buttons\\WHITE8X8")` + `SetVertexColor(r, g, b, a)`.
   - **Sin `C_Timer.After`:** Utilizar el polyfill centralizado en `Core/Constants.lua` o marcos invisibles con script `OnUpdate` y cancelación explícita.
   - **Registro Defensivo de Prefijos:** Toda llamada a `RegisterAddonMessagePrefix` debe estar protegida defensivamente:
     ```lua
     if RegisterAddonMessagePrefix then
         RegisterAddonMessagePrefix(prefix)
     end
     ```

4. **Presupuesto de Red y Límites de Mensajería (255 Bytes):**
   - El límite absoluto de carga útil por mensaje en WotLK 3.3.5a es de **255 bytes**.
   - Los módulos de sincronización (`RaidSync`, `AutoSync`, `AlertHub`, `VotingSystem`) deben serializar la información de manera compacta.
   - Todo despacho por canales masivos (`GUILD`, `RAID`, `PARTY`) debe contar con limitadores de flujo (*leaky-bucket throttling*) para evitar desconexiones accidentales de jugadores.

5. **Rendimiento para Cabinas de Internet (Low-End PC):**
   - El addon debe mantener 60 FPS estables incluso en hardware modesto de cabinas de internet (CPUs dual-core, gráficos integrados Intel HD).
   - Minimizar asignaciones de tablas temporales dentro de eventos de alta frecuencia como `COMBAT_LOG_EVENT_UNFILTERED` o scripts `OnUpdate`.

6. **Comandos de Consola y Retrocompatibilidad:**
   - Comandos principales: `/raidsuite`, `/wprs`, `/seq`, `/sequito`.
   - Se mantiene retrocompatibilidad total con los alias existentes para la comunidad.

7. **Gestión Git y Versionado:**
   - La rama de producción y desarrollo es exclusivamente `main`. Queda prohibido el uso o recreación de la rama `master`.
   - Toda contribución debe respetar las directivas de [GOVERNANCE.md](GOVERNANCE.md) y [CONTRIBUTING.md](CONTRIBUTING.md).

---

## 2. Mapa Arquitectónico del Addon

| Directorio | Propósito |
| :--- | :--- |
| [Core/](Core/) | Núcleo del framework: constantes 3.3.5a, despachador CLEU, gestión de perfiles, sistema de temas y GUI. |
| [Data/](Data/) | Bases de datos locales de hechizos, líneas de voz y metadatos de combate. |
| [Locales/](Locales/) | Archivos de localización lingüística (`esMX.lua` y `enUS.lua`). |
| [Modules/Core/](Modules/Core/) | Módulos del sistema: Dashboard principal, esfera radial, minimapa y panel de opciones. |
| [Modules/Utility/](Modules/Utility/) | Utilidades: Generador inteligente de macros por clase, monturas, compañeros y calendario. |
| [Modules/Raid/](Modules/Raid/) | Herramientas de banda: Concilio de botín (Loot Council), sincronización de raid, análisis de wipes e inspectores. |
| [Modules/PvP/](Modules/PvP/) | Utilidades competitivas: Rastreo de CC, tiempos de recarga de abalorios y alertas defensivas. |
| [Wanos_RaidSuite.toc](Wanos_RaidSuite.toc) | Descriptor oficial del addon para el cliente WoW 3.3.5a. |
