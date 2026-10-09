# 📦 Módulos Extra - Project Jaina RaidSuite

**Versión:** 10.2.0 (Definitive Edition)  
**Autor:** DarckRovert (Ingame: Elnazzareno) & Project Jaina Team  
**Documentación de módulos adicionales y opcionales**

---

## 🎒 Logistics.lua

### Descripción
El "Mayordomo" del addon. Se encarga de tareas de mantenimiento y calidad de vida.

### Funcionalidades
- **Auto-Reparación**: Repara tu equipo automáticamente al visitar un mercader.
- **Auto-Venta**: Vende todos los objetos grises (basura) automáticamente.
- **Auto-Comercio**: Pone agua/comida/piedras de salud en la ventana de comercio automáticamente (Mage/Warlock).
- **Gestión de Fragmentos**: Limita el número de Fragmentos de Alma para Brujos (Max: 28).

---

## 🐾 PetManager.lua

### Descripción
Sistema de control de mascotas específico para Brujos y Cazadores.

### Funcionalidades
- **Botón Orbital**: Aparece cuando tienes una mascota activa.
- **Monitor de Salud**: El borde se pone rojo si la mascota baja del 30% de salud.
- **Control**: 
  - Click Izquierdo: Atacar objetivo.
  - Click Derecho: Menú (Seguir, Quieto, Renombrar, Abandonar).

---

## 👁️ CCTracker.lua

### Descripción
Sistema de vigilancia de Crowd Control (CC).

### Funcionalidades
- **Rastreo**: Monitoriza la duración de:
  - Miedo (Fear)
  - Destierro (Banish)
  - Polimorfia (Polymorph)
  - Trampa Congelante (Freezing Trap)
  - Encadenar No-Muerto (Shackle Undead)
- **Alertas**: Emite un sonido y aviso en pantalla si el CC se rompe antes de tiempo.
- **Barras**: Muestra barras de tiempo para el CC activo.

---

## 🐎 Mounts.lua (SmartMounts)

### Descripción
Sistema de montura inteligente.

### Funcionalidades
- **Un Solo Botón**: Decide qué montura usar basada en la zona.
- **Lógica**:
  - Si se puede volar -> Montura Voladora.
  - Si no se puede volar -> Montura Terrestre.
  - Si estás en combate -> Selecciona enemigo y ataca.
  - Si estás montado -> Desmonta.
- **Atajos**: Configurable en el menú de teclado de WoW ("SEQUITO_MOUNT").

---

## 🔮 Runes.lua

### Descripción
Módulo visual exclusivo para Caballeros de la Muerte.

### Funcionalidades
- **Visualización**: Muestra 6 runas alrededor de la esfera principal.
- **Cooldowns**: Muestra el tiempo de reutilización de cada runa.
- **Tipos**: Se adapta a Sangre, Escarcha y Profano.

---

## ✨ Visuals.lua

### Descripción
Sistema de efectos visuales inmersivos para mejorar la experiencia de juego.

### Funcionalidades
- **Heartbeat (Latido)**: 
  - La esfera pulsa en rojo cuando tu HP está por debajo del 35%
  - Pulsa más rápido si estás por debajo del 20% (crítico)
  - Efecto visual de advertencia sin ser intrusivo

- **Proc Watcher (Detector de Procs)**:
  - Detecta procs importantes de tu clase
  - Hace brillar los botones cuando tienes un proc activo
  - Soporte para:
    - **Warlock**: Shadow Trance (Nightfall), Backlash, Molten Core
    - **Mage**: Hot Streak, Brain Freeze, Fingers of Frost
    - **Paladin**: Art of War
    - **Druid**: Eclipse (Lunar/Solar), Predatory Strikes
    - **Shaman**: Maelstrom Weapon
  - Brillo amarillo parpadeante en el botón correspondiente
  - Se actualiza automáticamente con tus buffs

### Configuración
- `HeartbeatEnabled`: Activar/desactivar efecto de latido
- `ProcGlowEnabled`: Activar/desactivar brillo de procs

### Notas Técnicas
- Usa `OnUpdate` para animación suave del latido
- Monitoriza `UNIT_AURA` para detectar procs
- Optimizado para no afectar el rendimiento

