class_name GameSession
extends Node
## Singleton que mantiene el estado global de la partida en curso.
## Almacena jugadores, sus recursos y estado general del juego.

# ---------------------------------------------------------------------------
# Constantes
# ---------------------------------------------------------------------------
const TEAM_COLORS: Array[Color] = [
	Color(0.2, 0.5, 1.0),   # Equipo 1: Azul
	Color(1.0, 0.3, 0.2),   # Equipo 2: Rojo
	Color(0.2, 0.85, 0.3),  # Equipo 3: Verde
	Color(1.0, 0.85, 0.1),  # Equipo 4: Amarillo
]

# ---------------------------------------------------------------------------
# Estado de partida
# ---------------------------------------------------------------------------
var is_running: bool = false
var tick: int = 0

# player_states[player_id] = { gold, population_used, population_cap, faction_id }
var player_states: Dictionary = {}

# ---------------------------------------------------------------------------
# Lifecycle
# ---------------------------------------------------------------------------
func _enter_tree() -> void:
	set_process(false)


# ---------------------------------------------------------------------------
# Inicializar partida
# ---------------------------------------------------------------------------
func start_session(player_count: int) -> void:
	player_states.clear()
	tick = 0
	is_running = true

	var rules: Dictionary = ConfigRegistry.get_game_rules()
	var starting_gold: int = rules.get("starting_gold", 100)
	var starting_pop_cap: int = rules.get("starting_population_cap", 5)

	for i in range(player_count):
		player_states[i + 1] = {
			"gold": starting_gold,
			"population_used": 0,
			"population_cap": starting_pop_cap,
			"faction_id": "faction_a"
		}

	set_process(true)
	EventBus.game_started.emit()


func stop_session() -> void:
	is_running = false
	set_process(false)


# ---------------------------------------------------------------------------
# Recursos
# ---------------------------------------------------------------------------
func get_gold(player_id: int) -> int:
	if player_id not in player_states:
		return 0
	return player_states[player_id].get("gold", 0)


func get_population(player_id: int) -> Array[int]:
	if player_id not in player_states:
		return [0, 0]
	var ps: Dictionary = player_states[player_id]
	return [ps.get("population_used", 0), ps.get("population_cap", 0)]


func get_team_color(player_id: int) -> Color:
	var idx: int = clamp(player_id - 1, 0, TEAM_COLORS.size() - 1)
	return TEAM_COLORS[idx]
