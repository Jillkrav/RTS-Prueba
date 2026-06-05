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

@onready var mesh: MeshInstance3D = $MeshInstance3D
@onready var health_bar: MeshInstance3D = $HealthBar

func _ready() -> void:
	# Set colors and collision layers based on team
	var material: StandardMaterial3D = StandardMaterial3D.new()
	if team == Team.BLUE:
		material.albedo_color = Color.BLUE
		collision_layer = 1 # Blue team layer
		collision_mask = 2 | 4 # Mask Red team (2) and Environment (4)
	else:
		material.albedo_color = Color.RED
		collision_layer = 2 # Red team layer
		collision_mask = 1 | 4 # Mask Blue team (1) and Environment (4)
	
	mesh.material_override = material
	
	if type == Type.RANGED:
		attack_range = 10.0
		attack_damage = 5.0
		mesh.scale = Vector3(0.6, 0.6, 0.6) # Scale it down
	else:
		mesh.scale = Vector3(1.0, 1.0, 1.0)
	
	update_health_bar()

func _physics_process(delta: float) -> void:
	if health <= 0:
		queue_free()
		return

	# Add gravity
	if not is_on_floor():
		velocity.y -= 9.8 * delta
	else:
		velocity.y = 0

	find_target()
	
	if target and is_instance_valid(target):
		var distance = global_position.distance_to(target.global_position)
		if distance > attack_range:
			move_to_target(delta)
		else:
			velocity.x = 0
			velocity.z = 0
			attack_target()
	else:
		move_towards_enemy_base(delta)
	
	move_and_slide()

func find_target() -> void:
	# Simple targeting: find nearest enemy unit or base
	var enemies = get_tree().get_nodes_in_group("units_" + ("red" if team == Team.BLUE else "blue"))
	enemies.append_array(get_tree().get_nodes_in_group("base_" + ("red" if team == Team.BLUE else "blue")))
	
	var closest_enemy: Node3D = null
	var min_dist = INF
	
	for enemy in enemies:
		if is_instance_valid(enemy):
			var dist = global_position.distance_to(enemy.global_position)
			if dist < min_dist:
				min_dist = dist
				closest_enemy = enemy
	
	target = closest_enemy

func move_to_target(_delta: float) -> void:
	if not target: return
	var dir = (target.global_position - global_position).normalized()
	velocity = dir * speed
	move_and_slide()

func move_towards_enemy_base(delta: float) -> void:
	# This will be refined in subclasses or based on scene layout
	var base_group = "base_" + ("red" if team == Team.BLUE else "blue")
	var enemy_bases = get_tree().get_nodes_in_group(base_group)
	if enemy_bases.size() > 0:
		target = enemy_bases[0]
		move_to_target(delta)

func attack_target() -> void:
	var current_time = Time.get_ticks_msec() / 1000.0
	if current_time - last_attack_time >= attack_speed:
		if target.has_method("take_damage"):
			target.take_damage(attack_damage)
			last_attack_time = current_time

func take_damage(amount: float) -> void:
	health -= amount
	update_health_bar()
	if health <= 0:
		queue_free()

func update_health_bar() -> void:
	if health_bar:
		var health_pct = clamp(health / max_health, 0.0, 1.0)
		health_bar.scale.x = health_pct
		# Color health bar
		var mat = StandardMaterial3D.new()
		mat.albedo_color = Color.GREEN.lerp(Color.RED, 1.0 - health_pct)
		health_bar.material_override = mat
