extends Node
## Global signal bus for decoupled communication between systems.
##
## Systems never call each other directly. They emit and listen through EventBus.
## All signals follow the pattern: signal_name(payload...)


# ---------------------------------------------------------------------------
# Unit signals
# ---------------------------------------------------------------------------
signal unit_created(unit_id: int, unit_type: String, owner_id: int)
signal unit_destroyed(unit_id: int, owner_id: int)
signal unit_state_changed(unit_id: int, old_state: String, new_state: String)
signal unit_selected(unit_ids: Array[int])
signal unit_deselected()
signal unit_order_issued(unit_ids: Array[int], order_data: Dictionary)


# ---------------------------------------------------------------------------
# Building signals
# ---------------------------------------------------------------------------
signal building_created(building_id: int, building_type: String, owner_id: int)
signal building_destroyed(building_id: int, owner_id: int)
signal building_captured(building_id: int, old_owner_id: int, new_owner_id: int)
signal building_loyalty_changed(building_id: int, loyalty: float, max_loyalty: float)
signal building_construction_started(building_id: int, building_type: String, owner_id: int)
signal building_construction_progress(building_id: int, progress: float)
signal building_construction_completed(building_id: int, owner_id: int)


# ---------------------------------------------------------------------------
# Combat signals
# ---------------------------------------------------------------------------
signal entity_attacked(attacker_id: int, target_id: int, damage: float)
signal entity_destroyed(entity_id: int, owner_id: int)
signal projectile_created(projectile_id: int, owner_id: int)
signal projectile_hit(projectile_id: int, target_id: int)


# ---------------------------------------------------------------------------
# Economy signals
# ---------------------------------------------------------------------------
signal resource_changed(player_id: int, resource_type: String, old_amount: float, new_amount: float)
signal population_changed(player_id: int, used: int, cap: int)


# ---------------------------------------------------------------------------
# Game state signals
# ---------------------------------------------------------------------------
signal game_started()
signal game_ended(winner_id: int, condition: String)
signal game_paused()
signal game_resumed()


# ---------------------------------------------------------------------------
# Squad / formation signals
# ---------------------------------------------------------------------------
signal squad_created(squad_id: int, leader_id: int)
signal squad_formation_changed(squad_id: int, formation_type: String)
signal squad_member_added(squad_id: int, unit_id: int)
signal squad_member_removed(squad_id: int, unit_id: int)


# ---------------------------------------------------------------------------
# Debug signals
# ---------------------------------------------------------------------------
signal debug_toggle(overlay_name: String, visible: bool)


# ---------------------------------------------------------------------------
# Convenience dispatchers (optional, helps tracing)
# ---------------------------------------------------------------------------
func emit_unit_created(unit_id: int, unit_type: String, owner_id: int) -> void:
	unit_created.emit(unit_id, unit_type, owner_id)


func emit_unit_destroyed(unit_id: int, owner_id: int) -> void:
	unit_destroyed.emit(unit_id, owner_id)


func emit_building_captured(building_id: int, old_owner_id: int, new_owner_id: int) -> void:
	building_captured.emit(building_id, old_owner_id, new_owner_id)


func emit_resource_changed(player_id: int, resource_type: String, old_amount: float, new_amount: float) -> void:
	resource_changed.emit(player_id, resource_type, old_amount, new_amount)


func emit_game_ended(winner_id: int, condition: String) -> void:
	game_ended.emit(winner_id, condition)