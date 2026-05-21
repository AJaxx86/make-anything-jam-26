extends Control
class_name FactSentenceDropOverlay

const INDICATOR_WIDTH := 4.0

var _hover_insert_index: int = -1
var _hover_line_x: float = 0.0
var _hover_line_top: float = 0.0
var _hover_line_bottom: float = 0.0


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE


func set_hover(insert_index: int, line_x: float, top: float, bottom: float) -> void:
	_hover_insert_index = insert_index
	_hover_line_x = line_x
	_hover_line_top = top
	_hover_line_bottom = bottom
	queue_redraw()


func clear_hover() -> void:
	_hover_insert_index = -1
	_hover_line_x = 0.0
	_hover_line_top = 0.0
	_hover_line_bottom = 0.0
	queue_redraw()


func _draw() -> void:
	if _hover_insert_index == -1:
		return

	var color := Color.WHITE
	var half_width := INDICATOR_WIDTH * 0.5
	draw_rect(
		Rect2(
			Vector2(_hover_line_x - half_width, _hover_line_top),
			Vector2(INDICATOR_WIDTH, _hover_line_bottom - _hover_line_top)
		),
		color
	)
