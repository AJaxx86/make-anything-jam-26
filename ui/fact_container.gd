extends HFlowContainer
class_name FactContainer

signal item_dropped(original_piece: FactPiece)

func _can_drop_data(_at_position: Vector2, data: Variant) -> bool:
    return data is FactPiece and data.get_parent() != self

func _drop_data(_at_position: Vector2, data: Variant) -> void:
    var original_piece = data as FactPiece
    var new_piece = original_piece.duplicate()
    add_child(new_piece)
    new_piece.setup(original_piece.text_value)
    item_dropped.emit(original_piece)