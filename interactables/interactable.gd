class_name Interactable extends Area3D

signal activate(caller: Interactable, camera_marker: Marker3D, camera_fov: float, open_ui_scene: PackedScene, reader_3d_scene: PackedScene)

## Prevents this interactable from being selected unless it's parent is selected first.
@export var required_parent: Interactable = null
@export var camera_marker: Marker3D = null
@export_range(0.0, 100.0, 1.0) var camera_fov: float = 75.0
@export var open_ui_scene: PackedScene = null
@export var reader_3d_scene: PackedScene = null

@export_group("SFX")
@export var activate_sfx: AudioStreamMP3 = null
@export var deactivate_sfx: AudioStreamMP3 = null
@export var ui_open_sfx: AudioStreamMP3 = null
@export var ui_close_sfx: AudioStreamMP3 = null
@export var reader_open_sfx: AudioStreamMP3 = null
@export var reader_close_sfx: AudioStreamMP3 = null


func _ready() -> void:
	connect("input_event", _on_input_event)


func _on_input_event(camera: Node, event: InputEvent, _event_position: Vector3, _normal: Vector3, _shape_idx: int) -> void:
	if not event.is_action_pressed(&"interact"):
		return

	var player_camera := camera as PlayerCam
	if player_camera == null:
		push_warning("Interactable " + name + " was clicked by a camera that is not a PlayerCam: " + camera.name)
		return

	var current_interactable := player_camera.get_current_interactable()
	if required_parent != null and current_interactable != required_parent and current_interactable != self:
		print_debug(self.name + " requires " + required_parent.name + " to be active first")
		return

	emit_signal(&"activate", self, camera_marker, camera_fov, open_ui_scene, reader_3d_scene)
	player_camera.set_camera_view(self, camera_marker, camera_fov, open_ui_scene, reader_3d_scene)
	print_debug("Clicked on " + name)
