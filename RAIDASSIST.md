# Project Jaina RaidSuite - RaidAssist - Guía Completa

**Versión:** 10.2.0 (Definitive Edition)  
**Autor:** DarckRovert (Ingame: Elnazzareno) & Project Jaina Team  
**Cliente WoW:** 3.3.5a (Build 12340)

---

## 📋 Descripción

RaidAssist es un sistema colaborativo que permite a toda la guild coordinar mejor en raids cuando todos usan Jaina. Comparte información automáticamente entre jugadores para mejorar la coordinación.

---

## 🚀 Funcionalidades

### 1. **Coordinador de Interrupciones**
- Rastrea quién usó interrupciones recientemente
- Sugiere quién debería interrumpir el siguiente cast
- Evita que todos interrumpan al mismo tiempo

**Uso:**
- Automático - solo usa tus interrupciones normalmente
- El addon rastrea y coordina automáticamente

---

### 2. **Compartir Cooldowns Importantes**
- Muestra los CDs de todo el raid en tiempo real
- Incluye: Bloodlust, Battle Rez, defensivos importantes
- El raid leader puede planificar mejor el uso de CDs

**Uso:**
```
/jaina ra
```
Ve a la pestaña "Cooldowns" para ver todos los CDs disponibles

---

### 3. **Sistema de Marcadores Inteligente**
- Distribuye objetivos automáticamente entre DPS
- Evita que todos ataquen el mismo mob

**Uso (solo Raid Leader):**
```lua
-- En un script o macro
S.RaidAssist:AssignTargets({"Skull", "Cross", "Square"})
```

---

### 4. **Avisos de Mecánicas de Boss**
- Anuncia fases del boss a todo el raid
- Alertas visuales y sonoras

**Uso:**
```
/jaina phase 2
```
Todos los jugadores con Jaina verán: "¡FASE 2!"

---

### 5. **Tracker de Consumibles del Raid**
- Verifica quién tiene flask y food buff
- Reporte rápido antes de pull

**Uso:**
```
/jaina checkcons
```
Muestra quién NO tiene consumibles activos

---

### 6. **Sistema de Asignaciones**
- El raid leader asigna tareas específicas
- Cada jugador ve su asignación

**Uso (solo Raid Leader):**
```lua
S.RaidAssist:AssignRole("NombreJugador", "Interrumpir adds izquierda")
```

---

### 7. **Contador de Muertes/Wipes**
- Cuenta automáticamente los wipes
- Útil para ver progreso en bosses nuevos

**Uso:**
```
/jaina wipes          -- Ver contador
/jaina resetwipes     -- Reiniciar contador
```

---

### 8. **Sincronización de Pull Timer**
- Countdown sincronizado para todo el raid
- Todos ven el mismo timer

**Uso:**
```
/jaina pull 10        -- Pull en 10 segundos
/jaina pull 5         -- Pull en 5 segundos
```

---

### 9. **Detector de Problemas Post-Wipe**
- Analiza por qué murió la gente
- Ayuda a identificar problemas comunes

**Uso:**
```lua
S.RaidAssist:AnalyzeWipe()
```

---

### 10. **Modo Progresión vs Farm**
- **Progresión**: Más avisos, más ayudas visuales
- **Farm**: Minimalista, solo lo esencial

**Uso:**
```
/jaina mode progression
/jaina mode farm
/jaina mode              -- Toggle entre modos
```

---

## 🎮 Comandos Principales

### Para Todos los Jugadores
```
/jaina ra                 -- Abrir panel de RaidAssist
/jaina wipes              -- Ver contador de wipes
/jaina mode               -- Cambiar modo
```

### Para Raid Leaders
```
/jaina raleader           -- Panel compacto de líder
/jaina pull [segundos]    -- Iniciar pull timer
/jaina phase [número]     -- Anunciar fase
/jaina checkcons          -- Revisar consumibles
/jaina resetwipes         -- Reiniciar contador
```

---

## 📊 Interfaz de Usuario

### Panel Principal (`/jaina ra`)
Tiene 4 pestañas:

1. **Estado**: Muestra quién tiene Jaina y estado de consumibles
2. **Cooldowns**: Lista de CDs importantes del raid
3. **Asignaciones**: Tareas asignadas a cada jugador
4. **Estadísticas**: Wipes, modo actual, etc.

### Panel de Líder (`/jaina raleader`)
Panel compacto con botones rápidos:
- Pull Timer (10s)
- Anunciar Fase 2
- Revisar Consumibles
- Abrir Panel Completo

---

## 🔧 Configuración

El sistema funciona automáticamente cuando:
1. Estás en un grupo/raid
2. Otros jugadores también tienen Jaina instalado
3. El addon detecta automáticamente quién tiene Jaina

**No requiere configuración manual.**

---

## 💡 Tips de Uso

### Para Raid Leaders:
1. Usa `/jaina raleader` para tener acceso rápido a funciones importantes
2. Antes de cada pull, usa `/jaina checkcons` para verificar consumibles
3. Usa `/jaina pull 10` para dar tiempo a todos de prepararse
4. Cambia a modo "progression" en bosses nuevos para más ayudas

### Para Miembros del Raid:
1. Mantén `/jaina ra` abierto para ver información del raid
2. Presta atención a las asignaciones que te lleguen
3. Usa tus interrupciones normalmente - el addon coordina automáticamente

---

## 🐛 Solución de Problemas

**No veo a otros jugadores en la lista:**
- Asegúrate de estar en grupo/raid
- Verifica que ellos también tengan Jaina instalado
- Espera unos segundos - la sincronización toma tiempo

**Los cooldowns no se actualizan:**
- Haz click en "Actualizar" en la pestaña de Cooldowns
- La actualización automática ocurre cada 2 segundos

**El pull timer no aparece:**
- Verifica que el raid leader haya usado el comando
- Asegúrate de tener Jaina actualizado a v10.2.0+

---

## 📝 Notas Técnicas

- Usa `SendAddonMessage()` para comunicación (100% legal)
- Compatible con WoW 3.3.5 (WotLK)
- No automatiza decisiones de combate
- Solo comparte información ya disponible en el juego

---

## ✅ Mejoras Implementadas

- [x] **Integración visual con la esfera principal** - Botón satélite + indicador de estado
- [x] **Más opciones de configuración** - Pestaña RaidAssist en Options
- [x] **Alertas personalizables** - Posición configurable (TOP/CENTER/BOTTOM)
- [x] **Historial de wipes con estadísticas detalladas** - Guardado en SavedVariables
- [x] **Sistema de macros compartidos** - Nuevo módulo MacroSync

---

## 🎯 Próximas Mejoras (Roadmap)

- [ ] Integración con DBM/BigWigs
- [ ] Alertas de mecánicas de boss
- [ ] Sistema de estrategias predefinidas
- [ ] Comandos de voz (TTS)

---

## 🆕 Comandos de Asistencia

### Alertas
```
/jaina alert [mensaje]              -- Muestra alerta de prueba
/jaina alertpos [top/center/bottom] -- Cambia posición de alertas
```

### Historial de Wipes
```
/jaina wipehistory    -- Ver historial completo con estadísticas
/jaina clearwipes     -- Limpiar historial guardado
```

### Macros Compartidos (MacroSync)
```
/jaina macro share <nombre>   -- Comparte macro con el grupo
/jaina macro list             -- Lista macros recibidos
/jaina macro import <nombre>  -- Importa macro compartido
/jaina macro library          -- Muestra biblioteca de tu clase
/jaina macro getlib <nombre>  -- Importa de biblioteca
/jaina macro getall           -- Importa todos de biblioteca
/jaina macro request          -- Solicita lista del grupo
```

---

**Versión:** 10.2.0 (Definitive Edition)  
**Autor:** DarckRovert (Ingame: Elnazzareno) & Project Jaina Team  
**Servidor:** Project Jaina (projectjaina.com)
