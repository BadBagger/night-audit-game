extends Node2D

const SAVE_PATH := "res://art/navigation/chapter1_navigation_authoring.json"
const DEFAULT_BACKGROUND := "res://art/backgrounds/pier9_ch1_background_v2.png"

var background: Sprite2D
var camera: Camera2D
var hud_label: Label
var mode := "walkable"
var polygons := {
	"walkable": [],
	"blocked": [],
	"occluder_foreground": [],
}
var current_points := PackedVector2Array()
var mouse_world := Vector2.ZERO

func _ready() -> void:
	_build_background()
	_build_camera()
	_build_hud()
	_load_existing()
	queue_redraw()

func _build_background() -> void:
	background = Sprite2D.new()
	background.texture = load(DEFAULT_BACKGROUND)
	background.centered = false
	background.z_index = -100
	add_child(background)

func _build_camera() -> void:
	camera = Camera2D.new()
	camera.position = Vector2(840, 472)
	camera.zoom = Vector2(1.0, 1.0)
	camera.enabled = true
	add_child(camera)

func _build_hud() -> void:
	var canvas := CanvasLayer.new()
	canvas.layer = 50
	add_child(canvas)
	hud_label = Label.new()
	hud_label.position = Vector2(12, 10)
	hud_label.add_theme_font_size_override("font_size", 13)
	hud_label.add_theme_color_override("font_color", Color(0.92, 0.94, 0.96))
	canvas.add_child(hud_label)
	_update_hud()

func _process(delta: float) -> void:
	var pan := Vector2.ZERO
	if Input.is_key_pressed(KEY_A):
		pan.x -= 1.0
	if Input.is_key_pressed(KEY_D):
		pan.x += 1.0
	if Input.is_key_pressed(KEY_W):
		pan.y -= 1.0
	if Input.is_key_pressed(KEY_S):
		pan.y += 1.0
	if pan != Vector2.ZERO:
		camera.position += pan.normalized() * 520.0 * delta / camera.zoom.x
	_update_hud()

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseMotion:
		mouse_world = get_global_mouse_position()
		_update_hud()
		queue_redraw()
	elif event is InputEventMouseButton and event.pressed:
		if event.button_index == MOUSE_BUTTON_LEFT:
			current_points.append(get_global_mouse_position())
			queue_redraw()
		elif event.button_index == MOUSE_BUTTON_RIGHT:
			_commit_current_polygon()
		elif event.button_index == MOUSE_BUTTON_WHEEL_UP:
			camera.zoom *= 1.08
		elif event.button_index == MOUSE_BUTTON_WHEEL_DOWN:
			camera.zoom /= 1.08
	elif event is InputEventKey and event.pressed and not event.echo:
		_handle_key(event)

func _handle_key(event: InputEventKey) -> void:
	match event.keycode:
		KEY_1:
			mode = "walkable"
			current_points.clear()
		KEY_2:
			mode = "blocked"
			current_points.clear()
		KEY_3:
			mode = "occluder_foreground"
			current_points.clear()
		KEY_ENTER:
			_commit_current_polygon()
		KEY_BACKSPACE:
			if current_points.size() > 0:
				current_points.remove_at(current_points.size() - 1)
		KEY_Z:
			if polygons[mode].size() > 0:
				polygons[mode].pop_back()
		KEY_C:
			current_points.clear()
		KEY_DELETE:
			polygons[mode].clear()
			current_points.clear()
		KEY_F:
			camera.position = Vector2(840, 472)
			camera.zoom = Vector2.ONE
		KEY_P:
			_print_export()
		KEY_SPACE:
			_commit_current_polygon()
	if event.keycode == KEY_S and event.ctrl_pressed:
		_save()
	_update_hud()
	queue_redraw()

func _commit_current_polygon() -> void:
	if current_points.size() < 3:
		return
	polygons[mode].append(current_points.duplicate())
	current_points.clear()

func _draw() -> void:
	_draw_polygons("walkable", Color(0.16, 0.9, 0.36, 0.22), Color(0.3, 1.0, 0.48, 0.92))
	_draw_polygons("blocked", Color(1.0, 0.18, 0.14, 0.24), Color(1.0, 0.32, 0.26, 0.95))
	_draw_polygons("occluder_foreground", Color(0.56, 0.26, 1.0, 0.24), Color(0.72, 0.46, 1.0, 0.95))
	_draw_current()

func _draw_polygons(kind: String, fill: Color, stroke: Color) -> void:
	for polygon in polygons[kind]:
		if polygon.size() < 3:
			continue
		draw_polygon(polygon, PackedColorArray([fill]))
		var line := PackedVector2Array(polygon)
		line.append(polygon[0])
		draw_polyline(line, stroke, 3.0)
		for point in polygon:
			draw_circle(point, 4.0, stroke)

func _draw_current() -> void:
	var stroke := _mode_stroke()
	for point in current_points:
		draw_circle(point, 5.0, stroke)
	if current_points.size() > 1:
		draw_polyline(current_points, stroke, 3.0)
	if current_points.size() > 0:
		draw_line(current_points[current_points.size() - 1], mouse_world, Color(stroke.r, stroke.g, stroke.b, 0.55), 2.0)

func _mode_stroke() -> Color:
	match mode:
		"blocked":
			return Color(1.0, 0.32, 0.26, 1.0)
		"occluder_foreground":
			return Color(0.72, 0.46, 1.0, 1.0)
		_:
			return Color(0.3, 1.0, 0.48, 1.0)

func _load_existing() -> void:
	if not FileAccess.file_exists(SAVE_PATH):
		return
	var file := FileAccess.open(SAVE_PATH, FileAccess.READ)
	if file == null:
		return
	var parsed = JSON.parse_string(file.get_as_text())
	if not parsed is Dictionary:
		return
	for key in polygons.keys():
		polygons[key].clear()
		for raw_polygon in parsed.get(key, []):
			var points := PackedVector2Array()
			for raw_point in raw_polygon:
				if raw_point is Array and raw_point.size() >= 2:
					points.append(Vector2(float(raw_point[0]), float(raw_point[1])))
			if points.size() >= 3:
				polygons[key].append(points)

func _save() -> void:
	_commit_current_polygon()
	var payload := {
		"background": DEFAULT_BACKGROUND,
		"notes": "Authored with tools/NavigationAuthoringTool.tscn. Walkable and blocked are used by Chapter 1. occluder_foreground marks painted elements that need a foreground cutout or 3D depth layer so Dana can travel behind them.",
		"walkable": _serialize_polygons(polygons["walkable"]),
		"blocked": _serialize_polygons(polygons["blocked"]),
		"occluder_foreground": _serialize_polygons(polygons["occluder_foreground"]),
	}
	var file := FileAccess.open(SAVE_PATH, FileAccess.WRITE)
	if file == null:
		push_error("Could not save navigation authoring JSON: %s" % SAVE_PATH)
		return
	file.store_string(JSON.stringify(payload, "\t"))
	print("Saved navigation authoring: ", SAVE_PATH)

func _serialize_polygons(raw_polygons: Array) -> Array:
	var out := []
	for polygon in raw_polygons:
		var points := []
		for point in polygon:
			points.append([round(point.x), round(point.y)])
		out.append(points)
	return out

func _print_export() -> void:
	print(JSON.stringify({
		"walkable": _serialize_polygons(polygons["walkable"]),
		"blocked": _serialize_polygons(polygons["blocked"]),
		"occluder_foreground": _serialize_polygons(polygons["occluder_foreground"]),
	}, "\t"))

func _update_hud() -> void:
	if hud_label == null:
		return
	hud_label.text = "Navigation Authoring | mode: %s | mouse: %d,%d | polygons W:%d B:%d O:%d\n1 walkable  2 blocked  3 foreground/3D occluder | Left click point  Right click/Enter close | Backspace undo point  Z undo polygon  Delete clear mode  F frame  Ctrl+S save | WASD pan  wheel zoom" % [
		mode,
		round(mouse_world.x),
		round(mouse_world.y),
		polygons["walkable"].size(),
		polygons["blocked"].size(),
		polygons["occluder_foreground"].size(),
	]
