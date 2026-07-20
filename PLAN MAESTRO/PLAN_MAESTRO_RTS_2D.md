# Plan Maestro — RTS 2D Configurable

**Proyecto:** RTS de ejércitos grandes en Godot 4  
**Estado:** Diseño y preproducción del modo 2D  
**Versión:** 1.0  
**Principio rector:** primero una simulación simple, observable, rápida y data-driven; después contenido, IA avanzada y modo 3D.

---

## 1. Visión del juego

El proyecto comienza como un RTS 2D de vista superior centrado en economía simple, producción de tropas, control de ejércitos, captura de estructuras y destrucción/captura del castillo enemigo. Debe soportar muchas unidades sin perder legibilidad ni rendimiento.

La visualización inicial funciona deliberadamente como herramienta de depuración:

- **Color:** identifica equipo/jugador.
- **Figura:** identifica estado de la unidad.
- **Cuadrado:** inactiva/quieta.
- **Círculo:** moviéndose.
- **Triángulo:** atacando.
- **Forma adicional futura:** capturando, huyendo, construyendo o incapacitada.

Ejemplos: círculo azul = unidad del equipo 1 moviéndose; triángulo rojo = equipo 2 atacando. La forma es una representación temporal; la simulación nunca debe depender de sprites, modelos o animaciones finales.

## 2. Alcance y límites

### 2.1 Objetivo del MVP

El MVP debe permitir iniciar una partida local contra bots, seleccionar mapa/facción/equipo/color, crear aldeanos y soldados, recolectar oro, construir, mover tropas, atacar, capturar edificios y terminar una partida por caída del castillo.

### 2.2 Fuera del MVP

No implementar al inicio: multijugador en red, campaña, voces finales, comercio complejo, felicidad profunda, skins, niebla competitiva compleja, entrenamiento de unidades, templos/arena/taverna completos, ni modo 3D jugable.

Estos sistemas se dejan como puntos de extensión en datos e interfaces, pero no se programan antes de que el bucle central sea estable.

### 2.3 Regla de diseño

Cada característica debe responder:
1. ¿Aporta una decisión jugable visible?
2. ¿Puede configurarse sin reescribir lógica?
3. ¿Puede activarse/desactivarse sin romper una partida?
4. ¿Tiene una prueba de depuración verificable?

Si no responde las cuatro, se posterga.

## 3. Arquitectura general

Separar estrictamente cuatro capas:

| Capa | Responsabilidad | No debe contener |
|---|---|---|
| Datos | Definiciones JSON, mapas, balance y catálogos | Lógica de combate hardcodeada |
| Dominio/Simulación | Estados, reglas, órdenes, combate, economía y victoria | UI, sprites finales, rutas de archivos |
| Presentación | Dibujar unidades, HUD, menús, efectos y audio | Decisiones de IA o estadísticas base |
| Infraestructura | Carga de archivos, guardado, logging, pooling | Reglas específicas de una unidad |

**Regla clave:** una unidad se identifica por `unit_id`; el código carga sus stats base, aplica facción, mejoras y modificadores temporales para crear sus stats efectivos. No duplicar estadísticas finales por cada facción salvo una excepción documentada.

## 4. Decisiones técnicas

- Usar Godot 4 y GDScript al inicio; migrar únicamente cuellos de botella medidos a C# o GDExtension.
- Usar coordenadas 2D de mundo (`Vector2`) como fuente de verdad del modo RTS.
- Usar una capa de simulación desacoplada de los `Node2D`: los nodos son representación, no el estado autoritativo.
- Actualizar sistemas pesados por intervalos: IA estratégica cada varios segundos, visión por lotes y pathfinding sólo al recibir/cambiar órdenes.
- Usar `Object Pooling` para unidades, proyectiles, indicadores y efectos: activar, reiniciar y reutilizar en vez de instanciar/liberar constantemente.
- Usar grupos/arrays por equipo y tipo; evitar búsquedas globales repetidas de nodos en cada frame.
- Medir FPS, tiempo por sistema, unidades activas, órdenes activas, rutas recalculadas y proyectiles activos desde el primer prototipo.

## 5. Rendimiento para ejércitos grandes

### 5.1 Presupuesto inicial

Definir una meta inicial de 300–500 unidades simuladas y visibles a 60 FPS en el equipo objetivo. Esta cifra es un presupuesto de prueba, no una promesa: se eleva sólo después de perfilar.

### 5.2 Actualizaciones escalonadas

- Movimiento y combate cercano: cada frame o fixed tick.
- Búsqueda de objetivo: distribuida por lotes; no todas las unidades el mismo frame.
- IA táctica de escuadrón: 4–10 veces por segundo.
- IA estratégica del bot: cada 1–5 segundos.
- UI y minimapa: frecuencia reducida si es necesario.

### 5.3 Búsquedas espaciales

No comparar cada unidad con todas las demás. Implementar una cuadrícula espacial (`spatial hash`) que mantenga entidades por celda y permita consultar únicamente vecinos cercanos para ataque, separación y captura.

### 5.4 Navegación

Usar navegación por celdas. Para el MVP, A* sobre una grilla estática/bakeada por mapa es suficiente. Para masas grandes, las unidades que comparten destino deben usar un **campo de flujo (flow field)** o ruta de escuadrón compartida, no cientos de A* individuales.

Implementar en orden:
1. Ruta individual A* para pocas unidades.
2. Objetivo común y formación.
3. Ruta compartida por grupo.
4. Flow field sólo cuando el profiler demuestre que A* es cuello de botella.

### 5.5 Evitación y colisiones

Las unidades no deben usar física rígida para empujarse masivamente. Aplicar una fuerza simple de separación con vecinos de la cuadrícula espacial, limitar su magnitud y priorizar llegar al slot de formación. Esto reduce atascos y costo de física.

## 6. Estados y órdenes

### 6.1 Máquina de estados de unidad

Estados mínimos: `idle`, `moving`, `attacking`, `chasing`, `capturing`, `gathering`, `building`, `dead`.

Cada estado debe tener: condición de entrada, actualización, condición de salida y figura de debug. Ejemplo: una unidad en `attacking` puede volver a `chasing` si el objetivo sale de rango, o a `idle` si el objetivo muere y no tiene orden persistente.

### 6.2 Órdenes

Las órdenes son datos serializables, no callbacks sueltos:

```json
{
  "type": "move",
  "target_position": [1240, 680],
  "target_entity_id": null,
  "queue": false,
  "issued_by": "player_1"
}
```

Tipos iniciales: `move`, `attack_move`, `attack_target`, `capture`, `gather`, `build`, `stop`. Una orden puede pertenecer a unidad individual, líder o ejército.

### 6.3 Formaciones y liderazgo

Reemplazar el booleano ambiguo por un campo de rol:

- `leadership_capacity`: cantidad máxima de seguidores; 0 significa que no lidera.
- `formation_role`: `leader`, `follower` o `independent`.
- `squad_id`: identificador del ejército/escuadrón actual.

El líder recibe la ruta principal; cada seguidor recibe un **slot local** relativo a él. Formaciones iniciales: línea, columna y bloque. No implementar formaciones complejas hasta validar que la línea no se rompe al chocar con obstáculos.

## 7. Datos y formatos

### 7.1 JSON como formato de autoría

JSON es legible y adecuado para editar configuraciones. Cada archivo debe incluir `schema_version`, `id` estable y referencias por ID, nunca por nombre visible.

Para datos de alta frecuencia o mapas grandes, JSON no se lee durante la partida: se carga una vez al iniciar o al cambiar de mapa. Más adelante, un proceso de build puede validar JSON y generar un formato compacto (`.res`, `.tres` o binario propio) para distribución; el JSON se conserva como fuente editable.

### 7.2 Convenciones

- IDs: minúsculas, `snake_case`: `archer`, `red_legion`, `castle_main`.
- Claves: `snake_case`.
- Unidades de tiempo: segundos; distancia: unidades de mundo; vida/daño: números; porcentajes: decimal entre 0 y 1.
- Nunca usar `null` cuando un valor seguro sea posible; para atributos no aplicables, omitirlos o usar una estructura por tipo.
- Validar todas las referencias al cargar: IDs inexistentes, números negativos, costos inválidos, ciclos de dependencia y mapas sin castillo.

### 7.3 Stats base y modificadores

`units.json` define la base. `factions.json` aporta modificadores explícitos. El cálculo recomendado es: base → bonificaciones aditivas → multiplicadores → modificadores temporales → límites mínimo/máximo.

```json
{
  "schema_version": 1,
  "id": "archer",
  "display_name_key": "unit.archer.name",
  "category": "military",
  "attack": {"mode": "ranged", "damage": 10, "range": 180, "cooldown_sec": 1.0, "projectile_speed": 500, "area_radius": 0},
  "health_max": 10,
  "armor": 0,
  "move_speed": 90,
  "cost": {"gold": 10},
  "train_time_sec": 1.0,
  "leadership_capacity": 0,
  "capture_power": 1,
  "experience": {"max_level": 3},
  "visual": {"debug_shape": "triangle", "animation_set": "archer_base"}
}
```

```json
{
  "id": "faction_a",
  "unit_modifiers": {
    "archer": {"health_max_add": 1, "damage_add": -1, "special_ability_level_add": 1}
  }
}
```

## 8. Estructura de carpetas

Usar rutas simples y consistentes. En Godot, separar recursos de ejecución (`res://`) de contenido fuente/editable si el repositorio lo requiere.

```text
res://
  autoload/
    game_session.gd
    config_registry.gd
    event_bus.gd
    debug_metrics.gd
  scenes/
    bootstrap/
    menu/
    rts/
      map/
      units/
      buildings/
      ui/
      effects/
    shared/
    future_3d/
  scripts/
    domain/
      commands/
      combat/
      economy/
      ai/
      navigation/
      formation/
      save/
    presentation/
    infrastructure/
    tests/
  data/
    config/
      game_rules.json
      difficulties.json
      teams.json
    units/
      units.json
      abilities.json
    buildings/
      buildings.json
    factions/
      factions.json
    ai/
      strategies.json
      tactics.json
    animations/
      animation_sets.json
    localization/
      es_cl.json
    maps/
      map_registry.json
      2_players/
        valley_01/
          map.json
          terrain.json
          nav_grid.json
          script.gd
          props.json
  assets/
    audio/
      music/
      voices/
      weapons/
      ambience/
    sprites/
      units/
      buildings/
      terrain/
      ui/
    models_3d/
      props/
      characters/
      skins/
    materials/
    shaders/
  docs/
    design/
    schemas/
    decisions/
  tests/
```

**Nota:** en 2D no existe skybox; conservar `assets/models_3d/` y datos de ambiente 3D para el futuro sin mezclarlo con mapas RTS. Cada mapa RTS contiene sus datos propios, mientras `map_registry.json` es el catálogo que ve el menú.

## 9. Mapas

Un mapa debe definir tamaño, capa de terreno, obstáculos, puntos iniciales, recursos, zonas de construcción y navegación. El mapa no debe tener estadísticas de unidades ni lógica genérica de combate.

```json
{
  "schema_version": 1,
  "id": "valley_01",
  "display_name_key": "map.valley_01.name",
  "player_capacity": 2,
  "world_size": [4096, 4096],
  "spawn_points": [
    {"id": "spawn_a", "team_slot": 1, "position": [480, 2048]},
    {"id": "spawn_b", "team_slot": 2, "position": [3616, 2048]}
  ],
  "resources": [{"type": "gold", "position": [2048, 2048], "amount": 10000}],
  "navigation_file": "nav_grid.json"
}
```

## 10. Economía, edificios y victoria

### 10.1 Economía MVP

Recurso inicial: oro. Un aldeano recibe orden de minar, deposita automáticamente o en un punto definido y el jugador usa el oro en unidades/edificios. El comercio sólo se diseña como interfaz futura y se posterga.

### 10.2 Población

Las casas y edificios entregan capacidad. La producción falla de manera clara si `population_used + unit_population_cost > population_cap`. El sistema de felicidad queda como modificador opcional sin activarse en el MVP.

### 10.3 Edificios

Todos deben tener: `health_max`, `loyalty_max`, `cost`, `build_time_sec`, `footprint`, `tags`, `production_queue` opcional y `capture_rules`. Paredes infinitas rompen el balance y pueden trabar rutas: usar vida muy alta o inmunidad configurable, pero permitir siempre una contramedida explícita.

Captura: unidades con `capture_power` reducen lealtad sólo si cumplen reglas de proximidad, cantidad mínima, ausencia/presencia de defensor y estado no interrumpido. Cuando lealtad llega a cero, se cambia el propietario, se cancelan órdenes inválidas y se notifica el evento.

### 10.4 Condición de derrota

Un equipo pierde al destruirse o cambiar de dueño su `castle_main`, según regla de mapa. Esta regla debe ser configurable: `destroy`, `capture` o `either`.

## 11. Combate

El combate MVP es determinista en lo posible: daño, alcance, cooldown, objetivo y muerte. Un ataque a distancia crea un proyectil pooled; el melee aplica daño al estar en rango y tras respetar cooldown.

Separar adquisición de objetivo de ejecución de ataque. Prioridad inicial configurable: enemigo más cercano visible, luego el que ataca al líder, luego objetivos de alto valor. Evitar que todas las unidades cambien de objetivo cada tick; usar un intervalo y un umbral de cambio.

## 12. IA de bots

La IA no debe “hacer trampa” salvo opción explícita. Debe consultar el mismo estado visible que usaría el jugador cuando la niebla esté activa.

Capas:

| Módulo | Responsabilidad inicial |
|---|---|
| Comandante | Escoge postura: expandir, defender, atacar, recuperarse |
| Economía | Mantiene mineros, reserva oro y población |
| Producción | Elige cola de unidades y edificios |
| Exploración | Revela puntos de interés y enemigos |
| Defensa | Protege castillo, mineros y rutas |
| Ataque | Forma un ejército, elige objetivo y emite órdenes |
| Adaptación | Ajusta composición según amenazas observadas |

La dificultad activa capacidades, no altera silenciosamente stats. Ejemplo: fácil usa economía/defensa/ataque simple y reacciona lento; normal agrega exploración y composición básica; difícil activa adaptación, mejor elección de objetivos y menor intervalo de decisión. Guardar perfiles en `difficulties.json`.

## 13. UI, depuración y pruebas

La UI inicial debe tener: selección, barra de vida/lealtad, recursos, población, órdenes básicas, cola de producción, menú de pausa y panel de debug.

El panel de debug debe poder mostrar/ocultar: IDs, equipo por color, estado por figura, destino, ruta, slot de formación, celda espacial, objetivo, rango de ataque, FPS, tiempo de simulación y contadores de pool. Cada sistema nuevo se aprueba sólo con una escena de prueba reproducible.

Pruebas mínimas automatizadas: carga y validación de JSON, cálculo de stats por facción, pago de costos, límite de población, captura, condición de victoria, selección de objetivo y serialización de órdenes.

## 14. Preparación para 3D

El modo 3D es un consumidor futuro de los mismos datos de mundo, no una copia del RTS. Mantener IDs comunes para unidad, facción, edificio, mapa, propietario e inventario/estado persistente.

Crear desde ahora una interfaz conceptual `WorldState`: entidades con ID, posición, equipo, vida, control/propietario y flags. El RTS escribe/lee ese estado; el modo 3D podrá cargar una representación distinta. No intentar usar las mismas escenas ni físicas 2D/3D.

## 15. Fases y tareas atómicas

### Fase 0 — Base del repositorio

**Resultado:** proyecto abre, tiene estructura, reglas documentadas y datos validados.

- Crear repositorio Git, `.gitignore` de Godot y ramas `main`/`develop`.
- Crear estructura de carpetas definida en este documento.
- Crear escena `bootstrap` y una pantalla temporal.
- Crear `ConfigRegistry` como autoload para cargar JSON.
- Crear validador que informe archivo, clave y error.
- Crear `game_rules.json`, `units.json`, `buildings.json`, `factions.json` mínimos.
- Crear escena sandbox y panel de métricas.
- Registrar una decisión técnica por archivo en `docs/decisions/`.

**Criterio de aceptación:** el juego carga los JSON, muestra errores entendibles para un archivo inválido y abre la escena sandbox.

### Fase 1 — Simulación visual básica

**Resultado:** unidades coloreadas se crean, se seleccionan y se mueven.

- Crear `UnitState` puro con ID, propietario, posición, vida y orden.
- Crear `UnitView` que pinta forma/color desde el estado.
- Crear pool de `UnitView`.
- Crear spawner de 20 unidades por equipo.
- Implementar selección por clic y caja.
- Implementar orden `move` con clic derecho.
- Cambiar figura a círculo durante movimiento y cuadrado al detenerse.
- Mostrar ID, estado y destino en debug.
- Medir FPS con 50, 100, 250 y 500 unidades.

**Criterio de aceptación:** 250 unidades reciben órdenes sin errores, se reutilizan desde pool y el debug identifica estado/equipo.

### Fase 2 — Mapa y navegación

**Resultado:** las unidades navegan alrededor de obstáculos sin atascarse gravemente.

- Definir formato `map.json` y `nav_grid.json`.
- Crear un mapa de prueba con suelo, obstáculo y dos spawn points.
- Implementar grilla de navegación estática.
- Implementar A* para un destino individual.
- Agregar suavizado de ruta simple.
- Implementar grid espacial para vecinos.
- Agregar separación local limitada.
- Dibujar ruta, celdas bloqueadas y vecinos en debug.
- Crear prueba de 100 unidades hacia un mismo punto.

**Criterio de aceptación:** unidades rodean el obstáculo, no atraviesan celdas bloqueadas y el rendimiento queda registrado.

### Fase 3 — Órdenes, grupos y formaciones

**Resultado:** un ejército responde como grupo.

- Implementar cola de órdenes serializable.
- Implementar `attack_move` sin combate todavía.
- Crear entidad `SquadState` y `squad_id`.
- Asignar líder y seguidores por capacidad de liderazgo.
- Implementar formación línea.
- Implementar formación columna.
- Reasignar slots al llegar o perder un miembro.
- Agregar orden `stop`.
- Añadir pruebas de asignación de slots.

**Criterio de aceptación:** seleccionar líder/seguidores, enviar a destino y mantener una formación reconocible.

### Fase 4 — Combate mínimo

**Resultado:** dos equipos pueden enfrentarse y morir.

- Cargar arquero y unidad melee desde JSON.
- Implementar detección de enemigos por grid espacial.
- Implementar selección de objetivo con intervalo.
- Implementar estado `chasing`.
- Implementar cooldown y daño melee.
- Implementar proyectiles pooled y daño a distancia.
- Implementar muerte, retiro del pool y evento de muerte.
- Cambiar figura a triángulo durante ataque.
- Crear prueba 50 vs 50.

**Criterio de aceptación:** ambos tipos atacan según sus rangos/cooldowns; no existen referencias a objetivos muertos.

### Fase 5 — Economía y construcción

**Resultado:** el jugador puede financiar y producir su ejército.

- Crear estado de jugador: oro, población usada y máxima.
- Implementar mina de oro simple.
- Crear aldeano y orden `gather`.
- Implementar descuento de costo validado.
- Crear castillo, casa y cuartel.
- Implementar colocación de construcción con validación de suelo/colisión.
- Implementar tiempo de construcción.
- Implementar capacidad de población desde edificios.
- Implementar cola de producción de cuartel.

**Criterio de aceptación:** el jugador mina, construye casas y cuartel, y produce unidades hasta su límite poblacional.

### Fase 6 — Captura y condiciones de partida

**Resultado:** la partida tiene victoria y derrota funcionales.

- Implementar `loyalty_max` y propietario de edificio.
- Implementar orden/estado `capture`.
- Implementar reducción de lealtad y su interrupción.
- Implementar cambio de dueño y actualización visual.
- Configurar castillo como objetivo de derrota.
- Implementar pantalla de victoria/derrota.
- Probar victoria por destrucción, captura y regla `either`.

**Criterio de aceptación:** una partida se puede ganar sin intervención manual de debug.

### Fase 7 — Menús, facciones y configuración

**Resultado:** se puede iniciar una partida configurable.

- Crear menú principal: partida rápida, opciones, salir.
- Crear selector de mapa desde `map_registry.json`.
- Crear selector de número de jugadores, equipo, color y facción.
- Crear tres facciones desde datos con modificadores visibles.
- Implementar cálculo de stats efectivos y panel debug de desglose.
- Crear opciones de audio, gráficos, controles, interfaz y debug.
- Guardar/cargar ajustes locales.

**Criterio de aceptación:** cambiar facción modifica stats sin editar scripts; el menú lista mapas válidos.

### Fase 8 — Bot inicial

**Resultado:** un bot completa el bucle básico contra el jugador.

- Crear percepción mínima del bot.
- Implementar economía: minar y construir casa al llegar al límite.
- Implementar producción de unidades básicas.
- Implementar defensa alrededor del castillo.
- Implementar creación de escuadrón y ataque al castillo enemigo.
- Crear perfiles fácil/normal/difícil en JSON.
- Agregar logs de decisiones del bot.
- Ejecutar pruebas repetidas bot vs bot.

**Criterio de aceptación:** bot vs bot termina partidas sin errores ni recursos negativos.

### Fase 9 — Contenido y robustez

**Resultado:** vertical slice presentable de tres mapas y tres facciones.

- Crear 3 mapas pequeños con rutas/obstáculos distintos.
- Balancear unidades/edificios con tablas de datos.
- Añadir niebla de guerra como opción experimental.
- Añadir tácticas simples y adaptación de bot.
- Añadir audio placeholder y efectos simples.
- Crear guardado de partida si el estado está serializable.
- Perfilar, corregir cuellos de botella y documentar límites.

**Criterio de aceptación:** una sesión completa es jugable, reproducible y sus datos se validan al iniciar.

## 16. Protocolo para trabajar con IA de menor capacidad

Entregarle siempre un único bloque de trabajo con: objetivo, archivos permitidos, interfaces existentes, criterios de aceptación, restricciones y prueba manual. Nunca pedir “haz el RTS” ni mezclar UI, IA, combate y datos en una sola instrucción.

Plantilla:

```text
TAREA: Implementar [una tarea atómica].
CONTEXTO: Godot 4, proyecto RTS 2D; consultar docs/design/PLAN_MAESTRO.md.
ARCHIVOS PERMITIDOS: [lista cerrada].
NO HACER: [sistemas fuera de alcance].
ENTRADA: [datos o interfaces existentes].
SALIDA ESPERADA: [clase/archivo/comportamiento].
ACEPTACIÓN: [pasos verificables].
DEBUG: [qué debe verse o registrarse].
```

Después de cada tarea: ejecutar proyecto, probar el criterio, revisar cambios Git, actualizar este documento o el registro de decisiones si se cambió una regla. Una tarea fallida se reduce, no se compensa agregando más código.

## 17. Riesgos y decisiones pendientes

- **Escala de unidades:** no prometer miles antes de perfilar con hardware objetivo.
- **Paredes indestructibles:** pueden crear estados sin salida; definir demolición y navegación antes de incluirlas.
- **Felicidad:** puede añadir micromanejo sin mejorar el bucle; mantener desactivada hasta el vertical slice.
- **Captura:** necesita reglas anti-frustración (progreso visible, interrupción, defensor, tiempo).
- **Modo 3D:** mantener compatibilidad de datos, pero evitar que condicione o retrase el MVP 2D.
- **JSON:** validar al inicio; los archivos mal formados deben fallar con mensajes claros, no con errores silenciosos en combate.

## 18. Definition of Done global

Una funcionalidad está terminada sólo cuando:

- Sus datos están definidos y validados.
- Tiene comportamiento visible en sandbox o partida.
- Puede depurarse mediante overlay/log.
- No rompe los tests existentes.
- Tiene criterio de aceptación comprobado.
- Su alcance y archivos modificados quedaron documentados.

---

## Próxima tarea recomendada

Ejecutar **Fase 0 completa** antes de programar movimiento o combate. El primer entregable concreto es un proyecto Godot con `ConfigRegistry`, JSON mínimo validado, escena sandbox y panel de métricas; desde ahí se implementa Fase 1 de manera incremental.
