extends Node

var _container: CanvasLayer
var _cache: Dictionary[PackedScene, Control] = {}


func _ready() -> void:
	_container = CanvasLayer.new()
	_container.name = "UIContainer"
	_container.layer = 10
	get_tree().root.call_deferred("add_child", _container)


func open_ui(scene: PackedScene) -> Control:
	if scene == null:
		return null

	if _cache.has(scene):
		var existing: Control = _cache[scene]
		existing.show()
		return existing

	var instance: Control = scene.instantiate()
	_container.add_child(instance)
	_cache[scene] = instance
	return instance


func close_ui(instance: Control) -> void:
	if instance != null and instance.is_inside_tree():
		instance.hide()


func close_all() -> void:
	for instance in _cache.values():
		instance.hide()
