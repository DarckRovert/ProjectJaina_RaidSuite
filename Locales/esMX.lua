--[[
    SEQUITO - Localization (esMX)
]]--

local addonName, S = ...
S.L = S.L or {}

-- Si el cliente es esMX o esES
-- if GetLocale() == "esMX" or GetLocale() == "esES" then
    S.L["INITIALIZED"] = "Jaina: Sistema iniciado."
    S.L["OPTIONS"] = "Opciones"
    S.L["LOCKED"] = "Posición Bloqueada"
    S.L["UNLOCKED"] = "Posición Desbloqueada"
    
    -- RaidAssist System
    S.L["RAIDASSIST"] = "Asistente de Raid"
    S.L["RAIDASSIST_PANEL"] = "Panel de Asistente"
    S.L["RAIDASSIST_LEADER"] = "Panel de Líder"
    S.L["RAIDASSIST_ENABLED"] = "Sistema Activado"
    S.L["RAIDASSIST_MODE"] = "Modo"
    S.L["MODE_FARM"] = "Farmeo"
    S.L["MODE_PROGRESSION"] = "Progresión"
    
    -- Features
    S.L["INTERRUPT_COORDINATOR"] = "Coordinador de Interrupciones"
    S.L["COOLDOWN_SHARING"] = "Compartir Cooldowns"
    S.L["SMART_MARKERS"] = "Marcadores Inteligentes"
    S.L["CONSUMABLES_TRACKER"] = "Rastreador de Consumibles"
    S.L["PULL_TIMER"] = "Temporizador de Pull"
    S.L["WIPE_ANALYSIS"] = "Análisis Post-Wipe"
    S.L["MECHANIC_ANNOUNCEMENTS"] = "Avisos de Mecánicas"
    
    -- UI Elements - Options Panel
    S.L["RAIDASSIST_OPTIONS"] = "Opciones de Raid Assist"
    S.L["ENABLE_SYSTEM"] = "Sistema Raid Assist habilitado"
    S.L["ENABLE_SYSTEM_DESC"] = "Activa o desactiva el sistema completo de asistencia de raid"
    S.L["SELECT_MODE"] = "Modo de Operación:"
    S.L["MODE_DESC"] = "Ajusta el nivel de asistencia según el tipo de raid"
    S.L["MODE_FARM_TEXT"] = "Farm (menos avisos)"
    S.L["MODE_PROGRESSION_TEXT"] = "Progresión (más ayuda)"
    S.L["FEATURE_SETTINGS"] = "Funcionalidades:"
    S.L["RAIDASSIST_INFO"] = "Raid Assist funciona mejor cuando varios miembros del raid tienen Jaina instalado. Usa |cff00ff00/sequito ra|r para abrir el panel principal."
    S.L["INTERRUPT_DESC"] = "Rastrea y sugiere turnos de interrupción"
    S.L["COOLDOWN_DESC"] = "Sincroniza cooldowns importantes del raid"
    S.L["MARKERS_DESC"] = "Distribuye objetivos entre DPS automáticamente"
    S.L["CONSUMABLES_DESC"] = "Verifica flask/food de todos los miembros"
    S.L["PULLTIMER_DESC"] = "Countdown sincronizado para pulls"
    S.L["WIPEANALYSIS_DESC"] = "Detecta causas de muerte y patrones"
    S.L["ANNOUNCEMENTS_DESC"] = "Anuncia fases de boss y mecánicas importantes"
    
    -- UI Elements - RaidAssistUI
    S.L["SEQUITO_RAIDASSIST"] = "Jaina Asistente de Raid"
    S.L["TAB_STATUS"] = "Estado"
    S.L["TAB_COOLDOWNS"] = "Cooldowns"
    S.L["TAB_ASSIGNMENTS"] = "Asignaciones"
    S.L["TAB_STATS"] = "Estadísticas"
    S.L["USERS_WITH_SEQUITO"] = "Usuarios con Jaina:"
    S.L["CONSUMABLES_STATUS"] = "Estado de Consumibles:"
    S.L["UPDATE"] = "Actualizar"
    S.L["IMPORTANT_COOLDOWNS"] = "Cooldowns Importantes:"
    S.L["RAID_ASSIGNMENTS"] = "Asignaciones de Raid:"
    S.L["SESSION_STATS"] = "Estadísticas de Sesión:"
    S.L["WIPES"] = "Wipes"
    S.L["MODE"] = "Modo"
    S.L["RESET_COUNTER"] = "Reset Contador"
    S.L["RAID_LEADER"] = "Raid Leader"
    S.L["PULL_TIMER_10S"] = "Pull Timer (10s)"
    S.L["ANNOUNCE_PHASE_2"] = "Anunciar Fase 2"
    S.L["OPEN_FULL_PANEL"] = "Abrir Panel Completo"
    S.L["CONSUMABLES_REPORT"] = "=== Reporte de Consumibles ==="
    S.L["NO_FLASK"] = "Sin Flask:"
    S.L["NO_FOOD"] = "Sin Food:"
    S.L["ALL_HAVE_CONSUMABLES"] = "¡Todos tienen consumibles!"
    
    -- RaidAssist Messages
    S.L["RA_INITIALIZED"] = "|cFF00FFFFJaina RaidAssist|r: Inicializado"
    S.L["YOUR_ASSIGNED_TARGET"] = "Tu objetivo asignado:"
    S.L["PHASE_ANNOUNCED"] = "¡FASE %s!"
    S.L["PHASE_BY_PLAYER"] = "¡FASE %s! (anunciado por %s)"
    S.L["YOUR_ASSIGNMENT"] = "Tu asignación:"
    S.L["WIPE_NUMBER"] = "Wipe #%d"
    S.L["PULL_NOW"] = "¡PULL!"
    S.L["PULL_IN_SECONDS"] = "Pull en: %.1f"
    S.L["WIPE_ANALYSIS_HEADER"] = "=== Análisis de Wipe ==="
    S.L["WIPE_ANALYSIS_LINE"] = "%d. %s (%d jugadores)"
    S.L["MODE_CHANGED_TO"] = "Modo cambiado a: %s"
    
    -- Messages
    S.L["INTERRUPT_READY"] = "Interrupción lista"
    S.L["INTERRUPT_USED"] = "usó interrupción en"
    S.L["COOLDOWN_READY"] = "Cooldown listo:"
    S.L["CD_READY"] = "Listo" -- Clave faltante añadida
    S.L["COOLDOWN_USED"] = "Cooldown usado:"
    
    -- Critical Fixes (Missing Keys)
    S.L["WIPE_ANALYZER_TITLE"] = "Analizador de Wipes"
    S.L["SECTION_FIRST_DEATH"] = "Primera Muerte"
    S.L["SYSTEM_ONLINE"] = "Sistema en Línea"
    S.L["COOLDOWN_MONITOR"] = "Monitor de Cooldowns"
    S.L["ASSIGNMENTS_PANEL"] = "Panel de Asignaciones"
    
    -- v10.0 Strings
    S.L["DASHBOARD_TITLE"] = "Jaina Dashboard"
    S.L["CONNECT_TITLE"] = "Jaina Connect"
    S.L["COACH_TITLE"] = "Smart Coach"
    S.L["EXPORT_REPORT"] = "Reporte Raid"
    S.L["EXPORT_PROFILE"] = "Exportar Perfil"
    S.L["REPORT_GENERATED"] = "Reporte Generado"
    S.L["PROFILE_GENERATED"] = "Perfil Generado"
    S.L["COPY_PASTE"] = "Copia este texto (Ctrl+C)"
    
    S.L["COACH_MANA"] = "Mana Crítico"
    S.L["COACH_BUFF"] = "¡Falta Buff!"
    S.L["COACH_DANGER"] = "¡PELIGRO!"
    S.L["COACH_DEATH_PATTERN"] = "Has muerto 2 veces por %s"
    
    S.L["ASSIGN_AUTO_SUCCESS"] = "Asignación automática completada"
    
    S.L["TARGET_ASSIGNED"] = "Objetivo asignado:"
    S.L["MISSING_FLASK"] = "¡Falta Flask!"
    S.L["MISSING_FOOD"] = "¡Falta Comida!"
    S.L["PULL_IN"] = "Pull en"
    S.L["SECONDS"] = "segundos"
    S.L["PHASE"] = "Fase"
    S.L["WIPE_COUNT"] = "Wipes:"
    S.L["WIPE_DETECTED"] = "Wipe detectado"
    
    -- MacroSync System
    S.L["MACROSYNC"] = "Macros Compartidos"
    S.L["MACROSYNC_INITIALIZED"] = "Sistema de macros compartidos iniciado"
    S.L["MACRO_SHARED"] = "Macro '%s' compartido con el grupo"
    S.L["MACRO_RECEIVED"] = "Macro '%s' recibido de %s"
    S.L["MACRO_IMPORTED"] = "Macro '%s' importado exitosamente"
    S.L["MACRO_NOT_FOUND"] = "Macro '%s' no encontrado"
    S.L["MACRO_LIBRARY"] = "Biblioteca de Macros"
    S.L["MACRO_LIBRARY_CLASS"] = "Biblioteca de Macros: %s"
    S.L["SHARED_MACROS"] = "Macros Compartidos"
    S.L["NO_SHARED_MACROS"] = "No hay macros compartidos"
    S.L["MACRO_REQUEST_SENT"] = "Solicitando macro '%s' a %s"
    S.L["MACRO_LIST_REQUEST"] = "Solicitando lista de macros del grupo"
    S.L["MACROS_FROM_PLAYER"] = "Macros de %s:"
    S.L["ALL_SPECS"] = "Todas"
    S.L["SPEC_NUM"] = "Spec %d"
    S.L["DEATH_CAUSE"] = "Causa de muerte:"
    
    -- Alerts
    S.L["ALERT_POSITION"] = "Posici\195\179n de Alertas"
    S.L["ALERT_TOP"] = "Arriba"
    S.L["ALERT_CENTER"] = "Centro"
    S.L["ALERT_BOTTOM"] = "Abajo"
    S.L["ALERT_SOUND"] = "Sonido de Alertas"
    S.L["ALERT_FLASH"] = "Flash de Pantalla"
    S.L["ALERT_DURATION"] = "Duraci\195\179n de Alertas"
    
    -- Wipe History
    S.L["WIPE_HISTORY"] = "Historial de Wipes"
    S.L["WIPE_STATS"] = "Estad\195\173sticas de Wipes"
    S.L["TOTAL_WIPES"] = "Total de wipes"
    S.L["AVG_DURATION"] = "Duraci\195\179n promedio"
    S.L["BY_ZONE"] = "Por zona"
    S.L["COMMON_DEATHS"] = "Causas comunes de muerte"
    S.L["CLEAR_HISTORY"] = "Borrar Historial"
    S.L["HISTORY_CLEARED"] = "Historial de wipes borrado."
    
    -- Commands
    S.L["CHECK_CONSUMABLES"] = "Revisar Consumibles"
    S.L["VIEW_WIPES"] = "Ver Wipes"
    S.L["CHANGE_MODE"] = "Cambiar Modo"
    S.L["RESET_WIPES"] = "Reiniciar Contador"
    S.L["ANNOUNCE_PHASE"] = "Anunciar Fase"
    
    -- Status
    S.L["ONLINE"] = "En línea"
    S.L["OFFLINE"] = "Desconectado"
    S.L["READY"] = "Listo"
    S.L["NOT_READY"] = "No listo"
    S.L["ACTIVE"] = "Activo"
    S.L["INACTIVE"] = "Inactivo"
    
    -- Assignments
    S.L["ASSIGN_TASK"] = "Asignar Tarea"
    S.L["ASSIGNMENT"] = "Asignación"
    S.L["ASSIGNED_TO"] = "asignado a"
    S.L["NO_ASSIGNMENTS"] = "Sin asignaciones"
    
-- else (merged)
    -- Fallback English
    S.L["INITIALIZED"] = "Jaina: System started."
    S.L["OPTIONS"] = "Options"
    S.L["LOCKED"] = "Position Locked"
    S.L["UNLOCKED"] = "Position Unlocked"
    
    -- RaidAssist System
    S.L["RAIDASSIST"] = "Raid Assist"
    S.L["RAIDASSIST_PANEL"] = "Assist Panel"
    S.L["RAIDASSIST_LEADER"] = "Leader Panel"
    S.L["RAIDASSIST_ENABLED"] = "System Enabled"
    S.L["RAIDASSIST_MODE"] = "Mode"
    S.L["MODE_FARM"] = "Farm"
    S.L["MODE_PROGRESSION"] = "Progression"
    
    -- Features
    S.L["INTERRUPT_COORDINATOR"] = "Interrupt Coordinator"
    S.L["COOLDOWN_SHARING"] = "Cooldown Sharing"
    S.L["SMART_MARKERS"] = "Smart Markers"
    S.L["CONSUMABLES_TRACKER"] = "Consumables Tracker"
    S.L["PULL_TIMER"] = "Pull Timer"
    S.L["WIPE_ANALYSIS"] = "Wipe Analysis"
    S.L["MECHANIC_ANNOUNCEMENTS"] = "Mechanic Announcements"
    
    -- UI Elements - Options Panel
    S.L["RAIDASSIST_OPTIONS"] = "RaidAssist Options"
    S.L["ENABLE_SYSTEM"] = "Enable RaidAssist System"
    S.L["ENABLE_SYSTEM_DESC"] = "Enable or disable the complete raid assistance system"
    S.L["SELECT_MODE"] = "Select Mode:"
    S.L["MODE_DESC"] = "Adjust assistance level based on raid type"
    S.L["MODE_FARM_TEXT"] = "Farm (less warnings)"
    S.L["MODE_PROGRESSION_TEXT"] = "Progression (more help)"
    S.L["FEATURE_SETTINGS"] = "Features:"
    S.L["RAIDASSIST_INFO"] = "RaidAssist works best when multiple raid members have Jaina installed. Use |cff00ff00/sequito ra|r to open main panel."
    S.L["INTERRUPT_DESC"] = "Track and suggest interrupt rotations"
    S.L["COOLDOWN_DESC"] = "Synchronize important raid cooldowns"
    S.L["MARKERS_DESC"] = "Distribute targets among DPS automatically"
    S.L["CONSUMABLES_DESC"] = "Verify flask/food for all members"
    S.L["PULLTIMER_DESC"] = "Synchronized countdown for pulls"
    S.L["WIPEANALYSIS_DESC"] = "Detect death causes and patterns"
    S.L["ANNOUNCEMENTS_DESC"] = "Announce boss phases and important mechanics"
    
    -- UI Elements - RaidAssistUI
    S.L["SEQUITO_RAIDASSIST"] = "Jaina Raid Assist"
    S.L["TAB_STATUS"] = "Status"
    S.L["TAB_COOLDOWNS"] = "Cooldowns"
    S.L["TAB_ASSIGNMENTS"] = "Assignments"
    S.L["TAB_STATS"] = "Statistics"
    S.L["USERS_WITH_SEQUITO"] = "Users with Jaina:"
    S.L["CONSUMABLES_STATUS"] = "Consumables Status:"
    S.L["UPDATE"] = "Update"
    S.L["IMPORTANT_COOLDOWNS"] = "Important Cooldowns:"
    S.L["RAID_ASSIGNMENTS"] = "Raid Assignments:"
    S.L["SESSION_STATS"] = "Session Statistics:"
    S.L["WIPES"] = "Wipes"
    S.L["MODE"] = "Mode"
    S.L["RESET_COUNTER"] = "Reset Counter"
    S.L["RAID_LEADER"] = "Raid Leader"
    S.L["PULL_TIMER_10S"] = "Pull Timer (10s)"
    S.L["ANNOUNCE_PHASE_2"] = "Announce Phase 2"
    S.L["OPEN_FULL_PANEL"] = "Open Full Panel"
    S.L["CONSUMABLES_REPORT"] = "=== Consumables Report ==="
    S.L["NO_FLASK"] = "No Flask:"
    S.L["NO_FOOD"] = "No Food:"
    S.L["ALL_HAVE_CONSUMABLES"] = "Everyone has consumables!"
    
    -- RaidAssist Messages
    S.L["RA_INITIALIZED"] = "|cFF00FFFFJaina RaidAssist|r: Initialized"
    S.L["YOUR_ASSIGNED_TARGET"] = "Your assigned target:"
    S.L["PHASE_ANNOUNCED"] = "PHASE %s!"
    S.L["PHASE_BY_PLAYER"] = "PHASE %s! (announced by %s)"
    S.L["YOUR_ASSIGNMENT"] = "Your assignment:"
    S.L["WIPE_NUMBER"] = "Wipe #%d"
    S.L["PULL_NOW"] = "PULL!"
    S.L["PULL_IN_SECONDS"] = "Pull in: %.1f"
    S.L["WIPE_ANALYSIS_HEADER"] = "=== Wipe Analysis ==="
    S.L["WIPE_ANALYSIS_LINE"] = "%d. %s (%d players)"
    S.L["MODE_CHANGED_TO"] = "Mode changed to: %s"
    
    -- Messages
    S.L["INTERRUPT_READY"] = "Interrupt ready"
    S.L["INTERRUPT_USED"] = "used interrupt on"
    S.L["COOLDOWN_READY"] = "Cooldown ready:"
    S.L["COOLDOWN_USED"] = "Cooldown used:"
    S.L["TARGET_ASSIGNED"] = "Target assigned:"
    S.L["MISSING_FLASK"] = "Missing Flask!"
    S.L["MISSING_FOOD"] = "Missing Food!"
    S.L["PULL_IN"] = "Pull in"
    S.L["SECONDS"] = "seconds"
    S.L["PHASE"] = "Phase"
    S.L["WIPE_COUNT"] = "Wipes:"
    S.L["WIPE_DETECTED"] = "Wipe detected"
    S.L["DEATH_CAUSE"] = "Death cause:"
    
    -- Commands
    S.L["CHECK_CONSUMABLES"] = "Check Consumables"
    S.L["VIEW_WIPES"] = "View Wipes"
    S.L["CHANGE_MODE"] = "Change Mode"
    S.L["RESET_WIPES"] = "Reset Counter"
    S.L["ANNOUNCE_PHASE"] = "Announce Phase"
    
    -- Status
    S.L["ONLINE"] = "Online"
    S.L["OFFLINE"] = "Offline"
    S.L["READY"] = "Ready"
    S.L["NOT_READY"] = "Not ready"
    S.L["ACTIVE"] = "Active"
    S.L["INACTIVE"] = "Inactive"
    
    -- Assignments
    S.L["ASSIGN_TASK"] = "Assign Task"
    S.L["ASSIGNMENT"] = "Assignment"
    S.L["ASSIGNED_TO"] = "assigned to"
    S.L["NO_ASSIGNMENTS"] = "No assignments"
    
    -- TrinketTracker (v7.2.0)
    S.L["TRINKET_TRACKER"] = "Tracker de Trinkets"
    S.L["TRINKET_USED"] = "usó TRINKET!"
    S.L["TRINKET_READY"] = "tiene trinket LISTO!"
    S.L["TRINKETS_ON_CD"] = "Trinkets en CD:"
    S.L["TRINKETS_READY"] = "Trinkets LISTOS:"
    S.L["TRINKET_CLEARED"] = "Trinket tracker limpiado"
    S.L["ENEMY_TRINKETS"] = "Trinkets Enemigos"
    
    -- WipeAnalyzer (v7.2.0)
    S.L["WIPE_ANALYZER"] = "Analizador de Wipes"
    S.L["WIPE_DETECTED"] = "¡Wipe detectado!"
    S.L["FIRST_DEATH"] = "Primera muerte:"
    S.L["NO_CONSUMABLES"] = "Sin poción/healthstone:"
    S.L["TOTAL_DEATHS"] = "Total muertes:"
    S.L["INTERRUPTS_SUCCESS"] = "Interrupts exitosos:"
    S.L["WIPE_ANALYSIS"] = "ANÁLISIS DE WIPE"
    S.L["ANALYSIS_CLEARED"] = "Análisis limpiado"
    S.L["NO_WIPE_DATA"] = "No hay datos de wipe para analizar"
    
    -- CooldownMonitor (v8.0.0)
    S.L["COOLDOWN_MONITOR"] = "Raid Cooldowns"
    S.L["RAID_COOLDOWNS"] = "Cooldowns del Raid"
    S.L["BRES_AVAILABLE"] = "Battle Res disponibles:"
    S.L["LUST_AVAILABLE"] = "Heroism/Bloodlust disponible"
    S.L["NO_BRES"] = "No hay Battle Res disponibles"
    S.L["CD_READY"] = "LISTO"
    S.L["FILTER_ALL"] = "Todos"
    S.L["FILTER_BRES"] = "BRes"
    S.L["FILTER_LUST"] = "Lust"
    S.L["FILTER_RAID_CD"] = "Raid CD"
    S.L["FILTER_EXTERNAL"] = "External"
    S.L["FILTER_TANK_CD"] = "Tank CD"
    S.L["CM_TIMELINE_MODE"] = "Modo Cronograma"
    S.L["CM_COMPACT_MODE"] = "Modo Compacto"
    S.L["CM_CLASS_COLOR"] = "Color por Clase"
    S.L["SEQUITO_PLATES"] = "Jaina Plates"
    S.L["SHOW_CC"] = "Mostrar CC"
    S.L["SHOW_THREAT"] = "Mostrar Amenaza"
    S.L["SCALE"] = "Escala"
    
    -- Module Headers
    S.L["MODULE_OPTIONS"] = "Opciones"
    S.L["MODULE_HELP"] = "Ayuda"
    
    -- Assignments (v8.0.0)
    S.L["ASSIGNMENTS_PANEL"] = "Asignaciones de Raid"
    S.L["INTERRUPT_ROTATION"] = "Rotación de Cortes"
    S.L["AVAILABLE"] = "Disponibles"
    S.L["ACTIVE_ROTATION"] = "Rotación Activa"
    S.L["EMPTY"] = "Vacío"
    S.L["AUTO_GENERATE"] = "Auto-Generar"
    S.L["ANNOUNCE"] = "Anunciar"
    S.L["CLEAR"] = "Limpiar"
    S.L["SYNC"] = "Sincronizar"
    S.L["NO_INTERRUPTERS"] = "No hay interrupters detectados"
    S.L["ASSIGN_AUTO_SUCCESS"] = "Rotación asignada automáticamente"
    S.L["ASSIGN_CLEARED"] = "Todas las asignaciones han sido limpiadas"
    S.L["TANK_ASSIGNMENTS"] = "Asignación de Tanques"
    S.L["HEALER_ASSIGNMENTS"] = "Asignación de Healers"
    S.L["MARK_ASSIGNMENTS"] = "Asignación de Marcas"
    S.L["NOTE_PLACEHOLDER"] = "Escribe aquí las asignaciones..."
    S.L["ANNOUNCE_RAID"] = "Anunciar a Raid"
    
    -- Config Options
    S.L["CFG_ENABLED"] = "Habilitar"
    S.L["CFG_ANNOUNCE"] = "Anunciar en chat"
    S.L["CFG_LOCKED"] = "Bloquear Marco"
    S.L["CFG_SCALE"] = "Escala"
    S.L["CFG_TRACK_INTERRUPTS"] = "Registrar Cortes"
    S.L["CFG_MIN_DURATION"] = "Duración Mínima (s)"
    
    -- WipeAnalyzer (v8.0.0)
    S.L["WIPE_ANALYZER_TITLE"] = "ANÁLISIS DE WIPE"
    S.L["WIPE_SUMMARY_FMT"] = "Combate: %s\nDuración: |cffffffff%.1f seg|r | Muertes: |cffff0000%d|r"
    S.L["SECTION_FIRST_DEATH"] = "PRIMERA MUERTE:"
    S.L["SECTION_NO_CONSUMABLES"] = "SIN POCIÓN / HEALTHSTONE"
    S.L["SECTION_INTERRUPTS"] = "INTERRUPTS"
    S.L["SECTION_TIMELINE"] = "CRONOLOGÍA"
    S.L["DEATH_REPORT_FMT"] = "Murió a los %.1fs por %s (%s)"
    
    -- Option Categories
    S.L["CAT_GENERAL"] = "General"
    S.L["CAT_INTERFACE"] = "Interfaz"
    S.L["CAT_PVP"] = "PvP"
    S.L["CAT_RAID"] = "Raid"
    S.L["CAT_DUNGEON"] = "Dungeon"
    S.L["CAT_CLASS"] = "Clase"
    S.L["CAT_UTILITY"] = "Utilidades"
    S.L["SYSTEM_ONLINE"] = "Sistema Online"
    
    -- ReadyChecker (v7.2.0)
    S.L["READY_CHECKER"] = "Chequeo Pre-Pull"
    S.L["SCAN_RAID"] = "Escanear Raid"
    S.L["ANNOUNCE_PROBLEMS"] = "Anunciar Problemas"
    S.L["ALL_READY"] = "¡Todos listos!"
    S.L["PROBLEMS_DETECTED"] = "Problemas detectados:"
    S.L["MISSING_POISON"] = "Veneno"
    S.L["MISSING_PET"] = "Mascota"
    S.L["MISSING_FLASK"] = "Sin Flask"
    S.L["MISSING_FOOD"] = "Sin Comida"
    S.L["LOW_MANA"] = "Mana bajo"
    S.L["DEAD"] = "MUERTO"
    S.L["AFK"] = "AFK"
    S.L["DISCONNECTED"] = "DESCONECTADO"
    
    -- FocusFire (v8.0.0)
    S.L["FOCUSFIRE_PANEL"] = "Panel de Focus Fire"
    S.L["CALL_TARGET"] = "Llamar Target"
    S.L["FOCUS_TARGET"] = "¡FOCUS!"
    S.L["TARGET_CALLED"] = "Target llamado"
    S.L["NO_TARGET"] = "Sin objetivo"
    
    -- CCCoordinator (v8.0.0)
    S.L["CC_PANEL"] = "Coordinador de CC"
    S.L["ASSIGN_CC"] = "Asignar CC"
    S.L["CC_BROKEN"] = "¡CC ROTO!"
    S.L["DR_WARNING"] = "DR activo"
    S.L["CC_IMMUNE"] = "Inmune a CC"
    
    -- HealerTracker (v8.0.0)
    S.L["HEALER_TRACKER"] = "Monitor de Healers"
    S.L["LOW_MANA_ALERT"] = "¡Healer bajo de mana!"
    S.L["OOM"] = "SIN MANA"
    S.L["ENEMY_HEALERS"] = "Healers Enemigos"
    
    -- DefensiveAlerts (v8.0.0)
    S.L["DEFENSIVE_PANEL"] = "Alertas Defensivas"
    S.L["NEED_PEEL"] = "¡NECESITO PEEL!"
    S.L["NEED_HEAL"] = "¡NECESITO HEAL!"
    S.L["NEED_DISPEL"] = "¡NECESITO DISPEL!"
    S.L["USING_DEFENSIVE"] = "Usando defensivo"
    
    -- PullGuide (v8.0.0)
    S.L["PULL_GUIDE"] = "Guía de Pulls"
    S.L["MARK_PACK"] = "Marcar Pack"
    S.L["SUGGEST_CC"] = "Sugerir CC"
    S.L["KILL_ORDER"] = "Orden de Kill"
    
    -- DungeonTimer (v8.0.0)
    S.L["DUNGEON_TIMER"] = "Timer de Dungeons"
    S.L["HEROIC_RESET"] = "Reset de Heroicas"
    S.L["COMPLETED_TODAY"] = "Completadas Hoy"
    S.L["TIME_REMAINING"] = "Tiempo Restante"
    
    -- LootCouncil (v8.0.0)
    S.L["LOOT_COUNCIL"] = "Loot Council"
    S.L["START_SESSION"] = "Iniciar Sesión"
    S.L["END_SESSION"] = "Terminar Sesión"
    S.L["VOTE"] = "Votar"
    S.L["PASS"] = "Pasar"
    S.L["NEED"] = "Necesito"
    S.L["GREED"] = "Codicia"
    
    -- LootCouncil (v8.0.0)
    S.L["LC_TITLE"] = "Loot Council"
    S.L["LC_ONLY_LEADER"] = "Solo líderes pueden iniciar Loot Council"
    S.L["LC_STARTING"] = "Iniciando sesión de Loot Council para: %s"
    S.L["LC_VOTE_BTN"] = "Votar"
    S.L["LC_WINNER"] = "%s gana: %s"
    S.L["LC_CANDIDATE"] = "Candidato"
    S.L["LC_RESPONSE"] = "Respuesta"
    S.L["LC_VOTES"] = "Votos"
    
    -- PlayerNotes (v8.0.0)
    S.L["PLAYER_NOTES"] = "Notas de Jugadores"
    S.L["ADD_NOTE"] = "Agregar Nota"
    S.L["DELETE_NOTE"] = "Eliminar Nota"
    S.L["SHARE_NOTE"] = "Compartir Nota"
    
    -- BuildManager (v8.0.0)
    S.L["BUILD_MANAGER"] = "Gestor de Builds"
    S.L["SAVE_BUILD"] = "Guardar Build"
    S.L["LOAD_BUILD"] = "Cargar Build"
    S.L["SHARE_BUILD"] = "Compartir Build"
    S.L["DELETE_BUILD"] = "Eliminar Build"
    
    -- EventCalendar (v8.0.0)
    S.L["EVENT_CALENDAR"] = "Calendario de Eventos"
    S.L["UPCOMING_EVENTS"] = "Próximos Eventos"
    S.L["CONFIRM_ATTENDANCE"] = "Confirmar Asistencia"
    S.L["DECLINE"] = "Rechazar"
    S.L["TENTATIVE"] = "Tentativo"
    
    -- PerformanceStats (v8.0.0)
    S.L["PERFORMANCE_STATS"] = "Estadísticas de Rendimiento"
    S.L["AVERAGE_DPS"] = "DPS Promedio"
    S.L["AVERAGE_HPS"] = "HPS Promedio"
    S.L["BEST_PERFORMANCE"] = "Mejor Rendimiento"
    S.L["COMPARE_RAIDS"] = "Comparar Raids"
    
    -- VotingSystem (v8.0.0)
    S.L["VOTING_SYSTEM"] = "Sistema de Votaciones"
    S.L["CREATE_POLL"] = "Crear Votación"
    S.L["VOTE_YES"] = "Sí"
    S.L["VOTE_NO"] = "No"
    S.L["POLL_RESULTS"] = "Resultados"
    S.L["POLL_ENDED"] = "Votación Terminada"
    
    -- VersionSync (v8.0.0)
    S.L["VERSION_SYNC"] = "Sincronización de Versiones"
    S.L["CHECK_VERSIONS"] = "Verificar Versiones"
    S.L["OUTDATED_VERSION"] = "Versión Desactualizada"
    S.L["UP_TO_DATE"] = "Actualizado"
    S.L["UPDATE_AVAILABLE"] = "¡Actualización Disponible!"
    
    -- QuickWhisper (v8.0.0)
    S.L["QUICK_WHISPER"] = "Quick Whisper"
    S.L["TEMPLATE_INV"] = "Inv please"
    S.L["TEMPLATE_AFK"] = "AFK 5 min"
    S.L["TEMPLATE_SUMMON"] = "Need summon"
    S.L["TEMPLATE_READY"] = "Ready"
    S.L["TEMPLATE_BRB"] = "BRB"
    
-- Redundant English keys removed to favor Spanish definitions above
    
    -- Register Global Binding Strings (for WoW Menu)
    _G["BINDING_HEADER_SEQUITO"] = "Jaina"
    _G["BINDING_NAME_SEQUITO_MOUNT"] = "Montura Inteligente"
    _G["BINDING_NAME_SEQUITO_TARGET"] = "Atacar/Targetear"
    _G["BINDING_NAME_SEQUITO_PEEL"] = "Pedir Peel"
    _G["BINDING_NAME_SEQUITO_HEAL"] = "Pedir Cura"
    _G["BINDING_NAME_SEQUITO_DISPEL"] = "Pedir Dispel"
    _G["BINDING_NAME_SEQUITO_DEFENSIVE"] = "Anunciar Defensivo"
    _G["BINDING_NAME_SEQUITO_WHISPER1"] = "Mensaje Rápido 1"
    _G["BINDING_NAME_SEQUITO_WHISPER2"] = "Mensaje Rápido 2"
    _G["BINDING_NAME_SEQUITO_WHISPER3"] = "Mensaje Rápido 3"
    _G["BINDING_NAME_SEQUITO_CALLTARGET"] = "Marcar Foco (FocusFire)"
    _G["BINDING_NAME_SEQUITO_CALLCC"] = "Anunciar CC"
    _G["BINDING_NAME_SEQUITO_MARKPACK"] = "Marcar Pack (Pull)"
    _G["BINDING_NAME_SEQUITO_VOTE_YES"] = "Votar: Sí"
    _G["BINDING_NAME_SEQUITO_VOTE_NO"] = "Votar: No"
    
    -- Bindings (v8.0.0)
    _G["BINDING_NAME_SEQUITO_OPTIONS"] = "Abrir Configuración"
    _G["BINDING_NAME_SEQUITO_ASSIGNMENTS"] = "Panel de Asignaciones"
    _G["BINDING_NAME_SEQUITO_WIPE"] = "Analizar Último Wipe"
    _G["BINDING_NAME_SEQUITO_COOLDOWNS"] = "Monitor de Cooldowns"
    _G["BINDING_NAME_SEQUITO_PULL_TIMER"] = "Iniciar Pull (10s)"

    -- Gamification & Achievements
    S.L["ACH_INITIATE"] = "Iniciado"
    S.L["ACH_INITIATE_DESC"] = "Inicia sesión con el addon Jaina activo en tu hermandad."
    S.L["ACH_MACRO_MASTER"] = "Maestro de Macros"
    S.L["ACH_MACRO_MASTER_DESC"] = "Genera un conjunto de macros automáticas optimizadas para tu clase."
    S.L["ACH_WIPE_SAVIOR"] = "Salvador de Banda"
    S.L["ACH_WIPE_SAVIOR_DESC"] = "Lanza un hechizo crucial de salvamento (Himno Divino, Tranquilidad o Renacer) en combate."
    S.L["ACH_CANNON_FODDER"] = "Carne de Cañón"
    S.L["ACH_CANNON_FODDER_DESC"] = "Caer en combate durante una estancia o encuentro desafiante."

    -- Menu & Quick Settings
    S.L["OPEN_OPTIONS"] = "Abrir Opciones"
    S.L["ANALYZE_WIPE"] = "Analizar Último Wipe"
    S.L["COOLDOWN_MONITOR"] = "Monitor de Cooldowns"
    S.L["RAID_TOOLS"] = "Herramientas de Raid"
    S.L["READY_CHECK"] = "Comprobación de Listos"
    S.L["QUICK_SETTINGS"] = "Ajustes Rápidos"
    S.L["LOCK_SPHERE"] = "Bloquear Esfera"

    -- Academy & Inspection
    S.L["ACADEMY_INSPECTOR"] = "Inspector de Academia"
    S.L["TALENTS"] = "Talentos"
    S.L["ILVL_APPROX"] = "Nivel de Objeto Aprox."
    S.L["COOLDOWN_ASSIGNMENTS"] = "Asignaciones de Cooldowns"
    S.L["NOT_RAID_LEADER"] = "Solo el Líder de Banda puede ejecutar esta acción."

    -- Humor & Fun Speech
    S.L["HUMOR_TITLE"] = "Frases y Humor de Incursión"
    S.L["HUMOR_DESC"] = "Expresiones cómicas e inmersivas automáticas para actividades de hermandad."
    S.L["HUMOR_ENABLED"] = "Habilitar Modo Humor"
-- end
