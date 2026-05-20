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

var active_facts: Array[Dictionary] = []

func _ready() -> void:
	# Connect drag and drop cleanup signals
	source_flow.item_dropped.connect(_on_item_dropped)
	target_flow.item_dropped.connect(_on_item_dropped)

	submit_button.pressed.connect(_on_submit_pressed)

	# Load facts on initialization
	load_new_facts()

func _on_item_dropped(original_piece: FactPiece) -> void:
	original_piece.queue_free()

func load_new_facts() -> void:
	# Only fetch new facts if the current batch is completely finished
	if not active_facts.is_empty():
		return

	# Clear existing UI pieces to prepare a clean board
	for child in source_flow.get_children(): child.queue_free()
	for child in target_flow.get_children(): child.queue_free()

	active_facts = Global.get_facts(facts_per_round, "random")

	if active_facts.is_empty():
		print("All facts have been completed!")
		return

	var all_pieces: Array[String] = []

	# Loop through all retrieved facts to gather their pieces
	for fact_dict in active_facts:
		var full_fact_data = _get_full_fact_data(fact_dict["category"], fact_dict["fact"])
		if not full_fact_data.is_empty():
			all_pieces.append_array(full_fact_data["sentence"])
			all_pieces.append_array(full_fact_data["false_words"])

	# Shuffle them all together
	all_pieces.shuffle()

	# Instantiate pieces in the top source container
	for word in all_pieces:
		var piece: FactPiece = fact_piece_scene.instantiate()
		source_flow.add_child(piece)
		piece.setup(word)

# Helper function to find the full dictionary including false_words
func _get_full_fact_data(category: String, sentence: Array) -> Dictionary:
	# Safety check in case a category doesn't exist
	if not Global._facts.has(category):
		return {}

	for f in Global._facts[category]["split_facts"]:
		if f["sentence"] == sentence:
			return f
	return {}

func _on_submit_pressed() -> void:
	var constructed_sentence: Array = []

	# Read the text values in order from left to right in the target container
	for child in target_flow.get_children():
		if child is FactPiece:
			constructed_sentence.append(child.text_value)

	# Check if the constructed array matches ANY of our currently active facts
	var matched_fact: Dictionary = {}
	for fact in active_facts:
		if constructed_sentence == fact["fact"]:
			matched_fact = fact
			break # Match found, stop looking

	if not matched_fact.is_empty():
		print("Correct! Fact solved.")
		Global.complete_fact(matched_fact)

		# --- Cleanup False Words ---
		var full_data = _get_full_fact_data(matched_fact["category"], matched_fact["fact"])
		# Duplicate the array so we can cross items off as we find them
		var false_words_to_remove = full_data.get("false_words", []).duplicate()

		# Iterate through the source container and delete matching false words
		for child in source_flow.get_children():
			if child is FactPiece:
				var found_index = false_words_to_remove.find(child.text_value)
				if found_index != -1:
					# Remove from our hit-list so we only delete one piece per false word
					false_words_to_remove.remove_at(found_index)
					child.queue_free()

		# Remove the solved fact from our active list
		active_facts.erase(matched_fact)

		# Clear ONLY the target container so the used correct pieces vanish
		for child in target_flow.get_children():
			child.queue_free()

		# Check if we cleared all facts for this round
		if active_facts.is_empty():
			print("Round cleared!")
			if auto_load_next:
				load_new_facts()
	else:
		print("Incorrect, keep trying.")
