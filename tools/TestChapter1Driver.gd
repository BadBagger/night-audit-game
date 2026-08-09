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
	_check("chapter1 uses generated v2 background plate", _uses_texture(main_scene, "res://art/backgrounds/pier9_ch1_background_v2.png"))
	_check("chapter1 foreground rain is light overlay only", not main_scene.atmosphere.draw_ground_effects and main_scene.atmosphere.draw_foreground_effects and main_scene.atmosphere.rain_lines <= 100)
	_check("chapter1 world audio layer exists", main_scene.world_audio != null and main_scene.world_audio.is_in_group("chapter1_world_audio"))
	_check("chapter1 set dressing root exists", main_scene.set_dressing_root != null)
	_check("chapter1 keeps generated plate clean of pasted-on prop stack", main_scene.set_dressing_root.get_child_count() == 0)
	_check("chapter1 has no procedural set-piece drawings in scene", _count_procedural_set_pieces() == 0)
	_check("chapter1 leaves wetness and worldbuilding baked into the plate", main_scene.atmosphere.puddles.is_empty() and main_scene.atmosphere.light_pools.is_empty())
	_check("chapter1 spatial soundscape uses imported audio", main_scene.world_audio.ambient_players.size() >= 5 and main_scene.world_audio.one_shot_players.size() >= 6)
	_check("chapter1 player has authored polygon walk and block maps", main_scene.player.walkable_polygons.size() >= 1 and main_scene.player.blocked_polygons.size() >= 3)
	_check("chapter1 allows broad movement through the generated yard", main_scene.player.can_stand_at(Vector2(760, 650)) and main_scene.player.can_stand_at(Vector2(1000, 600)) and main_scene.player.can_stand_at(Vector2(1240, 640)))
	_check("chapter1 blocks office, body, containers, and harbor edge", not main_scene.player.can_stand_at(Vector2(470, 180)) and not main_scene.player.can_stand_at(Vector2(430, 520)) and not main_scene.player.can_stand_at(Vector2(1390, 310)) and not main_scene.player.can_stand_at(Vector2(1300, 820)))
	_check("chapter1 keeps evidence reachable from legal walk path", _has_reachable_standpoint(Vector2(445, 520)) and _has_reachable_standpoint(Vector2(595, 500)) and _has_reachable_standpoint(Vector2(245, 650)))
	_check("chapter1 living idles use animated source frames", main_scene.player.character_visual.sprite.sprite_frames.get_frame_count("idle") > 1 and main_scene.reyes.character_visual.sprite.sprite_frames.get_frame_count("idle") > 1 and main_scene.frank.character_visual.sprite.sprite_frames.get_frame_count("idle") > 1)
	_check("chapter1 body is baked into background, not overlaid as a floating sprite", main_scene.mick_body.name == "MickBodyBakedIntoBackground")

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

func _count_reusable_decals() -> int:
	var count := 0
	for child in main_scene.set_dressing_root.get_children():
		if child.is_in_group("reusable_decal_sprite"):
			count += 1
	return count

func _count_procedural_set_pieces() -> int:
	var count := 0
	for child in main_scene.set_dressing_root.get_children():
		var script = child.get_script()
		if script != null and script.resource_path == "res://scripts/Chapter1SetPiece.gd":
			count += 1
	return count

func _uses_texture(root: Node, path: String) -> bool:
	for child in root.get_children():
		if child is Sprite2D and child.texture != null and child.texture.resource_path == path:
			return true
	return false

func _has_reusable_asset(asset_id: String) -> bool:
	for child in main_scene.set_dressing_root.get_children():
		if not child.is_in_group("reusable_prop_sprite"):
			continue
		if child.get("asset_id") == asset_id and child.get("texture") != null:
			return true
	return false

func _all_reusable_props_opaque() -> bool:
	for child in main_scene.set_dressing_root.get_children():
		if not child.is_in_group("reusable_prop_sprite"):
			continue
		if child.modulate.a < 0.99:
			return false
	return true

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
