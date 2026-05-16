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

## How long the pause action must be held before it opens the pause menu.
## Releasing before this threshold performs the contextual back/cancel action instead.
@export var escape_hold_threshold: float = 0.45

var paused: bool = false

var _position_history: Array[Dictionary] = []
var _open_ui: Control = null
var _escape_is_down: bool = false
var _escape_hold_time: float = 0.0
var _escape_hold_triggered: bool = false
var _center_basis: Basis
var _target_center_basis: Basis
var _target_global_position: Vector3
var _target_fov: float


func _ready() -> void:
	_center_basis = global_transform.basis.orthonormalized()
	_target_center_basis = _center_basis
	_target_global_position = global_position
	_target_fov = fov
	_position_history.clear()
	_position_history.append(get_current_target_camera_state())

	if pause_menu != null:
		set_ui_visibility(pause_menu, false)


func _input(event: InputEvent) -> void:
	if event.is_action_pressed("pause") and not _escape_is_down:
		_escape_is_down = true
		_escape_hold_time = 0.0
		_escape_hold_triggered = false
		get_viewport().set_input_as_handled()
	elif event.is_action_released("pause"):
		if _escape_is_down and not _escape_hold_triggered:
			handle_escape_tap()
		reset_escape_hold_state()
		get_viewport().set_input_as_handled()


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("interact"):
		pass


func _process(delta: float) -> void:
	handle_escape_hold(delta)
	if paused:
		return
	update_camera_target(delta)
	handle_cam_movement(delta)


## Intended to be connected directly to Interactable.Activate.
## Moves this camera to the marker's global position/orientation and eases to camera_fov.
## open_ui is accepted so the Interactable.Activate signal can call this function directly.
func set_camera_view(camera_marker: Marker3D, camera_fov: float, open_ui: Control = null) -> void:
	if camera_marker == null:
		push_warning("set_camera_view was called without a camera marker.")
		return

	var camera_state := {
		"position": camera_marker.global_position,
		"basis": camera_marker.global_transform.basis.orthonormalized(),
		"fov": clamp(camera_fov, 1.0, 179.0),
		"ui": open_ui,
	}

	_position_history.append(camera_state)
	apply_camera_state(camera_state)


func handle_escape_hold(delta: float) -> void:
	if not _escape_is_down or _escape_hold_triggered:
		return

	_escape_hold_time += delta
	if _escape_hold_time < escape_hold_threshold:
		return

	_escape_hold_triggered = true
	if not paused:
		open_pause_menu()


func handle_escape_tap() -> void:
	if paused:
		close_pause_menu()
		return

	if _open_ui != null:
		close_current_ui(true)
		return

	go_back_camera_state()


func reset_escape_hold_state() -> void:
	_escape_is_down = false
	_escape_hold_time = 0.0
	_escape_hold_triggered = false


func open_pause_menu() -> void:
	if paused:
		return

	paused = true
	if pause_menu != null:
		set_ui_visibility(pause_menu, true)


func close_pause_menu() -> void:
	if not paused:
		return

	paused = false
	if pause_menu != null:
		set_ui_visibility(pause_menu, false)


func close_current_ui(update_current_state: bool = false) -> void:
	if _open_ui == null:
		return

	set_ui_visibility(_open_ui, false)
	_open_ui = null

	if update_current_state and _position_history.size() > 0:
		var current_state_index := _position_history.size() - 1
		var current_state := _position_history[current_state_index]
		current_state["ui"] = null
		_position_history[current_state_index] = current_state


func get_current_target_camera_state(ui: Control = null) -> Dictionary:
	return {
		"position": _target_global_position,
		"basis": _target_center_basis,
		"fov": _target_fov,
		"ui": ui,
	}


func apply_camera_state(camera_state: Dictionary) -> void:
	close_current_ui(false)

	_target_global_position = camera_state["position"]
	_target_center_basis = camera_state["basis"]
	_target_fov = camera_state["fov"]

	var state_ui := camera_state.get("ui", null) as Control
	if state_ui != null:
		_open_ui = state_ui
		set_ui_visibility(_open_ui, true)


func set_ui_visibility(ui_node: Control, should_be_visible: bool) -> void:
	if ui_node == null:
		return

	ui_node.visible = should_be_visible
	emit_signal("Show_UI", ui_node, should_be_visible)


func go_back_camera_state() -> void:
	if _position_history.size() <= 1:
		return

	_position_history.pop_back()
	apply_camera_state(_position_history[_position_history.size() - 1])


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
