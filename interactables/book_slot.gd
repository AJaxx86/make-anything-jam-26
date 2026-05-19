extends Area3D

signal read_book(fact: Dictionary)

@export var slot_width: float = 0.32
@export var slot_height: float = 0.38
@export var slot_depth: float = 0.05

var _held_fact: Dictionary = {}
var _click_time: float = 0.0
var _click_down: bool = false

@onready var _collision_shape: CollisionShape3D = $CollisionShape3D
@onready var _book_mesh: MeshInstance3D = $BookMesh
@onready var _hover_indicator: MeshInstance3D = $HoverIndicator


func _ready() -> void:
	# Build collision shape
	var box := BoxShape3D.new()
	box.size = Vector3(slot_width, slot_height, slot_depth)
	_collision_shape.shape = box

	# Build hover indicator using the real book mesh so it looks identical
	var ghost_mesh := MeshInstance3D.new()
	ghost_mesh.mesh = preload("res://books/Book.obj")
	ghost_mesh.scale = Vector3(0.3, 0.3, 0.3)
	var ghost_mat := StandardMaterial3D.new()
	ghost_mat.albedo_color = Color(0.6, 0.9, 1.0, 0.3)
	ghost_mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	_hover_indicator.mesh = ghost_mesh.mesh
	_hover_indicator.scale = ghost_mesh.scale
	_hover_indicator.material_override = ghost_mat
	_hover_indicator.visible = false

	mouse_entered.connect(func():
		if input_ray_pickable and _held_fact.is_empty():
			_hover_indicator.visible = true
	)
	mouse_exited.connect(func():
		_hover_indicator.visible = false
	)

	# Input is handled by parent bookshelf_interactable, but we wire our own for click/hold
	input_event.connect(_on_input_event)


func _on_input_event(_camera: Node, event: InputEvent, _pos: Vector3, _normal: Vector3, _idx: int) -> void:
	if event.is_action_pressed("interact"):
		_click_down = true
		_click_time = 0.0
	elif event.is_action_released("interact"):
		_click_down = false
		if _click_time < 0.4:
			# Short click
			if _held_fact.is_empty():
				_place_book()
			else:
				read_book.emit(_held_fact)
		else:
			# Long click / hold
			if not _held_fact.is_empty():
				_return_book()
			else:
				_hover_indicator.visible = false


func _process(delta: float) -> void:
	if _click_down:
		_click_time += delta
		if _click_time >= 0.4 and not _held_fact.is_empty():
			# Visual feedback: pulse the ghost book while holding to return
			if _hover_indicator.visible:
				var pulse := 0.5 + 0.5 * sin(_click_time * 20.0)
				(_hover_indicator.material_override as StandardMaterial3D).albedo_color.a = 0.3 + pulse * 0.3


func _place_book() -> void:
	var stack := Global.get_book_stack()
	if stack.is_empty():
		print_debug("No book placed: stack is empty.")
		return

	var top: Dictionary = stack.back()
	if not Global.remove_from_book_stack(top):
		print_debug("No book placed: could not remove from global stack.")
		return

	_held_fact = top.duplicate()
	print_debug("Book placed: " + str(_held_fact))

	# Build real book mesh
	var real_mesh := MeshInstance3D.new()
	real_mesh.mesh = preload("res://books/Book.obj")
	if _held_fact.has("book_texture"):
		real_mesh.material_override = _held_fact["book_texture"]
	real_mesh.scale = Vector3(0.3, 0.3, 0.3)
	real_mesh.rotation_degrees = Vector3(
		randf_range(-5.0, 5.0),
		randf_range(-15.0, 15.0),
		randf_range(-5.0, 5.0)
	)

	# Clean old mesh if any
	if _book_mesh.get_child_count() > 0:
		for c in _book_mesh.get_children():
			c.queue_free()

	_book_mesh.add_child(real_mesh)
	_book_mesh.visible = true
	_hover_indicator.visible = false
	print_debug("_place_book(): book mesh built and made visible")


func _return_book() -> void:
	if _held_fact.is_empty():
		return

	print_debug("Book returned to stack: " + str(_held_fact))
	Global.add_to_book_stack(_held_fact)
	_held_fact.clear()

	for c in _book_mesh.get_children():
		c.queue_free()
	_book_mesh.visible = false

	# Reset hover indicator alpha
	var mat := _hover_indicator.material_override as StandardMaterial3D
	if mat:
		mat.albedo_color.a = 0.3


func has_book() -> bool:
	return not _held_fact.is_empty()
