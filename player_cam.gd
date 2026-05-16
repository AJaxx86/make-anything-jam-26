class_name PlayerCam extends Camera3D

signal Show_UI(ui_node: Control, show: bool)

## Maximum camera rotation, in degrees, when the mouse reaches the screen edge
## at the reference FOV. X controls left/right rotation, Y controls up/down rotation.
@export var mouse_rotation_degrees: Vector2 = Vector2(20.0, 20.0)

## The camera FOV where mouse_rotation_degrees applies exactly.
## When this camera's FOV changes, the mouse rotation scales from this value
## so narrow FOVs move less and wide FOVs move more.
@export var reference_fov_degrees: float = 75.0

## How quickly the camera eases toward the mouse-driven target rotation.
## Higher values feel snappier. Set to 0 or lower for instant movement.
@export var rotation_smoothing_speed: float = 10.0

## How quickly the camera moves toward a newly requested camera marker position.
## Higher values feel snappier. Set to 0 or lower for instant movement.
@export var position_smoothing_speed: float = 8.0

## How quickly the camera FOV changes toward a newly requested FOV.
## Higher values feel snappier. Set to 0 or lower for instant movement.
@export var fov_smoothing_speed: float = 8.0

@export var pause_menu: Control = null

var paused: bool = false

var _position_history: Array[Dictionary] = []
var _center_basis: Basis
var _target_center_basis: Basis
var _target_global_position: Vector3
var _target_fov: float


func _ready() -> void:
	_center_basis = global_transform.basis.orthonormalized()
	_target_center_basis = _center_basis
	_target_global_position = global_position
	_target_fov = fov


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("pause"):
		paused = not paused
		if paused:
			emit_signal("Show_UI", pause_menu, true)
		else:
			emit_signal("Show_UI", pause_menu, false)

	if event.is_action_pressed("interact"):
		pass


func _process(delta: float) -> void:
	if paused:
		return
	update_camera_target(delta)
	handle_cam_movement(delta)


## Intended to be connected directly to Interactable.Activate.
## Moves this camera to the marker's global position/orientation and eases to camera_fov.
## _open_ui is accepted so the Interactable.Activate signal can call this function directly.
func set_camera_view(camera_marker: Marker3D, camera_fov: float, open_ui: Control = null) -> void:
	if open_ui != null:
		emit_signal("Show_UI", open_ui, true)

	if camera_marker == null:
		push_warning("set_camera_view was called without a camera marker.")
		return

	_target_global_position = camera_marker.global_position
	_target_center_basis = camera_marker.global_transform.basis.orthonormalized()
	_target_fov = clamp(camera_fov, 1.0, 179.0)


func update_camera_target(delta: float) -> void:
	var position_weight := get_smoothing_weight(position_smoothing_speed, delta)
	if position_weight >= 1.0:
		global_position = _target_global_position
	else:
		global_position = global_position.lerp(_target_global_position, position_weight)

	var center_basis_weight := get_smoothing_weight(rotation_smoothing_speed, delta)
	if center_basis_weight >= 1.0:
		_center_basis = _target_center_basis
	else:
		_center_basis = _center_basis.slerp(_target_center_basis, center_basis_weight).orthonormalized()

	var fov_weight := get_smoothing_weight(fov_smoothing_speed, delta)
	if fov_weight >= 1.0:
		fov = _target_fov
	else:
		fov = lerp(fov, _target_fov, fov_weight)


func handle_cam_movement(delta: float) -> void:
	var viewport_size := Vector2(get_viewport().get_visible_rect().size)
	if viewport_size.x <= 0.0 or viewport_size.y <= 0.0:
		push_error("Invalid viewport size for camera movement: " + str(viewport_size))
		return

	var screen_center := viewport_size * 0.5
	var mouse_position := get_viewport().get_mouse_position()
	var mouse_from_center := mouse_position - screen_center
	var normalized_offset := Vector2(
		clamp(mouse_from_center.x / screen_center.x, -1.0, 1.0),
		clamp(mouse_from_center.y / screen_center.y, -1.0, 1.0)
	)

	var fov_scale := get_fov_scale(viewport_size.x / viewport_size.y)
	var yaw := deg_to_rad(-normalized_offset.x * mouse_rotation_degrees.x * fov_scale.x)
	var pitch := deg_to_rad(-normalized_offset.y * mouse_rotation_degrees.y * fov_scale.y)

	var target_basis := _center_basis * Basis(Vector3.UP, yaw) * Basis(Vector3.RIGHT, pitch)

	var smoothing_weight := get_smoothing_weight(rotation_smoothing_speed, delta)
	var next_basis := target_basis
	if smoothing_weight < 1.0:
		next_basis = global_transform.basis.slerp(target_basis, smoothing_weight).orthonormalized()

	var next_transform := global_transform
	next_transform.basis = next_basis
	global_transform = next_transform


func get_smoothing_weight(speed: float, delta: float) -> float:
	if speed <= 0.0:
		return 1.0
	return 1.0 - exp(-speed * delta)


func get_fov_scale(aspect_ratio: float) -> Vector2:
	var current_fov := get_camera_fov_radians(fov, aspect_ratio)
	var reference_fov := get_camera_fov_radians(reference_fov_degrees, aspect_ratio)

	return Vector2(
		current_fov.x / reference_fov.x,
		current_fov.y / reference_fov.y
	)


func get_camera_fov_radians(fov_degrees: float, aspect_ratio: float) -> Vector2:
	var safe_fov_degrees: float = max(fov_degrees, 0.001)
	var safe_aspect_ratio: float = max(aspect_ratio, 0.001)
	var locked_fov := deg_to_rad(safe_fov_degrees)

	if keep_aspect == Camera3D.KEEP_WIDTH:
		var width_locked_horizontal_fov := locked_fov
		var width_locked_vertical_fov := 2.0 * atan(tan(width_locked_horizontal_fov * 0.5) / safe_aspect_ratio)
		return Vector2(width_locked_horizontal_fov, width_locked_vertical_fov)

	var height_locked_vertical_fov := locked_fov
	var height_locked_horizontal_fov := 2.0 * atan(tan(height_locked_vertical_fov * 0.5) * safe_aspect_ratio)
	return Vector2(height_locked_horizontal_fov, height_locked_vertical_fov)
