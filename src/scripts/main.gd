extends Node3D

@onready var base_blue: Base = $BaseBlue
@onready var base_red: Base = $BaseRed

@onready var blue_melee_btn: Button = $HUD/Control/BlueControls/MeleeBtn
@onready var blue_ranged_btn: Button = $HUD/Control/BlueControls/RangedBtn

@onready var red_melee_btn: Button = $HUD/Control/RedControls/MeleeBtn
@onready var red_ranged_btn: Button = $HUD/Control/RedControls/RangedBtn

func _ready() -> void:
	blue_melee_btn.pressed.connect(base_blue.spawn_melee)
	blue_ranged_btn.pressed.connect(base_blue.spawn_ranged)
	
	red_melee_btn.pressed.connect(base_red.spawn_melee)
	red_ranged_btn.pressed.connect(base_red.spawn_ranged)
