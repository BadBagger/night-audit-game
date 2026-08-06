extends Node2D

var ch3: Node
var failures: Array = []
var checks := 0

func _ready() -> void:
	await _phase_retreat_rule()
	_reset_gamestate()
	await _phase_success_path()

	_report()
	get_tree().quit()

# --- Phase 1: the "second spot always forces retreat" rule, in isolation,
# with conditions that would otherwise favor a cover-holds outcome. ---
func _phase_retreat_rule() -> void:
	GameState.set_flag("times_spotted", 1)
	GameState.ledger["trust"]["costigan"] = 5  # deliberately generous cover
	GameState.heat = 0

	ch3 = load("res://scenes/Chapter3.tscn").instantiate()
	get_tree().root.add_child.call_deferred(ch3)
	await get_tree().process_frame
	await get_tree().process_frame
	await get_tree().process_frame
	await _drain_dialogue()

	_check("chapter3 retreat phase Dana has animated visual", _has_visual(ch3.player))
	_check("Voss has animated patrol visual", _has_visual(ch3.voss))
	ch3.voss.advance_patrol(ch3.voss.dwell_a + 0.1)
	ch3.voss.advance_patrol(0.2)
	_check("Voss uses walk animation while patrolling", ch3.voss.character_visual.current_mode == "walk")

	ch3.voss.player_spotted.emit()
	await _drain_until_flag("chapter3_retreat")
	_check("second spot forces retreat despite favorable cover", GameState.get_flag("chapter3_retreat", false))
	ch3.ledger_prop.interact()
	await get_tree().process_frame
	_check("audit board does not open after retreat", not ch3.audit_board.visible)

	ch3.get_parent().remove_child(ch3)
	ch3.queue_free()

func _reset_gamestate() -> void:
	GameState.collected_clues = {}
	GameState.cash = 400
	GameState.heat = 0
	GameState.npc_actions = {}
	GameState.ledger = {"trust": {"reyes": 0, "sal": 0, "priya": 0, "costigan": 0}, "flags": {}}

# --- Phase 2: full success path -- one spot that cover-holds, an
# over-flagged audit attempt that correctly rejects, then the correct
# solve, then the code-branch safe, then the scripted success ending. ---
func _phase_success_path() -> void:
	GameState.set_flag("sal_gave_code", true)
	GameState.ledger["trust"]["costigan"] = 1

	ch3 = load("res://scenes/Chapter3.tscn").instantiate()
	get_tree().root.add_child.call_deferred(ch3)
	await get_tree().process_frame
	await get_tree().process_frame
	await get_tree().process_frame

	_check("chapter3 intro dialogue opened", ch3.dialogue.box_visible)
	_check("intro line has audio loaded", ch3.dialogue.audio_player.stream != null)
	_check("chapter3 success phase Dana has animated visual", _has_visual(ch3.player))
	_check("chapter3 success phase Voss has animated visual", _has_visual(ch3.voss))
	await _drain_dialogue()

	ch3.voss.player_spotted.emit()
	await _drain_dialogue()
	_check("first spot with good cover does not retreat", not GameState.get_flag("chapter3_retreat", false))
	_check("times_spotted is 1", GameState.get_flag("times_spotted", 0) == 1)

	ch3.ledger_prop.interact()
	await get_tree().process_frame
	_check("audit board opened", ch3.audit_board.visible)

	# T1 flagged first so the incremental additions never pass through an
	# exact-match state on the way to over-flagged (order matters: the
	# board checks for a solve after every toggle).
	for id in ["T1", "T3", "T5", "T6", "T7", "T8"]:
		ch3.audit_board._on_toggled(id, true)
	_check("over-flagged set correctly rejected, not solved", not GameState.get_flag("audit_solved", false))

	ch3.audit_board._on_toggled("T1", false)
	await get_tree().process_frame
	_check("audit solved once the extra flag is corrected", GameState.get_flag("audit_solved", false))
	await _drain_dialogue()

	ch3.safe_prop.interact()
	await _drain_until_flag("chapter3_complete")
	_check("safe_done set on code branch", GameState.get_flag("safe_done", false))
	_check("heat unchanged on correct-code safe branch", GameState.heat == 0)

	_check("chapter3_success set once both objectives are done", GameState.get_flag("chapter3_success", false))
	_check("chapter3_complete set", GameState.get_flag("chapter3_complete", false))
	_check("chapter3_retreat NOT set on the success path", not GameState.get_flag("chapter3_retreat", false))

func _drain_dialogue(max_steps: int = 25) -> void:
	var steps := 0
	await get_tree().process_frame
	while ch3.dialogue.box_visible and ch3.dialogue.choice_container.get_child_count() == 0 and steps < max_steps:
		ch3.dialogue._advance()
		await get_tree().process_frame
		steps += 1
	if steps >= max_steps:
		_check("dialogue drained without hitting step cap (possible infinite loop)", false)

func _drain_until_flag(flag_name: String, max_steps: int = 30) -> void:
	var steps := 0
	await get_tree().process_frame
	while not GameState.get_flag(flag_name, false) and steps < max_steps:
		if ch3.dialogue.box_visible and ch3.dialogue.choice_container.get_child_count() == 0:
			ch3.dialogue._advance()
		await get_tree().process_frame
		steps += 1
	if steps >= max_steps:
		_check("%s set before step cap" % flag_name, false)

func _has_visual(node: Node) -> bool:
	return node.get("character_visual") != null

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
