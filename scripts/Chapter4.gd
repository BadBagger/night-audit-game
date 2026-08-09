extends Node2D

var player: CharacterBody2D
var dialogue: DialogueBoxUI
var reyes: StoryNPC
var priya: StoryNPC

const PRIYA_SCENE_POSITION := Vector2(905, 610)
const PRIYA_ENTRY_POSITION := Vector2(1040, 600)
const PRIYA_DOOR_POSITION := Vector2(1010, 565)

func _ready() -> void:
	_build_environment()
	_build_player()
	_build_npcs()
	_build_ui()
	dialogue.line_started.connect(_on_dialogue_line_started)
	dialogue.advanced.connect(_on_dialogue_finished)
	_start_apartment_scene()

func _build_environment() -> void:
	var plate := Sprite2D.new()
	plate.name = "chapter4_apartment_plate"
	plate.texture = preload("res://art/backgrounds/chapter4_apartment_plate.png")
	plate.position = Vector2(640, 380)
	plate.scale = Vector2(1.0, 1.0)
	plate.z_index = -100
	add_child(plate)

func _build_player() -> void:
	player = preload("res://scripts/Player.gd").new()
	player.position = Vector2(500, 570)
	player.movement_bounds = Rect2(Vector2(260, 300), Vector2(820, 340))
	add_child(player)
	player.set_character_visual(_make_character_visual(
		"res://art/characters/chapter3/dana",
		{"idle": {"fps": 1.0}, "walk": {"fps": 10.0}, "talk": {"fps": 6.0}, "interact": {"fps": 8.0, "loop": false}},
		0.54,
		Vector2(0, -76)
	))

	var cam := Camera2D.new()
	cam.zoom = Vector2(1.35, 1.35)
	cam.position_smoothing_enabled = true
	cam.enabled = true
	player.add_child(cam)

func _build_npcs() -> void:
	reyes = _make_npc("REYES", Vector2(785, 540), "res://art/characters/chapter1/reyes")
	priya = _make_npc("PRIYA", PRIYA_ENTRY_POSITION, "res://art/characters/chapter2/priya")
	priya.interact_enabled = false
	priya.visible = false

func _build_ui() -> void:
	dialogue = preload("res://scripts/DialogueBox.gd").new()
	add_child(dialogue)

	var hud := CanvasLayer.new()
	hud.layer = 5
	add_child(hud)
	var hint := Label.new()
	hint.text = "Chapter IV: Who Mick Was"
	hint.position = Vector2(16, 8)
	hint.add_theme_font_size_override("font_size", 12)
	hint.add_theme_color_override("font_color", Color(0.6, 0.62, 0.68))
	hud.add_child(hint)

func _start_apartment_scene() -> void:
	dialogue.play([
		{"speaker": "REYES", "text": "Walk me through it."},
		{"speaker": "DANA", "text": "Mick wasn't just laundering for Calloway. He was skimming from the laundering. Small, careful, consistent."},
		{"speaker": "DANA", "text": "Priya's strike fund. My legal bills. He paid them down quietly for three years while we weren't speaking."},
		{"speaker": "REYES", "text": "That's not nothing, Dana."},
		{"speaker": "DANA", "text": "It's not clean either. He built exactly the kind of books that ruined me. He just built them for me."},
	])
	dialogue.advanced.connect(_start_priya_scene, CONNECT_ONE_SHOT)

func _start_priya_scene() -> void:
	if GameState.get_action("priya") == "lean":
		priya.position = PRIYA_DOOR_POSITION
		priya.visible = true
		dialogue.play([
			{"speaker": "PRIYA", "text": "I already told you what I know. We're done."},
			{"speaker": "DANA", "text": "Priya, please-"},
			{"speaker": "PRIYA", "text": "You threatened to burn my strike fund four hours ago. I don't owe you the rest of my night."},
		])
		dialogue.advanced.connect(_finish_chapter4, CONNECT_ONE_SHOT)
		return

	if GameState.get_flag("priya_done", false):
		_stage_priya_entrance()
		dialogue.play([
			{"speaker": "PRIYA", "text": "So it was real money. Just not clean money."},
			{"speaker": "", "text": "(What do you tell her?)",
			 "choices": [
				{"label": "Tell her the full truth", "id": "truth"},
				{"label": "Let her keep one clean thing", "id": "lie"},
			 ]},
		])
		dialogue.choice_made.connect(_on_priya_truth_choice, CONNECT_ONE_SHOT)
	else:
		dialogue.play([{"speaker": "DANA", "text": "No one else is answering tonight. Then I take this straight to Calloway."}])
		dialogue.advanced.connect(_finish_chapter4, CONNECT_ONE_SHOT)

func _stage_priya_entrance() -> void:
	priya.position = PRIYA_ENTRY_POSITION
	priya.visible = true
	if priya.character_visual:
		priya.character_visual.set_facing(-1.0)
		priya.character_visual.play_walk(Vector2.LEFT)
	var tween := create_tween()
	tween.tween_property(priya, "position", PRIYA_SCENE_POSITION, 0.45).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	tween.tween_callback(priya.play_idle)

func _on_priya_truth_choice(id: String) -> void:
	if id == "truth":
		GameState.set_flag("priya_truth_told", true)
		dialogue.play([
			{"speaker": "DANA", "text": "It came from the skim. All of it. I thought you should hear that from someone, not read it in a filing someday."},
			{"speaker": "PRIYA", "text": "Every person on that line believed in that money. I have to decide what to do with that now. Thank you for not letting me find out the ugly way."},
		])
	else:
		GameState.set_flag("priya_truth_hidden", true)
		dialogue.play([
			{"speaker": "DANA", "text": "The fund's legitimate. Portland local, like you thought."},
			{"speaker": "PRIYA", "text": "Good. That's good. I needed one clean thing out of tonight."},
		])
	dialogue.advanced.connect(_finish_chapter4, CONNECT_ONE_SHOT)

func _finish_chapter4() -> void:
	GameState.set_flag("chapter4_complete", true)
	dialogue.play([{"speaker": "", "text": "CHAPTER IV COMPLETE - The books are personal now."}])
	dialogue.advanced.connect(_go_to_chapter5, CONNECT_ONE_SHOT)

func _go_to_chapter5() -> void:
	get_tree().change_scene_to_file("res://scenes/Chapter5.tscn")

func _make_npc(npc_name: String, pos: Vector2, root_path: String) -> StoryNPC:
	var npc = preload("res://scripts/StoryNPC.gd").new()
	npc.npc_name = npc_name
	npc.position = pos
	add_child(npc)
	npc.set_character_visual(_make_character_visual(
		root_path,
		{"idle": {"fps": 1.0}, "walk": {"fps": 7.0}, "talk": {"fps": 5.0}},
		0.54,
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
	for npc in [reyes, priya]:
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
	for npc in [reyes, priya]:
		if npc:
			npc.play_idle()
