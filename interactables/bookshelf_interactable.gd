class_name BookshelfInteractable
extends Interactable

@export var columns: int = 6

@export_group("Marker Mode")
## NodePath to a container of Marker3D nodes. Each marker defines the START
## (left-most slot) of a shelf row. The remaining slots are generated
## automatically to the right of the marker.
@export var marker_container: NodePath = ^""
## Horizontal spacing between slots in a row. Defaults to scaled book width.
@export var slot_spacing: float = 0.3375

const _BOOK_OBJ_BOUNDS := Vector3(0.3375, 0.13125, 0.375)
## Seconds to wait after activation before slots become interactive.
const _ACTIVATION_DELAY: float = 0.15

var _slots: Array[Area3D] = []
var _labels_node: Node3D
var _activation_delay_timer: float = 0.0

@onready var _slots_container := Node3D.new()


func _ready() -> void:
	super._ready()

	_labels_node = get_node_or_null("Labels")

	_slots_container.name = "Slots"
	add_child(_slots_container)

	if not marker_container.is_empty() and has_node(marker_container):
		_generate_slots_from_row_markers()
	else:
		_generate_slots_auto()

	_update_pickable_state()


func _process(delta: float) -> void:
	if _activation_delay_timer > 0.0:
		_activation_delay_timer -= delta
		if _activation_delay_timer < 0.0:
			_activation_delay_timer = 0.0
	_update_pickable_state()


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

	_activation_delay_timer = _ACTIVATION_DELAY


func _update_pickable_state() -> void:
	var player_camera := get_viewport().get_camera_3d() as PlayerCam
	var current := player_camera.get_current_interactable() if player_camera != null else null
	var is_shelf_active := (current == self)
	var slots_ready := is_shelf_active and _activation_delay_timer <= 0.0

	input_ray_pickable = not is_shelf_active

	if _labels_node != null:
		for child in _labels_node.get_children():
			if child is Area3D:
				child.input_ray_pickable = is_shelf_active

	for slot in _slots:
		var has_book: bool = slot.has_method("has_book") and slot.has_book()
		slot.input_ray_pickable = slots_ready and not has_book


func _generate_slots_from_row_markers() -> void:
	var container := get_node(marker_container)
	var row_idx := 0
	for child in container.get_children():
		if not (child is Marker3D):
			continue

		var start_pos: Vector3 = child.global_position
		var right: Vector3 = global_transform.basis.x.normalized()
		for col in range(columns):
			var pos := start_pos + right * (col * slot_spacing)
			var slot := _create_slot(
				pos,
				_BOOK_OBJ_BOUNDS.x,
				_BOOK_OBJ_BOUNDS.y,
				_BOOK_OBJ_BOUNDS.z,
				"BookSlot_%d_%d" % [row_idx, col]
			)
			slot.rotation_degrees = Vector3(0, 90, 0)
			_slots_container.add_child(slot)
			_slots.append(slot)

		row_idx += 1


func _generate_slots_auto() -> void:
	var shelf_y_positions := [2.827, 2.064, 1.410, 0.755]
	var shelf_left: float = 0.1
	var shelf_right: float = 2.3
	var available_width: float = shelf_right - shelf_left
	var spacing: float = available_width / maxi(columns, 1)

	for row in range(shelf_y_positions.size()):
		var y: float = shelf_y_positions[row]
		for col in range(columns):
			var x := shelf_left + col * spacing + spacing * 0.5
			var z := 0.55

			var slot := _create_slot(
				Vector3(x, y, z),
				_BOOK_OBJ_BOUNDS.x,
				_BOOK_OBJ_BOUNDS.y,
				_BOOK_OBJ_BOUNDS.z,
				"BookSlot_%d_%d" % [row, col]
			)
			slot.rotation_degrees = Vector3(0, 0, 0)
			_slots_container.add_child(slot)
			_slots.append(slot)


func _create_slot(
	pos: Vector3,
	width: float,
	height: float,
	depth: float,
	name_str: String
) -> Area3D:
	var slot := Area3D.new()
	slot.name = name_str
	slot.position = to_local(pos)
	slot.script = preload("res://interactables/book_slot.gd")
	slot.slot_width = width
	slot.slot_height = height
	slot.slot_depth = depth

	var col_shape := CollisionShape3D.new()
	col_shape.name = "CollisionShape3D"
	slot.add_child(col_shape)

	var hover_node := MeshInstance3D.new()
	hover_node.name = "HoverIndicator"
	hover_node.visible = false
	slot.add_child(hover_node)

	return slot
