extends Node3D

@export var book_thickness: float = 0.12

var _book_meshes: Array[MeshInstance3D] = []


func _ready() -> void:
	Global.added_to_stack.connect(_on_added_to_stack)
	Global.removed_from_stack.connect(_on_removed_from_stack)

	# Rebuild from existing global stack (e.g. after scene reload)
	for fact in Global.get_book_stack():
		_spawn_book_mesh(fact)
	_reposition_books()


func _on_added_to_stack(fact: Dictionary) -> void:
	_spawn_book_mesh(fact)
	_reposition_books()


func _on_removed_from_stack(_fact: Dictionary) -> void:
	if _book_meshes.is_empty():
		return
	var mesh: MeshInstance3D = _book_meshes.pop_back()
	mesh.queue_free()
	_reposition_books()


func _spawn_book_mesh(fact: Dictionary) -> void:
	var mesh := MeshInstance3D.new()
	mesh.mesh = preload("res://books/Book.obj")
	if fact.has("book_texture"):
		mesh.material_override = fact["book_texture"]
	mesh.scale = Vector3(0.3, 0.3, 0.3)
	mesh.rotation_degrees = Vector3(
		randf_range(-5.0, 5.0),
		randf_range(-15.0, 15.0),
		randf_range(-5.0, 5.0)
	)
	add_child(mesh)
	_book_meshes.append(mesh)


func _reposition_books() -> void:
	for i in range(_book_meshes.size()):
		_book_meshes[i].position.y = i * book_thickness
