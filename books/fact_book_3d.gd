extends Node3D

@onready var mesh_instance: MeshInstance3D = $MeshInstance3D

func setup(fact_data: Dictionary) -> void:
	if fact_data.has("open_book_texture"):
		mesh_instance.material_override = fact_data["open_book_texture"]
