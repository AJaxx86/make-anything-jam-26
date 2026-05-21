extends Node

signal added_to_stack(fact_dict: Dictionary)
signal removed_from_stack(fact_dict: Dictionary)

var _fact_json_path: String = "res://facts.json"
var _facts: Dictionary = {}
var _book_textures: Dictionary = {
	"space": {
		"closed": preload("res://books/materials/black.tres"),
		"open": preload("res://books/materials/black_open.tres")
	}
}
var _book_stack: Array[Dictionary] = []

var sfx_players: Array[SFXPlayer] = []
var music_player: MusicPlayer = null
var _music_tracks: Array[AudioStreamMP3] = [
	preload("res://music/lofi.mp3"),
]


func _ready() -> void:
	_import_facts()
	play_music(2.0)


func play_music(delay: float = 0.0) -> void:
	if music_player == null:
		var new_player: MusicPlayer = MusicPlayer.new()
		music_player = new_player
		music_player.connect("finished", _on_music_ended)
		add_child(music_player)

	if delay > 0.0:
		await get_tree().create_timer(delay).timeout

	music_player.stream = _music_tracks[0]
	music_player.start_playing(15.0, 15.0)
	print_debug("Playing music track: " + _music_tracks[0].get_path())


func _on_music_ended() -> void:
	play_music(2.0)


func get_facts(amount: int, category: String = "random") -> Array[Dictionary]:
	var picked_facts: Array[Dictionary] = []
	var incomplete_facts: Array[Dictionary] = []

	if category == "random":
		for cat in _facts.keys():
			for fact in _facts[cat]["split_facts"]:
				if not fact["completed"]:
					incomplete_facts.append({"category": cat, "fact": fact["sentence"]})
	elif category in _facts:
		for fact in _facts[category]["split_facts"]:
			if not fact["completed"]:
				incomplete_facts.append({"category": category, "fact": fact["sentence"]})
	else:
		push_error("Invalid fact category: " + category)
		return picked_facts

	incomplete_facts.shuffle()

	var count: int = mini(amount, incomplete_facts.size())
	for i in range(count):
		picked_facts.append(incomplete_facts[i])

	return picked_facts


func get_fact_data(category: String, sentence: Array) -> Dictionary:
	if category not in _facts:
		push_error("Invalid fact category: " + category)
		return {}

	var category_facts: Array = _facts[category]["split_facts"]
	for fact in category_facts:
		if fact["sentence"] == sentence:
			return fact

	push_error("Fact not found in " + category + ": " + str(sentence))
	return {}


func complete_fact(fact_dict: Dictionary) -> bool:
	if not fact_dict.has("category") or not fact_dict.has("fact"):
		push_error("Fact dict missing required keys: " + str(fact_dict))
		return false

	var cat: String = fact_dict["category"]
	if not cat in _facts:
		push_error("Invalid fact category: " + cat)
		return false

	var category_facts: Array = _facts[cat]["split_facts"]
	for fact in category_facts:
		if fact["sentence"] == fact_dict["fact"]:
			if fact["completed"]:
				print_debug("Fact was already completed: " + str(fact_dict["fact"]))
				return false
			fact["completed"] = true
			var enriched := fact_dict.duplicate()
			if not enriched.has("book_texture"):
				enriched["book_texture"] = _facts[cat]["book_texture"]
			if not enriched.has("open_book_texture"):
				enriched["open_book_texture"] = _facts[cat]["open_book_texture"]
			add_to_book_stack(enriched)
			print_debug("Marked fact as completed: " + str(fact_dict["fact"]))
			return true

	push_error("Failed to mark fact as completed: " + str(fact_dict))
	return false


func is_fact_completed(fact_dict: Dictionary) -> bool:
	var cat: String = fact_dict.get("category", "")
	if not cat in _facts:
		return false

	for fact in _facts[cat]["split_facts"]:
		if fact["sentence"] == fact_dict.get("fact", []):
			return fact["completed"]
	return false


func add_to_book_stack(fact: Dictionary) -> void:
	for entry in _book_stack:
		if entry["category"] == fact["category"] and entry["fact"] == fact["fact"]:
			print_debug("Fact already in book stack, skipping: " + str(fact))
			return
	var enriched := fact.duplicate()
	_book_stack.append(enriched)
	added_to_stack.emit(enriched)


func remove_from_book_stack() -> bool:
	if _book_stack.size() == 0:
		return false

	var book = _book_stack.pop_back()
	removed_from_stack.emit(book)
	return true


func get_book_stack() -> Array[Dictionary]:
	return _book_stack.duplicate()


func get_book_stack_count() -> int:
	return _book_stack.size()


func clear_book_stack() -> void:
	_book_stack.clear()


func get_completed_count(category: String = "") -> int:
	var count: int = 0
	var categories: Array = [category] if category != "" else _facts.keys()
	for cat in categories:
		if not cat in _facts:
			continue
		for fact in _facts[cat]["split_facts"]:
			if fact["completed"]:
				count += 1
	return count


func get_total_fact_count(category: String = "") -> int:
	var count: int = 0
	var categories: Array = [category] if category != "" else _facts.keys()
	for cat in categories:
		if not cat in _facts:
			continue
		count += _facts[cat]["split_facts"].size()
	return count


func reset_facts() -> void:
	for cat in _facts.keys():
		for fact in _facts[cat]["split_facts"]:
			fact["completed"] = false
	clear_book_stack()
	print_debug("All facts reset and book stack cleared.")


func _import_facts() -> void:
	var parsed := _load_facts_json()
	if parsed.is_empty():
		return

	var fact_splitter: String = "+"
	var fact_count: int = 0
	for fact in parsed:
		var category: String = fact["Category"].to_lower()
		if category not in _book_textures:
			push_warning("Book texture unavailable for " + category + ". Skipped.")
			continue

		if category not in _facts:
			_facts[category] = {
				"book_texture": _book_textures[category]["closed"],
				"open_book_texture": _book_textures[category]["open"],
				"split_facts": []
			}

		var fact_dict: Dictionary = {
			"sentence": _parse_fact_into_array(fact["Sentence"], fact_splitter),
			"false_words": _parse_fact_into_array(fact["False Facts"], fact_splitter),
			"description": fact["Description"],
			"completed": false
		}
		_facts[category]["split_facts"].append(fact_dict)
		fact_count += 1

	print_debug("Imported " + str(fact_count) + " facts from " + _fact_json_path + ".")


func _parse_fact_into_array(words: String, splitter: String) -> Array[String]:
	if words == "":
		push_error("Fact is missing words.")
		return []

	return Array(words.split(splitter)).map(func(part): return part.strip_edges())


func _load_facts_json() -> Array:
	var facts_path: String = _fact_json_path
	if not FileAccess.file_exists(facts_path):
		push_error("facts.json not found at " + facts_path)
		return []

	var file := FileAccess.open(facts_path, FileAccess.READ)
	var json_string := file.get_as_text()
	file.close()

	var parsed = JSON.parse_string(json_string)
	if parsed == null:
		push_error("Failed to parse facts.json as JSON.")
		return []
	if parsed.size() == 0:
		push_error("facts.json is empty. the game is pointless.")
		return []

	return parsed

# AUDIO

func play_sfx(sfx: AudioStreamMP3) -> void:
	var player: SFXPlayer = SFXPlayer.new()
	player.stream = sfx
	player.sfx_finished.connect(remove_sfx_player)
	sfx_players.append(player)

	add_child(player)


func play_sfx_random(sfx_array: Array[AudioStreamMP3]) -> void:
	var sfx: AudioStreamMP3 = sfx_array[randi() % sfx_array.size()]
	play_sfx(sfx)


func remove_sfx_player(player: SFXPlayer) -> void:
	var to_remove: int = sfx_players.find(player)
	if to_remove != -1:
		sfx_players.pop_at(to_remove)
		player.queue_free()
	else:
		push_warning("Tried to remove a non-existent SFX player: " + str(player))
