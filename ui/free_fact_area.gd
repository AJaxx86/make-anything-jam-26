extends Control
class_name FreeFactArea

signal item_dropped(original_piece: FactPiece)

@export var drop_sfx: Array[AudioStreamMP3]
@export var excluded_drop_area: Control
@export var initial_padding: Vector2 = Vector2(8, 8)
@export var initial_spacing: Vector2 = Vector2(8, 8)


func _can_drop_data(at_position: Vector2, data: Variant) -> bool:
	if not data is FactPiece:
		return false

	return can_drop_at_local(at_position)


func _drop_data(at_position: Vector2, data: Variant) -> void:
	if not data is FactPiece:
		return

	drop_piece_at_position(data as FactPiece, at_position)


func can_drop_at_local(local_pos: Vector2) -> bool:
	return not _is_excluded_global_position(global_position + local_pos)


func drop_piece_at_position(piece: FactPiece, local_pos: Vector2) -> void:
	if not can_drop_at_local(local_pos):
		return

	var old_parent: Node = piece.get_parent()
	if old_parent != null and old_parent != self:
		old_parent.remove_child(piece)
		if old_parent is FactSentenceContainer:
			(old_parent as FactSentenceContainer).call_deferred("_update_layout_minimum_height")

	if piece.get_parent() == null:
		add_child(piece)

	move_child(piece, get_child_count() - 1)
	piece.set_anchors_preset(Control.PRESET_TOP_LEFT)
	piece.position = _clamp_piece_position(local_pos - piece.size * 0.5, piece)
	piece.flash()
	item_dropped.emit(piece)
	Global.play_sfx_random(drop_sfx)


func add_fact_piece(piece: FactPiece) -> void:
	var old_parent: Node = piece.get_parent()
	if old_parent != null and old_parent != self:
		old_parent.remove_child(piece)
		if old_parent is FactSentenceContainer:
			(old_parent as FactSentenceContainer).call_deferred("_update_layout_minimum_height")

	if piece.get_parent() == null:
		add_child(piece)

	piece.set_anchors_preset(Control.PRESET_TOP_LEFT)
	call_deferred("_arrange_fact_pieces")


func clear_fact_pieces() -> void:
	for child in get_children():
		if child is FactPiece:
			child.queue_free()


func get_fact_pieces() -> Array[FactPiece]:
	var pieces: Array[FactPiece] = []
	for child in get_children():
		if child is FactPiece:
			pieces.append(child)
	return pieces


func _arrange_fact_pieces() -> void:
	var cursor: Vector2 = initial_padding
	var row_height: float = 0.0
	var available_width: float = maxf(size.x, initial_padding.x * 2.0)

	for piece in get_fact_pieces():
		var piece_size: Vector2 = piece.size
		if piece_size.x <= 0.0 or piece_size.y <= 0.0:
			piece_size = piece.get_combined_minimum_size()

		if cursor.x > initial_padding.x and cursor.x + piece_size.x > available_width:
			cursor.x = initial_padding.x
			cursor.y += row_height + initial_spacing.y
			row_height = 0.0

		piece.position = _clamp_piece_position(cursor, piece)
		cursor.x += piece_size.x + initial_spacing.x
		row_height = max(row_height, piece_size.y)


func _clamp_piece_position(target_position: Vector2, piece: FactPiece) -> Vector2:
	var piece_size: Vector2 = piece.size
	if piece_size.x <= 0.0 or piece_size.y <= 0.0:
		piece_size = piece.get_combined_minimum_size()

	var max_position := Vector2(
		maxf(0.0, size.x - piece_size.x),
		maxf(0.0, size.y - piece_size.y)
	)

	return Vector2(
		clampf(target_position.x, 0.0, max_position.x),
		clampf(target_position.y, 0.0, max_position.y)
	)


func _is_excluded_global_position(global_pos: Vector2) -> bool:
	if excluded_drop_area == null or not is_instance_valid(excluded_drop_area):
		return false

	var excluded_rect := Rect2(excluded_drop_area.global_position, excluded_drop_area.size)
	return excluded_rect.has_point(global_pos)
