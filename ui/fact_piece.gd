extends PanelContainer
class_name FactPiece

@onready var label: Label = %Label

var text_value: String = ""

func setup(word: String) -> void:
	text_value = word
	if not is_node_ready():
		await ready
	label.text = text_value

func _get_drag_data(_at_position: Vector2) -> Variant:
	var preview = duplicate()
	preview.modulate.a = 0.6

	var preview_container = Control.new()
	preview_container.add_child(preview)
	preview.position = -size / 2
	set_drag_preview(preview_container)

	return self
