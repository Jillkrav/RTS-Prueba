extends Node3D

@onready var base_blue = $BaseBlue
@onready var base_red = $BaseRed
@onready var blue_melee_btn: Button = $HUD/Control/BlueControls/MeleeBtn
@onready var blue_ranged_btn: Button = $HUD/Control/BlueControls/RangedBtn
@onready var red_melee_btn: Button = $HUD/Control/RedControls/MeleeBtn
@onready var red_ranged_btn: Button = $HUD/Control/RedControls/RangedBtn
@onready var camera: Camera3D = $Camera3D

func _ready() -> void:
	blue_melee_btn.pressed.connect(base_blue.spawn_melee)
	blue_ranged_btn.pressed.connect(base_blue.spawn_ranged)
	red_melee_btn.pressed.connect(base_red.spawn_melee)
	red_ranged_btn.pressed.connect(base_red.spawn_ranged)

func _input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		var mouse_event: InputEventMouseButton = event
		if mouse_event.pressed and mouse_event.button_index == MOUSE_BUTTON_LEFT:
			select_unit_from_mouse(mouse_event.position)

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
