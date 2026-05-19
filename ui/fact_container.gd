extends HFlowContainer
class_name FactContainer

signal item_dropped(original_piece: FactPiece)

# Phase 2: Engine checks if we are hovering over a valid drop zone
func _can_drop_data(_at_position: Vector2, data: Variant) -> bool:
    # Accept the drop if the dragged data is a FactPiece, 
    # AND it is not currently a child of this specific container
    return data is FactPiece and data.get_parent() != self

# Phase 3: Engine calls this when the mouse is released over this valid zone
func _drop_data(_at_position: Vector2, data: Variant) -> void:
    var original_piece = data as FactPiece
    
    # Decoupled approach: Duplicate the node instead of reparenting it
    var new_piece = original_piece.duplicate()
    add_child(new_piece)
    
    # Ensure the duplicated node retains the correct text
    new_piece.setup(original_piece.text_value)
    
    # Emit signal so the parent orchestrator can delete the original from its old location
    item_dropped.emit(original_piece)