extends Node2D

var player: CharacterBody2D
var dialogue: DialogueBoxUI
var board: DeductionBoardUI
var reyes: StoryNPC

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
	_build_player()
	_build_npc()
	_build_clues()
	_build_ui()

	dialogue.play([
		{"speaker": "DANA", "text": "He's in there. Pier 9. I got here before anyone else did.", "audio": "res://vo/chapter1/D-001.mp3"},
		{"speaker": "", "text": "(Walk with WASD or the arrow keys. Press E near something to examine it.)"},
	])

func _build_environment() -> void:
	var background := Sprite2D.new()
	background.texture = preload("res://art/backgrounds/pier9_ch1_background_pass01.png")
	background.position = Vector2(1280, 720)
	background.z_index = -100
	add_child(background)

func _build_player() -> void:
	player = preload("res://scripts/Player.gd").new()
	player.position = Vector2(620, 820)
	# Handoff's rect (250,480)-(2000,1040) leaves the spatter/receipt clues
	# (y=410/370) unreachably above the top edge, so this is widened to
	# actually cover every marker in GODOT_INTEGRATION_HANDOFF.md with
	# margin for the player's 40px interact radius; retune once Dana is
	# actually visible on the plate.
	player.movement_bounds = Rect2(Vector2(300, 320), Vector2(1650, 720))
	add_child(player)

	var cam := Camera2D.new()
	cam.zoom = Vector2(1.0, 1.0)
	cam.position_smoothing_enabled = true
	cam.limit_left = 0
	cam.limit_top = 0
	cam.limit_right = 2560
	cam.limit_bottom = 1440
	cam.enabled = true
	player.add_child(cam)

func _build_npc() -> void:
	reyes = preload("res://scripts/StoryNPC.gd").new()
	reyes.position = Vector2(900, 760)
	reyes.npc_name = "REYES"
	add_child(reyes)
	reyes.interacted.connect(_on_reyes_interact)

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
