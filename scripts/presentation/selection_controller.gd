class_name SelectionController
extends Node
## Maneja seleccion de unidades por clic y caja de seleccion.
## Emite señales al EventBus cuando cambia la seleccion.

const MAX_SELECTION: int = 20

var unit_view_pool: UnitViewPool = null
var unit_pool: UnitPool = null
var camera: Camera2D = null

var selected_unit_ids: Array[int] = []

# Seleccion por arrastre
var _drag_start: Vector2 = Vector2.ZERO
var _is_dragging: bool = false
const DRAG_THRESHOLD: float = 6.0

# Solo permitir seleccion de unidades del jugador local
var local_player_id: int = 1


func _input(event: InputEvent) -> void:
	if unit_view_pool == null or camera == null:
		return

	if event is InputEventMouseButton:
		var mb: InputEventMouseButton = event as InputEventMouseButton
		if mb.button_index == MOUSE_BUTTON_LEFT:
			if mb.pressed:
				_drag_start = mb.global_position
				_is_dragging = false
			else:
				if _is_dragging:
					_finish_drag_selection(mb.global_position)
				else:
					_handle_click_selection(mb.global_position)
				_is_dragging = false

	if event is InputEventMouseMotion and Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT):
		var mm: InputEventMouseMotion = event as InputEventMouseMotion
		if not _is_dragging:
			if mm.global_position.distance_to(_drag_start) > DRAG_THRESHOLD:
				_is_dragging = true


# ---------------------------------------------------------------------------
# Click simple
# ---------------------------------------------------------------------------
func _handle_click_selection(screen_pos: Vector2) -> void:
	var world_pos: Vector2 = camera.get_global_transform().affine_inverse() * screen_pos
	var uid: int = unit_view_pool.get_unit_id_at_position(world_pos)

	var add_to_selection: bool = Input.is_key_pressed(KEY_SHIFT)

	if uid == -1:
		if not add_to_selection:
			_deselect_all()
		return

	# Filtrar por jugador local
	var state: UnitState = unit_pool.get_unit(uid)
	if state == null or state.owner_id != local_player_id:
		if not add_to_selection:
			_deselect_all()
		return

	if add_to_selection:
		if uid in selected_unit_ids:
			_deselect_unit(uid)
		else:
			_select_unit(uid)
	else:
		_deselect_all()
		_select_unit(uid)


# ---------------------------------------------------------------------------
# Seleccion por caja
# ---------------------------------------------------------------------------
func _finish_drag_selection(screen_end: Vector2) -> void:
	var world_start: Vector2 = camera.get_global_transform().affine_inverse() * _drag_start
	var world_end: Vector2 = camera.get_global_transform().affine_inverse() * screen_end
	var rect: Rect2 = Rect2(world_start, Vector2.ZERO).expand(world_end)

	if not Input.is_key_pressed(KEY_SHIFT):
		_deselect_all()

	var candidates: Array[int] = unit_view_pool.get_units_in_rect(rect)
	for uid in candidates:
		var state: UnitState = unit_pool.get_unit(uid)
		if state != null and state.owner_id == local_player_id:
			if uid not in selected_unit_ids and selected_unit_ids.size() < MAX_SELECTION:
				_select_unit(uid)


# ---------------------------------------------------------------------------
# Helpers
# ---------------------------------------------------------------------------
func _select_unit(uid: int) -> void:
	selected_unit_ids.append(uid)
	unit_view_pool.set_selected(uid, true)
	EventBus.unit_selected.emit(selected_unit_ids.duplicate())


func _deselect_unit(uid: int) -> void:
	selected_unit_ids.erase(uid)
	unit_view_pool.set_selected(uid, false)
	EventBus.unit_selected.emit(selected_unit_ids.duplicate())


func _deselect_all() -> void:
	for uid in selected_unit_ids:
		unit_view_pool.set_selected(uid, false)
	selected_unit_ids.clear()
	EventBus.unit_deselected.emit()


func get_selected_ids() -> Array[int]:
	return selected_unit_ids.duplicate()
