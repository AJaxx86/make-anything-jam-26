class_name Interactable extends Area3D

signal activate(caller: Interactable, camera_marker: Marker3D, camera_fov: float, open_ui: Control)

## Prevents this interactable from being selected unless it's parent is selected first.
@export var required_parent: Interactable = null
@export var camera_marker: Marker3D = null
@export_range(10.0, 100.0, 01.0) var camera_fov: float = 75.0
@export var open_ui: Control = null


func _ready() -> void:
	connect("input_event", _on_input_event)


func _on_input_event(camera: Node, event: InputEvent, _event_position: Vector3, _normal: Vector3, _shape_idx: int) -> void:
	if not event.is_action_pressed(&"interact"):
		return

	var player_camera := camera as PlayerCam
	if player_camera == null:
		push_warning("Interactable " + name + " was clicked by a camera that is not a PlayerCam: " + camera.name)
		return

	if required_parent != null and player_camera.get_current_interactable() != required_parent:
		print_debug(self.name + " requires " + required_parent.name + " to be active first")
		return

	emit_signal(&"activate", self, camera_marker, camera_fov, open_ui)
	player_camera.set_camera_view(self, camera_marker, camera_fov, open_ui)
	print_debug("Clicked on " + name)
