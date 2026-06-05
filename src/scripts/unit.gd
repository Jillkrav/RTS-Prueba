extends CharacterBody3D
class_name Unit

enum Team { BLUE, RED }
enum Type { MELEE, RANGED }

@export var team: Team = Team.BLUE
@export var type: Type = Type.MELEE
@export var health: float = 100.0
@export var max_health: float = 100.0
@export var speed: float = 5.0
@export var attack_range: float = 1.5
@export var attack_damage: float = 10.0
@export var attack_speed: float = 1.0

var target: Node3D = null
var last_attack_time: float = 0.0

# Control manual del jugador
var is_selected: bool = false
var manual_target_pos: Vector3 = Vector3.ZERO
var has_manual_target: bool = false
var is_manual_mode: bool = true
var manual_attack_target: Node3D = null
var base_color: Color = Color.BLUE

var selection_indicator: MeshInstance3D = null

@onready var mesh: MeshInstance3D = $MeshInstance3D
@onready var health_bar: MeshInstance3D = $HealthBar

func _ready() -> void:
	if team == Team.BLUE:
		base_color = Color.BLUE
		collision_layer = 1
		collision_mask = 2 | 4
		add_to_group("units_blue")
	else:
		base_color = Color.RED
		collision_layer = 2
		collision_mask = 1 | 4
		add_to_group("units_red")

	var material: StandardMaterial3D = StandardMaterial3D.new()
	material.albedo_color = base_color
	mesh.material_override = material

	if type == Type.RANGED:
		attack_range = 10.0
		attack_damage = 5.0
		mesh.scale = Vector3(0.6, 0.6, 0.6)
	else:
		mesh.scale = Vector3(1.0, 1.0, 1.0)

	input_ray_pickable = true
	update_health_bar()
	_create_selection_indicator()

func _create_selection_indicator() -> void:
	selection_indicator = MeshInstance3D.new()
	var circle_mesh = CylinderMesh.new()
	circle_mesh.top_radius = 0.7
	circle_mesh.bottom_radius = 0.7
	circle_mesh.height = 0.05
	selection_indicator.mesh = circle_mesh

	var mat = StandardMaterial3D.new()
	mat.albedo_color = Color(0.0, 1.0, 0.2, 0.8)
	mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	selection_indicator.material_override = mat
	selection_indicator.position.y = -0.47
	selection_indicator.visible = false
	add_child(selection_indicator)

func select() -> void:
	is_selected = true
	if selection_indicator:
		selection_indicator.visible = true
	var mat: StandardMaterial3D = StandardMaterial3D.new()
	mat.albedo_color = base_color
	mat.emission_enabled = true
	mat.emission = base_color
	mat.emission_energy_multiplier = 2.5
	mesh.material_override = mat

func deselect() -> void:
	is_selected = false
	if selection_indicator:
		selection_indicator.visible = false
	var mat: StandardMaterial3D = StandardMaterial3D.new()
	mat.albedo_color = base_color
	mesh.material_override = mat

func move_to_position(pos: Vector3) -> void:
	is_manual_mode = true
	has_manual_target = true
	manual_target_pos = pos
	manual_attack_target = null
	target = null

func order_attack(enemy: Node3D) -> void:
	is_manual_mode = true
	has_manual_target = false
	manual_attack_target = enemy
	target = enemy

func _physics_process(delta: float) -> void:
	if health <= 0.0:
		queue_free()
		return

	if not is_on_floor():
		velocity.y -= 9.8 * delta
	else:
		velocity.y = 0.0

	_handle_manual_mode()
	move_and_slide()

func _handle_manual_mode() -> void:
	# Mover a posición indicada
	if has_manual_target:
		var dist: float = global_position.distance_to(manual_target_pos)
		if dist > 0.5:
			var dir: Vector3 = (manual_target_pos - global_position).normalized()
			velocity.x = dir.x * speed
			velocity.z = dir.z * speed
		else:
			velocity.x = 0.0
			velocity.z = 0.0
			has_manual_target = false
		return

	# Atacar objetivo indicado (orden del jugador o autodefensa)
	if manual_attack_target != null and is_instance_valid(manual_attack_target):
		target = manual_attack_target
		var distance: float = global_position.distance_to(target.global_position)
		if distance > attack_range:
			var dir: Vector3 = (target.global_position - global_position).normalized()
			velocity.x = dir.x * speed
			velocity.z = dir.z * speed
		else:
			velocity.x = 0.0
			velocity.z = 0.0
			attack_target()
	else:
		# Sin órdenes ni amenaza: quieta
		manual_attack_target = null
		target = null
		velocity.x = 0.0
		velocity.z = 0.0

func attack_target() -> void:
	var current_time: float = Time.get_ticks_msec() / 1000.0
	if current_time - last_attack_time >= attack_speed:
		if target != null and target.has_method("take_damage"):
			target.call("take_damage", attack_damage, self)
		last_attack_time = current_time

func take_damage(amount: float, attacker: Node3D = null) -> void:
	health -= amount
	update_health_bar()

	# Autodefensa: si no tiene órdenes activas y hay un agresor válido, contraataca
	if attacker != null and is_instance_valid(attacker):
		if not has_manual_target and manual_attack_target == null:
			manual_attack_target = attacker

	if health <= 0.0:
		queue_free()

func update_health_bar() -> void:
	if health_bar:
		var health_pct: float = clamp(health / max_health, 0.0, 1.0)
		health_bar.scale.x = health_pct
		var mat: StandardMaterial3D = StandardMaterial3D.new()
		mat.albedo_color = Color.GREEN.lerp(Color.RED, 1.0 - health_pct)
		health_bar.material_override = mat
