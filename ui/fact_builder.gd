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

# We now store an array of facts in case you retrieve more than 1
var active_facts: Array[Dictionary] = []

func _ready() -> void:
	# Connect drag and drop cleanup signals
	source_flow.item_dropped.connect(_on_item_dropped)
	target_flow.item_dropped.connect(_on_item_dropped)

	submit_button.pressed.connect(_on_submit_pressed)

	# Listen for when this UI node is hidden or shown
	visibility_changed.connect(_on_visibility_changed)

	# Run once on startup if the node starts visible
	if is_visible_in_tree():
		reset_and_load()

func _on_visibility_changed() -> void:
	# Trigger a reset whenever the UI is made visible
	if is_visible_in_tree():
		reset_and_load()

func _on_item_dropped(original_piece: FactPiece) -> void:
	original_piece.queue_free()

func reset_and_load() -> void:
	# 1. Clear existing UI pieces
	for child in source_flow.get_children(): child.queue_free()
	for child in target_flow.get_children(): child.queue_free()

	active_facts.clear()

	# 2. Fetch the desired amount of random facts
	active_facts = Global.get_facts(facts_per_round, "random")

	if active_facts.is_empty():
		print("All facts have been completed!")
		return

	var all_pieces: Array[String] = []

	# 3. Loop through all retrieved facts to gather their pieces
	for fact_dict in active_facts:
		var full_fact_data = _get_full_fact_data(fact_dict["category"], fact_dict["fact"])
		if not full_fact_data.is_empty():
			all_pieces.append_array(full_fact_data["sentence"])
			all_pieces.append_array(full_fact_data["false_words"])

	# 4. Shuffle them all together
	all_pieces.shuffle()

	# 5. Instantiate pieces in the top source container
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

		# Remove the solved fact from our active list
		active_facts.erase(matched_fact)

		# Clear ONLY the target container so the used pieces vanish
		# The remaining pieces for the other facts stay in the source container!
		for child in target_flow.get_children():
			child.queue_free()

		# Check if we cleared all facts for this round
		if active_facts.is_empty():
			print("Round cleared!")
			if auto_load_next:
				reset_and_load()
	else:
		print("Incorrect, keep trying.")
