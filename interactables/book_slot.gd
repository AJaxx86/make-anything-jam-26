extends Area3D

@export var slot_width: float = 0.32
@export var slot_height: float = 0.38
@export var slot_depth: float = 0.05

var _held_fact: Dictionary = {}

@onready var _collision_shape: CollisionShape3D = $CollisionShape3D
@onready var _hover_indicator: MeshInstance3D = $HoverIndicator

@export var place_book_sfx: AudioStreamMP3 = preload("res://sfx/book_on_shelf.mp3")


func _ready() -> void:
	var box := BoxShape3D.new()
	box.size = Vector3(slot_width, slot_height, slot_depth)
	_collision_shape.shape = box

	var ghost_mesh := MeshInstance3D.new()
	ghost_mesh.mesh = preload("res://books/Book.obj")
	ghost_mesh.scale = Vector3(0.3, 0.3, 0.3)
	ghost_mesh.rotation_degrees = Vector3(0, 0, 0)
	var ghost_mat := StandardMaterial3D.new()
	ghost_mat.albedo_color = Color(0.6, 0.9, 1.0, 0.3)
	ghost_mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	_hover_indicator.mesh = ghost_mesh.mesh
	_hover_indicator.scale = ghost_mesh.scale
	_hover_indicator.rotation_degrees = Vector3(-90, 0, 0)
	_hover_indicator.material_override = ghost_mat
	_hover_indicator.visible = false

	mouse_entered.connect(func():
		if input_ray_pickable and _held_fact.is_empty():
			_hover_indicator.visible = true
	)
	mouse_exited.connect(func():
		_hover_indicator.visible = false
	)

	input_event.connect(_on_input_event)


func _on_input_event(_camera: Node, event: InputEvent, _pos: Vector3, _normal: Vector3, _idx: int) -> void:
	if not event.is_action_pressed("interact"):
		return
	_place_book()

func _place_book() -> void:
	var stack: Array[Dictionary] = Global.get_book_stack()
	if stack.is_empty():
		print_debug("No book placed: stack is empty.")
		return

	var top: Dictionary = stack.back()
	if not Global.remove_from_book_stack(top):
		print_debug("No book placed: could not remove from global stack.")
		return

	_held_fact = top.duplicate()
	print_debug("Book placed: " + str(_held_fact))

	var book := preload("res://books/book.tscn").instantiate()
	book.input_ray_pickable = false
	add_child(book)
	book.setup(_held_fact)

	book.rotation_degrees = _hover_indicator.rotation_degrees
	var mesh: MeshInstance3D = book.get_node("BookMesh")
	mesh.position = Vector3.ZERO
	var col: CollisionShape3D = book.get_node("CollisionShape3D")
	col.position = Vector3.ZERO

	_hover_indicator.visible = false

	get_tree().create_timer(0.2).timeout.connect(func() -> void:
		if is_instance_valid(book):
			book.input_ray_pickable = true
	)

	Global.play_sfx(place_book_sfx)

func clear_book() -> void:
	_held_fact.clear()
	_hover_indicator.visible = false

func has_book() -> bool:
	return not _held_fact.is_empty()

func get_held_fact() -> Dictionary:
	return _held_fact.duplicate()
