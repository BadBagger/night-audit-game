extends Node2D

var player: CharacterBody2D
var dialogue: DialogueBoxUI
var board: DeductionBoardUI
var reyes: StoryNPC
var frank: StoryNPC
var mick_body: Sprite2D
var foreground_occluder: Sprite2D
var occlusion_controller: Pier9OcclusionController
var atmosphere: Node2D
var world_audio: Node2D
var set_dressing_root: Node2D

const CLUE_DEFS = [
	{"id": "spatter", "tag": "cause_location_mismatch", "label": "Arterial spatter, low, wrong wall",
	 "examine": "The blood pattern is low against the far wall. Wrong angle for someone standing here.",
	 "audio": "res://vo/chapter1/D-004.mp3",
	 "sfx": "res://sfx/foley/paper_rustle_v01.ogg",
	 "pos": Vector2(520, 410)},
	{"id": "receipt", "tag": "timeline_marker", "label": "Receipt, soaked but legible",
	 "examine": "Rain-soaked, but the ink held. It wasn't out here long before the rain started.",
	 "audio": "res://vo/chapter1/D-005.mp3",
	 "sfx": "res://sfx/foley/paper_rustle_v01.ogg",
	 "pos": Vector2(690, 370)},
	{"id": "ropeburn", "tag": "staging_evidence", "label": "Rope burn on the tie-down",
	 "examine": "A burn mark on the tie-down. Nothing here should have had rope on it.",
	 "audio": "res://vo/chapter1/D-006.mp3",
	 "sfx": "res://sfx/foley/gate_creak_v01.ogg",
	 "pos": Vector2(425, 515)},
	{"id": "cup", "tag": "irrelevant", "label": "Discarded coffee cup",
	 "examine": "Just a cup. Doesn't connect to anything.",
	 "audio": "res://vo/chapter1/D-007.mp3",
	 "sfx": "res://sfx/foley/footstep_concrete_wet_v01.ogg",
	 "pos": Vector2(1100, 500)},
	{"id": "footprint", "tag": "irrelevant", "label": "Smudged footprint",
	 "examine": "Too smeared by the rain to mean anything on its own.",
	 "audio": "res://vo/chapter1/D-008.mp3",
	 "sfx": "res://sfx/foley/footstep_wood_dock_v01.ogg",
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
	world_audio = preload("res://scripts/Chapter1WorldAudio.gd").new()
	world_audio.name = "Chapter1WorldAudio"
	add_child(world_audio)
	world_audio.configure(
		[
			{"name": "RainOnContainers", "path": "res://sfx/ambience/rain_loop_v01.ogg", "pos": Vector2(760, 420), "volume_db": -5.5, "max_distance": 1800.0},
			{"name": "HarborAir", "path": "res://sfx/ambience/dock_ambience_night_v01.ogg", "pos": Vector2(1450, 980), "volume_db": -10.0, "max_distance": 2200.0},
			{"name": "CallowayEngineMass", "path": "res://sfx/ambience/boat_engine_idle_v01.ogg", "pos": Vector2(2060, 520), "volume_db": -18.0, "max_distance": 1600.0},
			{"name": "DistantHarborHorn", "path": "res://sfx/ambience/foghorn_distant_v01.ogg", "pos": Vector2(2180, 360), "volume_db": -20.0, "max_distance": 2000.0},
		],
		[
			{"name": "PoliceRadioBursts", "path": "res://sfx/mechanical/radio_static_burst_v01.ogg", "pos": Vector2(1460, 850), "volume_db": -17.0, "max_distance": 900.0},
			{"name": "BarrierMetalCreak", "path": "res://sfx/foley/gate_creak_v01.ogg", "pos": Vector2(1142, 692), "volume_db": -18.0, "max_distance": 760.0},
			{"name": "DistantAlarmWash", "path": "res://sfx/tension/alarm_klaxon_distant_v01.ogg", "pos": Vector2(1980, 610), "volume_db": -24.0, "max_distance": 1200.0},
		]
	)

func _build_scene_art() -> void:
	set_dressing_root = Node2D.new()
	set_dressing_root.name = "Chapter1SetDressing"
	add_child(set_dressing_root)

	_add_reusable_prop("dock_edge_harbor", "res://art/reusable/props/long_pier_dock_edge_strip/long_pier_dock_edge_strip_trim.png", Vector2(1500, 1088), Vector2(1.65, 0.2), -5, false, 0.0, Color(0.72, 0.78, 0.82, 0.78))
	_add_reusable_prop("container_office_clutter", "res://art/reusable/props/open_container_office_clutter/open_container_office_clutter_trim.png", Vector2(610, 354), Vector2(0.16, 0.16), 3, false, 0.0, Color(0.86, 0.82, 0.76, 0.82))
	_add_reusable_prop("work_lamp_container", "res://art/reusable/props/portable_dock_lamp/portable_dock_lamp_trim.png", Vector2(710, 336), Vector2(0.07, 0.07), 5, false, 0.0, Color(1.0, 0.88, 0.72, 0.8))
	_add_reusable_prop("crime_scene_tape_left", "res://art/reusable/props/straight_hazard_tape/straight_hazard_tape_trim.png", Vector2(552, 620), Vector2(0.24, 0.018), 6, false, -2.5, Color(0.95, 0.9, 0.7, 0.7))
	_add_reusable_prop("crime_scene_tape_right", "res://art/reusable/props/straight_hazard_tape/straight_hazard_tape_trim.png", Vector2(888, 655), Vector2(0.28, 0.018), 6, false, 2.0, Color(0.95, 0.9, 0.7, 0.7))
	_add_reusable_prop("security_barrier_gate", "res://art/reusable/props/dock_security_gate/dock_security_gate_trim.png", Vector2(1142, 692), Vector2(0.12, 0.12), 6, false, 0.0, Color(0.78, 0.82, 0.84, 0.82))
	_add_reusable_prop("police_barrier_car_area", "res://art/reusable/props/portable_police_barricade/portable_police_barricade_trim.png", Vector2(1430, 850), Vector2(0.12, 0.12), 6, true, -4.0, Color(0.82, 0.84, 0.84, 0.82))
	_add_reusable_prop("crate_stack_near_gate", "res://art/reusable/props/wet_wooden_crate/wet_wooden_crate_trim.png", Vector2(1215, 575), Vector2(0.065, 0.065), 4, false, 0.0, Color(0.78, 0.78, 0.74, 0.82))
	_add_reusable_prop("crate_stack_container_shadow", "res://art/reusable/props/wet_wooden_crate/wet_wooden_crate_trim.png", Vector2(900, 492), Vector2(0.055, 0.055), 4, true, 0.0, Color(0.72, 0.72, 0.7, 0.78))
	_add_reusable_prop("barrel_cluster_gate", "res://art/reusable/props/rusty_oil_drum/rusty_oil_drum_trim.png", Vector2(1330, 610), Vector2(0.045, 0.045), 4, false, 0.0, Color(0.68, 0.74, 0.8, 0.8))
	_add_reusable_prop("barrel_near_harbor", "res://art/reusable/props/rusty_oil_drum/rusty_oil_drum_trim.png", Vector2(1640, 948), Vector2(0.052, 0.052), 6, true, 0.0, Color(0.68, 0.74, 0.8, 0.8))
	_add_reusable_prop("rope_coil_tiedown", "res://art/reusable/props/coiled_rope/coiled_rope_trim.png", Vector2(424, 536), Vector2(0.045, 0.045), 5, false, 0.0, Color(0.88, 0.82, 0.7, 0.86))
	_add_reusable_prop("rope_coil_harbor", "res://art/reusable/props/coiled_rope/coiled_rope_trim.png", Vector2(1775, 980), Vector2(0.055, 0.055), 6, true, 0.0, Color(0.82, 0.78, 0.68, 0.84))
	_add_reusable_prop("ropeburn_tiedown_fixture", "res://art/reusable/props/harbor_tiedown_ropeburn_fixture/harbor_tiedown_ropeburn_fixture_trim.png", Vector2(430, 515), Vector2(0.052, 0.052), 4, false, 0.0, Color(0.72, 0.74, 0.76, 0.82))
	_add_reusable_prop("evidence_marker_spatter", "res://art/reusable/props/evidence_marker_card/evidence_marker_card_trim.png", Vector2(570, 428), Vector2(0.02, 0.02), 7, false, -8.0, Color(1.0, 0.92, 0.64, 0.86))
	_add_reusable_prop("evidence_marker_receipt", "res://art/reusable/props/evidence_marker_card/evidence_marker_card_trim.png", Vector2(721, 386), Vector2(0.02, 0.02), 7, true, 6.0, Color(1.0, 0.92, 0.64, 0.86))
	_add_reusable_prop("evidence_marker_phone", "res://art/reusable/props/evidence_marker_card/evidence_marker_card_trim.png", Vector2(645, 456), Vector2(0.018, 0.018), 7, false, 12.0, Color(1.0, 0.92, 0.64, 0.86))
	_add_reusable_prop("cracked_phone_evidence", "res://art/reusable/props/cracked_phone_evidence/cracked_phone_evidence_trim.png", Vector2(647, 459), Vector2(0.034, 0.034), 6, false, 12.0, Color(0.76, 0.84, 0.9, 0.84))
	_add_reusable_prop("receipt_wet_close_prop", "res://art/reusable/props/receipt_wet_close_prop/receipt_wet_close_prop_trim.png", Vector2(692, 371), Vector2(0.032, 0.032), 6, false, -7.0, Color(0.94, 0.9, 0.78, 0.84))
	_add_reusable_prop("ironbound_crate_office_left", "res://art/reusable/props/ironbound_crate/ironbound_crate_trim.png", Vector2(468, 468), Vector2(0.048, 0.048), 3, false, 0.0, Color(0.72, 0.74, 0.72, 0.78))
	_add_reusable_prop("ironbound_crate_gate_block", "res://art/reusable/props/ironbound_crate/ironbound_crate_trim.png", Vector2(1114, 642), Vector2(0.058, 0.058), 5, true, 0.0, Color(0.74, 0.76, 0.74, 0.8))
	_add_reusable_prop("wet_crate_police_stack_low", "res://art/reusable/props/wet_wooden_crate/wet_wooden_crate_trim.png", Vector2(1516, 790), Vector2(0.058, 0.058), 5, false, 0.0, Color(0.66, 0.7, 0.72, 0.78))
	_add_reusable_prop("wet_crate_police_stack_high", "res://art/reusable/props/wet_wooden_crate/wet_wooden_crate_trim.png", Vector2(1565, 742), Vector2(0.052, 0.052), 6, true, 0.0, Color(0.64, 0.68, 0.7, 0.78))
	_add_reusable_prop("barrel_row_left_shadow", "res://art/reusable/props/rusty_oil_drum/rusty_oil_drum_trim.png", Vector2(812, 635), Vector2(0.04, 0.04), 4, true, 0.0, Color(0.56, 0.62, 0.66, 0.72))
	_add_reusable_prop("barrel_row_left_lit", "res://art/reusable/props/rusty_oil_drum/rusty_oil_drum_trim.png", Vector2(770, 604), Vector2(0.038, 0.038), 4, false, 0.0, Color(0.76, 0.72, 0.64, 0.76))
	_add_reusable_prop("hand_plane_on_desk", "res://art/reusable/props/rusty_hand_plane/rusty_hand_plane_trim.png", Vector2(648, 360), Vector2(0.018, 0.018), 8, false, -8.0, Color(0.78, 0.74, 0.66, 0.9))
	_add_reusable_prop("tape_container_backline", "res://art/reusable/props/straight_hazard_tape/straight_hazard_tape_trim.png", Vector2(742, 516), Vector2(0.22, 0.016), 7, true, -1.5, Color(0.95, 0.86, 0.58, 0.62))
	_add_reusable_prop("dock_strip_inner_edge", "res://art/reusable/props/long_pier_dock_edge_strip/long_pier_dock_edge_strip_trim.png", Vector2(1010, 1018), Vector2(1.25, 0.14), -4, false, 0.0, Color(0.5, 0.58, 0.62, 0.46))
	_add_reusable_decal("blood_spatter_low_wall_a", "res://art/reusable/decals/blood_spatter/arterial_low_01.svg", Vector2(528, 395), Vector2(0.18, 0.18), 8, -6.0, Color(0.36, 0.03, 0.025, 0.72))
	_add_reusable_decal("blood_spatter_low_wall_b", "res://art/reusable/decals/blood_spatter/arterial_low_02.svg", Vector2(584, 418), Vector2(0.13, 0.13), 8, 7.0, Color(0.34, 0.025, 0.025, 0.62))
	_add_reusable_decal("drag_scuff_wetness_decal", "res://art/reusable/decals/drag_scuff_wetness_decal/a.png", Vector2(598, 492), Vector2(0.22, 0.12), 5, -9.0, Color(0.6, 0.72, 0.74, 0.32))

	atmosphere = preload("res://scripts/Chapter1Atmosphere.gd").new()
	atmosphere.name = "Chapter1RainAndLighting"
	add_child(atmosphere)
	atmosphere.configure(
		[
			{"pos": Vector2(552, 700), "radius": Vector2(170, 34), "color": Color(0.46, 0.58, 0.62, 0.18)},
			{"pos": Vector2(860, 820), "radius": Vector2(230, 42), "color": Color(0.32, 0.48, 0.58, 0.16)},
			{"pos": Vector2(1510, 920), "radius": Vector2(260, 46), "color": Color(0.26, 0.42, 0.52, 0.18)},
			{"pos": Vector2(1110, 570), "radius": Vector2(135, 24), "color": Color(0.5, 0.58, 0.6, 0.12)},
			{"pos": Vector2(505, 438), "radius": Vector2(140, 20), "color": Color(0.56, 0.55, 0.48, 0.13)},
			{"pos": Vector2(732, 420), "radius": Vector2(190, 28), "color": Color(0.8, 0.62, 0.34, 0.11)},
			{"pos": Vector2(1260, 660), "radius": Vector2(210, 34), "color": Color(0.24, 0.42, 0.54, 0.12)},
			{"pos": Vector2(1740, 990), "radius": Vector2(240, 38), "color": Color(0.32, 0.58, 0.66, 0.13)},
		],
		[
			{"pos": Vector2(705, 360), "radius": 260.0, "color": Color(1.0, 0.62, 0.24, 0.12)},
			{"pos": Vector2(1410, 815), "radius": 240.0, "color": Color(0.24, 0.48, 1.0, 0.08)},
			{"pos": Vector2(1660, 1040), "radius": 220.0, "color": Color(0.36, 0.78, 0.9, 0.07)},
			{"pos": Vector2(515, 430), "radius": 190.0, "color": Color(0.96, 0.72, 0.38, 0.08)},
			{"pos": Vector2(1120, 690), "radius": 180.0, "color": Color(0.45, 0.62, 0.72, 0.06)},
		]
	)

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
	player.position = Vector2(652, 758)
	# Handoff's rect (250,480)-(2000,1040) leaves the spatter/receipt clues
	# (y=410/370) unreachably above the top edge, so this is widened to
	# actually cover every marker in GODOT_INTEGRATION_HANDOFF.md with
	# margin for the player's 40px interact radius; retune once Dana is
	# actually visible on the plate.
	player.movement_bounds = Rect2(Vector2(300, 320), Vector2(1650, 720))
	player.walkable_areas = [
		Rect2(Vector2(360, 390), Vector2(550, 270)),
		Rect2(Vector2(420, 620), Vector2(650, 320)),
		Rect2(Vector2(760, 500), Vector2(700, 190)),
		Rect2(Vector2(820, 690), Vector2(630, 310)),
		Rect2(Vector2(1460, 850), Vector2(420, 170)),
	]
	player.blocked_areas = [
		Rect2(Vector2(520, 315), Vector2(230, 80)),
		Rect2(Vector2(910, 250), Vector2(990, 260)),
		Rect2(Vector2(1140, 570), Vector2(520, 300)),
		Rect2(Vector2(1515, 380), Vector2(360, 440)),
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
	cam.zoom = Vector2(1.0, 1.0)
	cam.position_smoothing_enabled = true
	cam.limit_left = 0
	cam.limit_top = 0
	cam.limit_right = 2560
	cam.limit_bottom = 1440
	cam.enabled = true
	player.add_child(cam)

func _build_body() -> void:
	mick_body = _add_reusable_prop(
		"mick_tarp_body",
		"res://art/reusable/props/mick_tarp_body/mick_tarp_body_trim.png",
		Vector2(590, 438),
		Vector2(0.18, 0.18),
		4,
		false,
		-3.0,
		Color(0.82, 0.84, 0.84, 0.86)
	)

func _build_npc() -> void:
	reyes = preload("res://scripts/StoryNPC.gd").new()
	reyes.position = Vector2(860, 842)
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
	frank.position = Vector2(1260, 918)
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
