class_name UnitView
extends Node2D
## Representacion visual de una unidad.
## Lee el UnitState y dibuja la forma/color correspondiente.
## No toma decisiones de IA ni modifica el estado.

# Figura segun estado
const SHAPE_IDLE: String     = "square"    # cuadrado
const SHAPE_MOVING: String   = "circle"    # circulo
const SHAPE_ATTACK: String   = "triangle"  # triangulo

# Tamaño visual
const BASE_SIZE: float = 10.0
const SELECTED_RING_SIZE: float = 2.5
const HP_BAR_W: float = 20.0
const HP_BAR_H: float = 3.0
const HP_BAR_OFFSET_Y: float = -14.0

var state: UnitState = null
var is_selected: bool = false

# Debug
var show_id: bool = false
var show_state: bool = false
var _font: Font = null


func _ready() -> void:
	_font = ThemeDB.fallback_font
	set_process(true)


func _process(_delta: float) -> void:
	if state != null:
		global_position = state.position
		queue_redraw()


func _draw() -> void:
	if state == null:
		return

	var team_color: Color = GameSession.get_team_color(state.owner_id)
	var shape: String = _get_shape_for_state()

	# Dibuja la forma
	_draw_shape(shape, BASE_SIZE, team_color)

	# Anillo de seleccion
	if is_selected:
		draw_arc(Vector2.ZERO, BASE_SIZE + SELECTED_RING_SIZE, 0.0, TAU, 16, Color.WHITE, 1.5)

	# Barra de vida
	_draw_health_bar()

	# Debug texto
	if show_id or show_state:
		_draw_debug_text(team_color)


func _draw_shape(shape: String, size: float, color: Color) -> void:
	match shape:
		"circle":
			draw_circle(Vector2.ZERO, size, color)
		"triangle":
			var pts: PackedVector2Array = PackedVector2Array([
				Vector2(0, -size),
				Vector2(size * 0.866, size * 0.5),
				Vector2(-size * 0.866, size * 0.5)
			])
			draw_colored_polygon(pts, color)
		_:  # square / default
			draw_rect(Rect2(-size, -size, size * 2, size * 2), color)


func _draw_health_bar() -> void:
	if state.health_max <= 0.0:
		return
	var ratio: float = clamp(state.health / state.health_max, 0.0, 1.0)
	var bar_pos: Vector2 = Vector2(-HP_BAR_W * 0.5, HP_BAR_OFFSET_Y)

	# Fondo gris
	draw_rect(Rect2(bar_pos, Vector2(HP_BAR_W, HP_BAR_H)), Color(0.3, 0.3, 0.3, 0.8))
	# Vida
	if ratio > 0.0:
		var hp_color: Color = Color.GREEN if ratio > 0.5 else (Color.YELLOW if ratio > 0.25 else Color.RED)
		draw_rect(Rect2(bar_pos, Vector2(HP_BAR_W * ratio, HP_BAR_H)), hp_color)


func _draw_debug_text(color: Color) -> void:
	var txt: String = ""
	if show_id:
		txt += "#%d " % state.unit_id
	if show_state:
		txt += state.current_state
	if not txt.is_empty() and _font != null:
		draw_string(_font, Vector2(-HP_BAR_W * 0.5, HP_BAR_OFFSET_Y - 6), txt,
				HORIZONTAL_ALIGNMENT_LEFT, -1, 10, color)


func _get_shape_for_state() -> String:
	if state == null:
		return SHAPE_IDLE
	match state.current_state:
		UnitState.STATE_MOVING:
			return SHAPE_MOVING
		UnitState.STATE_ATTACKING, UnitState.STATE_CHASING:
			return SHAPE_ATTACK
		_:
			return SHAPE_IDLE
