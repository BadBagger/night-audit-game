extends Node2D

const OUTPUT_DIR := "res://tmp/screenshots"
const CAPTURES := [
	{"name": "chapter1_pier9", "scene": "res://scenes/Main.tscn"},
	{"name": "chapter2_debts_owed", "scene": "res://scenes/Chapter2.tscn"},
	{"name": "chapter3_calloway_star", "scene": "res://scenes/Chapter3.tscn"},
	{"name": "chapter4_apartment", "scene": "res://scenes/Chapter4.tscn"},
	{"name": "chapter5_settlement", "scene": "res://scenes/Chapter5.tscn"},
]

var current_scene: Node

func _ready() -> void:
	get_viewport().size = Vector2i(1600, 900)
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(OUTPUT_DIR))
	await get_tree().process_frame
	for capture in CAPTURES:
		await _capture_scene(capture["scene"], capture["name"])
	get_tree().quit(0)

func _capture_scene(scene_path: String, capture_name: String) -> void:
	if current_scene:
		current_scene.queue_free()
		await get_tree().process_frame

	current_scene = load(scene_path).instantiate()
	get_tree().root.add_child.call_deferred(current_scene)
	for i in range(12):
		await get_tree().process_frame
	_hide_runtime_ui(current_scene)
	await get_tree().process_frame
	_hide_runtime_ui(current_scene)

	var viewport_texture := get_viewport().get_texture()
	if viewport_texture == null:
		push_error("Viewport texture unavailable; run without --headless for captures.")
		return
	var image := viewport_texture.get_image()
	if image == null:
		push_error("Viewport image unavailable; run without --headless for captures.")
		return
	var output_path := "%s/%s.png" % [OUTPUT_DIR, capture_name]
	var err := image.save_png(output_path)
	if err != OK:
		push_error("Failed to save %s: %s" % [output_path, err])
	else:
		print("SAVED ", ProjectSettings.globalize_path(output_path))

func _hide_runtime_ui(root: Node) -> void:
	for child in root.get_children():
		if child is CanvasLayer:
			child.visible = false
		_hide_runtime_ui(child)
