class_name Spawner
extends Node
## Crea unidades en posiciones de spawn para pruebas y partidas.

var unit_pool: UnitPool = null


# ---------------------------------------------------------------------------
# Spawn de prueba: N unidades por equipo alrededor de un punto
# ---------------------------------------------------------------------------
func spawn_test_units(count_per_team: int, spawn_positions: Array[Vector2],
		unit_types: Array[String] = ["swordsman", "archer"]) -> void:
	if unit_pool == null:
		push_error("Spawner: unit_pool no asignado")
		return

	for team_idx in range(spawn_positions.size()):
		var center: Vector2 = spawn_positions[team_idx]
		var owner_id: int = team_idx + 1

		for i in range(count_per_team):
			var cols: int = max(1, int(sqrt(float(count_per_team))))
			var row: int = i / cols
			var col: int = i % cols
			var offset: Vector2 = Vector2(col * 20.0 - (cols * 10.0), row * 20.0)
			var pos: Vector2 = center + offset

			var unit_type: String = unit_types[i % unit_types.size()]
			unit_pool.acquire(unit_type, owner_id, pos)


# ---------------------------------------------------------------------------
# Spawn de una unidad individual
# ---------------------------------------------------------------------------
func spawn_unit(unit_type: String, owner_id: int, position: Vector2) -> UnitState:
	if unit_pool == null:
		push_error("Spawner: unit_pool no asignado")
		return null
	return unit_pool.acquire(unit_type, owner_id, position)
