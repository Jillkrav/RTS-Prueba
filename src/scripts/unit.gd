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
var is_activated: bool = false

@onready var mesh: MeshInstance3D = $MeshInstance3D
@onready var health_bar: MeshInstance3D = $HealthBar

func _ready() -> void:
	var material: StandardMaterial3D = StandardMaterial3D.new()

	if team == Team.BLUE:
		material.albedo_color = Color.BLUE
		collision_layer = 1
		collision_mask = 2 | 4
		add_to_group("units_blue")
	else:
		material.albedo_color = Color.RED
		collision_layer = 2
		collision_mask = 1 | 4
		add_to_group("units_red")

	mesh.material_override = material

	if type == Type.RANGED:
		attack_range = 10.0
		attack_damage = 5.0
		mesh.scale = Vector3(0.6, 0.6, 0.6)
	else:
		mesh.scale = Vector3(1.0, 1.0, 1.0)

	input_ray_pickable = true
	update_health_bar()

func activate() -> void:
	is_activated = true

func _physics_process(delta: float) -> void:
	if health <= 0.0:
		queue_free()
		return

	if not is_on_floor():
		velocity.y -= 9.8 * delta
	else:
		velocity.y = 0.0

	if not is_activated:
		velocity.x = 0.0
		velocity.z = 0.0
		move_and_slide()
		return

	find_target()

	if target != null and is_instance_valid(target):
		var distance: float = global_position.distance_to(target.global_position)
		if distance > attack_range:
			move_to_target()
		else:
			velocity.x = 0.0
			velocity.z = 0.0
			attack_target()
	else:
		move_towards_enemy_base()

	move_and_slide()

func find_target() -> void:
	var enemies: Array = []

	if team == Team.BLUE:
		enemies.append_array(get_tree().get_nodes_in_group("units_red"))
		enemies.append_array(get_tree().get_nodes_in_group("base_red"))
	else:
		enemies.append_array(get_tree().get_nodes_in_group("units_blue"))
		enemies.append_array(get_tree().get_nodes_in_group("base_blue"))

	var closest_enemy: Node3D = null
	var min_dist: float = INF

	for enemy in enemies:
		if enemy is Node3D and is_instance_valid(enemy):
			var enemy_node: Node3D = enemy
			var dist: float = global_position.distance_to(enemy_node.global_position)
			if dist < min_dist:
				min_dist = dist
				closest_enemy = enemy_node

	target = closest_enemy

func move_to_target() -> void:
	if target == null:
		return

	var dir: Vector3 = (target.global_position - global_position).normalized()
	velocity.x = dir.x * speed
	velocity.z = dir.z * speed

func move_towards_enemy_base() -> void:
	var base_group: String = "base_red" if team == Team.BLUE else "base_blue"
	var enemy_bases: Array = get_tree().get_nodes_in_group(base_group)

	if enemy_bases.size() > 0 and enemy_bases[0] is Node3D:
		target = enemy_bases[0]
		move_to_target()

func attack_target() -> void:
	var current_time: float = Time.get_ticks_msec() / 1000.0
	if current_time - last_attack_time >= attack_speed:
		if target != null and target.has_method("take_damage"):
			target.call("take_damage", attack_damage)
		last_attack_time = current_time

func take_damage(amount: float) -> void:
	health -= amount
	update_health_bar()

	if health <= 0.0:
		queue_free()

func update_health_bar() -> void:
	if health_bar:
		var health_pct: float = clamp(health / max_health, 0.0, 1.0)
		health_bar.scale.x = health_pct

		var mat: StandardMaterial3D = StandardMaterial3D.new()
		mat.albedo_color = Color.GREEN.lerp(Color.RED, 1.0 - health_pct)
		health_bar.material_override = mat
