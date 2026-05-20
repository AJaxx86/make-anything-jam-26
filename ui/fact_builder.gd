extends Control

@export var fact_piece_scene: PackedScene

@export_group("Node References")
@export var source_flow: FactContainer
@export var target_flow: FactContainer
@export var submit_button: Button

@export_group("Game Settings")
## How many facts should be retrieved and jumbled together?
@export var facts_per_round: int = 1
## Should the game automatically load new facts when the board is cleared?
@export var auto_load_next: bool = true

@export_group("SFX")
@export var check_correct: AudioStreamMP3
@export var check_incorrect: AudioStreamMP3
@export var check_incorrect_fart: AudioStreamMP3
@export_range(0.0, 100.0, 1.0) var fart_chance: float = 20.0

var active_facts: Array[Dictionary] = []

func _ready() -> void:
	source_flow.item_dropped.connect(_on_item_dropped)
	target_flow.item_dropped.connect(_on_item_dropped)

	submit_button.pressed.connect(_on_submit_pressed)

	load_new_facts()

func _on_item_dropped(original_piece: FactPiece) -> void:
	original_piece.queue_free()

func load_new_facts() -> void:
	if not active_facts.is_empty():
		return

	for child in source_flow.get_children(): child.queue_free()
	for child in target_flow.get_children(): child.queue_free()

	active_facts = Global.get_facts(facts_per_round, "random")

	if active_facts.is_empty():
		print("All facts have been completed!")
		return

	var all_pieces: Array[String] = []

	for fact_dict in active_facts:
		var full_fact_data = _get_full_fact_data(fact_dict["category"], fact_dict["fact"])
		if not full_fact_data.is_empty():
			all_pieces.append_array(full_fact_data["sentence"])
			all_pieces.append_array(full_fact_data["false_words"])

	all_pieces.shuffle()

	for word in all_pieces:
		var piece: FactPiece = fact_piece_scene.instantiate()
		source_flow.add_child(piece)
		piece.setup(word)

func _get_full_fact_data(category: String, sentence: Array) -> Dictionary:
	if not Global._facts.has(category):
		return {}

	for f in Global._facts[category]["split_facts"]:
		if f["sentence"] == sentence:
			return f
	return {}

func _on_submit_pressed() -> void:
	var constructed_sentence: Array = []

	for child in target_flow.get_children():
		if child is FactPiece:
			constructed_sentence.append(child.text_value)

	var matched_fact: Dictionary = {}
	for fact in active_facts:
		if constructed_sentence == fact["fact"]:
			matched_fact = fact
			break

	if not matched_fact.is_empty():
		print("Correct! Fact solved.")
		Global.complete_fact(matched_fact)

		var full_data = _get_full_fact_data(matched_fact["category"], matched_fact["fact"])
		var false_words_to_remove = full_data.get("false_words", []).duplicate()

		for child in source_flow.get_children():
			if child is FactPiece:
				var found_index = false_words_to_remove.find(child.text_value)
				if found_index != -1:
					false_words_to_remove.remove_at(found_index)
					child.queue_free()

		active_facts.erase(matched_fact)

		for child in target_flow.get_children():
			child.queue_free()

		if active_facts.is_empty():
			print("Round cleared!")
			if auto_load_next:
				load_new_facts()

		Global.play_sfx(check_correct)
	else:
		var chance: int = randi() % 100
		if chance < fart_chance:
			Global.play_sfx(check_incorrect_fart)
		else:
			Global.play_sfx(check_incorrect)
		print("Incorrect, keep trying.")
