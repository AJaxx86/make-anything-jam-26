extends Interactable

var _fact: Dictionary = {}
var _click_down: bool = false
var _click_time: float = 0.0
var _return_triggered: bool = false
const _RETURN_HOLD_TIME: float = 0.4

@onready var _book_mesh: MeshInstance3D = $BookMesh
@onready var return_book_sfx: AudioStreamMP3 = preload("res://sfx/book_off_shelf.mp3")


func setup(fact: Dictionary) -> void:
	_fact = fact.duplicate()
	if _fact.has("book_texture"):
		_book_mesh.material_override = _fact["book_texture"]


func _ready() -> void:
	connect("input_event", _on_input_event)


func _on_input_event(_camera: Node, event: InputEvent, _pos: Vector3, _normal: Vector3, _idx: int) -> void:
	if event.is_action_pressed("interact"):
		_click_down = true
		_click_time = 0.0
	elif event.is_action_released("interact"):
		_click_down = false
		if _return_triggered:
			_return_triggered = false
			return
		var player_camera := get_viewport().get_camera_3d() as PlayerCam
		if player_camera != null:
			player_camera.set_camera_view(self, null, camera_fov, open_ui_scene, reader_3d_scene, _fact)
		else:
			push_warning("Book clicked but no PlayerCam found in viewport.")


func _process(delta: float) -> void:
	if _click_down and not _return_triggered:
		_click_time += delta
		if _click_time >= _RETURN_HOLD_TIME:
			_return_triggered = true
			_return_book()


func _return_book() -> void:
	if _fact.is_empty():
		return
	Global.add_to_book_stack(_fact)
	var slot := get_parent()
	if slot.has_method("clear_book"):
		slot.clear_book()
	Global.play_sfx(return_book_sfx)
	queue_free()
