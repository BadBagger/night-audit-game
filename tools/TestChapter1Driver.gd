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
	_check("chapter1 atmosphere layer exists", main_scene.atmosphere != null and main_scene.atmosphere.is_in_group("chapter1_atmosphere"))
	_check("chapter1 set dressing root exists", main_scene.set_dressing_root != null)
	_check("chapter1 has dense dockyard set dressing", main_scene.set_dressing_root.get_child_count() >= 16)
	_check("chapter1 has rain, puddles, and light pools", main_scene.atmosphere.rain_lines >= 80 and main_scene.atmosphere.puddles.size() >= 4 and main_scene.atmosphere.light_pools.size() >= 3)
	_check("chapter1 key props are named for tuning", main_scene.set_dressing_root.has_node("security_barrier_gate") and main_scene.set_dressing_root.has_node("container_office_clutter") and main_scene.set_dressing_root.has_node("dock_edge_harbor"))
	_check("chapter1 uses real reusable prop sprites", _count_reusable_props() >= 17)
	_check("chapter1 reusable props load expected assets", _has_reusable_asset("portable_dock_lamp") and _has_reusable_asset("straight_hazard_tape") and _has_reusable_asset("wet_wooden_crate") and _has_reusable_asset("rusty_oil_drum") and _has_reusable_asset("coiled_rope") and _has_reusable_asset("evidence_marker_card"))
	_check("chapter1 structural placeholders use reusable sprites", _has_reusable_asset("long_pier_dock_edge_strip") and _has_reusable_asset("open_container_office_clutter") and _has_reusable_asset("dock_security_gate") and _has_reusable_asset("portable_police_barricade") and _has_reusable_asset("harbor_tiedown_ropeburn_fixture"))
	_check("chapter1 player has walkable areas and building blockers", main_scene.player.walkable_areas.size() >= 3 and main_scene.player.blocked_areas.size() >= 3)
	_check("chapter1 blocks roof and building stand positions", not main_scene.player.can_stand_at(Vector2(1220, 710)) and not main_scene.player.can_stand_at(Vector2(1640, 500)))
	_check("chapter1 keeps evidence reachable from legal walk path", _has_reachable_standpoint(Vector2(520, 410)) and _has_reachable_standpoint(Vector2(690, 370)) and _has_reachable_standpoint(Vector2(425, 515)))
	_check("chapter1 living idles use animated source frames", main_scene.player.character_visual.sprite.sprite_frames.get_frame_count("idle") > 1 and main_scene.reyes.character_visual.sprite.sprite_frames.get_frame_count("idle") > 1 and main_scene.frank.character_visual.sprite.sprite_frames.get_frame_count("idle") > 1)
	_check("chapter1 body is staged as background evidence", main_scene.mick_body.visual_scale <= 0.45 and main_scene.mick_body.modulate.a < 0.9)

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
	get_tree().quit(1 if failures.size() > 0 else 0)

func _find_clues() -> Array:
	var out := []
	for c in main_scene.get_children():
		if c.get("clue_id") != null and c.clue_id != "":
			out.append(c)
	return out

func _count_reusable_props() -> int:
	var count := 0
	for child in main_scene.set_dressing_root.get_children():
		if child.is_in_group("reusable_prop_sprite"):
			count += 1
	return count

func _has_reusable_asset(asset_id: String) -> bool:
	for child in main_scene.set_dressing_root.get_children():
		if not child.is_in_group("reusable_prop_sprite"):
			continue
		if child.get("asset_id") == asset_id and child.get("texture") != null:
			return true
	return false

func _has_reachable_standpoint(target: Vector2) -> bool:
	for x_offset in range(-56, 57, 14):
		for y_offset in range(-56, 57, 14):
			var candidate := target + Vector2(x_offset, y_offset)
			if candidate.distance_to(target) <= 56.0 and main_scene.player.can_stand_at(candidate):
				return true
	return false

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
