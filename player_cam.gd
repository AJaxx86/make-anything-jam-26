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

@export var pause_menu_scene: PackedScene

## Distance in front of the camera to place the 3D reader mesh.
@export var reader_distance: float = 1.2

## How long the pause action must be held before it opens the pause menu.
## Releasing before this threshold performs the contextual back/cancel action instead.
@export var escape_hold_threshold: float = 0.45

var paused: bool = false

var _position_history: Array[Dictionary] = []
var _open_ui_scene: PackedScene = null
var _open_ui_instance: Control = null
var _reader_3d_scene: PackedScene = null
var _reader_3d_instance: Node3D = null
var _ui_was_visible_before_pause: bool = false
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

func _input(event: InputEvent) -> void:
	if event.is_action_pressed(&"pause") and not _escape_is_down:
		_escape_is_down = true
		_escape_hold_time = 0.0
		_escape_hold_triggered = false
		get_viewport().set_input_as_handled()
		return
	elif event.is_action_released(&"pause"):
		if _escape_is_down and not _escape_hold_triggered:
			handle_escape_tap()
		reset_escape_hold_state()
		get_viewport().set_input_as_handled()
		return

	if paused or _open_ui_instance != null:
		return

	var current_interactable := get_current_interactable()
	if current_interactable is LabelInteractable and current_interactable.is_editing:
		if event is InputEventKey:
			current_interactable.handle_text_input(event)
			get_viewport().set_input_as_handled()

func _process(delta: float) -> void:
	handle_escape_hold(delta)
	if paused:
		return
	update_camera_target(delta)
	if _open_ui_instance == null:
		handle_cam_movement(delta)
	else:
		global_transform.basis = _center_basis

func set_camera_view(caller: Interactable, camera_marker: Marker3D = null, camera_fov: float = 75.0, open_ui_scene: PackedScene = null, reader_3d_scene: PackedScene = null, fact_data: Dictionary = {}) -> void:
	var current_interactable := get_current_interactable()
	if current_interactable is LabelInteractable:
		current_interactable.stop_editing(false)

	var state_position: Vector3 = _target_global_position
	var state_basis: Basis = _target_center_basis
	var state_fov: float = clamp(camera_fov, 1.0, 179.0)

	if camera_marker != null:
		state_position = camera_marker.global_position
		state_basis = camera_marker.global_transform.basis.orthonormalized()

	if camera_fov == 0.0:
		state_fov = _target_fov

	if _position_history.size() >= 2:
		var previous_state := _position_history[_position_history.size() - 2]
		var previous_interactable := previous_state.get("interactable", null) as Interactable
		if previous_interactable == caller:
			go_back_camera_state()
			return

	var camera_state := {
		"interactable": caller,
		"marker": camera_marker,
		"position": state_position,
		"basis": state_basis,
		"fov": state_fov,
		"ui_scene": open_ui_scene,
		"reader_3d_scene": reader_3d_scene,
		"fact_data": fact_data,
	}

	if is_current_camera_state(camera_marker, caller):
		if camera_marker == null and camera_fov == 0.0 and (_open_ui_scene != open_ui_scene or _reader_3d_scene != reader_3d_scene):
			if open_ui_scene != null or reader_3d_scene != null:
				close_current_ui(false)
				_open_ui_scene = open_ui_scene
				_reader_3d_scene = reader_3d_scene
				if open_ui_scene != null:
					_open_ui_instance = UIManager.open_ui(open_ui_scene)
					set_ui_visibility(_open_ui_instance, true)
				if reader_3d_scene != null:
					_spawn_reader_3d(reader_3d_scene, fact_data)
			else:
				close_current_ui(true)
			return
		_position_history[_position_history.size() - 1] = camera_state
	else:
		_position_history.append(camera_state)

	apply_camera_state(camera_state)

	if caller is LabelInteractable:
		caller.start_editing()

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

	var current_interactable := get_current_interactable()
	if current_interactable is LabelInteractable and current_interactable.is_editing:
		current_interactable.stop_editing(false)
		go_back_camera_state()
		return

	if _open_ui_instance != null:
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

	if _open_ui_instance != null and _open_ui_instance.visible:
		UIManager.close_ui(_open_ui_instance)
		_ui_was_visible_before_pause = true

	if pause_menu_scene != null:
		var inst := UIManager.open_ui(pause_menu_scene)
		set_ui_visibility(inst, true)

func close_pause_menu() -> void:
	if not paused:
		return

	paused = false

	if pause_menu_scene != null:
		var inst := UIManager.open_ui(pause_menu_scene)
		UIManager.close_ui(inst)

	if _ui_was_visible_before_pause and _open_ui_scene != null:
		UIManager.open_ui(_open_ui_scene)
		_ui_was_visible_before_pause = false

func close_current_ui(update_current_state: bool = false) -> void:
	if _open_ui_instance == null and _reader_3d_instance == null:
		return

	if _open_ui_instance != null:
		set_ui_visibility(_open_ui_instance, false)
		UIManager.close_ui(_open_ui_instance)
		_open_ui_instance = null
		_open_ui_scene = null

	if _reader_3d_instance != null:
		_reader_3d_instance.queue_free()
		_reader_3d_instance = null
		_reader_3d_scene = null

	if update_current_state and _position_history.size() > 0:
		var current_state_index := _position_history.size() - 1
		var current_state := _position_history[current_state_index]
		if current_state.get("ui_scene", null) == null and current_state.get("reader_3d_scene", null) == null:
			go_back_camera_state()
		else:
			current_state["ui_scene"] = null
			current_state["reader_3d_scene"] = null
			_position_history[current_state_index] = current_state

func get_current_target_camera_state(ui_scene: PackedScene = null, reader_3d_scene: PackedScene = null, fact_data: Dictionary = {}) -> Dictionary:
	return {
		"marker": null,
		"position": _target_global_position,
		"basis": _target_center_basis,
		"fov": _target_fov,
		"ui_scene": ui_scene,
		"reader_3d_scene": reader_3d_scene,
		"fact_data": fact_data,
	}

func get_current_interactable() -> Interactable:
	if _position_history.is_empty():
		return null
	return _position_history[_position_history.size() - 1].get("interactable", null) as Interactable

func is_current_camera_state(camera_marker: Marker3D, caller: Interactable) -> bool:
	if _position_history.is_empty():
		return false

	var current_state := _position_history[_position_history.size() - 1]
	var current_marker := current_state.get("marker", null) as Marker3D

	if camera_marker != null:
		return current_marker == camera_marker

	var current_interactable := current_state.get("interactable", null) as Interactable
	return current_interactable == caller

func apply_camera_state(camera_state: Dictionary) -> void:
	close_current_ui(false)

	_target_global_position = camera_state["position"]
	_target_center_basis = camera_state["basis"]
	_target_fov = camera_state["fov"]

	var state_ui_scene := camera_state.get("ui_scene", null) as PackedScene
	if state_ui_scene != null:
		_open_ui_scene = state_ui_scene
		_open_ui_instance = UIManager.open_ui(state_ui_scene)
		set_ui_visibility(_open_ui_instance, true)

	var state_reader_scene := camera_state.get("reader_3d_scene", null) as PackedScene
	if state_reader_scene != null:
		_reader_3d_scene = state_reader_scene
		var state_fact := camera_state.get("fact_data", {}) as Dictionary
		_spawn_reader_3d(state_reader_scene, state_fact)

func set_ui_visibility(ui_node: Control, should_be_visible: bool) -> void:
	if ui_node == null:
		return

	ui_node.visible = should_be_visible
	emit_signal("Show_UI", ui_node, should_be_visible)

func go_back_camera_state() -> void:
	if _position_history.size() <= 1:
		return

	var current_interactable := get_current_interactable()
	if current_interactable is LabelInteractable:
		current_interactable.stop_editing(false)

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

func _spawn_reader_3d(scene: PackedScene, fact_data: Dictionary = {}) -> void:
	if scene == null:
		return
	_reader_3d_instance = scene.instantiate()
	add_child(_reader_3d_instance)
	_reader_3d_instance.position = Vector3(0, 0, -reader_distance)
	if _reader_3d_instance.has_method("setup") and not fact_data.is_empty():
		_reader_3d_instance.setup(fact_data)
