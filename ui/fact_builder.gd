extends Control

@export var fact_piece_scene: PackedScene

@export_group("Node References")
@export var source_flow: FactContainer
@export var target_flow: FactSentenceContainer
@export var submit_button: Button
@export var all_facts_message: Label

@export_group("Game Settings")
@export var facts_per_round: int = 1
@export var auto_load_next: bool = true

@export_group("SFX")
@export var check_correct: AudioStreamMP3
@export var check_incorrect: AudioStreamMP3
@export var check_incorrect_fart: AudioStreamMP3
@export_range(0.0, 100.0, 1.0) var fart_chance: float = 10.0

var active_facts: Array[Dictionary] = []


func _ready() -> void:
	all_facts_message.hide()

	load_new_facts()


func _on_item_dropped(original_piece: FactPiece) -> void:
	if original_piece != null:
		original_piece.set_feedback_colour(FactPiece.STATE.DEFAULT)
	_reset_feedback_colours()


func _reset_feedback_colours() -> void:
	for piece in target_flow.get_fact_pieces():
		piece.set_feedback_colour(FactPiece.STATE.DEFAULT)


func _find_best_matching_fact(constructed_sentence: Array) -> Dictionary:
	var best_fact: Dictionary = {}
	var best_score: int = -1

	for fact in active_facts:
		var target: Array = fact["fact"]
		var score: int = 0

		if constructed_sentence.size() == target.size():
			score += 1

		for i in range(min(constructed_sentence.size(), target.size())):
			if constructed_sentence[i] == target[i]:
				score += 3

		var target_words = target.duplicate()
		for word in constructed_sentence:
			var idx = target_words.find(word)
			if idx != -1:
				score += 1
				target_words.remove_at(idx)

		if score > best_score:
			best_score = score
			best_fact = fact

	return best_fact


func _evaluate_sentence(constructed_sentence: Array, target_fact: Array) -> Array[int]:
	var result: Array[int] = []
	result.resize(constructed_sentence.size())
	result.fill(FactPiece.STATE.INCORRECT)

	if target_fact.is_empty():
		return result

	var target_remaining: Array = target_fact.duplicate()
	var matched_constructed: Array[bool] = []
	matched_constructed.resize(constructed_sentence.size())
	matched_constructed.fill(false)

	for i in range(min(constructed_sentence.size(), target_fact.size())):
		if constructed_sentence[i] == target_fact[i]:
			result[i] = FactPiece.STATE.CORRECT_POSITION
			matched_constructed[i] = true
			target_remaining[i] = ""

	for i in range(constructed_sentence.size()):
		if matched_constructed[i]:
			continue

		var word = constructed_sentence[i]
		var found_idx = target_remaining.find(word)
		if found_idx != -1:
			result[i] = FactPiece.STATE.WRONG_POSITION
			target_remaining[found_idx] = ""

	return result


func load_new_facts() -> void:
	if not active_facts.is_empty():
		return

	for child in source_flow.get_children():
		if child is FactPiece:
			child.queue_free()
	target_flow.clear_fact_pieces()

	active_facts = Global.get_facts(facts_per_round, "random")

	if active_facts.is_empty():
		all_facts_message.show()
		print_debug("All facts have been completed!")
		return

	var all_pieces: Array[String] = []

	for fact_dict in active_facts:
		var full_fact_data = Global.get_fact_data(fact_dict["category"], fact_dict["fact"])
		if not full_fact_data.is_empty():
			all_pieces.append_array(full_fact_data["sentence"])
			all_pieces.append_array(full_fact_data["false_words"])

	all_pieces.shuffle()

	for word in all_pieces:
		var piece: FactPiece = fact_piece_scene.instantiate()
		source_flow.add_child(piece)
		piece.setup(word)


func _on_submit_pressed() -> void:
	var constructed_sentence: Array = []
	var pieces: Array[FactPiece] = []

	for piece in target_flow.get_fact_pieces():
		constructed_sentence.append(piece.text_value)
		pieces.append(piece)

	var matched_fact: Dictionary = {}
	for fact in active_facts:
		if constructed_sentence == fact["fact"]:
			matched_fact = fact
			break

	if not matched_fact.is_empty():
		print_debug("Fact correct: %s" % str(constructed_sentence))
		Global.complete_fact(matched_fact)

		var full_data = Global.get_fact_data(matched_fact["category"], matched_fact["fact"])
		var false_words_to_remove = full_data.get("false_words", []).duplicate()

		for child in source_flow.get_children():
			if child is FactPiece:
				var found_index = false_words_to_remove.find(child.text_value)
				if found_index != -1:
					false_words_to_remove.remove_at(found_index)
					child.queue_free()

		active_facts.erase(matched_fact)

		target_flow.clear_fact_pieces()

		if active_facts.is_empty():
			print_debug("Round cleared!")
			if auto_load_next:
				load_new_facts()

		Global.play_sfx(check_correct)
	else:
		var best_fact = _find_best_matching_fact(constructed_sentence)
		if not best_fact.is_empty():
			var feedback = _evaluate_sentence(constructed_sentence, best_fact["fact"])
			for i in range(min(pieces.size(), feedback.size())):
				pieces[i].set_feedback_colour(feedback[i])

		var chance: int = randi() % 100
		if chance < fart_chance:
			Global.play_sfx(check_incorrect_fart)
		else:
			Global.play_sfx(check_incorrect)
		print_debug("Fact incorrect: %s" % str(constructed_sentence))
