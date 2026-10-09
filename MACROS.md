# 📜 Guía de Macros - Project Jaina RaidSuite

**Versión:** 10.2.0 (Definitive Edition)  
**Autor:** DarckRovert (Ingame: Elnazzareno) & Project Jaina Team  
**Cliente WoW:** 3.3.5a (Build 12340)

---

**Sequito** genera macros inteligentes inspiradas en Necrosis. Estas macros se adaptan dinámicamente a tu clase, especialización activa (las 30 ramas de talentos de WotLK 3.3.5a) y hechizos aprendidos, garantizando fluidez sin bloqueos de secuencia.

---

## 🔮 Universal & Utilidades Inteligentes

Estas macros están disponibles o se adaptan a todas las clases del juego:

### [SeqRot] (Macro de Rotación Inteligente Adaptativa)
Es la joya del sistema de combate de Sequito. Genera una macro multifunción que se adapta a las **30 especializaciones de las 10 clases**:
- **Pulsación directa:** Lanza el hechizo principal o filler de la rotación (con `/startattack` y `/petattack` integrados).
- **Shift:** Lanza el DoT principal, finisher o habilidad de daño burst.
- **Ctrl:** Lanza el hechizo secundario de prioridad o control de daño.
- **Alt:** Habilidad de remate (Execute/Drain Soul), CD ofensivo o AoE.
- **Sanadores:** Modificadores automáticos con soporte de cursor (`[@mouseover,help]`) y jugador (`[@player]`).
- **Druidas:** Detección de forma nativa (`[form:1]` oso vs `[form:3]` gato) para no mezclar habilidades de tanqueo y dps.

### [SeqRacial] (Macro Racial)
Utiliza la habilidad racial activa de tu personaje con un grito de batalla inmersivo:
- **Orc**: Furia Sangrienta (*"¡Por el Sequito del Terror!"*)
- **Troll**: Rabiar
- **Human**: Sálvese quien pueda
- **Undead**: Voluntad de los Renegados
- **Blood Elf**: Torrente Arcano
- **Tauren**: Pisotón de guerra
- **Night Elf**: Fusión con las sombras
- **Dwarf**: Forma de piedra
- **Gnome**: Filo de la fuga
- **Draenei**: Ofrenda de los naaru

### [SeqMount] (Montura Inteligente)
Un solo botón para todas tus necesidades de transporte:
- Si estás en zona donde se permite volar, invoca tu montura voladora.
- Si estás en tierra o mazmorras, invoca tu montura terrestre.
- Desmonta automáticamente si ya estás montado.

### [SeqInt] (Interrupción Inteligente de Hechizo)
Configurada para las 9 clases que poseen cortes de casteo:
- **Prioridad:** Con tecla Shift corta el foco (`[mod:shift, target=focus]`), de lo contrario corta tu objetivo actual.
- **Habilidades según clase:**
  - *Pícaro:* Patada
  - *Guerrero:* Zurrar
  - *Caballero de la Muerte:* Helada mental
  - *Mago:* Contrahechizo
  - *Chamán:* Corte de viento
  - *Sacerdote:* Silencio
  - *Cazador:* Disparo silenciador
  - *Brujo:* Bloqueo de hechizo (Manáfago)

### [SeqCC] (Control de Masas Inteligente)
Aplica el CC principal de tu clase manteniendo el control del combate:
- **Modificadores:** `[mod:ctrl, target=mouseover]` para cc al vuelo sin perder target, `[mod:shift, target=focus]` para cc al foco, o directo al objetivo.
- **Habilidades:** Polimorfia (Mago), Miedo (Brujo), Ceguera (Pícaro), Ciclón (Druida), Encadenar no-muerto (Sacerdote), Disparo disperso (Cazador), Martillo de justicia (Paladín).

---

## ☠️ Caballero de la Muerte (Death Knight)

- **[SeqStart]:** Opener de combate con Toque helado y ataque de pet.
- **[SeqGrip]:** Atracción letal con prioridad Focus > Mouseover > Objetivo.
- **[SeqInt]:** Helada mental con corte a foco en Shift.
- **[SeqHeal]:** Autosanación con Transfusión de runa; en Shift activa Pacto de la muerte para sacrificar al esbirro, o consume poción rúnica.
- **[SeqAoE]:** Propagación de enfermedades con Pestilencia y Muerte y descomposición.
- **[SeqArmy]:** Invocación de Ejército de muertos con aviso sonoro.
- **[SeqRot]:** Rotación adaptada a Sangre (Golpe en el corazón/Mortal), Escarcha (Asolar/Golpe de Escarcha) o Profano (Golpe de la Plaga/Espiral), con Golpe con runa en cola de autoataque (`/cast !Golpe con runa`).

---

## 🔮 Brujo (Warlock - Necrosis Core)

- **[SeqStart]:** Opener según rama de talentos (Inmolar, Corrupción o Metamorfosis).
- **[SeqPet]:** Control total de esbirro con un solo botón: Clic normal ataca, Alt sigue, y lanza habilidades especiales según el demonio invocado (Manáfago: Bloqueo de hechizo a foco/mouseover o Devorar magia en jugador con Shift; Súcubo: Seducción; Abisario: Sacrificio con Shift).
- **[SeqHeal]:** Piedra de salud en clic primario; en Shift canaliza salud hacia el demonio.
- **[SeqBanish]:** Desterrar con prioridad Focus > Mouseover > Objetivo.
- **[SeqCC]:** Miedo inteligente con prioridad Mouseover > Focus > Objetivo.
- **[SeqDispel]:** Devorar magia sobre aliados o en el propio jugador con Alt.
- **[SeqBurst]:** Metamorfosis con Aura de inmolación, uso sincronizado de abalorios (ranuras 13 y 14), guantes de ingeniería (ranura 10) y Poción de velocidad.
- **[SeqRot]:**
  - *Aflicción:* Descarga de las Sombras; Shift para Poseer (o Aflicción inestable); Ctrl para Aflicción inestable / Maldición de agonía; Alt para Drenar alma en fase de ejecución (<25%).
  - *Demonología:* Incinerar/Descarga; Shift para Inmolar; Ctrl para Fuego de alma (proc Diezmar); Alt para Corrupción; transformado en demonio activa Aura de inmolación automáticamente.
  - *Destrucción:* Incinerar; Shift para Inmolar; Ctrl para Conflagrar; Alt para Descarga de Caos.

---

## 🛡️ Paladín (Paladin)

- **[SeqBubble]:** Escudo divino con `/stopcasting` e inmunidad de emergencia; permite cancelación segura con tecla Alt (`/cancelaura [mod:alt] Escudo divino`) con protección `[nomod]` para no autocancelar accidentalmente.
- **[SeqPull]:** Escudo de vengador para tanques con aviso por chat.
- **[SeqHeal]:** Choque Sagrado en Shift, Luz Sagrada en Ctrl, Destello de Luz con mouseover y jugador (sin spam innecesario en canales).
- **[SeqRot]:**
  - *Sagrado:* Choque Sagrado / Luz Sagrada / Destello de Luz por mouseover.
  - *Protección:* Escudo de rectitud; Shift para Martillo de rectitud; Ctrl para Consagración; Alt para Sentencia de sabiduría.
  - *Reprensión:* Golpe de cruzado; Shift para Tormenta divina; Ctrl para Sentencia de sabiduría; Alt para Exorcismo instantáneo.

---

## 🐺 Chamán (Shaman)

- **[SeqLust]:** Detecta si eres Horda (Ansia de sangre) o Alianza (Heroísmo) y grita el aviso a la banda.
- **[SeqWolves]:** Invoca Espíritu feral + Ira del chamán (Mejora).
- **[SeqTide]:** Tótem Marea de maná con aviso de recuperación a los sanadores.
- **[SeqRot]:**
  - *Elemental:* Descarga de relámpagos; Shift para Ráfaga de lava; Ctrl para Choque de llamas; Alt para Cadena de relámpagos.
  - *Mejora:* Golpe de tormenta; Shift para Látigo de lava; Ctrl para Choque de tierra; Alt para Descarga de relámpagos con Arma vorágine x5.
  - *Restauración:* Ola de sanación menor; Shift para Sanación en cadena; Ctrl para Mareas vivas con mouseover.

---

## 🏹 Cazador (Hunter)

- **[SeqMD]:** Redirección inteligente a `@focus`, a la mascota si existe, o al objetivo amigo.
- **[SeqRot]:** Disparo firme (con `!Disparo automático`); Shift para Disparo de quimera / Disparo explosivo / Cólera de las bestias; Ctrl para Disparo de puntería / Flecha negra / Matar; Alt para Picadura de serpiente.

---

## 🗡️ Pícaro (Rogue)

- **[SeqTricks]:** Secretos del oficio a foco o aliado con aviso automático por susurro.
- **[SeqRot]:**
  - *Asesinato:* Mutilar como ataque principal; Shift para Envenenar; Ctrl para Hambre de sangre.
  - *Combate:* Golpe siniestro; Shift para Eviscerar; Ctrl para Hacer picadillo; Alt para Asesinato múltiple / Aluvión de acero.
  - *Sutileza:* Hemorragia; Shift para Eviscerar; Ctrl para Paso de las Sombras.

---

## 🧙‍♂️ Mago (Mage)

- **[SeqTable]:** Ritual de refrigerio (Mesita) con anuncio por chat y aviso de finalización.
- **[SeqDecurse]:** Eliminar maldición con soporte de cursor (`@mouseover`) y autolanzamiento.
- **[SeqRot]:**
  - *Arcano:* Descarga Arcana; Shift para Misiles Arcanos; Ctrl para Tromba Arcana.
  - *Fuego:* Bola de Fuego; Shift para Bomba viva; Ctrl para Piroexplosión instantánea con proc; Alt para Agostar.
  - *Escarcha:* Descarga de Escarcha; Shift para Lanza de hielo; Ctrl para Congelación profunda.

---

## ⚕️ Sacerdote (Priest)

- **[SeqHymn]:** Himno divino con temporizador de cuenta regresiva en el canal.
- **[SeqRot]:**
  - *Disciplina:* Sanación relámpago; Shift para Palabra de poder: escudo; Ctrl para Penitencia; Alt para Rezo de alivio con mouseover.
  - *Sagrado:* Sanación relámpago; Shift para Círculo de sanación; Ctrl para Rezo de alivio; Alt para Renovar.
  - *Sombras:* Tortura mental; Shift para Toque vampírico; Ctrl para Peste devoradora; Alt para Explosión mental.

---

## 🌿 Druida (Druid)

- **[SeqRez]:** Renacer en combate (Brez) con aviso y frase de rol personalizable.
- **[SeqInnervate]:** Estimular hacia cursor (`@mouseover`), objetivo aliado o jugador.
- **[SeqRot]:**
  - *Equilibrio:* Cólera; Shift para Fuego estelar; Ctrl para Fuego lunar; Alt para Enjambre de insectos.
  - *Feral Oso (`[form:1]`):* Destrozar oso en Shift / Magullar en normal.
  - *Feral Gato (`[form:3]`):* Destrozar felino; Shift para Destripar; Ctrl para Mordedura feroz.
  - *Restauración:* Recrecimiento; Shift para Rejuvenecimiento; Ctrl para Flor de vida; Alt para Crecimiento salvaje con mouseover.

---

## 🛡️ Guerrero (Warrior)

- **[SeqWall]:** Muro de escudo con grito de batalla para alertar a los sanadores.
- **[SeqRot]:**
  - *Armas:* Golpe mortal como ataque primario + Golpe heroico en cola; Shift para Desgarrar; Ctrl para Abrumar con proc; Alt para Ejecutar.
  - *Furia:* Sed de sangre + Golpe heroico encadenado; Shift para Torbellino; Ctrl para Embate con proc.
  - *Protección:* Devastar / Hender armadura + Golpe heroico encadenado; Shift para Embate con escudo; Ctrl para Revancha; Alt para Ola de choque.

---

## 🔄 MacroSync - Sistema de Macros Compartidos

**Sequito** permite compartir y sincronizar macros de forma bidireccional entre usuarios de la hermandad, banda o grupo:

### Comandos de MacroSync

| Comando | Descripción |
|---------|-------------|
| `/sequito macro share <nombre>` | Comparte una macro con tu grupo, banda o por susurro |
| `/sequito macro list` | Lista las macros recibidas de otros jugadores |
| `/sequito macro import <nombre>` | Importa una macro recibida al libro de macros |
| `/sequito macro library` | Muestra la biblioteca de macros integrada para tu clase |
| `/sequito macro getlib <nombre>` | Importa una macro específica de la biblioteca |
| `/sequito macro getall` | Importa todas las macros recomendadas para tu clase |
| `/sequito macro request` | Solicita la lista de macros disponibles a los compañeros |

---

## ❓ Preguntas Frecuentes

**¿Se actualizan solas las macros al cambiar de talentos?**  
Sí. Al cambiar de especialización dual o aprender nuevas habilidades (`PLAYER_TALENT_UPDATE` y `LEARNED_SPELL_IN_TAB`), Sequito recalcula y regenera tus macros `Seq*` automáticamente para adaptarlas a tu nueva especialización y rangos máximos.

**¿Puede Sequito borrar mis macros personales?**  
No. El motor de gestión de macros solo inspecciona y administra las macros creadas por el propio addon (prefijo `Seq`). Tus macros personales nunca son eliminadas ni modificadas.

**¿Qué pasa si mi espacio de macros está lleno (18/18 por personaje)?**  
El addon avisa por chat si has alcanzado el límite nativo del cliente de WoW y no puede crear una nueva macro hasta que liberes una ranura.
