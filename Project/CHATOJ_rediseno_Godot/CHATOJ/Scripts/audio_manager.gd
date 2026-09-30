extends Node


# =========================
# AUDIO GLOBAL DE CH'ATOJ
# =========================

var music_player: AudioStreamPlayer
var ambience_player: AudioStreamPlayer
var current_music_path := ""
var current_ambience_path := ""
var music_loop := true
var ambience_loop := true
var _stream_cache: Dictionary = {}


func _ready():
	music_player = AudioStreamPlayer.new()
	music_player.name = "MusicPlayer"
	add_child(music_player)
	music_player.finished.connect(_on_music_finished)

	ambience_player = AudioStreamPlayer.new()
	ambience_player.name = "AmbiencePlayer"
	add_child(ambience_player)
	ambience_player.finished.connect(_on_ambience_finished)


func _get_stream(path: String) -> AudioStream:
	if _stream_cache.has(path):
		return _stream_cache[path]

	if not ResourceLoader.exists(path):
		push_warning("Audio no encontrado: " + path)
		return null

	var stream = load(path) as AudioStream
	if stream != null:
		_stream_cache[path] = stream

	return stream


func play_sfx(path: String, volume_db := 0.0, pitch_scale := 1.0):
	var stream = _get_stream(path)
	if stream == null:
		return null

	var player = AudioStreamPlayer.new()
	player.stream = stream
	player.volume_db = volume_db
	player.pitch_scale = pitch_scale
	add_child(player)
	player.finished.connect(player.queue_free)
	player.play()
	return player


func play_2d(path: String, world_position: Vector2, volume_db := 0.0, pitch_scale := 1.0):
	var stream = _get_stream(path)
	if stream == null:
		return null

	var current_scene = get_tree().current_scene
	if current_scene == null:
		return play_sfx(path, volume_db, pitch_scale)

	var player = AudioStreamPlayer2D.new()
	player.stream = stream
	player.volume_db = volume_db
	player.pitch_scale = pitch_scale
	player.max_distance = 1400.0
	player.attenuation = 1.1
	current_scene.add_child(player)
	player.global_position = world_position
	player.finished.connect(player.queue_free)
	player.play()
	return player


func start_loop_2d(owner: Node2D, path: String, volume_db := -8.0):
	var stream = _get_stream(path)
	if stream == null or owner == null:
		return null

	var player = AudioStreamPlayer2D.new()
	player.stream = stream
	player.volume_db = volume_db
	player.max_distance = 1000.0
	player.attenuation = 1.2
	owner.add_child(player)

	player.finished.connect(
		func():
			if is_instance_valid(player) and is_instance_valid(owner):
				player.play()
	)

	player.play()
	return player


func play_music(path: String, volume_db := -10.0, restart := false):
	if not restart and current_music_path == path and music_player.playing:
		return

	var stream = _get_stream(path)
	if stream == null:
		return

	music_player.stop()
	music_player.stream = stream
	music_player.volume_db = volume_db
	current_music_path = path
	music_loop = true
	music_player.play()


func stop_music():
	music_loop = false
	current_music_path = ""
	if music_player != null:
		music_player.stop()


func _on_music_finished():
	if music_loop and current_music_path != "" and music_player != null:
		music_player.play()


func play_ambience(path: String, volume_db := -22.0, restart := false):
	if not restart and current_ambience_path == path and ambience_player.playing:
		return

	var stream = _get_stream(path)
	if stream == null:
		return

	ambience_player.stop()
	ambience_player.stream = stream
	ambience_player.volume_db = volume_db
	current_ambience_path = path
	ambience_loop = true
	ambience_player.play()


func stop_ambience():
	ambience_loop = false
	current_ambience_path = ""
	if ambience_player != null:
		ambience_player.stop()


func _on_ambience_finished():
	if ambience_loop and current_ambience_path != "" and ambience_player != null:
		ambience_player.play()
