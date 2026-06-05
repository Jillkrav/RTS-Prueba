extends StaticBody3D

class_name Base

@export var team: Unit.Team = Unit.Team.BLUE
@export var health: float = 500.0
@export var max_health: float = 500.0

@onready var spawn_point: Marker3D = $SpawnPoint
@onready var health_bar: MeshInstance3D = $HealthBar

var unit_scene: PackedScene = preload("res://src/scenes/unit.tscn")

func _ready() -> void:
	add_to_group("base_" + ("blue" if team == Unit.Team.BLUE else "red"))
	
	var material: StandardMaterial3D = StandardMaterial3D.new()
	material.albedo_color = Color.BLUE if team == Unit.Team.BLUE else Color.RED
	$MeshInstance3D.material_override = material
	
	# Set collision layers
	if team == Unit.Team.BLUE:
		collision_layer = 1
	else:
		collision_layer = 2
		
	update_health_bar()

func spawn_melee() -> void:
	spawn_unit(Unit.Type.MELEE)

func spawn_ranged() -> void:
	spawn_unit(Unit.Type.RANGED)

func spawn_unit(type: Unit.Type) -> void:
	var unit = unit_scene.instantiate()
	unit.team = team
	unit.type = type
	get_parent().add_child(unit)
	unit.global_position = spawn_point.global_position
	unit.add_to_group("units_" + ("blue" if team == Unit.Team.BLUE else "red"))

func take_damage(amount: float) -> void:
	health -= amount
	update_health_bar()
	if health <= 0:
		# Game over logic could go here
		queue_free()

func update_health_bar() -> void:
	if health_bar:
		var health_pct = clamp(health / max_health, 0.0, 1.0)
		health_bar.scale.x = health_pct * 5.0 # Bases are wider
		var mat = StandardMaterial3D.new()
		mat.albedo_color = Color.GREEN.lerp(Color.RED, 1.0 - health_pct)
		health_bar.material_override = mat
