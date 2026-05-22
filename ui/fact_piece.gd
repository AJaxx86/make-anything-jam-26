extends PanelContainer
class_name FactPiece

@onready var label: Label = %Label

var text_value: String = ""

enum STATE {DEFAULT, CORRECT_POSITION, WRONG_POSITION, INCORRECT}


func setup(word: String) -> void:
	text_value = word
	if not is_node_ready():
		await ready
	label.text = text_value.rstrip(".")
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
