extends Node3D

@onready var base_blue = $BaseBlue
@onready var base_red = $BaseRed
@onready var blue_melee_btn: Button = $HUD/Control/BlueControls/MeleeBtn
@onready var blue_ranged_btn: Button = $HUD/Control/BlueControls/RangedBtn
@onready var red_melee_btn: Button = $HUD/Control/RedControls/MeleeBtn
@onready var red_ranged_btn: Button = $HUD/Control/RedControls/RangedBtn
@onready var camera: Camera3D = $Camera3D

# Zoom
var zoom_speed: float = 2.0
var zoom_min: float = 5.0
var zoom_max: float = 30.0

# Movimiento WASD
var move_speed: float = 10.0
var sprint_multiplier: float = 3.0

# Rotación con mouse
var rotate_speed: float = 0.005
var is_rotating: bool = false

func _ready() -> void:
	blue_melee_btn.pressed.connect(base_blue.spawn_melee)
	blue_ranged_btn.pressed.connect(base_blue.spawn_ranged)
	red_melee_btn.pressed.connect(base_red.spawn_melee)
	red_ranged_btn.pressed.connect(base_red.spawn_ranged)

func _input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		var mouse_event: InputEventMouseButton = event
		match mouse_event.button_index:
			MOUSE_BUTTON_LEFT:
				if mouse_event.pressed:
					select_unit_from_mouse(mouse_event.position)
			MOUSE_BUTTON_WHEEL_UP:
				if mouse_event.pressed:
					_zoom_camera(-zoom_speed)
			MOUSE_BUTTON_WHEEL_DOWN:
				if mouse_event.pressed:
					_zoom_camera(zoom_speed)
			MOUSE_BUTTON_MIDDLE:
				is_rotating = mouse_event.pressed

	if event is InputEventMouseMotion and is_rotating:
		var motion: InputEventMouseMotion = event
		camera.rotate_y(-motion.relative.x * rotate_speed)

func _process(delta: float) -> void:
	_handle_movement(delta)

func _handle_movement(delta: float) -> void:
	var direction := Vector3.ZERO

	var forward := -camera.global_transform.basis.z
	forward.y = 0.0
	forward = forward.normalized()

	var right := camera.global_transform.basis.x
	right.y = 0.0
	right = right.normalized()

	if Input.is_key_pressed(KEY_W):
		direction += forward
	if Input.is_key_pressed(KEY_S):
		direction -= forward
	if Input.is_key_pressed(KEY_A):
		direction -= right
	if Input.is_key_pressed(KEY_D):
		direction += right

	if direction != Vector3.ZERO:
		var speed := move_speed
		if Input.is_key_pressed(KEY_SHIFT):
			speed *= sprint_multiplier
		camera.global_position += direction.normalized() * speed * delta

func _zoom_camera(delta: float) -> void:
	var forward: Vector3 = -camera.global_transform.basis.z.normalized()
	var new_pos: Vector3 = camera.global_position + forward * delta
	var dist: float = new_pos.y
	if dist < zoom_min or dist > zoom_max:
		return
	camera.global_position = new_pos

func select_unit_from_mouse(mouse_position: Vector2) -> void:
	var from: Vector3 = camera.project_ray_origin(mouse_position)
	var to: Vector3 = from + camera.project_ray_normal(mouse_position) * 1000.0

	var query: PhysicsRayQueryParameters3D = PhysicsRayQueryParameters3D.create(from, to)
	var space_state: PhysicsDirectSpaceState3D = get_world_3d().direct_space_state
	var result: Dictionary = space_state.intersect_ray(query)

	if result.is_empty():
		return

	var collider: Object = result["collider"]

	if collider is Unit:
		var unit: Unit = collider
		unit.activate()
