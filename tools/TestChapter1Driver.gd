extends Node2D

var main_scene: Node
var failures: Array = []
var checks := 0

func _ready() -> void:
	main_scene = load("res://scenes/Main.tscn").instantiate()
	get_tree().root.add_child.call_deferred(main_scene)
	await get_tree().process_frame
	await get_tree().process_frame
	await get_tree().process_frame

	_check("intro dialogue opened", main_scene.dialogue.box_visible)
	_check("intro line has audio loaded", main_scene.dialogue.audio_player.stream != null)

	await _drain_dialogue()

	# Real play order: talk to Reyes first (consumes the intro/"look around" branch)
	# before examining anything, exactly like a player would.
	main_scene.reyes.interact()
	await _drain_dialogue()
	_check("intro_done set after first Reyes talk", GameState.get_flag("intro_done", false))

	var clues := _find_clues()
	_check("found 5 clue objects", clues.size() == 5)

	for c in clues:
		c.interact()
		await _drain_dialogue()

	_check("all 5 clues logged in evidence", GameState.collected_clues.size() == 5)
	var before := GameState.collected_clues.size()
	clues[0].interact()
	await _drain_dialogue()
	_check("repeat-examine stays at same evidence count", GameState.collected_clues.size() == before)

	_check("has_all_required_clues true after 3 real clues", GameState.has_all_required_clues())

	main_scene.reyes.interact()
	await _drain_dialogue()
	_check("board opened after Reyes 'walk me through it' line", main_scene.board.visible)

	main_scene.board._select_slot(0)
	var wrong_entry = null
	for cid in GameState.collected_clues:
		if GameState.collected_clues[cid]["tag"] != main_scene.board.slots[0]["tag"]:
			wrong_entry = GameState.collected_clues[cid]
			break
	if wrong_entry:
		main_scene.board._assign_clue(wrong_entry["tag"], wrong_entry["label"])
		_check("wrong clue rejected, slot still empty", main_scene.board.slots[0]["filled"] == "")

	for i in range(main_scene.board.slots.size()):
		var slot = main_scene.board.slots[i]
		if slot["filled"] != "":
			continue
		var match_entry = null
		for cid in GameState.collected_clues:
			if GameState.collected_clues[cid]["tag"] == slot["tag"]:
				match_entry = GameState.collected_clues[cid]
				break
		main_scene.board._select_slot(i)
		main_scene.board._assign_clue(match_entry["tag"], match_entry["label"])

	_check("board solved flag set", GameState.get_flag("board_solved", false))
	_check("board closed after solve", not main_scene.board.visible)

	await _drain_dialogue()

	main_scene.reyes.interact()
	await _drain_dialogue()
	_check("phone choice presented", main_scene.dialogue.choice_container.get_child_count() == 2)

	main_scene.dialogue._on_choice("leave")
	# Stop as soon as the flag lands, rather than draining all the way through
	# the chapter summary line -- that line's "advanced" signal is wired to
	# change_scene_to_file() in real gameplay, which this harness (Main
	# instantiated as a plain child, not the true current_scene) can't
	# survive. The flag/trust checks below don't need that line to render.
	var steps := 0
	while not GameState.get_flag("chapter1_complete", false) and steps < 20:
		if main_scene.dialogue.box_visible and main_scene.dialogue.choice_container.get_child_count() == 0:
			main_scene.dialogue._advance()
		await get_tree().process_frame
		steps += 1

	_check("chapter1_complete flag set", GameState.get_flag("chapter1_complete", false))
	_check("reyes trust incremented on 'leave' branch", GameState.ledger["trust"]["reyes"] == 1)
	_check("phone_pocketed flag NOT set on 'leave' branch", not GameState.get_flag("phone_pocketed", false))

	_report()
	get_tree().quit()

func _find_clues() -> Array:
	var out := []
	for c in main_scene.get_children():
		if c.get("clue_id") != null and c.clue_id != "":
			out.append(c)
	return out

func _drain_dialogue(max_steps: int = 20) -> void:
	var steps := 0
	await get_tree().process_frame
	while main_scene.dialogue.box_visible and main_scene.dialogue.choice_container.get_child_count() == 0 and steps < max_steps:
		main_scene.dialogue._advance()
		await get_tree().process_frame
		steps += 1
	if steps >= max_steps:
		_check("dialogue drained without hitting step cap (possible infinite loop)", false)

func _check(label: String, ok: bool) -> void:
	checks += 1
	if ok:
		print("PASS  ", label)
	else:
		print("FAIL  ", label)
		failures.append(label)

func _report() -> void:
	print("")
	print("=== %d/%d checks passed ===" % [checks - failures.size(), checks])
	if failures.size() > 0:
		print("FAILURES:")
		for f in failures:
			print(" - ", f)
