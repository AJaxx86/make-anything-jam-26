extends HFlowContainer
class_name FactContainer

signal item_dropped(original_piece: FactPiece)

@export var drop_sfx: Array[AudioStreamMP3]

const ROW_GROUP_TOLERANCE: float = 10.0


func _can_drop_data(_at_position: Vector2, data: Variant) -> bool:
	return data is FactPiece


func _drop_data(at_position: Vector2, data: Variant) -> void:
	if not data is FactPiece:
		return

	drop_piece_at_position(data as FactPiece, at_position)


func drop_piece_at_position(piece: FactPiece, local_pos: Vector2) -> void:
	var insert_index: int = _find_insert_index(local_pos, piece)
	insert_piece_at_index(piece, insert_index)


func get_fact_pieces() -> Array[FactPiece]:
	var pieces: Array[FactPiece] = []
	for child in get_children():
		if child is FactPiece:
			pieces.append(child)
	return pieces


func get_piece_index(piece: FactPiece) -> int:
	return get_fact_pieces().find(piece)


func insert_piece_at_index(piece: FactPiece, insert_index: int) -> void:
	var old_parent: Node = piece.get_parent()
	var was_in_container: bool = old_parent == self
	var old_index: int = -1

	if was_in_container:
		old_index = get_piece_index(piece)
		if old_index == -1:
			return
		if old_index < insert_index:
			insert_index -= 1

	if old_parent != null:
		old_parent.remove_child(piece)

	var target_child_index: int = _logical_to_child_index(insert_index)
	add_child(piece)
	if target_child_index >= 0 and target_child_index < get_child_count() - 1:
		move_child(piece, target_child_index)

	piece.flash()
	item_dropped.emit(piece)
	Global.play_sfx_random(drop_sfx)


func _logical_to_child_index(logical_index: int) -> int:
	if logical_index < 0:
		return 0

	var piece_count: int = 0
	for i in range(get_child_count()):
		if get_child(i) is FactPiece:
			if piece_count == logical_index:
				return i
			piece_count += 1

	return get_child_count()


func _find_insert_index(local_pos: Vector2, exclude_piece: FactPiece) -> int:
	var layout: Array[Dictionary] = _get_piece_layout_data(exclude_piece)
	if layout.is_empty():
		return 0

	var rows: Array[Dictionary] = _group_into_rows(layout)
	if rows.is_empty():
		return 0

	var best_row: Dictionary = rows[0]
	var best_row_dist: float = INF
	for row in rows:
		var row_dist: float = _distance_to_row(local_pos.y, row)
		if row_dist < best_row_dist:
			best_row_dist = row_dist
			best_row = row

	var best_boundary: Dictionary = best_row["boundaries"][0]
	var best_boundary_dist: float = INF
	for boundary in best_row["boundaries"]:
		var boundary_dist: float = abs(local_pos.x - boundary["x"])
		if boundary_dist < best_boundary_dist:
			best_boundary_dist = boundary_dist
			best_boundary = boundary

	return best_boundary["insert_index"]


func _get_piece_layout_data(exclude_piece: FactPiece = null) -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	for child in get_children():
		if child is FactPiece and child != exclude_piece:
			var rect: Rect2 = Rect2(child.position, child.size)
			result.append({
				"piece": child,
				"top": rect.position.y,
				"bottom": rect.position.y + rect.size.y,
				"left": rect.position.x,
				"right": rect.position.x + rect.size.x,
			})
	return result


func _group_into_rows(layout: Array[Dictionary]) -> Array[Dictionary]:
	var sorted: Array[Dictionary] = layout.duplicate()
	sorted.sort_custom(func(a: Dictionary, b: Dictionary) -> bool:
		var y_diff: float = a["top"] - b["top"]
		if abs(y_diff) > ROW_GROUP_TOLERANCE:
			return y_diff < 0.0
		return a["left"] < b["left"]
	)

	var rows: Array[Dictionary] = []
	var current_row: Array[Dictionary] = [sorted[0]]
	var current_y: float = sorted[0]["top"]

	for i in range(1, sorted.size()):
		var item: Dictionary = sorted[i]
		if abs(item["top"] - current_y) <= ROW_GROUP_TOLERANCE:
			current_row.append(item)
		else:
			rows.append(_build_row_data(current_row))
			current_row = [item]
			current_y = item["top"]

	if not current_row.is_empty():
		rows.append(_build_row_data(current_row))

	return rows


func _build_row_data(row_items: Array[Dictionary]) -> Dictionary:
	var sorted_row_items: Array[Dictionary] = row_items.duplicate()
	sorted_row_items.sort_custom(func(a: Dictionary, b: Dictionary) -> bool:
		return a["left"] < b["left"]
	)

	var top: float = INF
	var bottom: float = -INF
	var boundaries: Array[Dictionary] = []

	for item in sorted_row_items:
		top = min(top, item["top"])
		bottom = max(bottom, item["bottom"])

	for i in range(sorted_row_items.size() + 1):
		var x: float
		var insert_index: int
		if i == 0:
			x = sorted_row_items[0]["left"]
			insert_index = get_piece_index(sorted_row_items[0]["piece"])
		elif i == sorted_row_items.size():
			x = sorted_row_items[sorted_row_items.size() - 1]["right"]
			insert_index = get_piece_index(sorted_row_items[sorted_row_items.size() - 1]["piece"]) + 1
		else:
			var left_piece: Dictionary = sorted_row_items[i - 1]
			var right_piece: Dictionary = sorted_row_items[i]
			x = (left_piece["right"] + right_piece["left"]) * 0.5
			insert_index = get_piece_index(right_piece["piece"])
		boundaries.append({"x": x, "insert_index": insert_index})

	return {
		"top": top,
		"bottom": bottom,
		"boundaries": boundaries,
	}


func _distance_to_row(mouse_y: float, row: Dictionary) -> float:
	var row_top: float = row["top"]
	var row_bottom: float = row["bottom"]
	if mouse_y < row_top:
		return row_top - mouse_y
	if mouse_y > row_bottom:
		return mouse_y - row_bottom
	return 0.0
