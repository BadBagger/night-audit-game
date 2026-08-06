extends Node2D

var player: CharacterBody2D
var dialogue: DialogueBoxUI
var audit_board: AuditBoardUI
var voss: PatrolNPC
var ledger_prop: StoryNPC
var safe_prop: StoryNPC

func _ready() -> void:
	_build_environment()
	_build_player()
	_build_npcs()
	_build_ui()

	dialogue.line_started.connect(_on_dialogue_line_started)
	dialogue.advanced.connect(_on_dialogue_finished)
	dialogue.play([
		{"speaker": "DANA", "text": "Costigan's badge gets me as far as the crew corridor. After that I'm improvising.", "audio": "res://vo/chapter3/D-001.mp3"},
		{"speaker": "VOSS", "text": "New cleaning rotation, don't care whose idea it was, verify everyone against the manifest before they get past deck two.", "audio": "res://vo/chapter3/V-001.mp3"},
		{"speaker": "DANA", "text": "Verify against the manifest. Good thing I'm about to become very interested in manifests.", "audio": "res://vo/chapter3/D-002.mp3"},
	])

func _build_environment() -> void:
	var ground := Prop.new()
	ground.size = Vector2(1400, 900)
	ground.position = Vector2(700, 450)
	ground.color = Color(0.06, 0.07, 0.09)
	add_child(ground)

	var counting_room := Prop.new()
	counting_room.size = Vector2(320, 240)
	counting_room.position = Vector2(300, 320)
	counting_room.color = Color(0.14, 0.12, 0.09)
	counting_room.outline = Color(0.851, 0.522, 0.184, 0.5)
	add_child(counting_room)

	var crew_deck := Prop.new()
	crew_deck.size = Vector2(320, 240)
	crew_deck.position = Vector2(1100, 320)
	crew_deck.color = Color(0.09, 0.11, 0.15)
	crew_deck.outline = Color(0.4, 0.45, 0.55, 0.4)
	add_child(crew_deck)

func _build_player() -> void:
	player = preload("res://scripts/Player.gd").new()
	player.position = Vector2(300, 650)
	player.movement_bounds = Rect2(Vector2(120, 260), Vector2(1260, 480))
	add_child(player)
	player.set_character_visual(_make_character_visual(
		"res://art/characters/chapter3/dana",
		{"idle": {"fps": 1.0}, "walk": {"fps": 10.0}, "talk": {"fps": 6.0}, "interact": {"fps": 8.0, "loop": false}},
		0.64,
		Vector2(0, -76)
	))

	var cam := Camera2D.new()
	cam.zoom = Vector2(0.85, 0.85)
	cam.position_smoothing_enabled = true
	cam.enabled = true
	player.add_child(cam)

func _build_npcs() -> void:
	voss = preload("res://scripts/PatrolNPC.gd").new()
	voss.npc_name = "VOSS"
	voss.point_a = Vector2(300, 300)
	voss.point_b = Vector2(1100, 300)
	add_child(voss)
	voss.set_character_visual(_make_character_visual(
		"res://art/characters/chapter3/voss",
		{"idle": {"fps": 1.0}, "walk": {"fps": 8.0}, "talk": {"fps": 5.0}},
		0.66,
		Vector2(0, -76)
	))
	voss.interacted.connect(_on_voss_confrontation)
	voss.player_spotted.connect(_on_voss_confrontation)

	ledger_prop = preload("res://scripts/StoryNPC.gd").new()
	ledger_prop.npc_name = "LEDGER"
	ledger_prop.position = Vector2(240, 340)
	add_child(ledger_prop)
	ledger_prop.interacted.connect(_on_ledger_interact)

	safe_prop = preload("res://scripts/StoryNPC.gd").new()
	safe_prop.npc_name = "SAFE"
	safe_prop.position = Vector2(360, 340)
	add_child(safe_prop)
	safe_prop.interacted.connect(_on_safe_interact)

func _build_ui() -> void:
	dialogue = preload("res://scripts/DialogueBox.gd").new()
	add_child(dialogue)

	audit_board = preload("res://scripts/AuditBoard.gd").new()
	add_child(audit_board)
	audit_board.solved.connect(_on_audit_solved)

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
	if voss:
		if speaker == "VOSS":
			voss.play_talk()
		else:
			voss.play_idle()

func _on_dialogue_finished() -> void:
	var dana_visual := player.get("character_visual") as AnimatedCharacter2D if player else null
	if dana_visual:
		dana_visual.play_idle()
	if voss:
		voss.play_idle()

# ---------------------------------------------------------------- Ledger / Safe

func _on_ledger_interact() -> void:
	if GameState.get_flag("chapter3_retreat", false):
		return
	if GameState.get_flag("audit_solved", false):
		dialogue.play([{"speaker": "DANA", "text": "(Already been through this one.)"}])
		return
	var dana_visual := player.get("character_visual") as AnimatedCharacter2D if player else null
	if dana_visual:
		dana_visual.play_interact()
	audit_board.open()

func _on_audit_solved() -> void:
	if GameState.get_flag("audit_solved", false):
		return
	audit_board.visible = false
	GameState.set_flag("audit_solved", true)
	dialogue.play([
		{"speaker": "DANA", "text": "There it is. Not just a skim — a system. And Mick's initials are on two of these authorizations. He wasn't just funding Priya's strike. He was cooking these books himself.", "audio": "res://vo/chapter3/D-003.mp3"},
	])
	dialogue.advanced.connect(_check_success_ending, CONNECT_ONE_SHOT)

func _on_safe_interact() -> void:
	if GameState.get_flag("chapter3_retreat", false):
		return
	if GameState.get_flag("safe_done", false):
		dialogue.play([{"speaker": "DANA", "text": "(Already got what was in here.)"}])
		return
	var dana_visual := player.get("character_visual") as AnimatedCharacter2D if player else null
	if dana_visual:
		dana_visual.play_interact()
	if GameState.get_flag("sal_gave_code", false):
		dialogue.play([
			{"speaker": "DANA", "text": "Thank you, Sal.", "audio": "res://vo/chapter3/D-004a.mp3"},
		])
	else:
		GameState.heat += 1
		dialogue.play([
			{"speaker": "DANA", "text": "Wrong code. Of course it is.", "audio": "res://vo/chapter3/D-004b.mp3"},
			{"speaker": "DANA", "text": "No time to figure out why. Whatever's on top of that desk goes in her pocket instead.", "audio": "res://vo/chapter3/D-004c.mp3"},
		])
	GameState.set_flag("safe_done", true)
	dialogue.advanced.connect(_check_success_ending, CONNECT_ONE_SHOT)

# ---------------------------------------------------------------- Voss

func _on_voss_confrontation() -> void:
	if GameState.get_flag("chapter3_retreat", false) or GameState.get_flag("chapter3_success", false):
		return

	var times: int = GameState.get_flag("times_spotted", 0) + 1
	GameState.set_flag("times_spotted", times)

	if times >= 2:
		_forced_retreat()
		return

	var cover_strength: int = 1 if GameState.ledger["trust"].get("costigan", 0) >= 1 else 0
	var attempt: int = cover_strength + (1 if GameState.heat == 0 else 0)

	if attempt >= 1:
		dialogue.play([
			{"speaker": "VOSS", "text": "I don't recognize you from the roster.", "audio": "res://vo/chapter3/V-002.mp3"},
			{"speaker": "DANA", "text": "Costigan pulled me in last minute, one of the regulars called out sick. Ask him yourself, I don't care, I've got four decks to finish before sunrise.", "audio": "res://vo/chapter3/D-005.mp3"},
			{"speaker": "VOSS", "text": "...Get it done. I'll be checking.", "audio": "res://vo/chapter3/V-003.mp3"},
		])
	else:
		_forced_retreat()

func _forced_retreat() -> void:
	GameState.set_flag("chapter3_retreat", true)
	GameState.set_flag("chapter3_complete", true)
	dialogue.play([
		{"speaker": "VOSS", "text": "Costigan's not on this boat to vouch for anyone tonight. Neither are you, in about ninety seconds.", "audio": "res://vo/chapter3/V-004.mp3"},
		{"speaker": "VOSS", "text": "Walk. Don't make this the part of your night that goes in a report.", "audio": "res://vo/chapter3/V-005.mp3"},
	])
	dialogue.advanced.connect(_show_chapter3_summary, CONNECT_ONE_SHOT)

# ---------------------------------------------------------------- Wrap-up

func _check_success_ending() -> void:
	if GameState.get_flag("chapter3_retreat", false):
		return
	if GameState.get_flag("audit_solved", false) and GameState.get_flag("safe_done", false):
		if not GameState.get_flag("chapter3_success", false):
			GameState.set_flag("chapter3_success", true)
			GameState.set_flag("chapter3_complete", true)
			dialogue.play([
				{"speaker": "VOSS", "text": "You're not cleaning crew. You're not press. And you're carrying something you didn't have an hour ago.", "audio": "res://vo/chapter3/V-006.mp3"},
				{"speaker": "DANA", "text": "Costigan can vouch —", "audio": "res://vo/chapter3/D-006.mp3"},
				{"speaker": "VOSS", "text": "Costigan doesn't run this boat. Kowalczyk. Mick's sister. That tracks, actually. He talked about you the same way people talk about weather they can't do anything about.", "audio": "res://vo/chapter3/V-007.mp3"},
				{"speaker": "DANA", "text": "Where's Calloway.", "audio": "res://vo/chapter3/D-007.mp3"},
				{"speaker": "VOSS", "text": "Not somewhere you're walking onto tonight uninvited. Go. Not because I like you. Because if something happens to you on this boat tonight, it stops being containable, and containable is my entire job.", "audio": "res://vo/chapter3/V-008.mp3"},
			])
			dialogue.advanced.connect(_show_chapter3_summary, CONNECT_ONE_SHOT)

func _show_chapter3_summary() -> void:
	var outcome := "forced off the boat" if GameState.get_flag("chapter3_retreat", false) else "got off clean"
	var summary := "CHAPTER III COMPLETE  —  %s. Heat: %s, Cash: $%s" % [
		outcome, GameState.heat, GameState.cash
	]
	dialogue.play([{"speaker": "", "text": summary}])
