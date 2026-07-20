# Plan de Acción — RTS 2D Configurable

**Fecha:** 2026-07-20  
**Estado del proyecto:** Básicamente un proyecto Godot 4.7 recién creado con el addon de Ziva Agent instalado.  
**Lo que existe:** `PLAN_MAESTRO_RTS_2D.md` (documento de diseño completo), `project.godot` configurado, nada más.

---

## Resumen de la situación actual

| Aspecto | Estado |
|---|---|
| Código GDScript | 0 archivos |
| Escenas (`.tscn`) | 0 archivos |
| Datos JSON | 0 archivos |
| Assets/Sprites | 0 archivos |
| Estructura de carpetas | Solo existe `PLAN MAESTRO/` y `addons/ziva_agent/` |
| Repositorio Git | No existe |
| Autoloads configurados | 0 |

El proyecto está **en el punto cero absoluto**, listo para comenzar la **Fase 0** del plan maestro.

---

## Análisis del plan maestro

El documento `PLAN_MAESTRO_RTS_2D.md` es excelente y completo (18 secciones, 548 líneas). Sus fortalezas:

1. **Arquitectura en 4 capas** (datos → dominio → presentación → infraestructura) — desacopla simulación de renderizado.
2. **Fases incrementales claras** — Fase 0 a Fase 9, cada una con criterios de aceptación.
3. **Enfoque data-driven** — JSON como fuente de verdad, stats calculados desde base + modificadores.
4. **Rendimiento desde el día 1** — grid espacial, pooling, actualizaciones escalonadas, A* → flow field.
5. **Formaciones y liderazgo** bien pensados con `leadership_capacity`, `formation_role`, `squad_id`.
6. **Protocolo para IA** — tareas atómicas con criterios cerrados.

---

## Fases del plan (resumen ejecutivo)

| Fase | Objetivo | Dependencias |
|---|---|---|
| **0 — Base** | Proyecto abre, estructura, JSON validados, escena sandbox | Ninguna |
| **1 — Simulación visual** | Unidades coloreadas se crean, seleccionan y mueven (formas/debug) | Fase 0 |
| **2 — Mapa y navegación** | A* sobre grilla, obstáculos, separación local | Fase 1 |
| **3 — Órdenes, grupos, formaciones** | Órdenes serializables, squads, líder/seguidores, formaciones línea/columna | Fase 2 |
| **4 — Combate mínimo** | Daño melee/rango, proyectiles pooled, muerte, 50v50 | Fase 3 |
| **5 — Economía y construcción** | Oro, aldeanos, minas, edificios, población, colas de producción | Fase 4 |
| **6 — Captura y condiciones de partida** | Lealtad, captura de edificios, victoria/derrota | Fase 5 |
| **7 — Menús, facciones y configuración** | Menú principal, selector de mapa/facción/color, 3 facciones, opciones | Fase 6 |
| **8 — Bot inicial** | IA completa: economía, producción, defensa, ataque, 3 dificultades | Fase 7 |
| **9 — Contenido y robustez** | 3 mapas, balance, niebla, audio, guardado, perfilado | Fase 8 |

---

## Plan de ejecución recomendado (paso a paso)

A continuación, cada paso está diseñado como una **tarea atómica** que Ziva puede ejecutar y verificar antes de pasar a la siguiente.

---

### ✅ PRIMEROS PASOS (Configuración inicial + Fase 0 completa)

#### Paso 0.1 — Inicializar Git
- `git init`, crear rama `main`, commit inicial.
- **Archivos:** raíz del proyecto.
- **Verificación:** `git log` muestra un commit.

#### Paso 0.2 — Crear estructura de carpetas
- Crear: `autoload/`, `scenes/bootstrap/`, `scenes/menu/`, `scenes/rts/map/`, `scenes/rts/units/`, `scenes/rts/buildings/`, `scenes/rts/ui/`, `scenes/rts/effects/`, `scenes/shared/`, `scenes/future_3d/`, `scripts/domain/commands/`, `scripts/domain/combat/`, `scripts/domain/economy/`, `scripts/domain/ai/`, `scripts/domain/navigation/`, `scripts/domain/formation/`, `scripts/domain/save/`, `scripts/presentation/`, `scripts/infrastructure/`, `scripts/tests/`, `data/config/`, `data/units/`, `data/buildings/`, `data/factions/`, `data/ai/`, `data/animations/`, `data/localization/`, `data/maps/2_players/`, `assets/audio/music/`, `assets/audio/voices/`, `assets/audio/weapons/`, `assets/audio/ambience/`, `assets/sprites/units/`, `assets/sprites/buildings/`, `assets/sprites/terrain/`, `assets/sprites/ui/`, `assets/models_3d/props/`, `assets/models_3d/characters/`, `assets/models_3d/skins/`, `assets/materials/`, `assets/shaders/`, `docs/design/`, `docs/schemas/`, `docs/decisions/`, `tests/`, `assets/generated/`
- **Archivos:** solo carpetas (Godot las registra al crearse desde el editor, pero podemos usar gitkeep).
- **Verificación:** `glob("**/*")` muestra las carpetas.

#### Paso 0.3 — Crear archivos JSON mínimos de datos
- **`data/config/game_rules.json`**: población máxima base, oro inicial, reglas de victoria.
- **`data/units/units.json`**: `schema_version`, lista con `villager`, `swordsman`, `archer` (stats base del plan).
- **`data/buildings/buildings.json`**: `castle`, `house`, `barracks` con `health_max`, `loyalty_max`, `cost`, `build_time_sec`, `footprint`.
- **`data/factions/factions.json`**: 2 facciones mínimas con modificadores sobre unidades.
- **Archivos:** `data/config/game_rules.json`, `data/units/units.json`, `data/buildings/buildings.json`, `data/factions/factions.json`.
- **Verificación:** los archivos existen, son JSON válidos y siguen el schema del plan.

#### Paso 0.4 — Crear autoload `ConfigRegistry`
- Singleton que carga todos los JSON al iniciar el juego.
- Expone métodos: `get_unit_data(id)`, `get_building_data(id)`, `get_faction_data(id)`, `get_game_rules()`.
- Validación básica: loguea errores si un archivo falta o está mal formado.
- **Archivo:** `autoload/config_registry.gd`.
- **Configuración:** agregar a `project.godot` como autoload.
- **Verificación:** ejecutar proyecto y ver en output que los datos se cargaron.

#### Paso 0.5 — Crear autoload `EventBus`
- Sistema de señales globales: `unit_died`, `building_captured`, `game_over`, `resource_changed`, `order_issued`.
- **Archivo:** `autoload/event_bus.gd`.
- **Configuración:** agregar como autoload en `project.godot`.
- **Verificación:** instanciar en una escena de prueba y conectar una señal.

#### Paso 0.6 — Crear autoload `DebugMetrics`
- Panel superpuesto que muestra FPS, contador de unidades activas, tiempo de simulación.
- Alternable con tecla F3.
- **Archivo:** `autoload/debug_metrics.gd`.
- **Configuración:** agregar como autoload en `project.godot`.
- **Verificación:** ejecutar proyecto, presionar F3 y ver el overlay.

#### Paso 0.7 — Crear autoload `GameSession`
- Estado global de la partida: jugadores, equipos, fase del juego, tiempo transcurrido.
- Contiene referencia al mapa activo y lista de entidades.
- **Archivo:** `autoload/game_session.gd`.
- **Configuración:** agregar como autoload en `project.godot`.
- **Verificación:** instanciar partida de prueba, verificar que el estado existe.

#### Paso 0.8 — Crear escena `Bootstrap`
- Escena raíz que inicia la configuración, verifica datos y transiciona al menú o sandbox.
- Por ahora: botón "Ir al sandbox" y botón "Salir".
- **Archivo:** `scenes/bootstrap/bootstrap.tscn` + `scenes/bootstrap/bootstrap.gd`.
- **Verificación:** abrir escena, mostrar botones.

#### Paso 0.9 — Crear escena Sandbox
- Escena de prueba con fondo, cámara 2D arrastrable, capacidad de spawnear entidades.
- Botón "Spawn 10 unidades" para pruebas.
- **Archivo:** `scenes/rts/sandbox.tscn` + `scenes/rts/sandbox.gd`.
- **Verificación:** abrir escena, spawnear entidades, mover cámara.

#### Paso 0.10 — Guardar decisión técnica y commit
- Crear `docs/decisions/001-estructura-inicial.md` documentando decisiones de Fase 0.
- Commit de Git con todo lo anterior.

**Criterio de aceptación Fase 0:** El juego carga los JSON, muestra errores entendibles para un archivo inválido y abre la escena sandbox.

---

### 🟡 FASE 1 — Simulación visual básica

Tras completar Fase 0, avanzar en este orden:

#### Paso 1.1 — `UnitState` (estructura de datos pura)
- Clase `UnitState` con: `unit_id`, `unit_type`, `owner_id`, `position`, `health_current`, `order`, `state` (idle/moving/attacking/etc), `squad_id`, `formation_role`, `target_position`, `target_entity_id`.
- **Archivo:** `scripts/domain/unit_state.gd`.
- **Verificación:** crear instancias de prueba.

#### Paso 1.2 — Pool de `UnitView`
- `UnitView` extiende `Node2D`, dibuja forma (cuadrado/círculo/triángulo) según estado usando `_draw()`.
- `UnitPool` que precarga N vistas y las activa/desactiva.
- **Archivos:** `scripts/presentation/unit_view.gd`, `scripts/infrastructure/unit_pool.gd`.
- **Verificación:** pool entrega vistas sin instanciar nuevas.

#### Paso 1.3 — Spawner y selección
- Sistema que crea 20 unidades por equipo desde el sandbox.
- Selección por clic izquierdo individual y por caja (arrastrar rectángulo).
- **Archivo:** `scripts/presentation/selection_manager.gd`.
- **Verificación:** hacer clic en unidad → se resalta. Arrastrar → selecciona múltiples.

#### Paso 1.4 — Orden `move`
- Clic derecho en el suelo → unidades seleccionadas reciben orden `move`.
- Cambian visual a círculo mientras se mueven, cuadrado al detenerse.
- Movimiento directo hacia el punto (sin navegación todavía).
- **Archivo:** `scripts/presentation/input_handler.gd`.
- **Verificación:** seleccionar unidades, clic derecho, se mueven en línea recta.

#### Paso 1.5 — Debug overlay
- Mostrar ID de unidad, estado actual, destino, equipo por color.
- Integrar con `DebugMetrics`.
- **Verificación:** F3 muestra datos de unidades seleccionadas.

#### Paso 1.6 — Prueba de rendimiento
- Spawnear 50, 100, 250, 500 unidades. Medir FPS.
- Registrar resultados en `docs/decisions/002-benchmark-fase1.md`.

**Criterio de aceptación Fase 1:** 250 unidades reciben órdenes sin errores, se reutilizan desde pool, debug identifica estado/equipo.

---

### 🟡 FASE 2 — Mapa y navegación

#### Paso 2.1 — Formato de mapa y mapa de prueba
- Crear `data/maps/map_registry.json` con catálogo.
- Creer `data/maps/2_players/valley_01/map.json` y `nav_grid.json` (grilla 64x64, celdas transitables y obstáculos).
- **Verificación:** cargar mapa desde `ConfigRegistry`.

#### Paso 2.2 — Grilla de navegación y A*
- Sistema `NavigationGrid` que carga `nav_grid.json` y ejecuta A*.
- Devuelve array de puntos (path).
- **Archivo:** `scripts/domain/navigation/navigation_grid.gd`, `scripts/domain/navigation/astar_pathfinder.gd`.
- **Verificación:** de punto A a punto B rodeando obstáculos.

#### Paso 2.3 — Grid espacial (SpatialHash)
- Divide el mundo en celdas. Cada unidad/entidad se registra en su celda.
- Consulta: "dame entidades en radio R alrededor de posición P".
- **Archivo:** `scripts/infrastructure/spatial_hash.gd`.
- **Verificación:** 500 unidades en grid, consulta vecinos en O(1) promedio.

#### Paso 2.4 — Separación local
- Sistema que aplica fuerza de separación entre unidades cercanas (usando SpatialHash).
- **Archivo:** `scripts/domain/navigation/local_separation.gd`.
- **Verificación:** unidades no se superponen al moverse a un punto común.

#### Paso 2.5 — Ruta + movimiento integrado
- Unidades usan A* para moverse, con separación local.
- Suavizado de ruta simple (eliminar waypoints redundantes).
- **Verificación:** 100 unidades hacia mismo punto, rodean obstáculos.

#### Paso 2.6 — Debug de navegación
- Dibujar ruta, celdas bloqueadas, vecinos en debug overlay.
- **Verificación:** overlay visible, toggle con F4.

**Criterio de aceptación Fase 2:** Unidades rodean obstáculo, no atraviesan celdas bloqueadas, rendimiento registrado.

---

### 🟡 FASE 3 — Órdenes, grupos y formaciones

#### Paso 3.1 — Órdenes serializables
- Clase `Order` con `type`, `target_position`, `target_entity_id`, `queue`, `issued_by`.
- Cola de órdenes por unidad.
- **Archivo:** `scripts/domain/commands/order.gd`.
- **Verificación:** serializar/deserializar orden a JSON.

#### Paso 3.2 — `attack_move` (sin combate)
- Orden `attack_move`: unidades se mueven al destino pero atacan objetivos enemigos en ruta (implementar después del combate, por ahora solo moverse).
- **Verificación:** unidades se mueven con ataque_move, ignoran enemigos por ahora.

#### Paso 3.3 — SquadState y liderazgo
- `SquadState` con `squad_id`, `leader_id`, `member_ids`, `formation_type`.
- Asignar líder según `leadership_capacity`.
- **Archivo:** `scripts/domain/formation/squad_state.gd`.
- **Verificación:** crear squad, asignar líder, seguidores siguen.

#### Paso 3.4 — Formación línea y columna
- Calcular slots relativos al líder para cada formación.
- Seguidores mantienen posición relativa mientras el líder se mueve.
- Reasignar slots al perder o agregar miembros.
- **Archivo:** `scripts/domain/formation/formation_manager.gd`.
- **Verificación:** 10 unidades en línea se mueven juntas manteniendo forma.

#### Paso 3.5 — Orden `stop`
- Detiene la unidad donde está, cancela órdenes en cola.
- **Verificación:** unidad en movimiento → stop → se detiene instantáneamente.

**Criterio de aceptación Fase 3:** Seleccionar líder/seguidores, enviar a destino, mantener formación reconocible.

---

### 🟡 FASE 4 — Combate mínimo

*(Continuar con el mismo patrón para Fases 4-9 siguiendo el plan maestro)*

---

## Recomendaciones clave

### Orden de implementación
1. **Hacer Fase 0 COMPLETA primero** — todo lo demás depende de ella.
2. No saltar fases — cada fase produce una base verificable para la siguiente.
3. No mezclar UI final con simulación temprana (usar formas/debug).

### Prioridades técnicas
- **Data-driven desde el día 1** — no hardcodear stats, cargar desde JSON.
- **Pooling desde la Fase 1** — no instanciar/liberar unidades en caliente.
- **SpatialHash desde la Fase 2** — evitar O(n²) en búsquedas.
- **Separación de capas** — `UnitState` (datos) ≠ `UnitView` (presentación).

### Lo que NO hacer en las primeras fases
- ❌ Sprites/animaciones finales (usar formas de debug)
- ❌ Multijugador en red
- ❌ Campaña o narrativa
- ❌ Audio definitivo
- ❌ Niebla de guerra (Fase 9)
- ❌ Modo 3D
- ❌ IA compleja antes de Fase 8

### Formato de cada tarea para Ziva

Cada tarea atómica debe seguir este formato:

```text
TAREA: [nombre]
CONTEXTO: Godot 4.7, proyecto RTS 2D, Fase [X]
ARCHIVOS PERMITIDOS: [lista]
NO HACER: [restricciones]
ENTRADA: [interfaces/datos existentes]
SALIDA ESPERADA: [clase/archivo/comportamiento]
ACEPTACIÓN: [pasos verificables]
DEBUG: [qué debe verse o registrarse]
```

---

## Próximo paso inmediato

**Ejecutar Fase 0 completa (Pasos 0.1 → 0.10)**. Es la base de todo el proyecto.

¿Por dónde quieres empezar?
- ¿Prefieres que ejecute toda la Fase 0 de una sola vez?
- ¿O prefieres ir paso a paso, verificando cada uno antes de continuar?
- ¿Quieres ajustar algo del plan antes de arrancar?
