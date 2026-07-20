class_name UnitPool
extends Node
## Pool de UnitState. Reutiliza estados en vez de crear/liberar constantemente.
## Capacidad configurable; expande automaticamente si se agota.

const INITIAL_CAPACITY: int = 200

var _pool: Array[UnitState] = []
var _active: Dictionary = {}  # unit_id -> UnitState
var _next_id: int = 1


func _ready() -> void:
	_pool.reserve(INITIAL_CAPACITY)
	for i in range(INITIAL_CAPACITY):
		_pool.append(UnitState.new())


# ---------------------------------------------------------------------------
# Obtener una unidad del pool
# ---------------------------------------------------------------------------
func acquire(unit_type: String, owner_id: int, spawn_pos: Vector2) -> UnitState:
	var state: UnitState
	if _pool.is_empty():
		state = UnitState.new()
		push_warning("UnitPool: pool agotado, creando nuevo UnitState")
	else:
		state = _pool.pop_back()

	var data: Dictionary = ConfigRegistry.get_unit_data(unit_type)
	state.setup_from_data(data)
	state.unit_id = _next_id
	state.owner_id = owner_id
	state.position = spawn_pos
	state.destination = spawn_pos
	state.path.clear()
	state.path_index = 0
	state.active_order = {}
	state.squad_id = -1
	state.formation_role = "independent"
	state.formation_slot_offset = Vector2.ZERO
	state.target_unit_id = -1
	state.set_state(UnitState.STATE_IDLE)

	_active[_next_id] = state
	_next_id += 1

	EventBus.emit_unit_created(state.unit_id, unit_type, owner_id)
	return state


# ---------------------------------------------------------------------------
# Devolver una unidad al pool
# ---------------------------------------------------------------------------
func release(unit_id: int) -> void:
	if unit_id not in _active:
		push_warning("UnitPool.release: unit_id %d no esta activo" % unit_id)
		return
	var state: UnitState = _active[unit_id]
	_active.erase(unit_id)
	_pool.append(state)
	EventBus.emit_unit_destroyed(unit_id, state.owner_id)


# ---------------------------------------------------------------------------
# Queries
# ---------------------------------------------------------------------------
func get_active() -> Dictionary:
	return _active


func get_unit(unit_id: int) -> UnitState:
	return _active.get(unit_id, null)


func get_active_count() -> int:
	return _active.size()


func get_pooled_count() -> int:
	return _pool.size()
