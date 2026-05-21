extends HFlowContainer
class_name FactSentenceContainer

signal item_dropped(original_piece: FactPiece)

@export var drop_sfx: Array[AudioStreamMP3]
@export var overlay: FactSentenceDropOverlay

const ROW_GROUP_TOLERANCE: float = 10.0
const ROW_ACTIVATION_THRESHOLD: float = 40.0
const EDGE_BOUNDARY_THRESHOLD: float = 48.0

var _hover_insert_index: int = -1
var _is_dragging: bool = false


func _can_drop_data(at_position: Vector2, data: Variant) -> bool:
	if not data is FactPiece:
		return false

	_is_dragging = true
	_update_hover(at_position, data as FactPiece)
	return true


func _drop_data(_at_position: Vector2, data: Variant) -> void:
	if not data is FactPiece:
		return

	var piece: FactPiece = data as FactPiece
	if _hover_insert_index != -1:
		insert_piece_at_index(piece, _hover_insert_index)

	_clear_hover()


func _ready() -> void:
	call_deferred("_update_layout_minimum_height")


func _notification(what: int) -> void:
	if what == NOTIFICATION_DRAG_END:
		_is_dragging = false
		_clear_hover()
	elif what == NOTIFICATION_SORT_CHILDREN:
		call_deferred("_update_layout_minimum_height")
	elif what == NOTIFICATION_RESIZED:
		call_deferred("_update_layout_minimum_height")


func get_fact_pieces() -> Array[FactPiece]:
	var pieces: Array[FactPiece] = []
	for child in get_children():
		if child is FactPiece:
			pieces.append(child)
	return pieces


func get_piece_index(piece: FactPiece) -> int:
	var pieces := get_fact_pieces()
	return pieces.find(piece)


func get_piece_layout_data(exclude_piece: FactPiece = null) -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	for child in get_children():
		if child is FactPiece and child != exclude_piece:
			var rect := Rect2(child.position, child.size)
			result.append({
				"piece": child,
				"rect": rect,
				"center": rect.get_center(),
				"top": rect.position.y,
				"bottom": rect.position.y + rect.size.y,
				"left": rect.position.x,
				"right": rect.position.x + rect.size.x,
			})
	return result


func insert_piece_at_index(piece: FactPiece, insert_index: int) -> void:
	var old_parent := piece.get_parent()
	var was_in_sentence := old_parent == self
	var old_logical_index := -1

	if was_in_sentence:
		old_logical_index = get_piece_index(piece)
		if old_logical_index == -1:
			push_warning("Piece not found in sentence container")
			return

		if old_logical_index < insert_index:
			insert_index -= 1

	if old_parent != null:
		old_parent.remove_child(piece)

	var target_child_index := _logical_to_child_index(insert_index)

	add_child(piece)
	if target_child_index >= 0 and target_child_index < get_child_count() - 1:
		move_child(piece, target_child_index)

	call_deferred("_update_layout_minimum_height")
	piece.flash()
	item_dropped.emit(piece)
	Global.play_sfx_random(drop_sfx)


func clear_fact_pieces() -> void:
	for child in get_children():
		if child is FactPiece:
			child.queue_free()
	call_deferred("_update_layout_minimum_height")


func _logical_to_child_index(logical_index: int) -> int:
	"""Convert a logical FactPiece index to an actual child index."""
	if logical_index < 0:
		return 0

	var child_idx := 0
	var piece_count := 0
	for i in range(get_child_count()):
		if get_child(i) is FactPiece:
			if piece_count == logical_index:
				return child_idx
			piece_count += 1
		child_idx += 1

	return child_idx


func _update_hover(mouse_pos: Vector2, dragged_piece: FactPiece) -> void:
	var layout: Array[Dictionary] = get_piece_layout_data(dragged_piece)

	if layout.is_empty():
		_hover_insert_index = 0
		var line_bottom: float = size.y if size.y > 0 else 40.0
		if overlay != null:
			overlay.set_hover(0, 0.0, 0.0, line_bottom)
		return

	var rows: Array[Dictionary] = _group_into_rows(layout)
	if rows.is_empty():
		_clear_hover()
		return

	var best_row: Dictionary = {}
	var best_row_dist: float = INF

	for row in rows:
		var row_dist: float = _distance_to_row(mouse_pos.y, row)
		if row_dist > ROW_ACTIVATION_THRESHOLD:
			continue

		var padded_left: float = row["left"] - EDGE_BOUNDARY_THRESHOLD
		var padded_right: float = row["right"] + EDGE_BOUNDARY_THRESHOLD
		if mouse_pos.x < padded_left or mouse_pos.x > padded_right:
			continue

		if row_dist < best_row_dist:
			best_row_dist = row_dist
			best_row = row

	if best_row.is_empty():
		_clear_hover()
		return

	var boundaries: Array[Dictionary] = best_row["boundaries"]
	if boundaries.is_empty():
		_clear_hover()
		return

	var chosen: Dictionary = _find_nearest_boundary(mouse_pos.x, boundaries)
	if chosen.is_empty():
		_clear_hover()
		return

	_hover_insert_index = chosen["insert_index"]
	if overlay != null:
		overlay.set_hover(
			_hover_insert_index,
			chosen["x"],
			best_row["top"],
			best_row["bottom"]
		)


func _group_into_rows(layout: Array[Dictionary]) -> Array[Dictionary]:
	if layout.is_empty():
		return []

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
	var left: float = INF
	var right: float = -INF
	for item in sorted_row_items:
		top = min(top, item["top"])
		bottom = max(bottom, item["bottom"])
		left = min(left, item["left"])
		right = max(right, item["right"])

	var boundaries: Array[Dictionary] = []
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
		"items": sorted_row_items,
		"top": top,
		"bottom": bottom,
		"left": left,
		"right": right,
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


func _find_nearest_boundary(mouse_x: float, boundaries: Array[Dictionary]) -> Dictionary:
	var best_boundary: Dictionary = {}
	var best_dist: float = INF

	for boundary in boundaries:
		var dist: float = abs(mouse_x - boundary["x"])
		if dist < best_dist:
			best_dist = dist
			best_boundary = boundary

	return best_boundary


func _update_layout_minimum_height() -> void:
	var content_height: float = 0.0
	for piece in get_fact_pieces():
		content_height = max(content_height, piece.position.y + piece.size.y)

	custom_minimum_size.y = content_height
	minimum_size_changed.emit()

	var sentence_area: Control = get_parent() as Control
	if sentence_area != null:
		sentence_area.custom_minimum_size.y = content_height
		sentence_area.minimum_size_changed.emit()


func _clear_hover() -> void:
	_hover_insert_index = -1
	if overlay != null:
		overlay.clear_hover()
