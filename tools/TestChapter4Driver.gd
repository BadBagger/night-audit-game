extends Node2D

var ch4: Node
var failures: Array = []
var checks := 0

func _ready() -> void:
	await _phase_truth_branch()
	_reset_gamestate()
	await _phase_lie_branch()
	_reset_gamestate()
	await _phase_lean_branch()

	_report()
	get_tree().quit(1 if failures.size() > 0 else 0)

func _phase_truth_branch() -> void:
	_seed_priya_intact("work")
	_load_chapter4()
	await _settle_scene()

	_check("chapter4 intro dialogue opened", ch4.dialogue.box_visible)
	_check("chapter4 uses generated background plate", ch4.has_node("chapter4_apartment_plate") and ch4.get_node("chapter4_apartment_plate") is Sprite2D)
	_check("chapter4 environment has no procedural Prop rectangles", _count_props(ch4) == 0)
	_check("chapter4 Dana has animated visual", ch4.player.get("character_visual") != null)
	_check("chapter4 Reyes has animated visual", ch4.reyes.character_visual != null)
	_check("Priya starts hidden before revisit beat", not ch4.priya.visible)
	await _drain_dialogue()
	_check("Priya truth choice offered when trust intact", ch4.dialogue.choice_container.get_child_count() == 2)
	_check("Priya enters for intact-trust revisit", ch4.priya.visible and ch4.priya.position.x > 940.0)

	ch4.dialogue._on_choice("truth")
	await _drain_until_flag("chapter4_complete")
	_check("priya_truth_told flag set", GameState.get_flag("priya_truth_told", false))
	_check("chapter4_complete set on truth branch", GameState.get_flag("chapter4_complete", false))
	_unload_chapter4()

func _phase_lie_branch() -> void:
	_seed_priya_intact("pay")
	_load_chapter4()
	await _settle_scene()
	await _drain_dialogue()
	ch4.dialogue._on_choice("lie")
	await _drain_until_flag("chapter4_complete")
	_check("priya_truth_hidden flag set", GameState.get_flag("priya_truth_hidden", false))
	_check("chapter4_complete set on lie branch", GameState.get_flag("chapter4_complete", false))
	_unload_chapter4()

func _phase_lean_branch() -> void:
	_seed_priya_intact("lean")
	_load_chapter4()
	await _settle_scene()
	await _advance_dialogue_steps(5)
	_check("Priya branch has no truth choice after LEAN", ch4.dialogue.choice_container.get_child_count() == 0)
	_check("Priya door position used after burned-trust branch", ch4.priya.visible and ch4.priya.position == ch4.PRIYA_DOOR_POSITION)
	await _drain_until_flag("chapter4_complete")
	_check("chapter4_complete set on leaned-Priya branch", GameState.get_flag("chapter4_complete", false))
	_check("truth flags remain unset after leaned-Priya branch", not GameState.get_flag("priya_truth_told", false) and not GameState.get_flag("priya_truth_hidden", false))
	_unload_chapter4()

func _seed_priya_intact(action: String) -> void:
	GameState.set_flag("priya_done", true)
	GameState.npc_actions["priya"] = action

func _load_chapter4() -> void:
	ch4 = load("res://scenes/Chapter4.tscn").instantiate()
	get_tree().root.add_child.call_deferred(ch4)

func _settle_scene() -> void:
	await get_tree().process_frame
	await get_tree().process_frame
	await get_tree().process_frame

func _unload_chapter4() -> void:
	ch4.get_parent().remove_child(ch4)
	ch4.queue_free()
	ch4 = null

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

func _advance_dialogue_steps(step_count: int) -> void:
	for i in range(step_count):
		if ch4.dialogue.box_visible and ch4.dialogue.choice_container.get_child_count() == 0:
			ch4.dialogue._advance()
		await get_tree().process_frame

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

func _count_props(root: Node) -> int:
	var count := 0
	for child in root.get_children():
		if child is Prop:
			count += 1
	return count

func _report() -> void:
	print("")
	print("=== %d/%d checks passed ===" % [checks - failures.size(), checks])
	if failures.size() > 0:
		print("FAILURES:")
		for f in failures:
			print(" - ", f)
