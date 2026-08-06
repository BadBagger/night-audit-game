extends Node2D

var player: CharacterBody2D
var dialogue: DialogueBoxUI
var calloway: StoryNPC
var voss: StoryNPC
var reyes: StoryNPC
var priya: StoryNPC

func _ready() -> void:
	_build_environment()
	_build_player()
	_build_npcs()
	_build_ui()
	dialogue.line_started.connect(_on_dialogue_line_started)
	dialogue.advanced.connect(_on_dialogue_finished)
	_start_finale()

func _build_environment() -> void:
	var ground := Prop.new()
	ground.size = Vector2(1400, 840)
	ground.position = Vector2(700, 420)
	ground.color = Color(0.055, 0.062, 0.075)
	add_child(ground)

	var room := Prop.new()
	room.size = Vector2(700, 360)
	room.position = Vector2(700, 380)
	room.color = Color(0.12, 0.10, 0.085)
	room.outline = Color(0.851, 0.522, 0.184, 0.45)
	add_child(room)

	var evidence_table := Prop.new()
	evidence_table.size = Vector2(280, 130)
	evidence_table.position = Vector2(650, 455)
	evidence_table.color = Color(0.19, 0.14, 0.09)
	evidence_table.outline = Color(0.93, 0.88, 0.72, 0.4)
	add_child(evidence_table)

func _build_player() -> void:
	player = preload("res://scripts/Player.gd").new()
	player.position = Vector2(510, 620)
	player.movement_bounds = Rect2(Vector2(260, 300), Vector2(840, 360))
	add_child(player)
	player.set_character_visual(_make_character_visual(
		"res://art/characters/chapter3/dana",
		{"idle": {"fps": 1.0}, "walk": {"fps": 10.0}, "talk": {"fps": 6.0}, "interact": {"fps": 8.0, "loop": false}},
		0.64,
		Vector2(0, -76)
	))

	var cam := Camera2D.new()
	cam.zoom = Vector2(0.9, 0.9)
	cam.position_smoothing_enabled = true
	cam.enabled = true
	player.add_child(cam)

func _build_npcs() -> void:
	calloway = _make_npc("CALLOWAY", Vector2(790, 540), "res://art/characters/chapter5/calloway", 0.62)
	voss = _make_npc("VOSS", Vector2(940, 550), "res://art/characters/chapter3/voss", 0.66)
	reyes = _make_npc("REYES", Vector2(370, 560), "res://art/characters/chapter1/reyes", 0.66)
	priya = _make_npc("PRIYA", Vector2(260, 545), "res://art/characters/chapter2/priya", 0.66)
	reyes.visible = _is_reyes_present()
	priya.visible = _is_priya_present()

func _build_ui() -> void:
	dialogue = preload("res://scripts/DialogueBox.gd").new()
	add_child(dialogue)

	var hud := CanvasLayer.new()
	hud.layer = 5
	add_child(hud)
	var hint := Label.new()
	hint.text = "Chapter V: Settlement"
	hint.position = Vector2(16, 8)
	hint.add_theme_font_size_override("font_size", 12)
	hint.add_theme_color_override("font_color", Color(0.6, 0.62, 0.68))
	hud.add_child(hint)

func _start_finale() -> void:
	dialogue.play([
		{"speaker": "CALLOWAY", "text": "Ms. Kowalczyk. I was told you'd probably find your way here eventually. Mick undersold you."},
		{"speaker": "DANA", "text": "He undersold a lot of things. Like the fact you had him killed."},
		{"speaker": "CALLOWAY", "text": "Prove it. Politely, I mean that."},
	])
	dialogue.advanced.connect(_offer_final_board, CONNECT_ONE_SHOT)

func _offer_final_board() -> void:
	dialogue.play([
		{"speaker": "", "text": "(How do you close the books?)",
		 "choices": [
			{"label": "Lay out the full evidence chain", "id": "evidence"},
			{"label": "Bluff the missing gaps", "id": "bluff"},
		 ]},
	])
	dialogue.choice_made.connect(_on_final_choice, CONNECT_ONE_SHOT)

func _on_final_choice(id: String) -> void:
	var ending := _resolve_ending(id)
	GameState.set_flag("final_ending", ending)
	match ending:
		"ledger":
			dialogue.play([
				{"speaker": "CALLOWAY", "text": "You were never trying to close my books. You were trying to close everyone's."},
				{"speaker": "DANA", "text": "Somebody had to actually finish the audit."},
				{"speaker": "PRIYA", "text": "What happens to you now?"},
				{"speaker": "DANA", "text": "I don't know yet. First time in three years I don't already know the answer to that."},
				{"speaker": "", "text": "ENDING: THE LEDGER NEVER CLOSES"},
			])
		"clean":
			dialogue.play([
				{"speaker": "REYES", "text": "You did this the hard way. Every step of it."},
				{"speaker": "DANA", "text": "Only way I know how, apparently."},
				{"speaker": "", "text": "ENDING: CLEAN BREAK"},
			])
		"paid":
			dialogue.play([
				{"speaker": "CALLOWAY", "text": "You bought enough truth to make me expensive. Not enough to make yourself clean."},
				{"speaker": "DANA", "text": "Yeah. I'm still paying it off, though."},
				{"speaker": "", "text": "ENDING: PAID IN FULL"},
			])
		"blood":
			dialogue.play([
				{"speaker": "VOSS", "text": "You got your answer. Doesn't mean you get to leave with it."},
				{"speaker": "", "text": "ENDING: BLOOD FOR BLOOD"},
			])
	dialogue.advanced.connect(_finish_game, CONNECT_ONE_SHOT)

func _finish_game() -> void:
	GameState.set_flag("game_complete", true)

func _resolve_ending(choice_id: String) -> String:
	var full_evidence: bool = bool(GameState.get_flag("chapter3_success", false)) and bool(GameState.get_flag("audit_solved", false)) and bool(GameState.get_flag("safe_done", false)) and GameState.has_all_required_clues()
	var sal_action := GameState.get_action("sal")
	var priya_action := GameState.get_action("priya")
	var leaned_count := 0
	for action in GameState.npc_actions.values():
		if action == "lean":
			leaned_count += 1
	var trust_total := 0
	for value in GameState.ledger["trust"].values():
		trust_total += int(value)

	if choice_id == "bluff" and not (_is_reyes_present() or _is_priya_present()):
		return "blood"
	if leaned_count >= 2 or trust_total <= -3:
		return "blood"
	if full_evidence and sal_action == "work" and priya_action == "work" and GameState.get_flag("costigan_boat_lead", false) and GameState.heat == 0 and GameState.get_flag("priya_truth_told", false):
		return "ledger"
	if full_evidence and leaned_count == 0:
		return "clean"
	if full_evidence:
		return "paid"
	return "blood"

func _is_reyes_present() -> bool:
	return GameState.ledger["trust"].get("reyes", 0) >= 0

func _is_priya_present() -> bool:
	return GameState.get_action("priya") != "lean" and not GameState.get_flag("priya_truth_hidden", false)

func _make_npc(npc_name: String, pos: Vector2, root_path: String, scale: float) -> StoryNPC:
	var npc = preload("res://scripts/StoryNPC.gd").new()
	npc.npc_name = npc_name
	npc.position = pos
	npc.interact_enabled = false
	add_child(npc)
	npc.set_character_visual(_make_character_visual(
		root_path,
		{"idle": {"fps": 1.0}, "walk": {"fps": 7.0}, "talk": {"fps": 5.0}},
		scale,
		Vector2(0, -76)
	))
	return npc

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
	for npc in [calloway, voss, reyes, priya]:
		if npc == null:
			continue
		if speaker == npc.npc_name:
			npc.play_talk()
		else:
			npc.play_idle()

func _on_dialogue_finished() -> void:
	var dana_visual := player.get("character_visual") as AnimatedCharacter2D if player else null
	if dana_visual:
		dana_visual.play_idle()
	for npc in [calloway, voss, reyes, priya]:
		if npc:
			npc.play_idle()
