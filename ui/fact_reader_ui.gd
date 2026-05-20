extends Control

@export var fact_label: Label
@export var description_label: Label


func setup(fact: Dictionary) -> void:
	var data: Dictionary = _get_full_fact_data(fact["category"], fact["sentence"])
	if data == {}:
		return

	fact_label.text = _construct_fact_sentence(data["sentence"])
	description_label.text = data["description"]


func _construct_fact_sentence(sentence: Array[String]) -> String:
	var sen: String = ""
	for part in sentence:
		sen += part + " "
	return sen.strip_edges()


func _get_full_fact_data(category: String, sentence: Array) -> Dictionary:
	if not Global._facts.has(category):
		push_error("Category not found: " + category)
		return {}
	for f in Global._facts[category]["split_facts"]:
		if f["sentence"] == sentence:
			return f
	push_error("Fact not found: " + str(sentence))
	return {}
