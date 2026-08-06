extends Node2D

var ch4: Node
var failures: Array = []
var checks := 0

func _ready() -> void:
	_reset_gamestate()
	GameState.set_flag("priya_done", true)
	GameState.npc_actions["priya"] = "work"

	ch4 = load("res://scenes/Chapter4.tscn").instantiate()
	get_tree().root.add_child.call_deferred(ch4)
	await get_tree().process_frame
	await get_tree().process_frame
	await get_tree().process_frame

	_check("chapter4 intro dialogue opened", ch4.dialogue.box_visible)
	_check("chapter4 Dana has animated visual", ch4.player.get("character_visual") != null)
	_check("chapter4 Reyes has animated visual", ch4.reyes.character_visual != null)
	await _drain_dialogue()
	_check("Priya truth choice offered when trust intact", ch4.dialogue.choice_container.get_child_count() == 2)

	ch4.dialogue._on_choice("truth")
	await _drain_until_flag("chapter4_complete")
	_check("priya_truth_told flag set", GameState.get_flag("priya_truth_told", false))
	_check("chapter4_complete set", GameState.get_flag("chapter4_complete", false))

	_report()
	get_tree().quit()

func _reset_gamestate() -> void:
	GameState.collected_clues = {}
	GameState.cash = 400
	GameState.heat = 0
	GameState.npc_actions = {}
	GameState.ledger = {"trust": {"reyes": 0, "sal": 0, "priya": 0, "costigan": 0}, "flags": {}}

func _drain_dialogue(max_steps: int = 25) -> void:
	var steps := 0
	await get_tree().process_frame
	while ch4.dialogue.box_visible and ch4.dialogue.choice_container.get_child_count() == 0 and steps < max_steps:
		ch4.dialogue._advance()
		await get_tree().process_frame
		steps += 1
	if steps >= max_steps:
		_check("dialogue drained without hitting step cap", false)

func _drain_until_flag(flag_name: String, max_steps: int = 25) -> void:
	var steps := 0
	await get_tree().process_frame
	while not GameState.get_flag(flag_name, false) and steps < max_steps:
		if ch4.dialogue.box_visible and ch4.dialogue.choice_container.get_child_count() == 0:
			ch4.dialogue._advance()
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
