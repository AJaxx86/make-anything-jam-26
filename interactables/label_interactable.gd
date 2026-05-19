class_name LabelInteractable extends Interactable

@onready var label_3d: Label3D = $Label3D

@export var max_length: int = 13

var is_editing: bool = false
var _original_text: String = ""
var _edit_text: String = ""
var _cursor_visible: bool = false
var _cursor_timer: float = 0.0


func _process(delta: float) -> void:
	if not is_editing:
		return

	_cursor_timer += delta
	if _cursor_timer >= 0.5:
		_cursor_timer -= 0.5
		_cursor_visible = not _cursor_visible
		_update_display_text()

func start_editing() -> void:
	if is_editing:
		return
	is_editing = true
	_original_text = label_3d.text
	_edit_text = _original_text
	label_3d.modulate = Color.YELLOW
	_cursor_visible = true
	_cursor_timer = 0.0
	_update_display_text()

func stop_editing(revert: bool = false) -> void:
	if not is_editing:
		return
	is_editing = false
	label_3d.modulate = Color.WHITE
	if revert:
		label_3d.text = _original_text
	else:
		label_3d.text = _edit_text

func handle_text_input(event: InputEventKey) -> void:
	if not is_editing:
		return
	if not event.pressed:
		return

	match event.keycode:
		KEY_BACKSPACE:
			if _edit_text.length() > 0:
				_edit_text = _edit_text.substr(0, _edit_text.length() - 1)
			_update_display_text()
		KEY_ENTER:
			stop_editing(false)
		_:
			if event.unicode != 0 and not event.ctrl_pressed and not event.alt_pressed and not event.meta_pressed:
				if _edit_text.length() < max_length:
					_edit_text += char(event.unicode)
					_update_display_text()

func _update_display_text() -> void:
	if not is_editing:
		return
	if _cursor_visible:
		label_3d.text = _edit_text + "|"
	else:
		label_3d.text = _edit_text
