extends Node

var failures: Array = []
var checks := 0

func _ready() -> void:
	var tool = load("res://tools/NavigationAuthoringTool.tscn").instantiate()
	get_tree().root.add_child.call_deferred(tool)
	await get_tree().process_frame
	await get_tree().process_frame

	_check("navigation authoring tool opens", tool != null and tool.background != null and tool.hud_label != null)
	_check("navigation tool loads chapter1 background", tool.background.texture != null and tool.background.texture.resource_path == "res://art/backgrounds/pier9_ch1_background_v2.png")
	_check("navigation tool loads editable layers", tool.polygons["walkable"].size() > 0 and tool.polygons["blocked"].size() > 0 and tool.polygons["occluder_foreground"].size() > 0)
	_check("navigation tool starts in walkable mode", tool.mode == "walkable")

	_report()
	get_tree().quit(1 if failures.size() > 0 else 0)

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
