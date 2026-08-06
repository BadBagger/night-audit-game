extends Node2D

var ch2: Node
var failures: Array = []
var checks := 0

func _ready() -> void:
	ch2 = load("res://scenes/Chapter2.tscn").instantiate()
	get_tree().root.add_child.call_deferred(ch2)
	await get_tree().process_frame
	await get_tree().process_frame
	await get_tree().process_frame

	_check("chapter2 intro dialogue opened", ch2.dialogue.box_visible)
	await _drain_dialogue()

	# --- Sal: WORK branch ---
	ch2.sal.interact()
	await get_tree().process_frame
	_check("sal intro line has audio loaded", ch2.dialogue.audio_player.stream != null)
	await _drain_dialogue()
	_check("ticket board opened after Sal intro", ch2.ticket_board.visible)

	ch2.ticket_board._try_ticket(3312, 12)
	_check("wrong ticket rejected", not GameState.get_flag("sal_ticket_solved", false))

	ch2.ticket_board._try_ticket(5206, 13)
	await _drain_dialogue()
	_check("sal ticket solved advances dialogue", ch2.dialogue.box_visible or GameState.get_flag("sal_ticket_solved", false))

	ch2.dialogue._on_choice("work")
	await _drain_dialogue()
	_check("sal_done set after WORK branch", GameState.get_flag("sal_done", false))
	_check("sal_gave_code true on WORK branch", GameState.get_flag("sal_gave_code", false))
	_check("sal trust +2 on WORK branch", GameState.ledger["trust"]["sal"] == 2)
	_check("cash unchanged on WORK branch", GameState.cash == 400)

	# --- Priya: LEAN branch ---
	ch2.priya.interact()
	await _drain_dialogue()
	_check("manifest board opened after Priya intro", ch2.manifest_board.visible)

	ch2.manifest_board._on_donation_toggled("G2", true)
	_check("wrong donation flagged doesn't solve it", not GameState.get_flag("priya_manifest_solved", false))
	ch2.manifest_board._on_donation_toggled("G2", false)

	ch2.manifest_board._on_donation_toggled("G1", true)
	ch2.manifest_board._on_donation_toggled("G3", true)
	ch2.manifest_board._on_account_toggled(true)
	await _drain_dialogue()
	_check("priya_manifest_solved set", GameState.get_flag("priya_manifest_solved", false))

	ch2.dialogue._on_choice("lean")
	await _drain_dialogue()
	_check("priya_done set after LEAN branch", GameState.get_flag("priya_done", false))
	_check("priya trust -3 on LEAN branch", GameState.ledger["trust"]["priya"] == -3)

	# --- Costigan: wrong order once, then correct sequence ---
	ch2.costigan.interact()
	await _drain_dialogue()
	_check("costigan choice offered", ch2.dialogue.choice_container.get_child_count() == 3)

	ch2.dialogue._on_choice("case")  # wrong first move from hostile -> soft miss
	await _drain_dialogue()
	_check("costigan stays hostile on wrong first move", ch2.costigan_state == "hostile")
	_check("costigan hostile_misses counted", ch2.costigan_hostile_misses == 1)

	ch2.dialogue._on_choice("grief")
	await _drain_dialogue()
	_check("costigan advances to guarded on grief", ch2.costigan_state == "guarded")

	ch2.dialogue._on_choice("case")
	await _drain_dialogue()
	_check("costigan advances to listening on case", ch2.costigan_state == "listening")

	ch2.dialogue._on_choice("offer")
	await _drain_dialogue()
	_check("costigan reaches open state", ch2.costigan_state == "open")
	_check("costigan_boat_lead flag set", GameState.get_flag("costigan_boat_lead", false))

	await _drain_dialogue()
	_check("costigan_done set", GameState.get_flag("costigan_done", false))

	_check("chapter2_complete set once all three are done", GameState.get_flag("chapter2_complete", false))

	_report()
	get_tree().quit()

func _drain_dialogue(max_steps: int = 25) -> void:
	var steps := 0
	await get_tree().process_frame
	while ch2.dialogue.box_visible and ch2.dialogue.choice_container.get_child_count() == 0 and steps < max_steps:
		ch2.dialogue._advance()
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
