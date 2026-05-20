extends Control

@export var master_volume_slider: HSlider
@export var sfx_volume_slider: HSlider
@export var music_volume_slider: HSlider

var default_volumes: Dictionary = {}


func _ready() -> void:
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
