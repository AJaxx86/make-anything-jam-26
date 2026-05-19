extends Node

signal added_to_stack(fact_dict: Dictionary)
signal removed_from_stack(fact_dict: Dictionary)

# Order: Category -> Texture path and fact array -> split sentence/completed
var _facts: Dictionary = {
	"space": {
		"book_texture": preload("res://books/materials/black.tres"),
		"split_facts": [
			{
				"sentence": [],
				"completed": false
			}
		]
	},
	"history": {
		"book_texture": preload("res://books/materials/yellow.tres"),
		"split_facts": [
			{
				"sentence": [],
				"completed": false
			}
		]
	},
	"animals": {
		"book_texture": preload("res://books/materials/brown.tres"),
		"split_facts": [
			{
				"sentence": [],
				"completed": false
			}
		]
	}
}
# Save the fact category when adding it to the book stack: [ {"category": "name", "fact": [split, fact], "book_texture": MaterialTexture3D} ]
var _book_stack: Array[Dictionary] = []


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


func complete_fact(fact_dict: Dictionary) -> bool:
	if not fact_dict.has("category") or not fact_dict.has("fact"):
		push_error("Fact dict missing required keys: " + str(fact_dict))
		return false

	var cat: String = fact_dict["category"]
	if not cat in _facts:
		push_error("Invalid fact category: " + cat)
		return false

	var category_facts: Array[Dictionary] = _facts[cat]["split_facts"]
	for fact in category_facts:
		if fact["sentence"] == fact_dict["fact"]:
			if fact["completed"]:
				print_debug("Fact was already completed: " + str(fact_dict["fact"]))
				return false
			fact["completed"] = true
			add_to_book_stack(fact_dict)
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
	# Guard against adding the exact same fact twice
	for entry in _book_stack:
		if entry["category"] == fact["category"] and entry["fact"] == fact["fact"]:
			print_debug("Fact already in book stack, skipping: " + str(fact))
			return
	_book_stack.append(fact)
	added_to_stack.emit(fact)


func remove_from_book_stack(fact: Dictionary) -> bool:
	for i in range(_book_stack.size()):
		var entry: Dictionary = _book_stack[i]
		if entry["category"] == fact["category"] and entry["fact"] == fact["fact"]:
			_book_stack.remove_at(i)
			print_debug("Removed fact from book stack: " + str(fact))
			removed_from_stack.emit(fact)
			return true
	push_error("Fact not found in book stack: " + str(fact))
	return false


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
