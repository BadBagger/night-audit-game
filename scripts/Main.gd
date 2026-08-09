extends Node2D

var player: CharacterBody2D
var dialogue: DialogueBoxUI
var board: DeductionBoardUI
var reyes: StoryNPC
var frank: StoryNPC
var mick_body: Node2D
var foreground_occluder: Sprite2D
var occlusion_controller: Pier9OcclusionController
var atmosphere: Node2D
var foreground_atmosphere: Node2D
var world_audio: Node2D
var set_dressing_root: Node2D

const CLUE_DEFS = [
	{"id": "spatter", "tag": "cause_location_mismatch", "label": "Arterial spatter, low, wrong wall",
	 "examine": "The blood pattern is low against the far wall. Wrong angle for someone standing here.",
	 "audio": "res://vo/chapter1/D-004.mp3",
	 "sfx": "res://sfx/foley/paper_rustle_v01.ogg",
	 "pos": Vector2(445, 520)},
	{"id": "receipt", "tag": "timeline_marker", "label": "Receipt, soaked but legible",
	 "examine": "Rain-soaked, but the ink held. It wasn't out here long before the rain started.",
	 "audio": "res://vo/chapter1/D-005.mp3",
	 "sfx": "res://sfx/foley/paper_rustle_v01.ogg",
	 "pos": Vector2(595, 500)},
	{"id": "ropeburn", "tag": "staging_evidence", "label": "Rope burn on the tie-down",
	 "examine": "A burn mark on the tie-down. Nothing here should have had rope on it.",
	 "audio": "res://vo/chapter1/D-006.mp3",
	 "sfx": "res://sfx/foley/gate_creak_v01.ogg",
	 "pos": Vector2(245, 650)},
	{"id": "cup", "tag": "irrelevant", "label": "Discarded coffee cup",
	 "examine": "Just a cup. Doesn't connect to anything.",
	 "audio": "res://vo/chapter1/D-007.mp3",
	 "sfx": "res://sfx/foley/footstep_concrete_wet_v01.ogg",
	 "pos": Vector2(585, 460)},
	{"id": "footprint", "tag": "irrelevant", "label": "Smudged footprint",
	 "examine": "Too smeared by the rain to mean anything on its own.",
	 "audio": "res://vo/chapter1/D-008.mp3",
	 "sfx": "res://sfx/foley/footstep_wood_dock_v01.ogg",
	 "pos": Vector2(840, 620)},
]

const BOARD_SLOTS = [
	{"tag": "cause_location_mismatch", "label": "Cause / location mismatch"},
	{"tag": "timeline_marker", "label": "Timeline marker"},
	{"tag": "staging_evidence", "label": "Staging evidence"},
]

func _ready() -> void:
	_build_environment()
	_build_ambience()
	_build_scene_art()
	_build_player()
	_build_body()
	_build_npc()
	_build_occlusion()
	_build_clues()
	_build_ui()

	dialogue.line_started.connect(_on_dialogue_line_started)
	dialogue.advanced.connect(_on_dialogue_finished)
	dialogue.play([
		{"speaker": "DANA", "text": "Mick.", "audio": "res://vo/chapter1/D-001.mp3"},
		{"speaker": "DANA", "text": "You still tie them like that."},
		{"speaker": "", "text": "Sirens start somewhere beyond the rain. Pier 9 snaps into focus."},
		{"speaker": "DANA", "text": "He's in there. Pier 9. I got here before anyone else did."},
		{"speaker": "", "text": "(Walk with WASD or the arrow keys. Press E near something to examine it.)"},
	])

func _build_environment() -> void:
	var background := Sprite2D.new()
	background.texture = load("res://art/backgrounds/pier9_ch1_background_v2.png")
	background.position = Vector2(840, 472.5)
	background.z_index = -100
	add_child(background)

	foreground_occluder = null

func _build_ambience() -> void:
	world_audio = preload("res://scripts/Chapter1WorldAudio.gd").new()
	world_audio.name = "Chapter1WorldAudio"
	add_child(world_audio)
	world_audio.configure(
		[
			{"name": "RainOnContainers", "path": "res://sfx/ambience/rain_loop_v01.ogg", "pos": Vector2(760, 420), "volume_db": -5.5, "max_distance": 1800.0},
			{"name": "HarborAir", "path": "res://sfx/ambience/dock_ambience_night_v01.ogg", "pos": Vector2(1450, 980), "volume_db": -10.0, "max_distance": 2200.0},
			{"name": "CallowayEngineMass", "path": "res://sfx/ambience/boat_engine_idle_v01.ogg", "pos": Vector2(2060, 520), "volume_db": -18.0, "max_distance": 1600.0},
			{"name": "DistantHarborHorn", "path": "res://sfx/ambience/foghorn_distant_v01.ogg", "pos": Vector2(2180, 360), "volume_db": -20.0, "max_distance": 2000.0},
			{"name": "ContainerRoomTone", "path": "res://sfx/ambience/warehouse_room_tone_v01.ogg", "pos": Vector2(650, 360), "volume_db": -17.0, "max_distance": 900.0},
		],
		[
			{"name": "PoliceRadioBursts", "path": "res://sfx/mechanical/radio_static_burst_v01.ogg", "pos": Vector2(1460, 850), "volume_db": -17.0, "max_distance": 900.0},
			{"name": "BarrierMetalCreak", "path": "res://sfx/foley/gate_creak_v01.ogg", "pos": Vector2(1142, 692), "volume_db": -18.0, "max_distance": 760.0},
			{"name": "DistantAlarmWash", "path": "res://sfx/tension/alarm_klaxon_distant_v01.ogg", "pos": Vector2(1980, 610), "volume_db": -24.0, "max_distance": 1200.0},
			{"name": "OfficePaperFlutter", "path": "res://sfx/foley/paper_rustle_v01.ogg", "pos": Vector2(690, 370), "volume_db": -22.0, "max_distance": 520.0},
			{"name": "ContainerDoorGroan", "path": "res://sfx/foley/door_creak_v01.ogg", "pos": Vector2(785, 430), "volume_db": -23.0, "max_distance": 620.0},
			{"name": "MicksPhoneBuzz", "path": "res://sfx/mechanical/phone_buzz_v01.ogg", "pos": Vector2(645, 456), "volume_db": -25.0, "max_distance": 460.0},
		]
	)

func _build_scene_art() -> void:
	set_dressing_root = Node2D.new()
	set_dressing_root.name = "Chapter1SetDressing"
	add_child(set_dressing_root)

	atmosphere = preload("res://scripts/Chapter1Atmosphere.gd").new()
	atmosphere.name = "Chapter1BackgroundRain"
	atmosphere.scene_size = Vector2(1680, 945)
	atmosphere.rain_lines = 95
	atmosphere.foreground_rain_lines = 32
	atmosphere.splash_count = 24
	atmosphere.set_layer_mode("foreground", 35)
	add_child(atmosphere)
	atmosphere.configure(
		[],
		[]
	)
	foreground_atmosphere = atmosphere

func _add_reusable_prop(piece_name: String, asset_path: String, pos: Vector2, sprite_scale: Vector2, z: int, flip_sprite: bool = false, rotation_deg: float = 0.0, tint: Color = Color.WHITE) -> Sprite2D:
	var prop: Sprite2D = preload("res://scripts/ReusableProp2D.gd").new()
	prop.name = piece_name
	prop.position = pos
	prop.z_index = z
	prop.modulate = tint
	prop.configure(asset_path, sprite_scale, flip_sprite, rotation_deg)
	set_dressing_root.add_child(prop)
	return prop

func _add_reusable_decal(piece_name: String, asset_path: String, pos: Vector2, sprite_scale: Vector2, z: int, rotation_deg: float = 0.0, tint: Color = Color.WHITE) -> Sprite2D:
	var decal := Sprite2D.new()
	decal.name = piece_name
	decal.texture = load(asset_path)
	decal.position = pos
	decal.scale = sprite_scale
	decal.rotation_degrees = rotation_deg
	decal.modulate = tint
	decal.z_index = z
	decal.add_to_group("reusable_decal_sprite")
	set_dressing_root.add_child(decal)
	return decal

func _build_player() -> void:
	player = preload("res://scripts/Player.gd").new()
	player.position = Vector2(760, 650)
	player.movement_bounds = Rect2(Vector2(120, 205), Vector2(1390, 650))
	player.walkable_areas = [
		Rect2(Vector2(140, 350), Vector2(1180, 410)),
		Rect2(Vector2(360, 205), Vector2(360, 250)),
		Rect2(Vector2(700, 305), Vector2(660, 280)),
		Rect2(Vector2(1030, 560), Vector2(470, 250)),
	]
	player.blocked_areas = [
		Rect2(Vector2(300, 70), Vector2(420, 205)),
		Rect2(Vector2(120, 70), Vector2(210, 260)),
		Rect2(Vector2(720, 45), Vector2(770, 245)),
		Rect2(Vector2(320, 470), Vector2(210, 95)),
		Rect2(Vector2(40, 585), Vector2(170, 180)),
		Rect2(Vector2(1320, 185), Vector2(255, 245)),
		Rect2(Vector2(1115, 720), Vector2(560, 225)),
		Rect2(Vector2(870, 770), Vector2(230, 110)),
	]
	player.z_index = 10
	player.footstep_sound = load("res://sfx/foley/footstep_wood_dock_v01.ogg") if ResourceLoader.exists("res://sfx/foley/footstep_wood_dock_v01.ogg") else null
	add_child(player)
	player.set_character_visual(_make_character_visual(
		"res://art/characters/chapter1/dana",
		{"idle": {"source": "talk", "fps": 1.4}, "walk": {"fps": 10.0}, "talk": {"fps": 6.0}, "interact": {"fps": 8.0, "loop": false}},
		0.56,
		Vector2(0, -76)
	))

	var cam := Camera2D.new()
	cam.zoom = Vector2(1.28, 1.28)
	cam.position_smoothing_enabled = true
	cam.limit_left = 0
	cam.limit_top = 0
	cam.limit_right = 1680
	cam.limit_bottom = 945
	cam.enabled = true
	player.add_child(cam)

func _build_body() -> void:
	mick_body = Node2D.new()
	mick_body.name = "MickBodyBakedIntoBackground"
	mick_body.position = Vector2(430, 520)
	add_child(mick_body)

func _build_npc() -> void:
	reyes = preload("res://scripts/StoryNPC.gd").new()
	reyes.position = Vector2(1185, 415)
	reyes.z_index = 10
	reyes.npc_name = "REYES"
	add_child(reyes)
	reyes.set_character_visual(_make_character_visual(
		"res://art/characters/chapter1/reyes",
		{"idle": {"source": "talk", "fps": 1.2}, "walk": {"fps": 8.0}, "talk": {"fps": 5.0}},
		0.58,
		Vector2(0, -76)
	))
	reyes.interacted.connect(_on_reyes_interact)

	frank = preload("res://scripts/StoryNPC.gd").new()
	frank.position = Vector2(1015, 710)
	frank.z_index = 10
	frank.npc_name = "FRANK"
	frank.interact_enabled = false
	add_child(frank)
	frank.set_character_visual(_make_character_visual(
		"res://art/characters/chapter1/frank",
		{"idle": {"source": "talk", "fps": 1.0}, "walk": {"fps": 7.0}, "talk": {"fps": 4.0}},
		0.58,
		Vector2(0, -76)
	))

func _build_occlusion() -> void:
	if foreground_occluder == null:
		return
	occlusion_controller = preload("res://scripts/Pier9OcclusionController.gd").new()
	add_child(occlusion_controller)
	occlusion_controller.setup(
		player,
		foreground_occluder,
		preload("res://art/backgrounds/pier9_ch1_foreground_occluder_trigger_mask_pass01.png")
	)

func _build_clues() -> void:
	for def in CLUE_DEFS:
		var c = preload("res://scripts/ClueObject.gd").new()
		c.clue_id = def["id"]
		c.tag = def["tag"]
		c.label = def["label"]
		c.examine_text = def["examine"]
		c.examine_audio = def["audio"]
		c.examine_sfx = def.get("sfx", "")
		c.position = def["pos"]
		c.show_marker = false
		if def["tag"] == "irrelevant":
			c.color = Color(0.45, 0.47, 0.5)
		add_child(c)

func _build_ui() -> void:
	dialogue = preload("res://scripts/DialogueBox.gd").new()
	add_child(dialogue)

	board = preload("res://scripts/DeductionBoard.gd").new()
	add_child(board)
	board.solved.connect(_on_board_solved)

	GameState.show_message.connect(_on_show_message)

	var hud := CanvasLayer.new()
	hud.layer = 5
	add_child(hud)
	var hint := Label.new()
	hint.text = "WASD / Arrows: move    E: interact    Space: advance dialogue"
	hint.position = Vector2(16, 8)
	hint.add_theme_font_size_override("font_size", 12)
	hint.add_theme_color_override("font_color", Color(0.6, 0.62, 0.68))
	hud.add_child(hint)

func _make_character_visual(root_path: String, animations: Dictionary, scale: float, offset: Vector2) -> AnimatedCharacter2D:
	var visual: AnimatedCharacter2D = preload("res://scripts/AnimatedCharacter2D.gd").new()
	visual.visual_scale = scale
	visual.visual_offset = offset
	visual.setup_from_folders(root_path, animations)
	return visual

func _on_dialogue_line_started(speaker: String) -> void:
	var dana_visual := player.get("character_visual") as AnimatedCharacter2D if player else null
	if dana_visual:
		if speaker == "DANA":
			dana_visual.play_talk()
		else:
			dana_visual.play_idle()
	if reyes:
		if speaker == "REYES":
			reyes.play_talk()
		else:
			reyes.play_idle()
	if frank:
		frank.play_idle()

func _on_dialogue_finished() -> void:
	var dana_visual := player.get("character_visual") as AnimatedCharacter2D if player else null
	if dana_visual:
		dana_visual.play_idle()
	if reyes:
		reyes.play_idle()
	if frank:
		frank.play_idle()

func _on_show_message(title: String, body: String, audio: String) -> void:
	if audio != "":
		dialogue.play([{"speaker": title, "text": body, "audio": audio}])
	else:
		dialogue.play([{"speaker": title, "text": body}])

func _on_reyes_interact() -> void:
	if not GameState.get_flag("intro_done", false):
		GameState.set_flag("intro_done", true)
		dialogue.play([
			{"speaker": "REYES", "text": "You beat us here. Course you did.", "audio": "res://vo/chapter1/R-001.mp3"},
			{"speaker": "DANA", "text": "I got a call.", "audio": "res://vo/chapter1/D-002.mp3"},
			{"speaker": "REYES", "text": "From who.", "audio": "res://vo/chapter1/R-002.mp3"},
			{"speaker": "DANA", "text": "Filtered voice. Blocked number.", "audio": "res://vo/chapter1/D-003.mp3"},
			{"speaker": "REYES", "text": "Ninety seconds, Dana. Then you're outside that tape. Look around if you have to. Fast.", "audio": "res://vo/chapter1/R-003.mp3"},
		])
	elif not GameState.has_all_required_clues():
		dialogue.play([{"speaker": "REYES", "text": "Whatever you're going to find, find it quick.", "audio": "res://vo/chapter1/R-004.mp3"}])
	elif not GameState.get_flag("board_solved", false):
		dialogue.play([{"speaker": "REYES", "text": "You've got that look. Walk me through what you've got.", "audio": "res://vo/chapter1/R-005.mp3"}])
		dialogue.advanced.connect(_open_board_once, CONNECT_ONE_SHOT)
	else:
		_start_phone_choice()

func _open_board_once() -> void:
	board.open(BOARD_SLOTS)

func _on_board_solved() -> void:
	GameState.set_flag("board_solved", true)
	board.visible = false
	dialogue.play([
		{"speaker": "DANA", "text": "He wasn't killed here. He was moved.", "audio": "res://vo/chapter1/D-009.mp3"},
		{"speaker": "REYES", "text": "...Yeah. That's what I've got too. Don't say it again where anyone else can hear you say it that fast.", "audio": "res://vo/chapter1/R-006.mp3"},
	])

func _start_phone_choice() -> void:
	dialogue.play([
		{"speaker": "", "text": "Mick's phone is half under his jacket, screen cracked. Reyes is a few feet away, giving you exactly enough room not to be watching.",
		 "choices": [
			{"label": "Pocket the phone", "id": "pocket"},
			{"label": "Leave it for evidence", "id": "leave"},
		 ]},
	])
	dialogue.choice_made.connect(_on_phone_choice, CONNECT_ONE_SHOT)

func _on_phone_choice(id: String) -> void:
	if id == "pocket":
		GameState.set_flag("phone_pocketed", true)
		GameState.set_flag("debt_reyes_unspoken", true)
		dialogue.play([
			{"speaker": "DANA", "text": "(You pocket the phone. Reyes doesn't look at your hand. That means he saw.)"},
			{"speaker": "REYES", "text": "Twenty-four hours, Dana. After that I have to put your name in a file, and I can't take it back out.", "audio": "res://vo/chapter1/R-007.mp3"},
		])
	else:
		GameState.ledger["trust"]["reyes"] += 1
		dialogue.play([
			{"speaker": "DANA", "text": "(You leave it exactly where you found it.)"},
			{"speaker": "REYES", "text": "Appreciate that. Twenty-four hours. Go talk to whoever he still talked to.", "audio": "res://vo/chapter1/R-008.mp3"},
		])
	dialogue.advanced.connect(_on_phone_lines_done, CONNECT_ONE_SHOT)

func _on_phone_lines_done() -> void:
	GameState.set_flag("chapter1_complete", true)
	_show_chapter_summary()

func _show_chapter_summary() -> void:
	var phone_status := "pocketed" if GameState.get_flag("phone_pocketed", false) else "left as evidence"
	var summary := "CHAPTER I COMPLETE  —  Ledger: Reyes trust %s, phone %s" % [
		GameState.ledger["trust"]["reyes"], phone_status
	]
	dialogue.play([{"speaker": "", "text": summary}])
	dialogue.advanced.connect(_go_to_chapter2, CONNECT_ONE_SHOT)

func _go_to_chapter2() -> void:
	get_tree().change_scene_to_file("res://scenes/Chapter2.tscn")
