class_name UnitState
extends RefCounted
## Estado puro de una unidad. Sin nodos, sin representacion visual.
## Es la fuente de verdad para posicion, vida, orden y estado de maquina.

# ---------------------------------------------------------------------------
# Constantes de estado
# ---------------------------------------------------------------------------
const STATE_IDLE: String     = "idle"
const STATE_MOVING: String   = "moving"
const STATE_ATTACKING: String= "attacking"
const STATE_CHASING: String  = "chasing"
const STATE_DEAD: String     = "dead"

# ---------------------------------------------------------------------------
# Identificadores
# ---------------------------------------------------------------------------
var unit_id: int = 0
var unit_type: String = ""
var owner_id: int = 1
signal state_changed(unit_id: int, old_state: String, new_state: String)

# ---------------------------------------------------------------------------
# Posicion y movimiento
# ---------------------------------------------------------------------------
var position: Vector2 = Vector2.ZERO
var destination: Vector2 = Vector2.ZERO
var path: Array[Vector2] = []
var path_index: int = 0

# ---------------------------------------------------------------------------
# Stats efectivos (cargados al spawn)
# ---------------------------------------------------------------------------
var health: float = 10.0
var health_max: float = 10.0
var move_speed: float = 80.0
var attack_damage: float = 10.0
var attack_range: float = 15.0
var attack_cooldown: float = 1.0
var attack_timer: float = 0.0
var armor: float = 0.0

# ---------------------------------------------------------------------------
# Estado actual
# ---------------------------------------------------------------------------
var current_state: String = STATE_IDLE
var target_unit_id: int = -1  # -1 = sin objetivo

# ---------------------------------------------------------------------------
# Orden activa (datos serializables)
# ---------------------------------------------------------------------------
var active_order: Dictionary = {}

# ---------------------------------------------------------------------------
# Liderazgo / Formacion
# ---------------------------------------------------------------------------
var leadership_capacity: int = 0
var formation_role: String = "independent"  # leader, follower, independent
var squad_id: int = -1
var formation_slot_offset: Vector2 = Vector2.ZERO


# ---------------------------------------------------------------------------
# Cambio de estado con señal
# ---------------------------------------------------------------------------
func set_state(new_state: String) -> void:
	if new_state == current_state:
		return
	var old: String = current_state
	current_state = new_state
	state_changed.emit(unit_id, old, new_state)


# ---------------------------------------------------------------------------
# Inicializacion desde datos JSON
# ---------------------------------------------------------------------------
func setup_from_data(data: Dictionary) -> void:
	unit_type = data.get("id", "unknown")
	health_max = float(data.get("health_max", 10))
	health = health_max
	move_speed = float(data.get("move_speed", 80.0))
	leadership_capacity = int(data.get("leadership_capacity", 0))

	var attack_data: Dictionary = data.get("attack", {})
	attack_damage = float(attack_data.get("damage", 5.0))
	attack_range = float(attack_data.get("range", 15.0))
	attack_cooldown = float(attack_data.get("cooldown_sec", 1.0))
	attack_timer = 0.0

	armor = float(data.get("armor", 0.0))


# ---------------------------------------------------------------------------
# Helpers
# ---------------------------------------------------------------------------
func is_alive() -> bool:
	return current_state != STATE_DEAD and health > 0.0


func has_destination() -> bool:
	return not path.is_empty() and path_index < path.size()


func get_next_waypoint() -> Vector2:
	if has_destination():
		return path[path_index]
	return position
