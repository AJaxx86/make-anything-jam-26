extends PanelContainer
class_name FactPiece

@onready var label: Label = %Label

var text_value: String = ""
var _base_font_size: int = 0

enum STATE {DEFAULT, CORRECT_POSITION, WRONG_POSITION, INCORRECT}


func _ready() -> void:
	var current_theme_font_size := label.get_theme_font_size("font_size")
	if current_theme_font_size > 0:
		_base_font_size = roundi(current_theme_font_size * float(Global.default_font_size) / Global.current_font_size)
	else:
		_base_font_size = Global.default_font_size
	if not Global.font_changed.is_connected(_on_global_font_changed):
		Global.font_changed.connect(_on_global_font_changed)
	_apply_font(Global.current_font, Global.current_font_size)


func setup(word: String) -> void:
	text_value = word
	if not is_node_ready():
		await ready
	label.text = text_value.rstrip(".")
	_update_size_for_font()
	set_feedback_colour(STATE.DEFAULT)


func flash() -> void:
	var tween: Tween = create_tween()
	tween.set_trans(Tween.TRANS_BACK)
	tween.set_ease(Tween.EASE_OUT)
	tween.tween_property(self, "scale", Vector2(1.15, 1.15), 0.15)
	tween.chain().tween_property(self, "scale", Vector2.ONE, 0.25)


func set_feedback_colour(state: int) -> void:
	match state:
		STATE.DEFAULT:
			modulate = Color.WHITE
		STATE.CORRECT_POSITION:
			modulate = Color.GREEN
		STATE.WRONG_POSITION:
			modulate = Color.YELLOW
		STATE.INCORRECT:
			modulate = Color.RED
		_:
			push_warning("Invalid state: %s" % state)


func _get_drag_data(_at_position: Vector2) -> Variant:
	var preview = duplicate()
	preview.modulate.a = 0.6

	var preview_container = Control.new()
	preview_container.add_child(preview)
	preview.position = -size / 2
	set_drag_preview(preview_container)

	return self


func _can_drop_data(at_position: Vector2, data: Variant) -> bool:
	if not data is FactPiece:
		return false

	var local_drop_pos: Vector2 = position + at_position
	var parent_node: Node = get_parent()
	if parent_node is FreeFactArea:
		return (parent_node as FreeFactArea).can_drop_at_local(local_drop_pos)
	if parent_node is FactContainer:
		return true
	if parent_node is FactSentenceContainer:
		(parent_node as FactSentenceContainer).update_drop_hover(local_drop_pos, data as FactPiece)
		return true
	return false


func _drop_data(at_position: Vector2, data: Variant) -> void:
	if not data is FactPiece:
		return

	var local_drop_pos: Vector2 = position + at_position
	var parent_node: Node = get_parent()
	if parent_node is FreeFactArea:
		(parent_node as FreeFactArea).drop_piece_at_position(data as FactPiece, local_drop_pos)
	elif parent_node is FactContainer:
		(parent_node as FactContainer).drop_piece_at_position(data as FactPiece, local_drop_pos)
	elif parent_node is FactSentenceContainer:
		(parent_node as FactSentenceContainer).drop_piece_at_position(data as FactPiece, local_drop_pos)


func _on_global_font_changed(font: FontFile, font_size: int) -> void:
	_apply_font(font, font_size)


func _apply_font(font: FontFile, font_size: int) -> void:
	label.add_theme_font_override("font", font)
	label.add_theme_font_size_override("font_size", roundi(_base_font_size * float(font_size) / Global.default_font_size))
	_update_size_for_font()


func _update_size_for_font() -> void:
	await get_tree().process_frame
	if not is_inside_tree():
		return
	reset_size()
	minimum_size_changed.emit()
	var parent_node: Node = get_parent()
	if parent_node is FreeFactArea:
		(parent_node as FreeFactArea).call_deferred("_arrange_fact_pieces")
	elif parent_node is FactSentenceContainer:
		(parent_node as FactSentenceContainer).call_deferred("_update_layout_minimum_height")
