extends Node2D

var player: CharacterBody2D
var dialogue: DialogueBoxUI
var ticket_board: TicketBoardUI
var manifest_board: ManifestBoardUI

var sal: StoryNPC
var priya: StoryNPC
var costigan: StoryNPC

var costigan_state := "hostile"
var costigan_hostile_misses := 0

func _ready() -> void:
	_build_environment()
	_build_ambience()
	_build_player()
	_build_npcs()
	_build_ui()

	dialogue.line_started.connect(_on_dialogue_line_started)
	dialogue.advanced.connect(_on_dialogue_finished)
	dialogue.play([
		{"speaker": "DANA", "text": "Three names, three doors. Sal's shop, Priya's picket line, Costigan's shack. Doesn't matter which order."},
	])

func _build_environment() -> void:
	var ground := Prop.new()
	ground.size = Vector2(1360, 860)
	ground.position = Vector2(700, 450)
	ground.color = Color(0.078, 0.086, 0.11)
	add_child(ground)

	var pawnshop := Prop.new()
	pawnshop.size = Vector2(180, 120)
	pawnshop.position = Vector2(260, 260)
	pawnshop.color = Color(0.16, 0.13, 0.08)
	pawnshop.outline = Color(0.851, 0.522, 0.184, 0.5)
	add_child(pawnshop)

	var picket := Prop.new()
	picket.size = Vector2(180, 120)
	picket.position = Vector2(1140, 260)
	picket.color = Color(0.10, 0.14, 0.10)
	picket.outline = Color(0.851, 0.522, 0.184, 0.5)
	add_child(picket)

	var dockshack := Prop.new()
	dockshack.size = Vector2(180, 120)
	dockshack.position = Vector2(700, 660)
	dockshack.color = Color(0.10, 0.12, 0.16)
	dockshack.outline = Color(0.851, 0.522, 0.184, 0.5)
	add_child(dockshack)

func _build_ambience() -> void:
	var path := "res://sfx/ambience/warehouse_room_tone_v01.ogg"
	if not ResourceLoader.exists(path):
		return
	var stream: AudioStream = load(path)
	if stream is AudioStreamOggVorbis:
		stream.loop = true
	var loop_player := AudioStreamPlayer.new()
	loop_player.stream = stream
	loop_player.volume_db = -10.0
	add_child(loop_player)
	loop_player.play()

func _build_player() -> void:
	player = preload("res://scripts/Player.gd").new()
	player.position = Vector2(700, 460)
	player.footstep_sound = load("res://sfx/foley/footstep_concrete_wet_v01.ogg") if ResourceLoader.exists("res://sfx/foley/footstep_concrete_wet_v01.ogg") else null
	add_child(player)
	player.set_character_visual(_make_character_visual(
		"res://art/characters/chapter2/dana",
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
	sal = preload("res://scripts/StoryNPC.gd").new()
	sal.position = Vector2(260, 320)
	sal.npc_name = "SAL"
	add_child(sal)
	sal.set_character_visual(_make_character_visual(
		"res://art/characters/chapter2/sal",
		{"idle": {"fps": 1.0}, "walk": {"fps": 7.0}, "talk": {"fps": 5.0}},
		0.64,
		Vector2(0, -76)
	))
	sal.interacted.connect(_on_sal_interact)

	priya = preload("res://scripts/StoryNPC.gd").new()
	priya.position = Vector2(1140, 320)
	priya.npc_name = "PRIYA"
	add_child(priya)
	priya.set_character_visual(_make_character_visual(
		"res://art/characters/chapter2/priya",
		{"idle": {"fps": 1.0}, "walk": {"fps": 8.0}, "talk": {"fps": 5.0}},
		0.66,
		Vector2(0, -76)
	))
	priya.interacted.connect(_on_priya_interact)

	costigan = preload("res://scripts/StoryNPC.gd").new()
	costigan.position = Vector2(700, 720)
	costigan.npc_name = "COSTIGAN"
	add_child(costigan)
	costigan.set_character_visual(_make_character_visual(
		"res://art/characters/chapter2/costigan",
		{"idle": {"fps": 1.0}, "walk": {"fps": 7.0}, "talk": {"fps": 4.0}},
		0.66,
		Vector2(0, -76)
	))
	costigan.interacted.connect(_on_costigan_interact)

func _build_ui() -> void:
	dialogue = preload("res://scripts/DialogueBox.gd").new()
	add_child(dialogue)

	ticket_board = preload("res://scripts/TicketBoard.gd").new()
	add_child(ticket_board)
	ticket_board.solved.connect(_on_ticket_solved)

	manifest_board = preload("res://scripts/ManifestBoard.gd").new()
	add_child(manifest_board)
	manifest_board.solved.connect(_on_manifest_solved)

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
	for npc in [sal, priya, costigan]:
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
	for npc in [sal, priya, costigan]:
		if npc:
			npc.play_idle()

# ---------------------------------------------------------------- Sal

func _on_sal_interact() -> void:
	if GameState.get_flag("sal_done", false):
		dialogue.play([{"speaker": "SAL", "text": "(You already got what you're getting from me.)"}])
		return
	if not GameState.get_flag("sal_intro_done", false):
		GameState.set_flag("sal_intro_done", true)
		dialogue.play([
			{"speaker": "SAL", "text": "Dana Kowalczyk. Christ. I heard about Mick this afternoon. I'm — I don't know what to say that isn't nothing.", "audio": "res://vo/chapter2/SA-001.mp3"},
			{"speaker": "DANA", "text": "Say what he pawned the week he died.", "audio": "res://vo/chapter2/DS-001.mp3"},
			{"speaker": "SAL", "text": "Nothing. He hadn't been in in months.", "audio": "res://vo/chapter2/SA-002.mp3"},
			{"speaker": "DANA", "text": "Your handwriting's on this, Sal.", "audio": "res://vo/chapter2/DS-002.mp3"},
		])
		dialogue.advanced.connect(func(): ticket_board.open(), CONNECT_ONE_SHOT)
	else:
		dialogue.play([{"speaker": "SAL", "text": "(You still need to work out that ticket.)"}])

func _on_ticket_solved(_ticket_number: int) -> void:
	ticket_board.visible = false
	GameState.set_flag("sal_ticket_solved", true)
	dialogue.play([
		{"speaker": "SAL", "text": "...Okay. Okay. He came in Tuesday. Wanted cash fast, no questions, and I know better than to give a Kowalczyk no questions, but he looked — he looked like a man settling up before he went somewhere he wasn't coming back from. I should've called somebody.", "audio": "res://vo/chapter2/SA-003.mp3"},
		{"speaker": "DANA", "text": "Who was he settling up with.", "audio": "res://vo/chapter2/DS-003.mp3"},
	])
	dialogue.advanced.connect(_offer_sal_choice, CONNECT_ONE_SHOT)

func _offer_sal_choice() -> void:
	dialogue.play([
		{"speaker": "", "text": "(How do you get him to answer?)",
		 "choices": [
			{"label": "Pay him for it", "id": "pay"},
			{"label": "Lean on what you know about him", "id": "lean"},
			{"label": "Work it out from what you already have", "id": "work"},
		 ]},
	])
	dialogue.choice_made.connect(_on_sal_choice, CONNECT_ONE_SHOT)

func _on_sal_choice(action: String) -> void:
	GameState.apply_action("sal", action)
	match action:
		"pay":
			dialogue.play([
				{"speaker": "DANA", "text": "This buys the rest of the sentence.", "audio": "res://vo/chapter2/DS-004a.mp3"},
				{"speaker": "SAL", "text": "There's a name on the intake carbon I didn't write down official. Renata Calloway's people. He said it like it was supposed to mean something to me. It didn't, then.", "audio": "res://vo/chapter2/SA-004a.mp3"},
			])
			GameState.set_flag("sal_gave_code", true)
		"lean":
			dialogue.play([
				{"speaker": "DANA", "text": "Sal. I know you're still fencing hot goods out the back for Voss's people. I could make one phone call to Reyes and you lose this shop by Thursday.", "audio": "res://vo/chapter2/DS-004b.mp3"},
				{"speaker": "SAL", "text": "That's — that's not — okay. Okay, Jesus. Calloway. Renata Calloway. That's who he was scared of. Now leave, please, before somebody sees you standing here.", "audio": "res://vo/chapter2/SA-004b.mp3"},
			])
			GameState.set_flag("sal_gave_code", false)
		"work":
			dialogue.play([
				{"speaker": "DANA", "text": "I'm not paying for it and I'm not threatening you for it. I already have the ticket number. I just need you to confirm what I already worked out.", "audio": "res://vo/chapter2/DS-004c.mp3"},
				{"speaker": "SAL", "text": "...Calloway. You got there yourself. Mick used to talk about you like that — said you never needed anybody to hand you the answer.", "audio": "res://vo/chapter2/SA-004c.mp3"},
			])
			GameState.set_flag("sal_gave_code", true)
	GameState.set_flag("sal_done", true)
	dialogue.advanced.connect(_check_chapter2_complete, CONNECT_ONE_SHOT)

# ---------------------------------------------------------------- Priya

func _on_priya_interact() -> void:
	if GameState.get_flag("priya_done", false):
		dialogue.play([{"speaker": "PRIYA", "text": "(You already got what you came for.)"}])
		return
	if not GameState.get_flag("priya_intro_done", false):
		GameState.set_flag("priya_intro_done", true)
		dialogue.play([
			{"speaker": "PRIYA", "text": "Nobody's crossing tonight. Not for time-and-a-half, not for anything. Take it back to whoever's paying you.", "audio": "res://vo/chapter2/PR-001.mp3"},
			{"speaker": "PRIYA", "text": "You're his sister.", "audio": "res://vo/chapter2/PR-002.mp3"},
			{"speaker": "DANA", "text": "Was.", "audio": "res://vo/chapter2/DP-001.mp3"},
			{"speaker": "PRIYA", "text": "I heard an hour ago. I didn't believe it till right now. We're done here tonight. Go home.", "audio": "res://vo/chapter2/PR-003.mp3"},
			{"speaker": "PRIYA", "text": "Mick used to bring coffee down here at 4 a.m. like clockwork. Didn't ask for anything. I used to joke he was the only honest man on this pier.", "audio": "res://vo/chapter2/PR-004.mp3"},
			{"speaker": "DANA", "text": "I need to know what he was doing here. Really doing.", "audio": "res://vo/chapter2/DP-002.mp3"},
		])
		dialogue.advanced.connect(func(): manifest_board.open(), CONNECT_ONE_SHOT)
	else:
		dialogue.play([{"speaker": "PRIYA", "text": "(You still need to work out the manifest.)"}])

func _on_manifest_solved() -> void:
	manifest_board.visible = false
	GameState.set_flag("priya_manifest_solved", true)
	dialogue.play([
		{"speaker": "DANA", "text": "Every big donation lines up with a shipment he'd have had eyes on. He was funding you.", "audio": "res://vo/chapter2/DP-003.mp3"},
		{"speaker": "PRIYA", "text": "No. No, that money came from a solidarity fund out of the Portland local, that's what he told me —", "audio": "res://vo/chapter2/PR-005.mp3"},
		{"speaker": "DANA", "text": "It's the same account number four times, Priya.", "audio": "res://vo/chapter2/DP-004.mp3"},
	])
	dialogue.advanced.connect(_offer_priya_choice, CONNECT_ONE_SHOT)

func _offer_priya_choice() -> void:
	dialogue.play([
		{"speaker": "", "text": "(How do you get her to talk?)",
		 "choices": [
			{"label": "Cover the strike fund's costs", "id": "pay"},
			{"label": "Threaten to expose the fund", "id": "lean"},
			{"label": "Just ask her to help you understand", "id": "work"},
		 ]},
	])
	dialogue.choice_made.connect(_on_priya_choice, CONNECT_ONE_SHOT)

func _on_priya_choice(action: String) -> void:
	GameState.apply_action("priya", action)
	match action:
		"pay":
			dialogue.play([
				{"speaker": "DANA", "text": "I'm not here to blow this up publicly. Whatever the strike fund needs to keep going, I'll cover what I can, so this doesn't get worse for your people while I find out the rest.", "audio": "res://vo/chapter2/DP-005a.mp3"},
				{"speaker": "PRIYA", "text": "...Fine. That's decent of you, actually. Doesn't mean I trust you yet.", "audio": "res://vo/chapter2/PR-006a.mp3"},
			])
		"lean":
			dialogue.play([
				{"speaker": "DANA", "text": "You want this line to keep holding, you tell me everything, right now, or I make sure every one of those donation records ends up somewhere that makes your strike look like a laundering front. I don't want to do that. But I will.", "audio": "res://vo/chapter2/DP-005b.mp3"},
				{"speaker": "PRIYA", "text": "He talked about you like you were the good one. Fine. He was scared of somebody named Calloway. Said if it ever came out where the money came from, it'd burn the strike and get people hurt. Congratulations, you just did the first part yourself.", "audio": "res://vo/chapter2/PR-006b.mp3"},
			])
		"work":
			dialogue.play([
				{"speaker": "DANA", "text": "I'm not going to threaten the one person he was actually trying to protect. Just — help me understand it. Please.", "audio": "res://vo/chapter2/DP-005c.mp3"},
				{"speaker": "PRIYA", "text": "...Calloway. That's the name he wouldn't say above a whisper. I don't know more than that. I didn't want to know more than that. You really didn't know any of this, did you.", "audio": "res://vo/chapter2/PR-006c.mp3"},
				{"speaker": "DANA", "text": "No.", "audio": "res://vo/chapter2/DP-006c.mp3"},
				{"speaker": "PRIYA", "text": "He was trying to fix something for you. I think that's what got him killed. I'm sorry.", "audio": "res://vo/chapter2/PR-007c.mp3"},
			])
	GameState.set_flag("priya_done", true)
	dialogue.advanced.connect(_check_chapter2_complete, CONNECT_ONE_SHOT)

# ---------------------------------------------------------------- Costigan

func _on_costigan_interact() -> void:
	if GameState.get_flag("costigan_done", false):
		dialogue.play([{"speaker": "COSTIGAN", "text": "(Nothing more to say tonight.)"}])
		return
	if not GameState.get_flag("costigan_intro_done", false):
		GameState.set_flag("costigan_intro_done", true)
		dialogue.play([
			{"speaker": "COSTIGAN", "text": "Get out.", "audio": "res://vo/chapter2/CO-001.mp3"},
			{"speaker": "DANA", "text": "Frank—", "audio": "res://vo/chapter2/DC-001.mp3"},
			{"speaker": "COSTIGAN", "text": "Your family already cost me one good man on this dock. I'm not doing this with the other one tonight.", "audio": "res://vo/chapter2/CO-002.mp3"},
		])
		dialogue.advanced.connect(_offer_costigan_choice, CONNECT_ONE_SHOT)
	elif not dialogue.box_visible:
		_offer_costigan_choice()

func _offer_costigan_choice() -> void:
	dialogue.play([
		{"speaker": "", "text": "(What do you say?)",
		 "choices": [
			{"label": "Talk about grief", "id": "grief"},
			{"label": "Talk about the case", "id": "case"},
			{"label": "Offer to help", "id": "offer"},
		 ]},
	])
	dialogue.choice_made.connect(_on_costigan_choice, CONNECT_ONE_SHOT)

func _on_costigan_choice(id: String) -> void:
	var transitions := {
		"hostile": {"grief": "guarded", "case": "hostile", "offer": "hostile"},
		"guarded": {"case": "listening", "grief": "guarded", "offer": "guarded"},
		"listening": {"offer": "open", "grief": "listening", "case": "listening"},
	}
	var prev_state := costigan_state
	var next_state: String = transitions.get(costigan_state, {}).get(id, costigan_state)

	if next_state == prev_state and prev_state == "hostile":
		costigan_hostile_misses += 1
		if costigan_hostile_misses >= 2:
			dialogue.play([{"speaker": "COSTIGAN", "text": "We're done here. Ask someone else.", "audio": "res://vo/chapter2/CO-007.mp3"}])
			GameState.set_flag("costigan_done", true)
			dialogue.advanced.connect(_check_chapter2_complete, CONNECT_ONE_SHOT)
			return
		else:
			dialogue.play([{"speaker": "COSTIGAN", "text": "...Not what I asked.", "audio": "res://vo/chapter2/CO-003b.mp3"}])
			dialogue.advanced.connect(_offer_costigan_choice, CONNECT_ONE_SHOT)
			return

	costigan_state = next_state
	match id:
		"grief":
			dialogue.play([
				{"speaker": "DANA", "text": "He tied his shoes like our dad did. Still did it three years after I stopped talking to him. I only just remembered that tonight, over his body.", "audio": "res://vo/chapter2/DC-002.mp3"},
				{"speaker": "COSTIGAN", "text": "...Yeah. He did that.", "audio": "res://vo/chapter2/CO-003.mp3"},
			])
		"case":
			dialogue.play([
				{"speaker": "DANA", "text": "He was moved before he was staged at Pier 9. Somebody wanted it to look like a dockside thing. It wasn't.", "audio": "res://vo/chapter2/DC-003.mp3"},
				{"speaker": "COSTIGAN", "text": "It wasn't dockside. No. Whatever he stepped in, it stepped in from higher up than any of my guys.", "audio": "res://vo/chapter2/CO-004.mp3"},
			])
		"offer":
			dialogue.play([
				{"speaker": "DANA", "text": "I think whoever did this used your dock's schedule to move him without anyone clocking it. If that's true, it's a hole in your operation, not a mark against it. I'd rather find it than let it happen to somebody else who works for you.", "audio": "res://vo/chapter2/DC-004.mp3"},
				{"speaker": "COSTIGAN", "text": "...Fine. Fine. There's a boat — the Calloway Star, moored off Berth 12, runs \"private charters\" that never seem to charter anybody real. Mick had a badge for it. I don't know why. I never asked, because I didn't want the answer.", "audio": "res://vo/chapter2/CO-005.mp3"},
			])

	if costigan_state == "open":
		GameState.set_flag("costigan_done", true)
		GameState.set_flag("costigan_boat_lead", true)
		dialogue.advanced.connect(_costigan_closing, CONNECT_ONE_SHOT)
	else:
		dialogue.advanced.connect(_offer_costigan_choice, CONNECT_ONE_SHOT)

func _costigan_closing() -> void:
	dialogue.play([
		{"speaker": "COSTIGAN", "text": "Dana. Whatever you find on that boat — you don't go at it alone. Man who runs security out there isn't someone you talk your way past twice.", "audio": "res://vo/chapter2/CO-006.mp3"},
	])
	dialogue.advanced.connect(_check_chapter2_complete, CONNECT_ONE_SHOT)

# ---------------------------------------------------------------- Wrap-up

func _check_chapter2_complete() -> void:
	if GameState.get_flag("sal_done", false) and GameState.get_flag("priya_done", false) and GameState.get_flag("costigan_done", false):
		if not GameState.get_flag("chapter2_complete", false):
			GameState.set_flag("chapter2_complete", true)
			_show_chapter2_summary()

func _show_chapter2_summary() -> void:
	var summary := "CHAPTER II COMPLETE  —  Ledger: Sal %s, Priya %s, Costigan %s, Cash $%s" % [
		GameState.ledger["trust"]["sal"], GameState.ledger["trust"]["priya"],
		GameState.ledger["trust"]["costigan"], GameState.cash
	]
	dialogue.play([{"speaker": "", "text": summary}])
	dialogue.advanced.connect(_go_to_chapter3, CONNECT_ONE_SHOT)

func _go_to_chapter3() -> void:
	get_tree().change_scene_to_file("res://scenes/Chapter3.tscn")
