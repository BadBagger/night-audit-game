extends Node2D

var player: CharacterBody2D
var dialogue: DialogueBoxUI
var board: DeductionBoardUI
var reyes: StoryNPC
var frank: StoryNPC
var mick_body: AnimatedCharacter2D
var foreground_occluder: Sprite2D
var occlusion_controller: Pier9OcclusionController
var atmosphere: Node2D
var set_dressing_root: Node2D

const CLUE_DEFS = [
	{"id": "spatter", "tag": "cause_location_mismatch", "label": "Arterial spatter, low, wrong wall",
	 "examine": "The blood pattern is low against the far wall. Wrong angle for someone standing here.",
	 "audio": "res://vo/chapter1/D-004.mp3",
	 "pos": Vector2(520, 410)},
	{"id": "receipt", "tag": "timeline_marker", "label": "Receipt, soaked but legible",
	 "examine": "Rain-soaked, but the ink held. It wasn't out here long before the rain started.",
	 "audio": "res://vo/chapter1/D-005.mp3",
	 "pos": Vector2(690, 370)},
	{"id": "ropeburn", "tag": "staging_evidence", "label": "Rope burn on the tie-down",
	 "examine": "A burn mark on the tie-down. Nothing here should have had rope on it.",
	 "audio": "res://vo/chapter1/D-006.mp3",
	 "pos": Vector2(425, 515)},
	{"id": "cup", "tag": "irrelevant", "label": "Discarded coffee cup",
	 "examine": "Just a cup. Doesn't connect to anything.",
	 "audio": "res://vo/chapter1/D-007.mp3",
	 "pos": Vector2(1100, 500)},
	{"id": "footprint", "tag": "irrelevant", "label": "Smudged footprint",
	 "examine": "Too smeared by the rain to mean anything on its own.",
	 "audio": "res://vo/chapter1/D-008.mp3",
	 "pos": Vector2(550, 700)},
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
	background.texture = preload("res://art/backgrounds/pier9_ch1_background_no_foreground_occluder.png")
	background.position = Vector2(1280, 720)
	background.z_index = -100
	add_child(background)

	foreground_occluder = Sprite2D.new()
	foreground_occluder.texture = preload("res://art/backgrounds/pier9_ch1_foreground_occluder_layer.png")
	foreground_occluder.position = Vector2(1280, 720)
	foreground_occluder.z_index = 40
	add_child(foreground_occluder)

func _build_ambience() -> void:
	for entry in [
		{"path": "res://sfx/ambience/dock_ambience_night_v01.ogg", "volume_db": -10.0},
		{"path": "res://sfx/ambience/rain_loop_v01.ogg", "volume_db": -6.0},
	]:
		if not ResourceLoader.exists(entry["path"]):
			continue
		var stream: AudioStream = load(entry["path"])
		if stream is AudioStreamOggVorbis:
			stream.loop = true
		var loop_player := AudioStreamPlayer.new()
		loop_player.stream = stream
		loop_player.volume_db = entry["volume_db"]
		add_child(loop_player)
		loop_player.play()

func _build_scene_art() -> void:
	set_dressing_root = Node2D.new()
	set_dressing_root.name = "Chapter1SetDressing"
	add_child(set_dressing_root)

	_add_set_piece("dock_edge_harbor", "dock_edge", Vector2(1500, 1088), Vector2(1120, 96), Color(0.04, 0.052, 0.06, 0.92), Color(0.42, 0.52, 0.56, 0.62), -5)
	_add_set_piece("container_office_clutter", "office_clutter", Vector2(630, 350), Vector2(280, 110), Color(0.12, 0.08, 0.05, 0.82), Color(0.84, 0.56, 0.28, 0.7), 3)
	_add_reusable_prop("work_lamp_container", "res://art/reusable/props/portable_dock_lamp/portable_dock_lamp_trim.png", Vector2(730, 330), Vector2(0.11, 0.11), 5)
	_add_reusable_prop("crime_scene_tape_left", "res://art/reusable/props/straight_hazard_tape/straight_hazard_tape_trim.png", Vector2(558, 624), Vector2(0.38, 0.04), 8, false, -2.5)
	_add_reusable_prop("crime_scene_tape_right", "res://art/reusable/props/straight_hazard_tape/straight_hazard_tape_trim.png", Vector2(890, 655), Vector2(0.44, 0.04), 8, false, 2.0)
	_add_set_piece("security_barrier_gate", "barrier", Vector2(1135, 685), Vector2(230, 42), Color(0.12, 0.13, 0.14, 0.9), Color(0.92, 0.58, 0.18, 0.82), 8)
	_add_set_piece("police_barrier_car_area", "barrier", Vector2(1430, 850), Vector2(270, 46), Color(0.12, 0.13, 0.14, 0.9), Color(0.3, 0.58, 0.96, 0.55), 8)
	_add_reusable_prop("crate_stack_near_gate", "res://art/reusable/props/wet_wooden_crate/wet_wooden_crate_trim.png", Vector2(1215, 575), Vector2(0.11, 0.11), 4)
	_add_reusable_prop("crate_stack_container_shadow", "res://art/reusable/props/wet_wooden_crate/wet_wooden_crate_trim.png", Vector2(900, 492), Vector2(0.09, 0.09), 4, true)
	_add_reusable_prop("barrel_cluster_gate", "res://art/reusable/props/rusty_oil_drum/rusty_oil_drum_trim.png", Vector2(1330, 610), Vector2(0.08, 0.08), 4)
	_add_reusable_prop("barrel_near_harbor", "res://art/reusable/props/rusty_oil_drum/rusty_oil_drum_trim.png", Vector2(1640, 948), Vector2(0.09, 0.09), 6, true)
	_add_reusable_prop("rope_coil_tiedown", "res://art/reusable/props/coiled_rope/coiled_rope_trim.png", Vector2(424, 536), Vector2(0.07, 0.07), 5)
	_add_reusable_prop("rope_coil_harbor", "res://art/reusable/props/coiled_rope/coiled_rope_trim.png", Vector2(1775, 980), Vector2(0.09, 0.09), 6, true)
	_add_reusable_prop("evidence_marker_spatter", "res://art/reusable/props/evidence_marker_card/evidence_marker_card_trim.png", Vector2(570, 428), Vector2(0.03, 0.03), 7, false, -8.0)
	_add_reusable_prop("evidence_marker_receipt", "res://art/reusable/props/evidence_marker_card/evidence_marker_card_trim.png", Vector2(721, 386), Vector2(0.03, 0.03), 7, true, 6.0)
	_add_reusable_prop("evidence_marker_phone", "res://art/reusable/props/evidence_marker_card/evidence_marker_card_trim.png", Vector2(645, 456), Vector2(0.027, 0.027), 7, false, 12.0)

	atmosphere = preload("res://scripts/Chapter1Atmosphere.gd").new()
	atmosphere.name = "Chapter1RainAndLighting"
	add_child(atmosphere)
	atmosphere.configure(
		[
			{"pos": Vector2(552, 700), "radius": Vector2(170, 34), "color": Color(0.46, 0.58, 0.62, 0.18)},
			{"pos": Vector2(860, 820), "radius": Vector2(230, 42), "color": Color(0.32, 0.48, 0.58, 0.16)},
			{"pos": Vector2(1510, 920), "radius": Vector2(260, 46), "color": Color(0.26, 0.42, 0.52, 0.18)},
			{"pos": Vector2(1110, 570), "radius": Vector2(135, 24), "color": Color(0.5, 0.58, 0.6, 0.12)},
		],
		[
			{"pos": Vector2(705, 360), "radius": 260.0, "color": Color(1.0, 0.62, 0.24, 0.12)},
			{"pos": Vector2(1410, 815), "radius": 240.0, "color": Color(0.24, 0.48, 1.0, 0.08)},
			{"pos": Vector2(1660, 1040), "radius": 220.0, "color": Color(0.36, 0.78, 0.9, 0.07)},
		]
	)

func _add_set_piece(piece_name: String, kind: String, pos: Vector2, piece_size: Vector2, color: Color, accent: Color, z: int) -> Node2D:
	var piece: Node2D = preload("res://scripts/Chapter1SetPiece.gd").new()
	piece.name = piece_name
	piece.position = pos
	piece.z_index = z
	piece.configure(kind, piece_size, color, accent)
	set_dressing_root.add_child(piece)
	return piece

func _add_reusable_prop(piece_name: String, asset_path: String, pos: Vector2, sprite_scale: Vector2, z: int, flip_sprite: bool = false, rotation_deg: float = 0.0) -> Sprite2D:
	var prop: Sprite2D = preload("res://scripts/ReusableProp2D.gd").new()
	prop.name = piece_name
	prop.position = pos
	prop.z_index = z
	prop.configure(asset_path, sprite_scale, flip_sprite, rotation_deg)
	set_dressing_root.add_child(prop)
	return prop

func _build_player() -> void:
	player = preload("res://scripts/Player.gd").new()
	player.position = Vector2(652, 758)
	# Handoff's rect (250,480)-(2000,1040) leaves the spatter/receipt clues
	# (y=410/370) unreachably above the top edge, so this is widened to
	# actually cover every marker in GODOT_INTEGRATION_HANDOFF.md with
	# margin for the player's 40px interact radius; retune once Dana is
	# actually visible on the plate.
	player.movement_bounds = Rect2(Vector2(300, 320), Vector2(1650, 720))
	player.z_index = 10
	player.footstep_sound = load("res://sfx/foley/footstep_wood_dock_v01.ogg") if ResourceLoader.exists("res://sfx/foley/footstep_wood_dock_v01.ogg") else null
	add_child(player)
	player.set_character_visual(_make_character_visual(
		"res://art/characters/chapter1/dana",
		{"idle": {"fps": 1.0}, "walk": {"fps": 10.0}, "talk": {"fps": 6.0}, "interact": {"fps": 8.0, "loop": false}},
		0.64,
		Vector2(0, -76)
	))

	var cam := Camera2D.new()
	cam.zoom = Vector2(1.0, 1.0)
	cam.position_smoothing_enabled = true
	cam.limit_left = 0
	cam.limit_top = 0
	cam.limit_right = 2560
	cam.limit_bottom = 1440
	cam.enabled = true
	player.add_child(cam)

func _build_body() -> void:
	mick_body = _make_character_visual(
		"res://art/characters/chapter1/mick_body",
		{"idle": {"fps": 1.0}},
		0.88,
		Vector2(0, -48)
	)
	mick_body.position = Vector2(610, 452)
	mick_body.z_index = 4
	add_child(mick_body)

func _build_npc() -> void:
	reyes = preload("res://scripts/StoryNPC.gd").new()
	reyes.position = Vector2(860, 842)
	reyes.z_index = 10
	reyes.npc_name = "REYES"
	add_child(reyes)
	reyes.set_character_visual(_make_character_visual(
		"res://art/characters/chapter1/reyes",
		{"idle": {"fps": 1.0}, "walk": {"fps": 8.0}, "talk": {"fps": 5.0}},
		0.66,
		Vector2(0, -76)
	))
	reyes.interacted.connect(_on_reyes_interact)

	frank = preload("res://scripts/StoryNPC.gd").new()
	frank.position = Vector2(1260, 918)
	frank.z_index = 10
	frank.npc_name = "FRANK"
	frank.interact_enabled = false
	add_child(frank)
	frank.set_character_visual(_make_character_visual(
		"res://art/characters/chapter1/frank",
		{"idle": {"fps": 1.0}, "walk": {"fps": 7.0}, "talk": {"fps": 4.0}},
		0.66,
		Vector2(0, -76)
	))

func _build_occlusion() -> void:
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
		c.position = def["pos"]
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
