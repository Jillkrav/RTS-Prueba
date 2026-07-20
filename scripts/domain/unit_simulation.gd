class_name UnitSimulation
extends Node
## Sistema de simulacion de unidades. Actualiza posicion y estado cada frame.
## No contiene logica de presentacion ni nodos visuales.

const ARRIVAL_THRESHOLD: float = 4.0
const SEPARATION_FORCE: float = 30.0
const SEPARATION_RADIUS: float = 14.0

var unit_pool: UnitPool = null


func _process(delta: float) -> void:
	if unit_pool == null:
		return
	var active: Dictionary = unit_pool.get_active()
	for uid in active:
		_tick_unit(active[uid], delta, active)


# ---------------------------------------------------------------------------
# Tick de unidad
# ---------------------------------------------------------------------------
func _tick_unit(state: UnitState, delta: float, all_units: Dictionary) -> void:
	if not state.is_alive():
		return

	match state.current_state:
		UnitState.STATE_IDLE:
			_apply_separation(state, all_units, delta)

		UnitState.STATE_MOVING:
			_move_unit(state, delta)
			_apply_separation(state, all_units, delta)


# ---------------------------------------------------------------------------
# Movimiento por waypoints
# ---------------------------------------------------------------------------
func _move_unit(state: UnitState, delta: float) -> void:
	if not state.has_destination():
		state.set_state(UnitState.STATE_IDLE)
		return

	var target: Vector2 = state.get_next_waypoint()
	var to_target: Vector2 = target - state.position
	var dist: float = to_target.length()

	if dist <= ARRIVAL_THRESHOLD:
		state.path_index += 1
		if state.path_index >= state.path.size():
			state.position = target
			state.path.clear()
			state.path_index = 0
			state.set_state(UnitState.STATE_IDLE)
		return

	var direction: Vector2 = to_target.normalized()
	var step: float = state.move_speed * delta
	state.position += direction * min(step, dist)


# ---------------------------------------------------------------------------
# Separacion simple para evitar solapamiento
# ---------------------------------------------------------------------------
func _apply_separation(state: UnitState, all_units: Dictionary, delta: float) -> void:
	var push: Vector2 = Vector2.ZERO
	for uid in all_units:
		if uid == state.unit_id:
			continue
		var other: UnitState = all_units[uid]
		var diff: Vector2 = state.position - other.position
		var d: float = diff.length()
		if d > 0.0 and d < SEPARATION_RADIUS:
			push += diff.normalized() * (SEPARATION_RADIUS - d) / SEPARATION_RADIUS

	if push.length() > 0.01:
		state.position += push * SEPARATION_FORCE * delta


# ---------------------------------------------------------------------------
# Emitir orden de movimiento
# ---------------------------------------------------------------------------
func issue_move_order(unit_ids: Array[int], destination: Vector2) -> void:
	var count: int = unit_ids.size()
	for i in range(count):
		var state: UnitState = unit_pool.get_unit(unit_ids[i])
		if state == null or not state.is_alive():
			continue

		# Offset de grupo simple: cuadricula de destinos
		var cols: int = max(1, int(sqrt(float(count))))
		var row: int = i / cols
		var col: int = i % cols
		var offset: Vector2 = Vector2(col * 18.0, row * 18.0)
		var target: Vector2 = destination + offset - Vector2((cols - 1) * 9.0, (row) * 9.0)

		state.path = [target]
		state.path_index = 0
		state.destination = target
		state.active_order = {
			"type": "move",
			"target_position": [target.x, target.y],
			"target_entity_id": null,
			"queue": false,
			"issued_by": "player_%d" % state.owner_id
		}
		state.set_state(UnitState.STATE_MOVING)
