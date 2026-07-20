class_name SandboxController
extends Node2D
## Controlador principal de la escena sandbox.
## Inicializa y conecta todos los sistemas de la Fase 1.

# Referencia a nodos hijos
@onready var unit_pool: UnitPool             = $UnitPool
@onready var unit_simulation: UnitSimulation = $UnitSimulation
@onready var unit_view_pool: UnitViewPool    = $UnitViewPool
@onready var spawner: Spawner               = $Spawner
@onready var selection_ctrl: SelectionController = $SelectionController
@onready var camera: Camera2D               = $Camera2D
@onready var units_layer: Node2D            = $UnitsLayer
@onready var selection_rect: ColorRect      = $SelectionRect

# Configuracion de prueba
const UNITS_PER_TEAM: int = 20
const SPAWN_A: Vector2 = Vector2(200, 360)
const SPAWN_B: Vector2 = Vector2(1080, 360)

# Camara
const CAM_SPEED: float = 400.0
const CAM_ZOOM_SPEED: float = 0.1
const CAM_ZOOM_MIN: float = 0.3
const CAM_ZOOM_MAX: float = 3.0

# Caja de seleccion en pantalla
var _drag_start_screen: Vector2 = Vector2.ZERO
var _is_drawing_rect: bool = false


func _ready() -> void:
	# Iniciar sesion
	GameSession.start_session(2)

	# Conectar sistemas
	unit_simulation.unit_pool = unit_pool
	unit_view_pool.initialize(units_layer)
	spawner.unit_pool = unit_pool
	selection_ctrl.unit_view_pool = unit_view_pool
	selection_ctrl.unit_pool = unit_pool
	selection_ctrl.camera = camera
	selection_ctrl.local_player_id = 1

	# Leer config debug
	var rules: Dictionary = ConfigRegistry.get_game_rules()
	var dbg: Dictionary = rules.get("debug", {})
	unit_view_pool.show_ids = dbg.get("show_ids", false)
	unit_view_pool.show_states = dbg.get("show_state", false)

	# Verificar errores de carga
	if ConfigRegistry.has_load_errors():
		for err in ConfigRegistry.get_load_errors():
			push_error("[CONFIG] " + err)

	# Spawn unidades de prueba
	spawner.spawn_test_units(UNITS_PER_TEAM, [SPAWN_A, SPAWN_B])

	# Conectar señal de movimiento
	EventBus.unit_order_issued.connect(_on_order_issued)


func _process(delta: float) -> void:
	_move_camera(delta)

	# Sincronizar views con estados
	unit_view_pool.sync(unit_pool.get_active())

	# Actualizar contadores en debug overlay
	DebugMetrics.set_unit_counts(unit_pool.get_active_count(), unit_pool.get_pooled_count())


# ---------------------------------------------------------------------------
# Camara WASD / bordes
# ---------------------------------------------------------------------------
func _move_camera(delta: float) -> void:
	var dir: Vector2 = Vector2.ZERO
	if Input.is_key_pressed(KEY_W) or Input.is_key_pressed(KEY_UP):
		dir.y -= 1
	if Input.is_key_pressed(KEY_S) or Input.is_key_pressed(KEY_DOWN):
		dir.y += 1
	if Input.is_key_pressed(KEY_A) or Input.is_key_pressed(KEY_LEFT):
		dir.x -= 1
	if Input.is_key_pressed(KEY_D) or Input.is_key_pressed(KEY_RIGHT):
		dir.x += 1
	if dir != Vector2.ZERO:
		camera.position += dir.normalized() * CAM_SPEED * delta / camera.zoom.x


func _input(event: InputEvent) -> void:
	# Zoom con rueda
	if event is InputEventMouseButton:
		var mb: InputEventMouseButton = event as InputEventMouseButton
		if mb.pressed:
			if mb.button_index == MOUSE_BUTTON_WHEEL_UP:
				camera.zoom = (camera.zoom + Vector2(CAM_ZOOM_SPEED, CAM_ZOOM_SPEED)).clamp(
						Vector2(CAM_ZOOM_MIN, CAM_ZOOM_MIN), Vector2(CAM_ZOOM_MAX, CAM_ZOOM_MAX))
			elif mb.button_index == MOUSE_BUTTON_WHEEL_DOWN:
				camera.zoom = (camera.zoom - Vector2(CAM_ZOOM_SPEED, CAM_ZOOM_SPEED)).clamp(
						Vector2(CAM_ZOOM_MIN, CAM_ZOOM_MIN), Vector2(CAM_ZOOM_MAX, CAM_ZOOM_MAX))

			# Click derecho: orden de movimiento
			elif mb.button_index == MOUSE_BUTTON_RIGHT and mb.pressed:
				var selected: Array[int] = selection_ctrl.get_selected_ids()
				if not selected.is_empty():
					var world_pos: Vector2 = camera.get_global_transform().affine_inverse() * mb.global_position
					unit_simulation.issue_move_order(selected, world_pos)
					EventBus.unit_order_issued.emit(selected, {
						"type": "move",
						"target_position": [world_pos.x, world_pos.y]
					})

	# Dibujar caja de seleccion visual
	if event is InputEventMouseButton:
		var mb: InputEventMouseButton = event as InputEventMouseButton
		if mb.button_index == MOUSE_BUTTON_LEFT:
			if mb.pressed:
				_drag_start_screen = mb.global_position
				_is_drawing_rect = false
			else:
				selection_rect.visible = false
				_is_drawing_rect = false

	if event is InputEventMouseMotion and Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT):
		var mm: InputEventMouseMotion = event as InputEventMouseMotion
		if mm.global_position.distance_to(_drag_start_screen) > 6.0:
			_is_drawing_rect = true
		if _is_drawing_rect:
			var r: Rect2 = Rect2(_drag_start_screen, Vector2.ZERO).expand(mm.global_position)
			selection_rect.global_position = r.position
			selection_rect.size = r.size
			selection_rect.visible = true


# ---------------------------------------------------------------------------
# Señales
# ---------------------------------------------------------------------------
func _on_order_issued(_unit_ids: Array[int], order_data: Dictionary) -> void:
	# Placeholder para feedback visual futuro
	pass
