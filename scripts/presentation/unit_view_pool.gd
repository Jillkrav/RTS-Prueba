class_name UnitViewPool
extends Node
## Pool de nodos UnitView. Crea, reutiliza y oculta nodos visuales.
## Sincroniza la cantidad de views activas con los UnitState activos.

const UNIT_VIEW_SCENE_PATH: String = "res://scenes/rts/units/unit_view.tscn"

var _pool: Array[UnitView] = []
var _active: Dictionary = {}  # unit_id (int) -> UnitView
var _scene: PackedScene = null
var _parent: Node2D = null

# Flags de debug
var show_ids: bool = false
var show_states: bool = false


func _ready() -> void:
	_scene = load(UNIT_VIEW_SCENE_PATH)


func initialize(parent: Node2D) -> void:
	_parent = parent


# ---------------------------------------------------------------------------
# Sincronizar views con states activos
# ---------------------------------------------------------------------------
func sync(active_states: Dictionary) -> void:
	# Liberar views huerfanas
	var to_remove: Array[int] = []
	for uid in _active:
		if uid not in active_states:
			to_remove.append(uid)
	for uid in to_remove:
		_release_view(uid)

	# Crear views para nuevos states
	for uid in active_states:
		if uid not in _active:
			_acquire_view(active_states[uid])

	# Actualizar flags de debug
	for uid in _active:
		var view: UnitView = _active[uid]
		view.show_id = show_ids
		view.show_state = show_states


# ---------------------------------------------------------------------------
# Obtener / devolver views
# ---------------------------------------------------------------------------
func _acquire_view(state: UnitState) -> void:
	var view: UnitView
	if not _pool.is_empty():
		view = _pool.pop_back()
	else:
		if _scene == null:
			push_error("UnitViewPool: escena UnitView no encontrada en " + UNIT_VIEW_SCENE_PATH)
			return
		view = _scene.instantiate()
		_parent.add_child(view)

	view.state = state
	view.global_position = state.position
	view.visible = true
	_active[state.unit_id] = view


func _release_view(unit_id: int) -> void:
	if unit_id not in _active:
		return
	var view: UnitView = _active[unit_id]
	_active.erase(unit_id)
	view.state = null
	view.visible = false
	_pool.append(view)


# ---------------------------------------------------------------------------
# Queries para seleccion
# ---------------------------------------------------------------------------
func get_view(unit_id: int) -> UnitView:
	return _active.get(unit_id, null)


func get_unit_id_at_position(world_pos: Vector2, radius: float = 14.0) -> int:
	for uid in _active:
		var view: UnitView = _active[uid]
		if view.global_position.distance_to(world_pos) <= radius:
			return uid
	return -1


func get_units_in_rect(rect: Rect2) -> Array[int]:
	var result: Array[int] = []
	for uid in _active:
		var view: UnitView = _active[uid]
		if rect.has_point(view.global_position):
			result.append(uid)
	return result


func set_selected(unit_id: int, selected: bool) -> void:
	if unit_id in _active:
		_active[unit_id].is_selected = selected


func get_active_count() -> int:
	return _active.size()


func get_pooled_count() -> int:
	return _pool.size()
