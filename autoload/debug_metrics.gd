class_name DebugMetrics
extends CanvasLayer
## Debug overlay showing FPS, entity counts, and simulation time.
##
## Toggle with F3 key. Extensible for future debug overlays
## as defined in section 13 of the plan maestro.


# ---------------------------------------------------------------------------
# Configuration
# ---------------------------------------------------------------------------
const TOGGLE_KEY: Key = Key.KEY_F3
const UPDATE_INTERVAL: float = 0.25  # seconds between refresh

# Colors
const COLOR_BG: Color = Color(0.0, 0.0, 0.0, 0.6)
const COLOR_TEXT: Color = Color(0.2, 1.0, 0.2)
const COLOR_WARN: Color = Color(1.0, 0.8, 0.0)
const COLOR_ERROR: Color = Color(1.0, 0.2, 0.2)
const BORDER_PADDING: float = 8.0
const LINE_HEIGHT: float = 16.0
const FONT_SIZE: int = 13


# ---------------------------------------------------------------------------
# State
# ---------------------------------------------------------------------------
var visible_overlay: bool = true
var _time_accum: float = 0.0
var _fps_values: Array[float] = []
var _fps_average: float = 0.0

# Counters (populated externally via setters)
var active_unit_count: int = 0
var active_building_count: int = 0
var pooled_unit_count: int = 0

# Internal
var _font: Font = null
var _lines: Array[String] = []


# ---------------------------------------------------------------------------
# Lifecycle
# ---------------------------------------------------------------------------
func _enter_tree() -> void:
	layer = 128  # high layer, on top of everything
	visible_overlay = true
	name = "DebugMetrics"
	set_process(true)
	set_process_input(true)


func _ready() -> void:
	_font = ThemeDB.fallback_font
	pass


func _input(event: InputEvent) -> void:
	if event is InputEventKey and event.keycode == TOGGLE_KEY and event.pressed and not event.echo:
		visible_overlay = not visible_overlay
		EventBus.debug_toggle.emit("metrics", visible_overlay)
		queue_redraw()


func _process(delta: float) -> void:
	if not visible_overlay:
		return

	_time_accum += delta

	# Track FPS
	var fps: float = Performance.get_monitor(Performance.TIME_FPS)
	_fps_values.append(fps)
	if _fps_values.size() > 60:
		_fps_values.pop_front()

	# Refresh text at interval
	if _time_accum >= UPDATE_INTERVAL:
		_time_accum = 0.0
		_refresh_lines()
		queue_redraw()


# ---------------------------------------------------------------------------
# Drawing
# ---------------------------------------------------------------------------
func _draw() -> void:
	if not visible_overlay:
		return

	if _font == null:
		_font = ThemeDB.fallback_font

	var text_width: float = 0.0
	for line in _lines:
		var line_w: float = _font.get_string_size(line, HORIZONTAL_ALIGNMENT_LEFT, -1, FONT_SIZE).x
		if line_w > text_width:
			text_width = line_w

	var panel_w: float = text_width + BORDER_PADDING * 2
	var panel_h: float = _lines.size() * LINE_HEIGHT + BORDER_PADDING * 2

	# Background
	draw_rect(Rect2(0, 0, panel_w, panel_h), COLOR_BG)

	# Lines
	var y: float = BORDER_PADDING + LINE_HEIGHT * 0.7
	for line in _lines:
		var color: Color = COLOR_TEXT
		if line.contains("WARN"):
			color = COLOR_WARN
		elif line.contains("ERR"):
			color = COLOR_ERROR
		draw_string(_font, Vector2(BORDER_PADDING, y), line, HORIZONTAL_ALIGNMENT_LEFT, -1, FONT_SIZE, color)
		y += LINE_HEIGHT


func _refresh_lines() -> void:
	_fps_average = 0.0
	if not _fps_values.is_empty():
		for v in _fps_values:
			_fps_average += v
		_fps_average /= _fps_values.size()
	else:
		_fps_average = Performance.get_monitor(Performance.TIME_FPS)

	var fps_display: float = snapped(_fps_average, 0.1)
	var fps_color_str: String = " OK " if fps_display >= 55.0 else ("WARN" if fps_display >= 30.0 else "ERR ")

	_lines.clear()
	_lines.append("[FPS] %s  %.1f" % [fps_color_str, fps_display])
	_lines.append(" units: %d active  |  %d pooled" % [active_unit_count, pooled_unit_count])
	_lines.append(" build: %d active" % active_building_count)

	# Memory info
	var mem: float = Performance.get_monitor(Performance.MEMORY_STATIC)
	_lines.append(" mem:  %.1f MB" % (mem / (1024.0 * 1024.0)))

	# Node count
	var nodes: int = Performance.get_monitor(Performance.OBJECT_NODE_COUNT)
	_lines.append(" nodes: %d" % nodes)

	_lines.append("--- [F3 toggle]")


# ---------------------------------------------------------------------------
# Public setters (called from other systems)
# ---------------------------------------------------------------------------
func set_unit_counts(active: int, pooled: int) -> void:
	active_unit_count = active
	pooled_unit_count = pooled


func set_building_count(count: int) -> void:
	active_building_count = count