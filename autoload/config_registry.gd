extends Node
## Singleton that loads and validates all JSON data files.
##
## Exposes typed accessors for units, buildings, factions, and game rules.
## All data is loaded once at game startup and validated for required fields
## and cross-references.


# ---------------------------------------------------------------------------
# Public dataset dictionaries
# ---------------------------------------------------------------------------
var game_rules: Dictionary = {}
var units: Dictionary = {}          # keyed by unit id
var buildings: Dictionary = {}      # keyed by building id
var factions: Dictionary = {}       # keyed by faction id

var units_list: Array[Dictionary] = []
var buildings_list: Array[Dictionary] = []
var factions_list: Array[Dictionary] = []

# Internal error log
var _load_errors: Array[String] = []


# ---------------------------------------------------------------------------
# Lifecycle
# ---------------------------------------------------------------------------
func _enter_tree() -> void:
	_load_all()


# ---------------------------------------------------------------------------
# Public API
# ---------------------------------------------------------------------------
func get_unit_data(unit_id: String) -> Dictionary:
	if unit_id in units:
		return units[unit_id] as Dictionary
	push_error("ConfigRegistry: unknown unit id '%s'" % unit_id)
	return {}


func get_building_data(building_id: String) -> Dictionary:
	if building_id in buildings:
		return buildings[building_id] as Dictionary
	push_error("ConfigRegistry: unknown building id '%s'" % building_id)
	return {}


func get_faction_data(faction_id: String) -> Dictionary:
	if faction_id in factions:
		return factions[faction_id] as Dictionary
	push_error("ConfigRegistry: unknown faction id '%s'" % faction_id)
	return {}


func get_game_rules() -> Dictionary:
	return game_rules


func get_load_errors() -> Array[String]:
	return _load_errors.duplicate()


func has_load_errors() -> bool:
	return not _load_errors.is_empty()


# ---------------------------------------------------------------------------
# Loading
# ---------------------------------------------------------------------------
func _load_all() -> void:
	_load_json("data/config/game_rules.json", _on_game_rules_loaded)
	_load_json("data/units/units.json", _on_units_loaded)
	_load_json("data/buildings/buildings.json", _on_buildings_loaded)
	_load_json("data/factions/factions.json", _on_factions_loaded)

	if has_load_errors():
		for err in _load_errors:
			push_error("ConfigRegistry: %s" % err)
	else:
		print("ConfigRegistry: all data loaded successfully (%d units, %d buildings, %d factions)" \
				% [units.size(), buildings.size(), factions.size()])


func _load_json(path: String, callback: Callable) -> void:
	var file_access: FileAccess = FileAccess.open("res://" + path, FileAccess.READ)
	if not file_access:
		_load_errors.append("Cannot open '%s'" % path)
		return

	var content: String = file_access.get_as_text()
	var parsed: Variant
	parsed = JSON.parse_string(content)

	if parsed == null:
		_load_errors.append("Invalid JSON in '%s'" % path)
		return

	if not parsed is Dictionary:
		_load_errors.append("Root is not a Dictionary in '%s'" % path)
		return

	var schema_version: Variant = parsed.get("schema_version")
	if schema_version == null or not (schema_version is int or schema_version is float):
		_load_errors.append("Missing or invalid 'schema_version' in '%s'" % path)
		return

	# JSON.parse_string returns numbers as float in Godot 4
	schema_version = int(schema_version)
	parsed["schema_version"] = schema_version

	callback.call(parsed, path)


# ---------------------------------------------------------------------------
# Per-file handlers
# ---------------------------------------------------------------------------
func _on_game_rules_loaded(data: Dictionary, path: String) -> void:
	game_rules = data.duplicate()
	_validate_game_rules(path)


func _on_units_loaded(data: Dictionary, path: String) -> void:
	var raw_units: Array = data.get("units", [])
	if raw_units.is_empty():
		_load_errors.append("No units found in '%s'" % path)
		return

	for entry in raw_units:
		if not entry is Dictionary:
			_load_errors.append("Non-dictionary entry in '%s'" % path)
			continue

		var uid: String = entry.get("id", "")
		if uid.is_empty():
			_load_errors.append("Unit missing 'id' in '%s'" % path)
			continue

		_validate_unit(uid, entry, path)
		units[uid] = entry
		units_list.append(entry)

	print("ConfigRegistry: loaded %d units" % units.size())


func _on_buildings_loaded(data: Dictionary, path: String) -> void:
	var raw_buildings: Array = data.get("buildings", [])
	if raw_buildings.is_empty():
		_load_errors.append("No buildings found in '%s'" % path)
		return

	for entry in raw_buildings:
		if not entry is Dictionary:
			_load_errors.append("Non-dictionary entry in '%s'" % path)
			continue

		var bid: String = entry.get("id", "")
		if bid.is_empty():
			_load_errors.append("Building missing 'id' in '%s'" % path)
			continue

		_validate_building(bid, entry, path)
		buildings[bid] = entry
		buildings_list.append(entry)

	print("ConfigRegistry: loaded %d buildings" % buildings.size())


func _on_factions_loaded(data: Dictionary, path: String) -> void:
	var raw_factions: Array = data.get("factions", [])
	if raw_factions.is_empty():
		_load_errors.append("No factions found in '%s'" % path)
		return

	for entry in raw_factions:
		if not entry is Dictionary:
			_load_errors.append("Non-dictionary entry in '%s'" % path)
			continue

		var fid: String = entry.get("id", "")
		if fid.is_empty():
			_load_errors.append("Faction missing 'id' in '%s'" % path)
			continue

		_validate_faction(fid, entry, path)
		factions[fid] = entry
		factions_list.append(entry)

	print("ConfigRegistry: loaded %d factions" % factions.size())


# ---------------------------------------------------------------------------
# Validation helpers
# ---------------------------------------------------------------------------
func _validate_game_rules(path: String) -> void:
	_assert_field(game_rules, "starting_gold", TYPE_INT, path)
	_assert_field(game_rules, "starting_population_cap", TYPE_INT, path)
	_assert_field(game_rules, "max_population_cap", TYPE_INT, path)
	_assert_field(game_rules, "victory_condition", TYPE_STRING, path)

	var valid_victory: Array[String] = ["destroy", "capture", "either"]
	if game_rules.get("victory_condition", "") not in valid_victory:
		_load_errors.append("Invalid 'victory_condition' in '%s': must be destroy/capture/either" % path)


func _validate_unit(uid: String, entry: Dictionary, path: String) -> void:
	_assert_field(entry, "category", TYPE_STRING, path, uid)
	_assert_field(entry, "health_max", TYPE_INT, path, uid)
	_assert_field(entry, "move_speed", TYPE_FLOAT, path, uid)
	_assert_field(entry, "cost", TYPE_DICTIONARY, path, uid)
	if entry.get("health_max", 0) <= 0:
		_load_errors.append("Unit '%s' has health_max <= 0 in '%s'" % [uid, path])


func _validate_building(bid: String, entry: Dictionary, path: String) -> void:
	_assert_field(entry, "health_max", TYPE_INT, path, bid)
	_assert_field(entry, "loyalty_max", TYPE_INT, path, bid)
	_assert_field(entry, "cost", TYPE_DICTIONARY, path, bid)
	if entry.get("health_max", 0) <= 0:
		_load_errors.append("Building '%s' has health_max <= 0 in '%s'" % [bid, path])


func _validate_faction(fid: String, entry: Dictionary, path: String) -> void:
	_assert_field(entry, "unit_modifiers", TYPE_DICTIONARY, path, fid)


func _assert_field(data: Dictionary, field: String, expected_type: int, path: String, id: String = "") -> void:
	var prefix: String = ""
	if not id.is_empty():
		prefix = "'%s' " % id

	if not data.has(field):
		_load_errors.append("%sMissing field '%s' in '%s'" % [prefix, field, path])
		return

	var value: Variant = data[field]
	var actual_type: int = typeof(value)
	
	# JSON.parse_string returns all numbers as float in Godot 4.
	# Accept float when int is expected (and vice versa).
	var is_type_ok: bool = actual_type == expected_type
	if not is_type_ok:
		if expected_type == TYPE_INT and actual_type == TYPE_FLOAT:
			is_type_ok = true
		elif expected_type == TYPE_FLOAT and actual_type == TYPE_INT:
			is_type_ok = true
	
	if not is_type_ok:
		_load_errors.append("%sField '%s' expected type %d but got %d in '%s'" \
				% [prefix, field, expected_type, actual_type, path])