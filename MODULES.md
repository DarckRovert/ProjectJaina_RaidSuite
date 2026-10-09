# 🛠️ Documentación de Módulos - Project Jaina RaidSuite

**Versión:** 10.2.0 (Definitive Edition)  
**Autor:** DarckRovert (Ingame: Elnazzareno) & Antigravity (Mythos 5)

---

33. [PerformanceStats.lua](#performancestatslua) - Estadísticas DPS/HPS
34. [VotingSystem.lua](#votingsystemlua) - Sistema de votaciones
35. [VersionSync.lua](#versionsynclua) - Sincronización de versiones
36. [QuickWhisper.lua](#quickwhisperlua) - Mensajes rápidos

### Utilidades (7)
37. [Logistics.lua](#logisticslua) - Auto-reparación y venta
38. [PetManager.lua](#petmanagerlua) - Control de mascotas
39. [Mounts.lua](#mountslua) - Sistema de monturas
40. [Visuals.lua](#visualslua) - Efectos visuales
41. [Runes.lua](#runeslua) - Runas de DK
42. [Menu.lua](#menulua) - Menú contextual
43. [RaidAssistUI.lua](#raidassistuilua) - UI de RaidAssist

### Plataforma v10.0 (Core)
44. [ConnectTab.lua](#connecttablua) - Hive Mind (Control Remoto)
45. [JainaDashboard.lua](#sequitodashboardlua) - GUI Unificada

### Nuevos en v10.1 (4)
46. [JainaSoulEngine.lua](#sequitosoulenginelua) - Motor de análisis
47. [JainaSpy.lua](#sequitospy-lua) - Inteligencia PvP
48. [Theme.lua](#themelua) - Sistema de temas
49. [TheOverlord.lua](#theoverlordlua) - HUD de combate (Reescrito)

---

## 🌐 ConnectTab.lua (Hive Mind)

### Descripción
El centro de mando de la plataforma Jaina. Permite a los oficiales controlar la configuración de sus raiders y enviar estrategias en tiempo real.

### Funcionalidades Clave

#### 1. Remote Config
- Comparte tu perfil de configuración con toda la raid.
- Resetea los contadores de daño (Recount/Details/Skada) de todos los miembros.
- **Seguridad:** Solo oficiales/líderes pueden iniciar comandos globales.

#### 2. Boss Strategies
- Envía notas tácticas que aparecen como popup a todos los miembros.
- Soporta textos largos gracias al protocolo de "Chunking" (troceado de mensajes).

#### 3. Raid Utilities
- Botones de acceso rápido para Pull Timer, Breaks y Ready Checks.

### API del Módulo
- `S.ConnectTab:Show()` - Muestra la pestaña en el Dashboard.
- `S.RaidSync:SendBossStrat(boss, text)` - Envía estrategia.
- `S.RaidSync:SendConfig(module, key, value)` - Envía configuración.

---

## 🔧 MacroGenerator.lua

### Descripción
El corazón de la actualización 2.3.0. Este módulo ha sido reescrito para replicar exactamente la lógica de macros de **Necrosis**. Ya no usa plantillas genéricas, sino lógica "hardcoded" específica para cada clase para garantizar la máxima calidad y utilidad.

### Funcionalidades Clave

#### 1. Real-Time Data Check
Antes de incluir un hechizo en una macro, el generador verifica estrictamente `IsSpellKnown(id)`.
- Si no sabes el hechizo (ej. nivel bajo), la macro se adapta o no se crea.
- Evita los molestos signos de interrogación (?) en las barras.

#### 2. Macros Inteligentes (Smart Macros)
Copia la filosofía "Multi-Función" de Necrosis.
- **[SeqPet]**: Un solo botón para Atacar, Seguir y usar Habilidad Especial (Shift) con prioridad Mouseover > Focus > Target.
- **[SeqHeal]**: Un solo botón para usar Piedra/Poción o crearla si no existe (Click Derecho).
- **[SeqStart]**: Selecciona enemigo, manda pet y lanza opener.

#### 3. Soporte Universal
Ahora genera este nivel de macros para las 10 clases, incluyendo:
- Macros de "Panic Buttons" (Burbuja, Muro de Escudo, Dispersión).
- Macros de Utilidad de Raid (Himno, Heroísmo, Redirección).

### API del Módulo

#### `Jaina_MacroGenerator_CreateMacros()`
Llama a la generación completa. Borra macros antiguas de Jaina y crea las nuevas.

#### `Jaina_MacroGenerator_GetSmartSpell(id)`
Helper interno que retorna el nombre del hechizo SOLO si está aprendido.

---

## 🔍 Universal.lua
*(Sin cambios mayores en API, ver documentación anterior)*

---

## 🔄 SpecWatcher.lua
Detecta cuando cambias de talentos (Dual Spec) y desencadena automáticamente `Jaina_MacroGenerator_CreateMacros()` para que tus botones siempre hagan lo correcto.

---

## 👥 RaidSync.lua / RaidIntel.lua / RaidPanel.lua
*(Sincronización y Panel de Raid)*

---

## 📊 CooldownMonitor.lua

### Descripción
Monitor de Cooldowns del Raid en tiempo real. Trackea CDs importantes de todos los miembros.

### Funcionalidades Clave

#### 1. Cooldowns Trackeados
- **Battle Res**: Rebirth (Druid), Soulstone (Warlock)
- **Heroism/Bloodlust**: Shaman
- **Raid CDs**: Divine Sacrifice, Aura Mastery, Anti-Magic Zone, Divine Hymn
- **Externals**: Pain Suppression, Guardian Spirit, Hand of Sacrifice/Protection
- **Tank CDs**: Shield Wall, Last Stand, Survival Instincts, Barkskin
- **Utility**: Misdirection, Tricks of the Trade, Innervate

#### 2. Panel Visual
- Panel flotante con todos los CDs del raid
- Filtros por tipo (BRes, Lust, Raid CD, External, Tank CD)
- Colores por tipo de cooldown
- Timer en tiempo real

#### 3. Alertas
- Anuncia en raid cuando se usa un CD importante
- Alerta cuando un BRes vuelve a estar disponible

### Comandos
- `/jaina cooldowns` - Abre/cierra el panel de CDs
- `/jaina cd bres` - Anuncia Battle Res disponibles
- `/jaina cd lust` - Anuncia Heroism/Bloodlust disponible

### API del Módulo
- `S.CooldownMonitor:Toggle()` - Abre/cierra panel
- `S.CooldownMonitor:GetAvailableBRes()` - Lista BRes disponibles
- `S.CooldownMonitor:AnnounceAvailable(type)` - Anuncia CDs disponibles

---

## 🎯 Assignments.lua

### Descripción
Sistema de Asignaciones Automáticas para Raids.

### Funcionalidades Clave

#### 1. Tipos de Asignaciones
- **Interrupts**: Rotación automática de interrupters
- **Tanks**: Asignar tanks a objetivos específicos
- **Healers**: Asignar healers a tanks/grupos
- **Cooldowns**: Asignar CDs defensivos a fases
- **Marks**: Asignar marcas de raid a jugadores

#### 2. Auto-Asignación
- Detecta automáticamente clases con interrupt
- Ordena por CD más corto (Shaman > Rogue/Warrior > Mage)
- Genera rotación óptima

#### 3. Sincronización
- Comparte asignaciones con el raid via addon messages
- Todos los usuarios de Jaina reciben las asignaciones

### Comandos
- `/jaina assign` - Abre panel de asignaciones
- `/jaina assign interrupts` - Auto-asigna rotación de interrupts
- `/jaina assign announce` - Anuncia todas las asignaciones

### API del Módulo
- `S.Assignments:Toggle()` - Abre/cierra panel
- `S.Assignments:AutoAssignInterrupts()` - Auto-asigna interrupts
- `S.Assignments:SyncToRaid()` - Sincroniza con el raid

---

## ✅ ReadyChecker.lua

### Descripción
Chequeo Pre-Pull Mejorado. Verifica que todos estén listos antes del pull.

### Funcionalidades Clave

#### 1. Verificaciones por Clase
- **Rogue**: Venenos aplicados (MH/OH)
- **Warlock/Hunter**: Mascota invocada
- **Warlock**: Healthstone en bolsas, Spellstone
- **DK**: Presencia activa, Horn of Winter
- **Paladin**: Aura y Sello activos
- **Shaman**: Escudo y Weapon Imbue
- **Mage**: Armadura activa
- **Warrior**: Grito y Postura
- **Druid**: Mark of the Wild
- **Priest**: Fortitude, Divine Spirit, Shadow Protection

#### 2. Verificaciones Generales
- Flask activo
- Food buff (Well Fed)
- Vida y Mana al 100%
- No muerto, no AFK, no desconectado

#### 3. Panel Visual
- Lista de todos los miembros con estado
- Icono verde (listo) o rojo (problemas)
- Detalle de qué falta a cada jugador

### Comandos
- `/jaina readycheck` - Abre panel y escanea
- `/jaina readycheck full` - Escaneo completo con anuncio

### API del Módulo
- `S.ReadyChecker:Toggle()` - Abre/cierra panel
- `S.ReadyChecker:ScanRaid()` - Escanea el raid
- `S.ReadyChecker:AnnounceProblems()` - Anuncia problemas al raid
- `S.ReadyChecker:QuickCheck()` - Retorna true si todos listos

---

## ⚔️ CombatTracker.lua
*(Métricas de combate)*

---

## 🎒 Logistics / PetManager / CCTracker
Módulos de soporte que mejoran la calidad de vida.
- **Logistics**: Vende basura gris automáticamente.
- **PetManager**: Botón orbital para controlar mascota (Warlock/Hunter/DK).
- **CCTracker**: Barras de tiempo para tus CCs (Miedo, Destierro, Oveja).

---

---

## 🔄 MacroSync.lua 

### Descripción
Sistema de sincronización y biblioteca de macros entre usuarios de Jaina.

### Funcionalidades Clave

#### 1. Sincronización entre Usuarios
- Comparte macros con tu grupo/raid via addon messages.
- Recibe y almacena macros de otros jugadores.
- Solicita lista de macros disponibles del grupo.
- Solicita macros específicos por nombre.

#### 2. Biblioteca de Macros por Clase
- 10 clases cubiertas con 3-5 macros cada una.
- Sistema de rating (estrellas) para calidad.
- Filtrado por especialización.
- Macros probados y optimizados para 3.3.5a.

### Comandos
- `/jaina macro share <nombre>` - Comparte macro con el grupo
- `/jaina macro list` - Lista macros recibidos
- `/jaina macro import <nombre>` - Importa macro compartido
- `/jaina macro library` - Muestra biblioteca de tu clase/spec
- `/jaina macro getlib <nombre>` - Importa de biblioteca
- `/jaina macro getall` - Importa todos de biblioteca
- `/jaina macro request` - Solicita lista del grupo

### API del Módulo
- `S.MacroSync:ShareMacro(name)` - Comparte un macro
- `S.MacroSync:ImportMacro(name)` - Importa macro compartido
- `S.MacroSync:ListLibraryMacros(class, spec)` - Lista biblioteca
- `S.MacroSync:ImportFromLibrary(name)` - Importa de biblioteca

---

## 🎯 RaidAssist.lua 

### Descripción
Asistente completo para raids con alertas personalizables e historial de wipes.

### Funcionalidades de Asistencia de Banda

#### 1. Sistema de Alertas Personalizables
- Alertas visuales con colores por tipo (INFO/WARNING/CRITICAL).
- Posición configurable: TOP, CENTER, BOTTOM.
- Sonidos personalizados por tipo de alerta.
- Animación de fade-out automática.

#### 2. Historial de Wipes
- Guardado persistente en SavedVariables.
- Estadísticas por zona y boss.
- Tiempo de combate y causa de muerte.
- Comandos para ver y limpiar historial.

#### 3. Integración Visual
- Botón satélite dedicado en la esfera.
- Indicador de estado raid/party.
- Submenú en el menú contextual.

### Comandos
- `/jaina wipehistory` - Ver historial de wipes
- `/jaina clearwipes` - Limpiar historial
- `/jaina alert [mensaje]` - Mostrar alerta de prueba
- `/jaina alertpos [top/center/bottom]` - Cambiar posición

### API del Módulo
- `S.RaidAssist:ShowAlert(msg, type, duration)` - Muestra alerta
- `S.RaidAssist:SetAlertPosition(pos)` - Cambia posición
- `S.RaidAssist:PrintWipeHistory()` - Imprime historial
- `S.RaidAssist:ClearWipeHistory()` - Limpia historial

---

## ⚔️ TrinketTracker.lua 

### Descripción
Tracker de Trinkets PvP enemigos para Arena y Battlegrounds.

### Funcionalidades Clave

#### 1. Detección Automática
- Detecta cuando un enemigo usa su trinket PvP.
- Soporta trinkets de facción y raciales (Will of the Forsaken, Every Man for Himself).
- Alerta visual y sonora al detectar uso.

#### 2. Timer de Cooldown
- Timer de 2 minutos por cada trinket usado.
- Muestra tiempo restante en panel flotante.
- Alerta cuando el trinket vuelve a estar disponible.

#### 3. Integración con Nameplates
- Iconos sobre nameplates enemigos mostrando estado del trinket.
- Desaturado cuando está en CD, normal cuando está listo.

#### 4. Anuncios Automáticos
- Anuncia en party/raid cuando un enemigo usa trinket (en arena).
- Comando para anunciar estado de todos los trinkets.

### Comandos
- `/jaina trinkets` - Abre/cierra el panel de trinkets
- `/jaina trinkets clear` - Limpia el tracker
- `/jaina trinkets announce` - Anuncia estado de trinkets al grupo

### API del Módulo
- `S.TrinketTracker:Toggle()` - Abre/cierra panel
- `S.TrinketTracker:GetTrinketStatus(name)` - Obtiene estado de trinket de un jugador
- `S.TrinketTracker:AnnounceAll()` - Anuncia todos los trinkets
- `S.TrinketTracker:ClearAll()` - Limpia el tracker

---

## 💀 WipeAnalyzer.lua 

### Descripción
Analizador de Wipes para raids que ayuda a identificar las causas de los wipes.

### Funcionalidades Clave

#### 1. Registro de Muertes
- Registra todas las muertes durante el combate.
- Guarda quién murió, cuándo, y por qué habilidad.
- Orden cronológico de muertes.

#### 2. Análisis de Primera Muerte
- Identifica quién murió primero (crítico para entender el wipe).
- Muestra la habilidad que causó la muerte.
- Muestra el enemigo que causó el daño.

#### 3. Verificación de Consumibles
- Detecta quién usó pociones/healthstones durante el combate.
- Lista jugadores que murieron sin usar consumibles.

#### 4. Tracking de Interrupts
- Registra interrupts exitosos.
- Ayuda a identificar si faltaron interrupts críticos.

#### 5. Historial de Wipes
- Guarda historial de wipes por sesión.
- Estadísticas por encuentro.

### Comandos
- `/jaina analyze` - Muestra análisis del último wipe
- `/jaina wipehistory` - Muestra historial de wipes
- `/jaina clearwipes` - Limpia historial

### API del Módulo
- `S.WipeAnalyzer:Toggle()` - Abre/cierra panel
- `S.WipeAnalyzer:Analyze()` - Analiza último wipe
- `S.WipeAnalyzer:AnnounceAnalysis()` - Anuncia análisis al raid
- `S.WipeAnalyzer:ShowHistory()` - Muestra historial

---

## 🧠 JainaSoulEngine.lua (NUEVO v10.1.0)

### Descripción
Motor de análisis de combate con predicción Time-To-Die y captura de estadísticas.

### Funcionalidades Clave

#### 1. Time-To-Die (TTD)
- Predicción por regresión lineal sobre 20 muestras de HP (cada 0.3s).
- Solo activo durante combate (PLAYER_REGEN events).
- Muestra segundos restantes para muerte del target.

#### 2. Stat Snapshot
- Captura: Spell Power, Attack Power, Crit, Haste, Armor, Dodge, Parry, Block, HP, Mana.
- Detección automática de main stat por clase.
- Comparación entre snapshots para detectar cambios de buffs/gear.

### API del Módulo
- `S.SoulEngine:GetTTD("target")` - Segundos hasta muerte
- `S.SoulEngine:GetTTDString("target")` - Formato legible ("23s", "1:45", "∞")
- `S.SoulEngine:GetSnapshot()` - Tabla completa de stats
- `S.SoulEngine:GetStat(stat)` - Stat individual
- `S.SoulEngine:CompareSnapshot(old)` - Diff entre snapshots

---

## 🕵️ JainaSpy.lua (NUEVO v10.1.0)

### Descripción
Módulo de inteligencia PvP. Detecta, trackea y alerta sobre enemigos cercanos y uso de stealth.

### Funcionalidades Clave

#### 1. Detección de Enemigos
- Detección via `COMBAT_LOG_EVENT_UNFILTERED` con flags de jugador hostil.
- Tracking por mouseover y target con clase real.
- Auto-limpieza a los 60s, máximo 20 enemigos.

#### 2. Alertas de Stealth
- Reconoce: Stealth, Prowl, Vanish, Invisibility, Shadowmeld (EN + esMX).
- Detecta openers: Cheap Shot, Ambush, Sap, Garrote, Pounce, Ravage.
- Frame de alerta rojo con fade de 4s y sonido configurable.
- Cooldown de 10s entre alertas para evitar spam.

#### 3. Panel de Enemigos
- Lista movible con 8 slots y colores por clase WoW.
- Timestamps relativos ("ahora", "15s", ">1m").
- Auto-muestra/oculta según haya enemigos.

### API del Módulo
- `S.Spy:GetEnemies()` - Lista de enemigos detectados
- `S.Spy:GetEnemyCount()` - Número de enemigos
- `S.Spy:IsStealthed(name)` - Verificar si un enemigo está en stealth

---

## 🎨 Theme.lua (NUEVO v10.1.0)

### Descripción
Sistema centralizado de colores con temas predefinidos para UI consistente.

### Temas Disponibles
| Tema | Primario | Secundario | Acento |
|---|---|---|---|
| **Demonio** (default) | Morado | Naranja fuego | Rosa |
| **Oscuro** | Cyan neón | Gris metálico | Blanco |
| **Clásico** | Dorado | Rojo sangre | Amarillo |

### API del Módulo
- `S.Theme:GetColor("primary")` - r, g, b, a
- `S.Theme:SetTheme("Oscuro")` - Cambia tema activo
- `S.Theme:StyleFrame(frame)` - Aplica tema a un frame
- `S.Theme:GetThemeName()` - Nombre del tema activo

---

## 👁️ TheOverlord.lua (REESCRITO v10.1.0)

### Descripción
HUD de combate con alertas de proc, barra de recursos y salud de mascota para todas las clases.

### Funcionalidades Clave

#### 1. Alertas de Proc
- Icono + texto con fade-in/out y glow pulsante.
- Procs: Shadow Trance, Backlash, Art of War, Rime, Killing Machine, Hot Streak, Brain Freeze, Sword and Board, Overpower, Surge of Light, Maelstrom Weapon (x5), Riposte.
- Soporte EN + esMX.

#### 2. Barra de Recurso
- Soul Shards (Warlock), Combo Points (Rogue/Druid), Runic Power (DK).
- Segmentos individuales con colores de clase.

#### 3. Salud de Mascota
- Barra compacta con icono de pet family.
- Glow rojo pulsante cuando HP < 20%.
- Clases: Warlock, Hunter, DK, Mage.

### Opciones (ModuleConfig)
- `showProcs` - Activar/desactivar alertas de proc
- `showResource` - Mostrar barra de recurso
- `showPetHealth` - Mostrar salud de mascota
- `opacity` - Opacidad global del HUD (0.1 - 1.0)

---

## 🎭 JainaHumor.lua (NUEVO v10.2.0)

### Descripción
Sistema interactivo de expresiones, frases cómicas e inmersión de hermandad ante actividades clave en mazmorras y bandas.

### Funcionalidades Clave
#### 1. Detección Inteligente por Eventos
- Escucha `UNIT_SPELLCAST_SENT` y `UNIT_SPELLCAST_SUCCEEDED` exclusivamente cuando el lanzador es el jugador (`unit == "player"`).
- Reemplazo dinámico de `%t` por el nombre del objetivo destinatario.

#### 2. Categorías Soportadas
- **Invocaciones:** Portal de reunión y rituales de brujo.
- **Pozos de Almas / Armario:** Piedras de salud para la banda.
- **Ruleta Rusa:** Ritual de la perdición / sacrificio voluntario.
- **Mesa de Mago / Refrigerio:** Buffet libre de carbohidratos mágicos.
- **Portales:** Teletransporte a capitales y advertencias sobre Dalaran Cráter.
- **Resurrección en Combate (BRez):** Druida (Renacer) y Brujo (Piedra de alma).
- **Resurrecciones Normales:** Paladín, Sacerdote y Chamán.
- **Heroísmo / Ansia de Sangre:** Gritos épicos de batalla.
- **Intervención Divina, Redirección, Festines y Reparaciones (Jeeves).**

#### 3. Seguridad Anti-Spam
- Cooldown interno de 12 segundos por categoría para evitar saturación de chat.
- Fallback seguro de canal (`RAID` -> `PARTY` -> `SAY`).

### Comandos
- `/shumor toggle` - Activar o desactivar el módulo.
- `/shumor channel [SAY|PARTY|RAID|YELL]` - Configurar canal de emisión.
- `/shumor test [CATEGORIA]` - Probar una frase cómica en chat.

---

**Nota:** Para detalles de implementación técnica, revisar el código fuente en `Modules/`.

