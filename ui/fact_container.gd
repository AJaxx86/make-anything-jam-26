extends HFlowContainer
class_name FactContainer

signal item_dropped(original_piece: FactPiece)

@export var drop_sfx: Array[AudioStreamMP3]


func _can_drop_data(_at_position: Vector2, data: Variant) -> bool:
	return data is FactPiece


func _drop_data(_at_position: Vector2, data: Variant) -> void:
	var piece: FactPiece = data as FactPiece
	var original_parent: FactContainer = piece.get_parent() as FactContainer

	if original_parent == self:
		return

	piece.get_parent().remove_child(piece)
	add_child(piece)
	piece.flash()
	item_dropped.emit(piece)
	Global.play_sfx_random(drop_sfx)
