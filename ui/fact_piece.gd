extends PanelContainer
class_name FactPiece

# Assuming you have a Label child to display the word
@onready var label: Label = %Label

var text_value: String = ""

func setup(word: String) -> void:
	text_value = word
	if not is_node_ready():
		await ready
	label.text = text_value

# Phase 1: Engine calls this when the user clicks and drags the node
func _get_drag_data(_at_position: Vector2) -> Variant:
	# Create the visual preview attached to the mouse pointer
	var preview = duplicate()
	preview.modulate.a = 0.6 # Make it semi-transparent

	# Center the preview on the mouse cursor
	var preview_container = Control.new()
	preview_container.add_child(preview)
	preview.position = -size / 2
	set_drag_preview(preview_container)

	# Return this exact node as the data payload
	return self
