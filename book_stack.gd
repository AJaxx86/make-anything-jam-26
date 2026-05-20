extends Node3D

@export var book_thickness: float = 0.12

var _book_instances: Array[Node3D] = []


func _ready() -> void:
	Global.added_to_stack.connect(_on_added_to_stack)
	Global.removed_from_stack.connect(_on_removed_from_stack)

	for fact in Global.get_book_stack():
		_spawn_book(fact)
	_reposition_books()


func _on_added_to_stack(fact: Dictionary) -> void:
	_spawn_book(fact)
	_reposition_books()


func _on_removed_from_stack(_fact: Dictionary) -> void:
	if _book_instances.is_empty():
		return
	var instance: Node3D = _book_instances.pop_back()
	instance.queue_free()
	_reposition_books()


func _spawn_book(fact: Dictionary) -> void:
	var book := preload("res://books/book.tscn").instantiate()
	book.input_ray_pickable = false
	book.rotation.y += randf_range(-10.0, 10.0)
	add_child(book)
	book.setup(fact)
	_book_instances.append(book)


func _reposition_books() -> void:
	for i in range(_book_instances.size()):
		_book_instances[i].position.y = i * book_thickness
