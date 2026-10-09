# 📦 Guía de Instalación - Project Jaina RaidSuite

**Versión:** 10.2.0 (Definitive Edition)  
**Autor:** DarckRovert (Ingame: Elnazzareno) & Project Jaina Team

---

## 📍 Requisitos

- **World of Warcraft:** 3.3.5a (Wrath of the Lich King)
- **Sistema Operativo:** Windows, macOS o Linux
- **Espacio en Disco:** ~3 MB

---

## 🚀 Instalación Rápida

### Paso 1: Descargar el Addon

1. Descarga la versión oficial de Project Jaina RaidSuite v10.2.0 (Definitive Edition)
2. Asegúrate de tener el archivo comprimido del addon

### Paso 2: Extraer Archivos

1. Extrae el archivo comprimido
2. Deberías tener una carpeta llamada `Wanos_RaidSuite`

### Paso 3: Copiar a la Carpeta de AddOns

**Ruta típica en Windows:**
```
World of Warcraft\Interface\AddOns\Jaina_RaidSuite\
```

**Para Project Jaina:**
```
[Directorio de Project Jaina]\Interface\AddOns\Jaina_RaidSuite\
```

### Paso 4: Verificar Estructura

Dentro de `Wanos_RaidSuite/`, deberías ver:
- `Wanos_RaidSuite.toc`
- `SEQUITO.lua`
- `Core/` (Arquitectura base, eventos y componentes del cónclave)
- `Modules/` (Contiene `Core`, `Raid`, `PvP`, `Utility`)
- `Locales/` (Soporte multilingüe en español e inglés)
- `Data/` (Bases de datos de procs, rotaciones y tiers)

Asegúrate de que la estructura sea:
```
AddOns/
└── Wanos_RaidSuite/
    ├── Wanos_RaidSuite.toc
    ├── Sequito.lua
    ├── Embeds.xml
    ├── Core/
    ├── Data/
    ├── Locales/
    └── Modules/
```

### Paso 5: Activar en el Juego

1. Inicia World of Warcraft
2. En la pantalla de selección de personaje, haz clic en **"AddOns"** (esquina inferior izquierda)
3. Busca **"Project Jaina - RaidSuite"** en la lista
4. Asegúrate de que esté **marcado** (checkbox activado)
5. Haz clic en **"Okay"**
6. Entra al juego con tu personaje

### Paso 6: Verificar Instalación

En el chat del juego, escribe:
```
/sequito
```

Deberías ver el mensaje de bienvenida de Sequito.

---

## ⚙️ Configuración Inicial

### Generar Macros

Para generar macros personalizadas para tu clase:
```
/sequito macros
```

Esto creará macros optimizadas según tu clase y especialización actual.

### Abrir Panel de Opciones

```
/sequito options
```

Aquí puedes configurar:
- Activar/desactivar módulos
- Ajustar notificaciones
- Configurar sincronización de raid
- Personalizar interfaz

### Abrir Panel de Raid

```
/sequito panel
```

Muestra información en tiempo real de tu raid.

---

## 🔄 Actualización

### Desde una Versión Anterior

1. **Respalda tu configuración** (opcional):
   - Copia `WTF/Account/TU_CUENTA/SavedVariables/Sequito.lua`

2. **Elimina la versión anterior**:
   - Borra la carpeta `AddOns/Sequito/`

3. **Instala la nueva versión**:
   - Sigue los pasos de instalación normal

4. **Restaura configuración** (si respaldaste):
   - Copia de vuelta el archivo `Sequito.lua` a SavedVariables

5. **Recarga la interfaz**:
   ```
   /reload
   ```

---

## 🐛 Solución de Problemas

### El addon no aparece en la lista

**Problema:** Sequito no aparece en el menú de AddOns.

**Solución:**
1. Verifica que la carpeta se llame exactamente `Wanos_RaidSuite`
2. Verifica que `Wanos_RaidSuite.toc` esté en la raíz de la carpeta
3. Asegúrate de estar en la carpeta correcta de AddOns
4. Reinicia completamente WoW

### Error al cargar el addon

**Problema:** Mensaje de error al iniciar sesión.

**Solución:**
1. Verifica que todos los archivos estén presentes
2. Revisa que no haya archivos corruptos
3. Descarga nuevamente el addon
4. Desactiva otros addons para verificar conflictos

### Los comandos no funcionan

**Problema:** `/sequito` no hace nada.

**Solución:**
1. Verifica que el addon esté activado en el menú de AddOns
2. Escribe `/reload` para recargar la interfaz
3. Revisa si hay errores con `/console scriptErrors 1`

### Las macros no se generan

**Problema:** `/sequito macros` no crea macros.

**Solución:**
1. Asegúrate de tener espacio libre en tu lista de macros
2. Elimina macros viejas si es necesario
3. Verifica que `MacroGenerator.lua` esté presente

### El panel de raid no se muestra

**Problema:** `/sequito panel` no abre nada.

**Solución:**
1. Verifica que estés en un grupo o raid
2. Intenta `/sequito reset` para reiniciar la posición
3. Revisa que `RaidPanel.lua` esté cargado

---

## 📝 Archivos de Configuración

### Ubicación de SavedVariables

**Windows:**
```
WTF\Account\TU_CUENTA\SavedVariables\Sequito.lua
```

**Por Personaje:**
```
WTF\Account\TU_CUENTA\SERVIDOR\PERSONAJE\SavedVariables\Sequito.lua
```

### Resetear Configuración

Para resetear completamente la configuración:

1. Cierra WoW
2. Elimina `SavedVariables/Sequito.lua`
3. Inicia WoW
4. Sequito usará configuración por defecto

---

## 🔗 Compatibilidad con Otros Addons

### Addons Compatibles

- ✅ **DBM** (Deadly Boss Mods)
- ✅ **Recount** / **Skada**
- ✅ **Bartender** / **Dominos**
- ✅ **Grid** / **Healbot**
- ✅ **Omen** (Threat Meter)
- ✅ **AtlasLoot**

### Posibles Conflictos

- ⚠️ **Necrosis**: Puede haber conflictos si ambos intentan crear las mismas macros
- ⚠️ **Otros addons de macros**: Desactiva generación automática en uno de ellos

---

## ✅ Verificación Post-Instalación
 
 Después de instalar, verifica que todo funcione:
 
 ```
 /sdash            - Abre el Dashboard Central de 4 pestañas
 /sequito macros   - Genera las macros inteligentes (SeqRot, SeqMount, etc.)
 /srot             - Despliega el HUD de rotación reactivo con procs
 /sinspect         - Abre el inspector de academia (GS real y encantamientos)
 /sloot            - Abre el panel del Concilio de Botín
 /sequito options  - Abre la configuración de módulos
 ```
 
 Si estos comandos responden correctamente y ves la Esfera Central flotante, ¡la instalación fue un éxito total! 🎉

---

## 📞 Soporte

Si sigues teniendo problemas:

1. Revisa [FAQ.md](FAQ.md) para preguntas comunes
2. Verifica [CHANGELOG.md](CHANGELOG.md) para problemas conocidos
3. Reporta el bug con detalles específicos

---

**Creado por DarckRovert (Ingame: Elnazzareno) & Project Jaina Team**
