extends Node2D

var ch5: Node
var failures: Array = []
var checks := 0

func _ready() -> void:
	await _phase_ledger_ending()
	_reset_gamestate()
	await _phase_clean_ending()
	_reset_gamestate()
	await _phase_hidden_truth_liability()
	_reset_gamestate()
	await _phase_paid_ending()
	_reset_gamestate()
	await _phase_blood_ending()
	_report()
	get_tree().quit()

func _phase_ledger_ending() -> void:
	_seed_full_evidence()
	GameState.npc_actions = {"sal": "work", "priya": "work"}
	GameState.ledger["trust"]["sal"] = 2
	GameState.ledger["trust"]["priya"] = 2
	GameState.ledger["trust"]["costigan"] = 2
	GameState.set_flag("priya_truth_told", true)

	ch5 = load("res://scenes/Chapter5.tscn").instantiate()
	get_tree().root.add_child.call_deferred(ch5)
	await get_tree().process_frame
	await get_tree().process_frame
	await get_tree().process_frame

	_check("chapter5 intro dialogue opened", ch5.dialogue.box_visible)
	_check("chapter5 Dana has animated visual", ch5.player.get("character_visual") != null)
	_check("Calloway has animated visual", ch5.calloway.character_visual != null)
	_check("Calloway uses dedicated chapter5 sprite path", ch5.calloway.character_visual.sprite.sprite_frames.get_frame_texture("idle", 0).resource_path.contains("/chapter5/calloway/"))
	_check("Voss has animated visual", ch5.voss.character_visual != null)
	_check("Priya is present after Chapter IV truth branch", ch5.priya.visible)
	await _drain_dialogue()
	_check("final evidence choice offered", ch5.dialogue.choice_container.get_child_count() == 2)

	ch5.dialogue._on_choice("evidence")
	await _drain_until_flag("game_complete")
	_check("ledger ending selected", GameState.get_flag("final_ending", "") == "ledger")
	_check("game_complete set on ledger ending", GameState.get_flag("game_complete", false))

	ch5.get_parent().remove_child(ch5)
	ch5.queue_free()

func _phase_clean_ending() -> void:
	_seed_full_evidence()
	GameState.npc_actions = {"sal": "work", "priya": "pay"}
	GameState.ledger["trust"]["sal"] = 2
	GameState.ledger["trust"]["priya"] = 1
	GameState.ledger["trust"]["costigan"] = 2

	ch5 = load("res://scenes/Chapter5.tscn").instantiate()
	get_tree().root.add_child.call_deferred(ch5)
	await get_tree().process_frame
	await get_tree().process_frame
	await get_tree().process_frame
	await _drain_dialogue()

	ch5.dialogue._on_choice("evidence")
	await _drain_until_flag("game_complete")
	_check("clean ending selected for full evidence with no lean", GameState.get_flag("final_ending", "") == "clean")

	ch5.get_parent().remove_child(ch5)
	ch5.queue_free()

func _phase_hidden_truth_liability() -> void:
	_seed_full_evidence()
	GameState.npc_actions = {"sal": "work", "priya": "work"}
	GameState.ledger["trust"]["sal"] = 2
	GameState.ledger["trust"]["priya"] = 2
	GameState.ledger["trust"]["costigan"] = 2
	GameState.set_flag("priya_truth_hidden", true)

	ch5 = load("res://scenes/Chapter5.tscn").instantiate()
	get_tree().root.add_child.call_deferred(ch5)
	await get_tree().process_frame
	await get_tree().process_frame
	await get_tree().process_frame

	_check("Priya absent from finale after Chapter IV lie", not ch5.priya.visible)
	await _drain_dialogue()

	ch5.dialogue._on_choice("evidence")
	await _drain_until_flag("game_complete")
	_check("hidden Priya truth blocks clean ending", GameState.get_flag("final_ending", "") == "paid")

	ch5.get_parent().remove_child(ch5)
	ch5.queue_free()

func _phase_paid_ending() -> void:
	_seed_full_evidence()
	GameState.npc_actions = {"sal": "pay", "priya": "lean"}
	GameState.ledger["trust"]["sal"] = 1
	GameState.ledger["trust"]["priya"] = -1
	GameState.ledger["trust"]["costigan"] = 2

	ch5 = load("res://scenes/Chapter5.tscn").instantiate()
	get_tree().root.add_child.call_deferred(ch5)
	await get_tree().process_frame
	await get_tree().process_frame
	await get_tree().process_frame
	await _drain_dialogue()

	ch5.dialogue._on_choice("evidence")
	await _drain_until_flag("game_complete")
	_check("paid ending selected for complete but compromised evidence path", GameState.get_flag("final_ending", "") == "paid")

	ch5.get_parent().remove_child(ch5)
	ch5.queue_free()

func _phase_blood_ending() -> void:
	_seed_full_evidence()
	GameState.npc_actions = {"sal": "lean", "priya": "lean"}
	GameState.ledger["trust"]["sal"] = -3
	GameState.ledger["trust"]["priya"] = -3

	ch5 = load("res://scenes/Chapter5.tscn").instantiate()
	get_tree().root.add_child.call_deferred(ch5)
	await get_tree().process_frame
	await get_tree().process_frame
	await get_tree().process_frame
	await _drain_dialogue()

	ch5.dialogue._on_choice("bluff")
	await _drain_until_flag("game_complete")
	_check("blood ending selected for high lean", GameState.get_flag("final_ending", "") == "blood")
	_check("game_complete set on blood ending", GameState.get_flag("game_complete", false))

func _seed_full_evidence() -> void:
	_reset_gamestate()
	GameState.add_clue("spatter", "cause_location_mismatch", "Arterial spatter")
	GameState.add_clue("receipt", "timeline_marker", "Receipt")
	GameState.add_clue("ropeburn", "staging_evidence", "Rope burn")
	GameState.set_flag("chapter3_success", true)
	GameState.set_flag("audit_solved", true)
	GameState.set_flag("safe_done", true)
	GameState.set_flag("costigan_boat_lead", true)

func _reset_gamestate() -> void:
	GameState.collected_clues = {}
	GameState.cash = 400
	GameState.heat = 0
	GameState.npc_actions = {}
	GameState.ledger = {"trust": {"reyes": 0, "sal": 0, "priya": 0, "costigan": 0}, "flags": {}}

func _drain_dialogue(max_steps: int = 25) -> void:
	var steps := 0
	await get_tree().process_frame
	while ch5.dialogue.box_visible and ch5.dialogue.choice_container.get_child_count() == 0 and steps < max_steps:
		ch5.dialogue._advance()
		await get_tree().process_frame
		steps += 1
	if steps >= max_steps:
		_check("dialogue drained without hitting step cap", false)

func _drain_until_flag(flag_name: String, max_steps: int = 30) -> void:
	var steps := 0
	await get_tree().process_frame
	while not GameState.get_flag(flag_name, false) and steps < max_steps:
		if ch5.dialogue.box_visible and ch5.dialogue.choice_container.get_child_count() == 0:
			ch5.dialogue._advance()
		await get_tree().process_frame
		steps += 1
	if steps >= max_steps:
		_check("%s set before step cap" % flag_name, false)

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
