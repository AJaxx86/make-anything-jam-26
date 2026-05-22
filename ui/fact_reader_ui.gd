extends Control

@export var fact_label: Label
@export var description_label: Label

var _label_base_font_sizes: Dictionary = {}
var _base_theme_font_size: int = 0


func _ready() -> void:
	_connect_font_changed()
	_apply_font(Global.current_font, Global.current_font_size)


func _connect_font_changed() -> void:
	if not Global.font_changed.is_connected(_on_global_font_changed):
		Global.font_changed.connect(_on_global_font_changed)


func _on_global_font_changed(font: FontFile, font_size: int) -> void:
	_apply_font(font, font_size)


func _apply_font(font: FontFile, font_size: int) -> void:
	if theme == null:
		theme = Theme.new()
	if _base_theme_font_size == 0:
		_base_theme_font_size = theme.default_font_size if theme.default_font_size > 0 else Global.default_font_size
	theme.set_default_font(font)
	theme.set_default_font_size(roundi(_base_theme_font_size * float(font_size) / Global.default_font_size))
	_apply_label_settings_font(self, font, font_size)


func _apply_label_settings_font(node: Node, font: FontFile, font_size: int) -> void:
	if node is Label:
		var label := node as Label
		if label.label_settings != null:
			var settings_id: int = label.label_settings.get_instance_id()
			if not _label_base_font_sizes.has(settings_id):
				_label_base_font_sizes[settings_id] = label.label_settings.font_size
			label.label_settings.font = font
			label.label_settings.font_size = roundi(_label_base_font_sizes[settings_id] * float(font_size) / Global.default_font_size)

	for child in node.get_children():
		_apply_label_settings_font(child, font, font_size)


func setup(fact: Dictionary) -> void:
	var data: Dictionary = Global.get_fact_data(fact["category"], fact["fact"])
	if data == {}:
		return

	fact_label.text = _construct_fact_sentence(data["sentence"])
	description_label.text = data["description"]


func _construct_fact_sentence(sentence: Array) -> String:
	return " ".join(sentence).strip_edges()
