extends Node2D
class_name Chapter1WorldAudio

var ambient_players: Array = []
var one_shot_players: Array = []
var one_shot_timer: Timer
var one_shot_index := 0

func _ready() -> void:
	add_to_group("chapter1_world_audio")

func configure(ambient_sources: Array, one_shot_sources: Array) -> void:
	for source in ambient_sources:
		_add_ambient_source(source)

	one_shot_players.clear()
	for source in one_shot_sources:
		var player := _make_player(source)
		one_shot_players.append(player)

	if one_shot_players.size() > 0:
		one_shot_timer = Timer.new()
		one_shot_timer.wait_time = 7.5
		one_shot_timer.autostart = true
		one_shot_timer.timeout.connect(_play_next_one_shot)
		add_child(one_shot_timer)

func _add_ambient_source(source: Dictionary) -> void:
	var player := _make_player(source)
	if player.stream == null:
		return
	if player.stream is AudioStreamOggVorbis:
		player.stream.loop = source.get("loop", true)
	ambient_players.append(player)
	player.play()

func _make_player(source: Dictionary) -> AudioStreamPlayer2D:
	var player := AudioStreamPlayer2D.new()
	player.name = source.get("name", "AudioSource")
	player.position = source.get("pos", Vector2.ZERO)
	player.volume_db = source.get("volume_db", -8.0)
	player.max_distance = source.get("max_distance", 900.0)
	player.attenuation = source.get("attenuation", 1.2)
	var path: String = source.get("path", "")
	if path != "" and ResourceLoader.exists(path):
		player.stream = load(path)
	add_child(player)
	return player

func _play_next_one_shot() -> void:
	if one_shot_players.is_empty():
		return
	var player: AudioStreamPlayer2D = one_shot_players[one_shot_index % one_shot_players.size()]
	one_shot_index += 1
	if player.stream == null:
		return
	player.pitch_scale = 0.94 + float(one_shot_index % 5) * 0.03
	player.play()
