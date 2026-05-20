extends Control

@export var fact_label: Label
@export var description_label: Label


func setup(fact: Dictionary) -> void:
	var data: Dictionary = Global.get_fact_data(fact["category"], fact["fact"])
	if data == {}:
		return

	fact_label.text = _construct_fact_sentence(data["sentence"])
	description_label.text = data["description"]


func _construct_fact_sentence(sentence: Array) -> String:
	return " ".join(sentence).strip_edges()
