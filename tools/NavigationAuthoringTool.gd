extends Node2D

const SAVE_PATH := "res://art/navigation/chapter1_navigation_authoring.json"
const DEFAULT_BACKGROUND := "res://art/backgrounds/pier9_ch1_background_v2.png"
const POINT_PICK_RADIUS := 14.0
const EDGE_PICK_DISTANCE := 12.0

var background: Sprite2D
var hud_label: Label
var map_layer: Node2D
var mode := "walkable"
var polygons := {
	"walkable": [],
	"blocked": [],
	"occluder_foreground": [],
}
var current_points := PackedVector2Array()
var mouse_world := Vector2.ZERO
var selected_kind := ""
var selected_polygon_index := -1
var selected_point_index := -1
var dragging_point := false
var view_offset := Vector2(28, 86)
var view_zoom := 0.78
var undo_stack: Array = []
var redo_stack: Array = []
var drag_snapshot: Dictionary = {}

func _ready() -> void:
	_build_map_layer()
	_build_hud()
	_load_existing()
	_frame_background()
	_capture_history_baseline()
	queue_redraw()

func _build_map_layer() -> void:
	map_layer = Node2D.new()
	add_child(map_layer)
	background = Sprite2D.new()
	background.texture = load(DEFAULT_BACKGROUND)
	background.centered = false
	background.z_index = -100
	map_layer.add_child(background)
	_apply_view_transform()

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
		view_offset -= pan.normalized() * 520.0 * delta
		_apply_view_transform()
	_update_hud()

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseMotion:
		mouse_world = _screen_to_world(event.position)
		if dragging_point:
			_move_selected_point(mouse_world)
		_update_hud()
		queue_redraw()
	elif event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
			var click_pos := _screen_to_world(event.position)
			if _select_nearest_point(click_pos):
				drag_snapshot = _snapshot_state()
				dragging_point = true
			elif event.shift_pressed and _insert_point_on_nearest_edge(click_pos):
				pass
			else:
				_push_undo_state()
				_clear_selection()
				current_points.append(click_pos)
			queue_redraw()
		elif event.button_index == MOUSE_BUTTON_LEFT and not event.pressed:
			if dragging_point and not drag_snapshot.is_empty() and not _states_equal(drag_snapshot, _snapshot_state()):
				undo_stack.append(drag_snapshot)
				redo_stack.clear()
				drag_snapshot = {}
			dragging_point = false
		elif event.button_index == MOUSE_BUTTON_RIGHT and event.pressed:
			_commit_current_polygon()
		elif event.button_index == MOUSE_BUTTON_WHEEL_UP and event.pressed:
			_zoom_at(event.position, 1.08)
		elif event.button_index == MOUSE_BUTTON_WHEEL_DOWN and event.pressed:
			_zoom_at(event.position, 1.0 / 1.08)
	elif event is InputEventKey and event.pressed and not event.echo:
		_handle_key(event)

func _handle_key(event: InputEventKey) -> void:
	if event.ctrl_pressed and event.keycode == KEY_Z:
		if event.shift_pressed:
			_redo()
		else:
			_undo()
		_update_hud()
		queue_redraw()
		return
	if event.ctrl_pressed and event.keycode == KEY_Y:
		_redo()
		_update_hud()
		queue_redraw()
		return
	match event.keycode:
		KEY_1:
			mode = "walkable"
			current_points.clear()
			_clear_selection()
		KEY_2:
			mode = "blocked"
			current_points.clear()
			_clear_selection()
		KEY_3:
			mode = "occluder_foreground"
			current_points.clear()
			_clear_selection()
		KEY_ENTER:
			_commit_current_polygon()
		KEY_BACKSPACE:
			if current_points.size() > 0:
				_push_undo_state()
				current_points.remove_at(current_points.size() - 1)
			elif _has_selection():
				_delete_selected_point()
		KEY_Z:
			_push_undo_state()
			if polygons[mode].size() > 0:
				polygons[mode].pop_back()
				_clear_selection()
		KEY_C:
			_push_undo_state()
			current_points.clear()
			_clear_selection()
		KEY_DELETE:
			if _has_selection():
				_delete_selected_point()
			elif event.shift_pressed:
				_push_undo_state()
				polygons[mode].clear()
				current_points.clear()
				_clear_selection()
		KEY_F:
			_frame_background()
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
	_push_undo_state()
	polygons[mode].append(current_points.duplicate())
	current_points.clear()

func _draw() -> void:
	if map_layer == null:
		return
	draw_set_transform(view_offset, 0.0, Vector2(view_zoom, view_zoom))
	_draw_polygons("walkable", Color(0.16, 0.9, 0.36, 0.22), Color(0.3, 1.0, 0.48, 0.92))
	_draw_polygons("blocked", Color(1.0, 0.18, 0.14, 0.24), Color(1.0, 0.32, 0.26, 0.95))
	_draw_polygons("occluder_foreground", Color(0.56, 0.26, 1.0, 0.24), Color(0.72, 0.46, 1.0, 0.95))
	_draw_current()
	draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)

func _draw_polygons(kind: String, fill: Color, stroke: Color) -> void:
	for polygon_index in range(polygons[kind].size()):
		var polygon = polygons[kind][polygon_index]
		if polygon.size() < 3:
			continue
		draw_polygon(polygon, PackedColorArray([fill]))
		var line := PackedVector2Array(polygon)
		line.append(polygon[0])
		draw_polyline(line, stroke, 3.0)
		for point_index in range(polygon.size()):
			var point: Vector2 = polygon[point_index]
			var is_selected := selected_kind == kind and selected_polygon_index == polygon_index and selected_point_index == point_index
			draw_circle(point, 6.5 if is_selected else 4.0, Color.WHITE if is_selected else stroke)
			if is_selected:
				draw_arc(point, 10.0, 0.0, TAU, 24, stroke, 2.0)

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

func _select_nearest_point(pos: Vector2) -> bool:
	var best := {
		"distance": POINT_PICK_RADIUS,
		"kind": "",
		"polygon_index": -1,
		"point_index": -1,
	}
	for kind in [mode, "walkable", "blocked", "occluder_foreground"]:
		for polygon_index in range(polygons[kind].size()):
			var polygon = polygons[kind][polygon_index]
			for point_index in range(polygon.size()):
				var distance := pos.distance_to(polygon[point_index])
				if distance <= best["distance"]:
					best = {
						"distance": distance,
						"kind": kind,
						"polygon_index": polygon_index,
						"point_index": point_index,
					}
	if best["kind"] == "":
		return false
	selected_kind = best["kind"]
	selected_polygon_index = best["polygon_index"]
	selected_point_index = best["point_index"]
	mode = selected_kind
	return true

func _move_selected_point(pos: Vector2) -> void:
	if not _has_selection():
		return
	var polygon: PackedVector2Array = polygons[selected_kind][selected_polygon_index]
	polygon[selected_point_index] = pos
	polygons[selected_kind][selected_polygon_index] = polygon

func _delete_selected_point() -> void:
	if not _has_selection():
		return
	_push_undo_state()
	var polygon: PackedVector2Array = polygons[selected_kind][selected_polygon_index]
	polygon.remove_at(selected_point_index)
	if polygon.size() < 3:
		polygons[selected_kind].remove_at(selected_polygon_index)
	else:
		polygons[selected_kind][selected_polygon_index] = polygon
	_clear_selection()

func _insert_point_on_nearest_edge(pos: Vector2) -> bool:
	var best := {
		"distance": EDGE_PICK_DISTANCE,
		"polygon_index": -1,
		"insert_index": -1,
	}
	for polygon_index in range(polygons[mode].size()):
		var polygon = polygons[mode][polygon_index]
		for point_index in range(polygon.size()):
			var a: Vector2 = polygon[point_index]
			var b: Vector2 = polygon[(point_index + 1) % polygon.size()]
			var distance := _distance_to_segment(pos, a, b)
			if distance <= best["distance"]:
				best = {
					"distance": distance,
					"polygon_index": polygon_index,
					"insert_index": point_index + 1,
				}
	if best["polygon_index"] < 0:
		return false
	_push_undo_state()
	var target: PackedVector2Array = polygons[mode][best["polygon_index"]]
	target.insert(best["insert_index"], pos)
	polygons[mode][best["polygon_index"]] = target
	selected_kind = mode
	selected_polygon_index = best["polygon_index"]
	selected_point_index = best["insert_index"]
	return true

func _distance_to_segment(point: Vector2, a: Vector2, b: Vector2) -> float:
	var ab := b - a
	if ab.length_squared() <= 0.0001:
		return point.distance_to(a)
	var t: float = clamp((point - a).dot(ab) / ab.length_squared(), 0.0, 1.0)
	return point.distance_to(a + ab * t)

func _has_selection() -> bool:
	return selected_kind != "" and selected_polygon_index >= 0 and selected_point_index >= 0 and selected_polygon_index < polygons[selected_kind].size() and selected_point_index < polygons[selected_kind][selected_polygon_index].size()

func _clear_selection() -> void:
	selected_kind = ""
	selected_polygon_index = -1
	selected_point_index = -1
	dragging_point = false

func _capture_history_baseline() -> void:
	undo_stack.clear()
	redo_stack.clear()
	drag_snapshot = {}

func _push_undo_state() -> void:
	undo_stack.append(_snapshot_state())
	if undo_stack.size() > 80:
		undo_stack.pop_front()
	redo_stack.clear()

func _undo() -> void:
	if undo_stack.is_empty():
		return
	redo_stack.append(_snapshot_state())
	_restore_state(undo_stack.pop_back())

func _redo() -> void:
	if redo_stack.is_empty():
		return
	undo_stack.append(_snapshot_state())
	_restore_state(redo_stack.pop_back())

func _snapshot_state() -> Dictionary:
	return {
		"polygons": {
			"walkable": _clone_polygons(polygons["walkable"]),
			"blocked": _clone_polygons(polygons["blocked"]),
			"occluder_foreground": _clone_polygons(polygons["occluder_foreground"]),
		},
		"current_points": current_points.duplicate(),
		"mode": mode,
	}

func _restore_state(state: Dictionary) -> void:
	var state_polygons: Dictionary = state.get("polygons", {})
	for key in polygons.keys():
		polygons[key] = _clone_polygons(state_polygons.get(key, []))
	current_points = state.get("current_points", PackedVector2Array()).duplicate()
	mode = state.get("mode", mode)
	_clear_selection()

func _clone_polygons(raw_polygons: Array) -> Array:
	var out := []
	for polygon in raw_polygons:
		out.append(PackedVector2Array(polygon))
	return out

func _states_equal(a: Dictionary, b: Dictionary) -> bool:
	return JSON.stringify(_state_to_jsonable(a)) == JSON.stringify(_state_to_jsonable(b))

func _state_to_jsonable(state: Dictionary) -> Dictionary:
	var state_polygons: Dictionary = state.get("polygons", {})
	return {
		"polygons": {
			"walkable": _serialize_polygons(state_polygons.get("walkable", [])),
			"blocked": _serialize_polygons(state_polygons.get("blocked", [])),
			"occluder_foreground": _serialize_polygons(state_polygons.get("occluder_foreground", [])),
		},
		"current_points": _serialize_points(state.get("current_points", PackedVector2Array())),
		"mode": state.get("mode", ""),
	}

func _apply_view_transform() -> void:
	if map_layer == null:
		return
	map_layer.position = view_offset
	map_layer.scale = Vector2(view_zoom, view_zoom)

func _screen_to_world(screen_pos: Vector2) -> Vector2:
	return (screen_pos - view_offset) / view_zoom

func _zoom_at(screen_pos: Vector2, factor: float) -> void:
	var before := _screen_to_world(screen_pos)
	view_zoom = clamp(view_zoom * factor, 0.25, 2.5)
	view_offset = screen_pos - before * view_zoom
	_apply_view_transform()
	queue_redraw()

func _frame_background() -> void:
	var viewport_size := get_viewport_rect().size
	var texture_size := Vector2(1680, 945)
	if background != null and background.texture != null:
		texture_size = background.texture.get_size()
	var fit_zoom: float = min((viewport_size.x - 56.0) / texture_size.x, (viewport_size.y - 118.0) / texture_size.y)
	view_zoom = clamp(fit_zoom, 0.25, 1.35)
	view_offset = Vector2((viewport_size.x - texture_size.x * view_zoom) * 0.5, 86.0)
	_apply_view_transform()
	queue_redraw()

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
		out.append(_serialize_points(polygon))
	return out

func _serialize_points(raw_points) -> Array:
	var points := []
	for point in raw_points:
		points.append([round(point.x), round(point.y)])
	return points

func _print_export() -> void:
	print(JSON.stringify({
		"walkable": _serialize_polygons(polygons["walkable"]),
		"blocked": _serialize_polygons(polygons["blocked"]),
		"occluder_foreground": _serialize_polygons(polygons["occluder_foreground"]),
	}, "\t"))

func _update_hud() -> void:
	if hud_label == null:
		return
	var selected_text := "none"
	if _has_selection():
		selected_text = "%s poly %d point %d" % [selected_kind, selected_polygon_index + 1, selected_point_index + 1]
	hud_label.text = "Navigation Authoring | mode: %s | selected: %s | mouse: %d,%d | zoom: %.2f | undo:%d redo:%d | polygons W:%d B:%d O:%d\n1 walkable  2 blocked/no-travel  3 foreground/3D occluder | Left click add/select  Drag selected point  Shift+click edge insert | Ctrl+Z undo  Ctrl+Y/Ctrl+Shift+Z redo | Right click/Enter close | Backspace/Delete selected point  Z undo polygon  Shift+Delete clear mode  F frame  Ctrl+S save" % [
		mode,
		selected_text,
		round(mouse_world.x),
		round(mouse_world.y),
		view_zoom,
		undo_stack.size(),
		redo_stack.size(),
		polygons["walkable"].size(),
		polygons["blocked"].size(),
		polygons["occluder_foreground"].size(),
	]
