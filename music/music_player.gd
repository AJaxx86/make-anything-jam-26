class_name MusicPlayer extends AudioStreamPlayer

var _fade_out_duration: float = 0.0
var _fade_out_triggered: bool = false
var _active_tween: Tween = null


func _ready() -> void:
	bus = &"Music"


func _process(_delta: float) -> void:
	if _fade_out_duration > 0.0 and playing and stream != null and not _fade_out_triggered:
		if get_playback_position() >= stream.get_length() - _fade_out_duration:
			_fade_out_triggered = true
			var tween: Tween = create_tween()
			tween.tween_property(self, "volume_db", -40, _fade_out_duration)


func start_playing(fade_in: float = 0.0, fade_out: float = 0.0) -> void:
	if _active_tween != null and _active_tween.is_valid():
		_active_tween.kill()
		_active_tween = null

	_fade_out_duration = fade_out
	_fade_out_triggered = false

	if fade_in > 0.0:
		volume_db = -40
		play()
		_active_tween = create_tween()
		_active_tween.tween_property(self, "volume_db", 0, fade_in)
	else:
		volume_db = 0
		play()


func stop_playing(fade_out: float = 0.0) -> void:
	if _active_tween != null and _active_tween.is_valid():
		_active_tween.kill()
		_active_tween = null

	_fade_out_duration = 0.0
	_fade_out_triggered = false

	if fade_out > 0.0 and playing:
		_active_tween = create_tween()
		_active_tween.tween_property(self, "volume_db", -40, fade_out)
		_active_tween.finished.connect(stop)
	else:
		stop()
