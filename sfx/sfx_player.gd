class_name SFXPlayer extends AudioStreamPlayer

signal sfx_finished(from: AudioStreamPlayer)


func _ready() -> void:
	connect("finished", _on_finished)
	bus = &"SFX"
	play()


func _on_finished() -> void:
	sfx_finished.emit(self)
