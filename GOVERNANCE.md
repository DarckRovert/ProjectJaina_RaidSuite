# 🏛️ Modelo de Gobernanza del Proyecto - WoW Perú RaidSuite

**Versión del Documento:** 1.0.0  
**Fecha de Entrada en Vigor:** 27 de Septiembre de 2026  
**Líder del Proyecto / Autor:** DarckRovert (Ingame: Elnazzareno) & WoW Perú Team  
**Servidor Destino:** [WoW Perú](https://wow-peru.lat/) - Reino Andino  
**Entorno de Ejecución:** World of Warcraft 3.3.5a (Build 12340)

---

## 1. Misión y Alcance

**Sequito** es una suite modular avanzada y de alto rendimiento diseñada para la optimización de incursiones (Raids), sincronización de banda, gestión de combate y herramientas de utilidad para clientes de World of Warcraft 3.3.5a (Wrath of the Lich King).

El objetivo primordial del proyecto es ofrecer:
- **Rendimiento Máximo:** Cero fugas de memoria y mínimo impacto en el Garbage Collector (GC) de Lua 5.1 durante encuentros de alta densidad (25 jugadores heroico).
- **Aislamiento Seguro (Zero Taint):** Estricto respeto por las fronteras seguras de la interfaz de Blizzard para garantizar que ningún módulo contamine el entorno de combate.
- **Sincronización Idempotente:** Protocolo de mensajería seguro y controlado entre miembros del grupo o hermandad mediante canales de addon.

---

## 2. Estructura de Roles y Responsabilidades

El proyecto Sequito se rige bajo un modelo de **Liderazgo Técnico Centralizado (Benevolent Governance)** con aportes comunitarios guiados.

```
       ┌─────────────────────────────────────────┐
       │   Líder del Proyecto (Project Lead)     │
       │     DarckRovert (Elnazzareno)            │
       └────────────────────┬────────────────────┘
                            │
       ┌────────────────────▼────────────────────┐
       │     Mantenedores del Core (Core Team)   │
       │    (Arquitectura, Taint, Protocolos)    │
       └────────────────────┬────────────────────┘
                            │
       ┌────────────────────▼────────────────────┐
       │    Contribuidores y Especialistas QA    │
       │ (Módulos de Clase, Locales, Raids)      │
       └─────────────────────────────────────────┘
```

### 2.1. Project Lead (Líder del Proyecto)
- **Titular:** DarckRovert (Ingame: `Elnazzareno`).
- **Atribuciones:**
  - Control de la visión a largo plazo y roadmap del addon.
  - Aprobación final y fusión (merge) de Pull Requests en la rama `main`.
  - Firma y publicación de lanzamientos oficiales (Releases) y tags en GitHub.
  - Veto técnico sobre cambios que comprometan el rendimiento o la compatibilidad con el cliente 3.3.5a.

### 2.2. Core Maintainers (Mantenedores del Core)
- **Responsabilidades:**
  - Mantenimiento del ciclo de vida del addon (`Sequito.lua`, `WoWPeru_RaidSuite.toc`).
  - Supervisión de los motores centrales: `CLEUDispatcher`, `AlertHub`, `ProfileManager`, `Theme` y `GUI`.
  - Verificación de ausencia de APIs incompatibles (e.g., funciones de MoP/Retail en cliente 3.3.5a).
  - Revisión y optimización de consumo de memoria y CPU en raids.

### 2.3. Contribuidores (Contributors)
- Cualquier desarrollador de la comunidad que aporte mejoras de código, correcciones de errores (bug fixes), localización o documentación mediante Pull Requests.
- Todo contribuidor debe alinearse con las pautas de estilo de [CONTRIBUTING.md](CONTRIBUTING.md) y este documento de gobernanza.

---

## 3. Toma de Decisiones Técnicas

Las decisiones dentro de Sequito siguen el principio de **Consenso Técnico Fundamentado con Veto del Líder**:

1. **Discusión Abierta:** Los debates técnicos se llevan a cabo de forma transparente en GitHub Issues o Pull Requests.
2. **Criterio Empírico:** Las decisiones sobre refactorizaciones o inclusiones de librerías deben respaldarse con evidencia medible (tiempos de CPU, memoria asignada, ausencia de taint).
3. **Desempate:** En caso de divergencia irreconciliable o decisiones de alto impacto arquitectónico, el Project Lead tiene la autoridad final de decisión.

---

## 4. Proceso de Cambio y Propuestas (RFC - Request for Comments)

Para cambios significativos en el addon, se requiere la apertura de una propuesta formal (Issue con prefijo `[RFC]`) antes de enviar código:

### Casos que requieren RFC previo:
- Incorporación de una nueva librería de terceros (`Libs/`).
- Modificación del protocolo de serialización o mensajería de addon (`RaidSync`, `AutoSync`, `VotingSystem`).
- Reestructuración de la base de datos de perfiles (`SequitoDB`).
- Rediseño mayor de la interfaz visual (`SequitoSphere`, `Dashboard`, `RaidPanel`).

---

## 5. Ciclo de Lanzamientos y Versionado

Sequito utiliza **Versionado Semántico (SemVer)** adaptado al ecosistema de WoW: `MAJOR.MINOR.PATCH`

- **MAJOR (vX.0.0):** Cambios arquitectónicos profundos, rediseño completo del núcleo o reestructuración de la base de datos de perfiles que requiera migración forzada.
- **MINOR (vx.Y.0):** Nuevos módulos funcionales (e.g. soporte para nuevas bandas, nuevos modos de inspección o utilidades) manteniendo total retrocompatibilidad.
- **PATCH (vx.y.Z):** Corrección de bugs, optimizaciones de rendimiento, actualización de traducciones o ajustes menores de interfaz.

### Estabilidad de Rama:
- `main`: Representa el estado estable listo para producción y juego real. Todo commit en `main` debe ser ejecutable sin errores en el cliente 3.3.5a.
- `feature/*` o `fix/*`: Ramas de trabajo donde se desarrollan funcionalidades o parches antes de su revisión.

---

## 6. Resolución de Conflictos

1. Todo desacuerdo técnico debe resolverse analizando el impacto en el usuario final, la seguridad y el rendimiento del cliente.
2. No se tolerarán descalificaciones personales ni actitudes hostiles, aplicándose estrictamente las medidas contempladas en [CODE_OF_CONDUCT.md](CODE_OF_CONDUCT.md).

---

## 7. Modificaciones a la Gobernanza

Este documento puede ser revisado periódicamente por el Project Lead para adaptarse a las necesidades del proyecto y de la comunidad de jugadores y desarrolladores.
