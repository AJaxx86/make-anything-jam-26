class_name Interactable extends Area3D

## If camera_marker is null, make sure to check that camera_pos isn't Vector3.ZERO before moving the camera
signal Activate(camera_marker: Marker3D, camera_fov: float, open_ui: Control)

@export var camera_marker: Marker3D = null
@export_range(10.0, 100.0, 01.0) var camera_fov: float = 75.0
@export var open_ui: Control = null


func _ready() -> void:
	connect("input_event", self._on_input_event)


func _on_input_event(camera: Node, _event: InputEvent, _event_postion: Vector3, _normal: Vector3, _shape_idx: int) -> void:
	if Input.is_action_just_pressed(&"interact"):
		emit_signal(&"Activate", camera_marker, camera_fov, open_ui)
		camera.set_camera_view(camera_marker, camera_fov, open_ui)
		print_debug("Clicked on " + self.name + " from " + camera.name)
