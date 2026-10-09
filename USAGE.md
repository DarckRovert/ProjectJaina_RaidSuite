# 📚 Manual de Usuario - Project Jaina RaidSuite

**Versión:** 10.2.0 (Definitive Edition)  
**Autor:** DarckRovert (Ingame: Elnazzareno) & Project Jaina Team  
**Servidor Destino:** [Project Jaina](https://projectjaina.com/) - Project Jaina  
**Cliente Compatible:** World of Warcraft 3.3.5a (Build 12340)

---

## 🌟 Bienvenido a Jaina

**Jaina** es una suite completa y revolucionaria diseñada para World of Warcraft 3.3.5a. Su objetivo es transformar tu experiencia de juego mediante una arquitectura moderna, fluida y colaborativa que une a jugadores individuales, grupos de mazmorra y hermandades enteras (clanes).

Olvídate de addons viejos que se traban o que solo sirven para una sola clase. Jaina ofrece **funcionalidad real, cero maquetas y soporte integral para las 10 clases del juego**.

---

## 🧭 Los Componentes del Ecosistema

Cuando entras al juego con Jaina activado, dispones de varios elementos interactivos diseñados para no estorbar y responder de inmediato:

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

1. **La Esfera Central (Orb):**
   - **Clic Izquierdo:** Abre o cierra el Dashboard Principal (`/sdash`).
   - **Clic Derecho:** Despliega el Menú Radial con accesos rápidos a utilidades, profesiones y monturas.
   - **Shift + Clic y Arrastrar:** Permite mover la esfera libremente por cualquier parte de tu pantalla.
2. **Botón del Minimapa:** Acceso directo con un solo clic a la configuración y paneles.
3. **Comando Universal:** Escribe `/jaina` o `/s` para ver el menú de ayuda interactivo.

---

## 🖥️ Capítulo 1: El Dashboard Central (`/sdash` o `/jaina`)

El Dashboard reúne toda la información vital en una interfaz elegante y moderna dividida en 4 pestañas:

1. **Pestaña «Resumen»:**
   - Visualiza los datos de tu personaje: clase, especialización activa, rol (Tanque, Sanador o DPS) y versión del cliente.
   - Monitorea el estado del grupo o banda: número de miembros, clases presentes y porcentaje de vida promedio.
   - Botones de acción rápida: Regenerar macros, comprobar listos (`Ready Check`) y escanear buffs faltantes.
2. **Pestaña «Logros»:**
   - Sistema interno de gamificación de hermandad. Registra proezas y metas completadas en raids clásicas (Naxxramas, Ulduar, Sagrario Obsidiana, Ciudadela de la Corona de Hielo).
   - Incluye botón para abrir el *Navegador Flotante de Logros*.
3. **Pestaña «Rotación»:**
   - Muestra la cadena de prioridades recomendada para tu talento actual y permite encender el **HUD Flotante de Rotación**.
4. **Pestaña «Tesoros» (Galería de Botín):**
   - Registro histórico de todas las piezas épicas y legendarias obtenidas por la hermandad durante las incursiones de banda.

---

## 📜 Capítulo 2: El Motor de Macros Dinámico (`SeqRot`)

A diferencia de las macros convencionales que usan secuencias rígidas (`/castsequence`) y se congelan si un hechizo falla o está fuera de rango, Jaina implementa un **motor inteligente de prioridades con modificadores**:

### ¿Cómo usar la macro `SeqRot`?
1. Escribe `/jaina macros` o abre tu libro de macros (`/m`).
2. En la pestaña de **Macros específicas del personaje**, busca la macro llamada **`SeqRot`**.
3. Arrástrala a tu tecla de ataque principal (por ejemplo, el número `1`).
4. **En combate:**
   - **Pulsación directa (sin teclas adicionales):** Lanza tu ataque principal o filler. Además, inicia el ataque automático (`/startattack`) y manda a tu mascota a atacar (`/petattack`).
   - **Manteniendo presionada la tecla Shift:** Lanza tu DoT principal, finisher o habilidad de daño burst.
   - **Manteniendo presionada la tecla Ctrl:** Lanza tu habilidad secundaria de prioridad o de recarga rápida.
   - **Manteniendo presionada la tecla Alt:** Habilidad de remate en fase de ejecución (como *Ejecutar* o *Drenar alma*), CD de daño o habilidad de área.

### Sanadores (Healers):
Si juegas Paladín Sagrado, Sacerdote Disciplina/Sagrado, Chamán Restauración o Druida Árbol, las macros incluyen soporte automático de cursor:
- Pasa el ratón sobre el marco de vida de un compañero y pulsa la macro: lo curará sin necesidad de cambiar tu objetivo actual (`[@mouseover,help]`).
- Si no hay nadie bajo el cursor, curará a tu objetivo amistoso o a ti mismo (`[@player]`).

### Druidas Ferales (Oso y Gato):
La macro detecta automáticamente tu forma animal:
- Si entras en **Forma de Oso (`[form:1]`)**: Se convierte en tu macro de tanqueo (*Magullar*, *Destrozar oso*, *Lacerar*).
- Si entras en **Forma de Felino (`[form:3]`)**: Se convierte en tu rotación de DPS (*Destrozar gato*, *Destripar*, *Mordedura feroz*, *Rugido salvaje*).

### Macros de Utilidad Generadas:
- **`SeqInt` (Interrupción Inteligente):** Presiónala normalmente para cortar el casteo de tu objetivo actual; si mantienes **Shift**, cortará el casteo de tu objetivo en **Foco** sin cambiar de target.
- **`SeqCC` (Control de Masas):** Aplica Polimorfia, Miedo, Ceguera, Ciclón o Martillo de Justicia con modificador de mouseover o foco.
- **`SeqMount` (Montura Inteligente):** Invoca automáticamente tu montura voladora si estás en zona donde se permite volar (Rasganorte, Terrallende), montura terrestre si estás en interiores/mazmorras, y te desmonta si estás montado.
- **`SeqRacial`:** Tu habilidad racial con grito inmersivo por el Jaina.

> [!TIP]
> **Cambio de Talentos:** Cada vez que cambias de talentos o compras la especialización dual, Jaina detecta el cambio automáticamente y adapta tus macros sin tocar tus macros personales.

---

## 🌐 Capítulo 3: Malla de Clan en Vivo (`ClanMesh`)

Uno de los mayores poderes de Jaina es que **los miembros de una hermandad no necesitan estar en la misma raid para colaborar**:

- **Canal de Hermandad Activo:** El sistema de red sincroniza información a través del canal `GUILD` de manera continua y eficiente.
- **Tráfico Protegido (Cero Caídas):** Jaina utiliza un sistema de transmisión por goteo que fragmenta los paquetes grandes con pausas seguras de 80 ms. Esto garantiza que nunca seas desconectado del servidor por saturación de chat (*anti-flood protection*).
- **Órdenes de Banda y Estrategias:**
  - Los oficiales pueden enviar notas tácticas de jefes que aparecen en pantalla grande para todos los miembros con el comando `/jaina sync start`.
  - Comandos de ataque coordinado:
    - `/jaina focus [Nombre]` - Marca un objetivo prioritario para que todos cambien de foco.
    - `/jaina alpha` - Orden de ataque masivo simultáneo.
    - `/jaina ready` - Chequeo de listos enriquecido con verificación de comida y frascos.

---

## 🎓 Capítulo 4: Modo Academia (`Academy Mode`)

Diseñado tanto para que los oficiales auditen a los miembros de la banda, como para que los jugadores aprendan a maximizar su rendimiento:

### 1. Inspector de Academia (`/sinspect` o `/seqinspect`)
Selecciona a cualquier jugador y escribe `/sinspect`:
- **Talentos Asíncronos:** Consulta los árboles de talentos exactos sin riesgo de error por lag.
- **GearScore Real de 3.3.5a:** Calcula el GearScore exacto según la fórmula oficial de Wrath of the Lich King, ponderando armas principales (2.0x), piezas grandes (1.0x) y accesorios.
- **Auditoría de Encantamientos:** Te avisa al instante si al jugador le faltan encantamientos recomendados en piezas mayores (cabeza, hombros, pecho, piernas, pies, muñecas, manos, capa o arma).

### 2. HUD Asesor de Rotación Reactivo (`/srot` o `/srotation`)
Abre una pequeña barra flotante que te muestra la secuencia ideal de hechizos según tu especialización:
- Muestra el tiempo restante de recarga de cada habilidad.
- **Alertas de PROCS en Tiempo Real:** Cuando se activa una habilidad instantánea por talentos (como *Buena racha* en Magos de Fuego, *El arte de la guerra* en Paladines Retri, *Oleada de sangre* en Guerreros, *Escarcha blanca* en Caballeros de la Muerte o *Diezmar* en Brujos), el icono correspondiente en el HUD se ilumina con un **borde verde esmeralda brillante** y muestra el texto **`PROC!`** para que no lo desaproveches.

---

## ⚖️ Capítulo 5: Concilio de Botín Inteligente (`Loot Council` - `/sloot`)

La distribución justa, rápida y transparente del botín en bandas de hermandad ahora cuenta con automatización total:

1. **Cola de Múltiples Ítems (Loot Queue):**
   - Cuando un jefe es derrotado y se abre la ventana de despojo (`LOOT_OPENED`), Jaina escanea automáticamente **todas** las piezas épicas o legendarias caídas y las encola.
   - Al finalizar la votación de una pieza, el addon abre inmediatamente la sesión para el siguiente ítem de la cola sin que el líder tenga que hacer nada manual.
2. **Respuestas de Jugador Estándar de WotLK:**
   - La ventana ofrece cuatro botones claros para que los miembros de la banda declaren su necesidad:
     - **Main Spec (MS):** Prioridad principal para tu talento activo.
     - **Off Spec (OS):** Para tu segunda especialización o equipamiento secundario.
     - **Mejora:** Para piezas con estadísticas menores o variantes.
     - **Pasar:** Si no necesitas el objeto.
3. **Auditoría de Compatibilidad y Marcas de Tier:**
   - **Tipos de Armadura:** Muestra la clase de cada candidato en su color oficial y audita si puede equipar la armadura (Placas, Malla, Cuero, Tela), alertando con `[Armadura Óptima]`, `[Equipable]` o `[No Equipable]`.
   - **Marcas de Santificación (Tier Tokens):** Comprueba automáticamente las clases válidas para evitar confusiones de despojo:
     - *Vencedor:* Pícaro, Caballero de la Muerte, Mago, Druida.
     - *Protector:* Guerrero, Cazador, Chamán.
     - *Conquistador:* Paladín, Sacerdote, Brujo.
4. **Temporizador Regresivo Visual y Desempate:**
   - Un contador visual en tiempo real muestra los segundos restantes de votación (configurable de 15 a 180s).
   - Al expirar el tiempo, el sistema avisa en el chat de banda al candidato ganador.
   - **Resolución de Empates:** Si dos candidatos terminan con la misma cantidad de votos de oficiales, Jaina compara automáticamente sus tiradas de dados para desempatar con justicia.
5. **Entrega Directa en el Juego (`GiveMasterLoot`):**
   - El Maestro Despojador dispone de un botón verde **`[Dar]`** en la fila del ganador. Al pulsarlo, Jaina ejecuta la llamada nativa de Blizzard `GiveMasterLoot` para depositar el ítem directamente en la mochila del jugador si el cadáver sigue abierto, o anuncia al ganador en el chat de banda.
6. **¿Qué pasa con los jugadores que NO tienen el addon?**
   - ¡Están totalmente incluidos! Jaina intercepta automáticamente los resultados de dados en el chat general (`/azar 100` o `/roll`).
   - El jugador sin el addon tira sus dados normalmente en el juego y Jaina lo añade de inmediato a la lista de candidatos con su puntuación numérica exacta, permitiendo al concilio deliberar y votar con transparencia.

---

## 📊 Capítulo 6: Auditoría de Combate y Wipes

- **Estadísticas Reales (`/jaina stats` o `/sstats`):** Registro de combate que extrae con precisión el daño infligido por ataques blancos, hechizos y daño periódico, así como la sanación efectiva (descontando la sobresanación o overhealing).
- **Analizador de Wipes (`/jaina wipe` o `/swipe`):** Cuando la banda cae en un combate, Jaina realiza una autopsia inmediata:
  - ¿Quién murió primero y qué hechizo o golpe le quitó la vida?
  - ¿Murió sin usar su Poción de Vida o Piedra de Salud?
  - ¿Hubo cortes de casteo fallidos contra el jefe?
  - Detección de patrones: si mueres 2 veces seguidas por la misma habilidad, el sistema te alertará para que corrijas tu posicionamiento.

---

## 🎭 Capítulo 7: Frases Cómicas de Incursión (`JainaHumor` - `/shumor`)

Para darle vida, diversión y buen humor a las sesiones de hermandad, Jaina incorpora un sistema inteligente de expresiones automáticas con jerga clásica de WoW y de la comunidad hispana/latina:

1. **Actividades y Escenarios Soportados:**
   - **Invocaciones de Brujo:** Pide clics con humor (*"¡Uber del Vacío llegando! Denle clic al portal que el brujo no es taxista gratis."*).
   - **Armario y Piedras de Salud:** Avisa a la banda que agarren sus galletas antes de morir (*"¡Puse el armario de almas! Agarren sus piedras antes de morir y culpar al healer."*).
   - **Ruleta Rusa / Ritual de la Perdición:** Anuncia la ruleta de sacrificio voluntario (*"¡RULETA RUSA INICIADA! Uno de ustedes será el almuerzo del demonio."*).
   - **Mesa de Comida de Mago:** Buffet libre de carbohidratos mágicos para no esperar al maná por fotosíntesis.
   - **Portales a Capitales:** Avisos cómicos ante posibles accidentes interdimensionales al Cráter de Dalaran.
   - **Resurrección en Combate (BRez):** Le recuerda al compañero que el suelo de ICC no es un hotel de cinco estrellas.
   - **Resurrecciones Normales:** Avisa al caído que los muertos no tiran dados de botín.
   - **Heroísmo / Ansia de Sangre:** Gritos épicos para reventar el medidor de DPS.
   - **Intervención Divina, Redirección, Festines y Reparaciones (Jeeves).**
2. **Protección Anti-Spam y Seguridad:**
   - Solo se activa cuando tú lanzas la habilidad con éxito (`unit == "player"`).
   - Enfriamiento interno de 12 segundos para evitar saturación de chat.
   - Canal inteligente: por defecto emite en `/say` (Decir), pero puedes configurarlo a `/party`, `/raid` o `/yell` con `/shumor channel [CANAL]`.
   - Puedes probar cualquier categoría al instante con `/shumor test [CATEGORIA]`.

---

## ⌨️ Tabla de Comandos Rápidos

| Comando | Alias | Qué hace |
|---------|-------|----------|
| `/jaina` | `/s` | Abre el menú interactivo o el Dashboard central |
| `/sdash` | `/jaina dashboard` | Abre/cierra el Dashboard principal de 4 pestañas |
| `/jaina macros` | `/smacros` | Genera y optimiza todas las macros de tu clase |
| `/srot` | `/srotation` | Muestra u oculta el HUD flotante de rotación reactiva |
| `/sinspect` | `/seqinspect` | Inspecciona al objetivo (Talentos, GS real y encantamientos) |
| `/sloot` | `/jaina lc` | Abre el panel del Concilio de Botín |
| `/shumor` | `/shumor toggle` | Controla y prueba las frases cómicas de incursión |
| `/sstats` | `/jaina stats` | Abre las estadísticas de rendimiento en combate |
| `/swipe` | `/jaina wipe` | Abre el análisis detallado del último wipe |
| `/sbuffs` | `/jaina buffs` | Escanea y reporta buffs faltantes en la banda |
| `/sfocus [Nombre]` | `/jaina focus` | Envía orden de target prioritario a toda la raid |
| `/sready` | `/jaina ready` | Inicia comprobación de listos táctica |

---

## ❓ Preguntas Frecuentes para Nuevos Usuarios

**¿Jaina gasta muchos recursos o me bajará los FPS en raid de 25 jugadores?**  
No. Todo el código de Jaina cuenta con acumuladores de tiempo rígidos (*throttling*) que limitan las comprobaciones visuales a 20 Hz en lugar de saturar tu procesador a 144 Hz. Es extremadamente liviano y seguro para clientes de 32 bits.

**¿Puedo usar Jaina si juego solo o solo hago mazmorras de 5 personas?**  
Por supuesto. Las macros adaptativas, el HUD de rotación con procs, el comando de montura y las estadísticas de combate funcionan perfectamente en solitario, en grupos de 5 y en campos de batalla (PvP).

**¿Qué pasa si mi lista de macros está llena (18/18 del personaje)?**  
El addon te avisará en el chat para que borres alguna macro vieja que ya no uses. Jaina nunca borrará tus macros personales creadas a mano.

---

*Desarrollado con dedicación para la comunidad de Project Jaina (Project Jaina).*
