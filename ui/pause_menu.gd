class_name PauseMenu extends Control

signal close_menu_pressed

@export var master_volume_slider: HSlider
@export var sfx_volume_slider: HSlider
@export var music_volume_slider: HSlider
@export var font_option_button: OptionButton

var default_volumes: Dictionary = {}
var _label_base_font_sizes: Dictionary = {}
var _base_theme_font_size: int = 0


func _ready() -> void:
	_font_setup()
	_apply_font(Global.current_font, Global.current_font_size)

	default_volumes = {
		"master": AudioServer.get_bus_volume_linear(0),
		"sfx": AudioServer.get_bus_volume_linear(1),
		"music": AudioServer.get_bus_volume_linear(2),
	}

	master_volume_slider.value = 0.5
	sfx_volume_slider.value = 0.5
	music_volume_slider.value = 0.5

	_apply_volume(0, "master", 0.5)
	_apply_volume(1, "sfx", 0.5)
	_apply_volume(2, "music", 0.5)


func _font_setup() -> void:
	if not Global.font_changed.is_connected(_on_global_font_changed):
		Global.font_changed.connect(_on_global_font_changed)
	if not font_option_button.item_selected.is_connected(_on_font_selection_item_selected):
		font_option_button.item_selected.connect(_on_font_selection_item_selected)

	font_option_button.clear()
	for font_name in Global.fonts.keys():
		font_option_button.add_item(font_name)

	var current_index: int = -1
	for index in range(font_option_button.item_count):
		if font_option_button.get_item_text(index) == Global.current_font_name:
			current_index = index
			break
	if current_index != -1:
		font_option_button.select(current_index)
	elif font_option_button.item_count > 0:
		font_option_button.select(0)
		Global.set_fonts(font_option_button.get_item_text(0))


func _on_font_selection_item_selected(index: int) -> void:
	var font_name: String = font_option_button.get_item_text(index)
	Global.set_fonts(font_name)


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


func _apply_volume(bus_index: int, bus_name: String, slider_value: float) -> void:
	var multiplier := slider_value / 0.5
	AudioServer.set_bus_volume_linear(bus_index, default_volumes[bus_name] * multiplier)


func _on_master_slider_drag_ended(_value_changed: bool) -> void:
	_apply_volume(0, "master", master_volume_slider.value)


func _on_sfx_slider_drag_ended(_value_changed: bool) -> void:
	_apply_volume(1, "sfx", sfx_volume_slider.value)


func _on_music_slider_drag_ended(_value_changed: bool) -> void:
	_apply_volume(2, "music", music_volume_slider.value)


func _on_volume_reset_pressed() -> void:
	master_volume_slider.value = 0.5
	sfx_volume_slider.value = 0.5
	music_volume_slider.value = 0.5

	_apply_volume(0, "master", 0.5)
	_apply_volume(1, "sfx", 0.5)
	_apply_volume(2, "music", 0.5)


func _on_quit_game_pressed() -> void:
	get_tree().quit()


func _on_close_menu_pressed() -> void:
	close_menu_pressed.emit()
