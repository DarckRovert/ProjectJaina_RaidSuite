# 🌐 Registro de Ecosistema - WoWPeru_RaidSuite

**Versión del Registro:** 1.0.0  
**Fecha de Actualización:** 27 de Septiembre de 2026  
**Líder Técnico / Arquitecto:** DarckRovert (Ingame: `Elnazzareno`)  
**Servidor Destino:** [WoW Perú](https://wow-peru.lat/) - Reino Andino  
**Entorno:** WotLK 3.3.5a (Build 12340) | Cliente Oficial 3.3.5a  

---

## 1. Convivencia en el Ecosistema WoW Perú

`WoWPeru_RaidSuite` convive e interactúa armónicamente con los demás sistemas del ecosistema oficial:

| Addon / Sistema | Prefijo de Red | Script de Servidor (Eluna) | Tablas MySQL (`characters`) | Función Principal |
| :--- | :--- | :--- | :--- | :--- |
| **`WoWPeru_BattlePass`** | `WP_BP` | `Server/70_BattlePassSystem.lua` | `character_battlepass`<br>`character_battlepass_quests` | Pase de Batalla Estacional de 50 niveles (Vía Gratuita y VIP). |
| **`WoWPeru_GameModes`** | `WP_GAMEMODE` | `71_GameModesSystem.lua` | `character_gamemodes` | Selector de modos de juego (Normal, Hardcore, Desafíos). |
| **`WowPeruVisualShop`** | `WP_VISUAL` | `59_SpellVisualCatalog.lua` | `character_visuals` | Catálogo visual de alas, auras y títulos. |
| **`WoWPeru_RaidSuite`** | `SEQUITO` / Canales addon | N/A (Solo Cliente) | `SequitoDB` (SavedVariables) | Suite de optimización y sincronización de combate, raids y bandas de alto rendimiento. |

---

## 2. Prefijos de Red y Canales de Comunicación

- **Prefijos Registrados:** `SEQUITO`, `RSYNC`, `ALERTHUB`, `VOTE`, `OVERLORD`.
- **Canales de Tráfico:** `RAID`, `PARTY`, `GUILD`, y `WHISPER` directo.
- **Presupuesto Máximo:** 255 bytes por trama (estricto 3.3.5a).
- **Protección de Red:** Cola de salida con *leaky-bucket throttling* (máximo 5 mensajes/segundo) para evitar el kick por spam del servidor.

---

## 3. Persistencia de Datos (SavedVariables)

Las estructuras persistidas en la carpeta `WTF/` se dividen en variables globales y por cuenta:

| SavedVariable | Propósito | Alcance |
| :--- | :--- | :--- |
| `SequitoDB` | Configuración del marco principal, esfera, HUD y alertas. | Cuenta / Perfil |
| `SequitoPlayerNotesDB` | Notas estratégicas y asignaciones por jugador/oficial. | Cuenta |
| `SequitoBuildDB` | Plantillas de talentos y configuraciones de spec. | Cuenta |
| `SequitoQuickWhisperDB` | Mensajes rápidos preconfigurados y plantillas de chat. | Cuenta |
| `SequitoStatsDB` | Estadísticas de combate y métricas de raid acumuladas. | Cuenta |
| `SequitoPositionsDB` | Coordenadas y posiciones de anclaje de ventanas y barras. | Cuenta |
| `SequitoLootDB` | Registro histórico de piezas entregadas y tiradas de botín. | Cuenta |

---

## 4. Estándar de Código y Convenciones

1. **Lua 5.1 Puro:** Cero sintaxis de versiones superiores.
2. **Widgets de Textura:** Usar siempre `SetTexture("Interface\\Buttons\\WHITE8X8")` seguido de `SetVertexColor()`.
3. **Control de Memoria:** Reciclar tablas en eventos de combate continuo y desvincular scripts `OnUpdate` al cerrar componentes.
