extends Node2D
class_name Chapter1SetPiece

var kind := "crate"
var size := Vector2(120, 70)
var base_color := Color(0.18, 0.14, 0.1)
var accent_color := Color(0.82, 0.52, 0.22, 0.7)
var dark_color := Color(0.035, 0.04, 0.05, 0.8)

func _ready() -> void:
	add_to_group("chapter1_set_piece")
	queue_redraw()

func configure(piece_kind: String, piece_size: Vector2, color: Color = Color(0.18, 0.14, 0.1), accent: Color = Color(0.82, 0.52, 0.22, 0.7)) -> void:
	kind = piece_kind
	size = piece_size
	base_color = color
	accent_color = accent
	queue_redraw()

func _draw() -> void:
	match kind:
		"crate":
			_draw_crate()
		"barrel":
			_draw_barrel()
		"rope":
			_draw_rope()
		"barrier":
			_draw_barrier()
		"dock_edge":
			_draw_dock_edge()
		"office_clutter":
			_draw_office_clutter()
		"evidence_card":
			_draw_evidence_card()
		"work_lamp":
			_draw_work_lamp()
		"tape":
			_draw_tape()
		_:
			_draw_crate()

func _draw_crate() -> void:
	var rect := Rect2(-size / 2, size)
	draw_rect(rect, base_color)
	draw_rect(rect, dark_color, false, 2.0)
	draw_line(Vector2(-size.x * 0.42, -size.y * 0.28), Vector2(size.x * 0.42, size.y * 0.28), Color(0.56, 0.38, 0.22, 0.5), 2.0)
	draw_line(Vector2(-size.x * 0.42, size.y * 0.28), Vector2(size.x * 0.42, -size.y * 0.28), Color(0.08, 0.06, 0.04, 0.45), 2.0)
	for x in [-0.33, 0.33]:
		draw_line(Vector2(size.x * x, -size.y * 0.5), Vector2(size.x * x, size.y * 0.5), Color(0.08, 0.06, 0.04, 0.4), 1.5)

func _draw_barrel() -> void:
	var r := Vector2(size.x * 0.42, size.y * 0.5)
	_draw_flat_ellipse(Vector2.ZERO, r, base_color)
	draw_arc(Vector2(0, -r.y * 0.55), r.x, 0, TAU, 28, Color(0.65, 0.7, 0.72, 0.32), 2.0)
	draw_arc(Vector2(0, r.y * 0.55), r.x, 0, TAU, 28, dark_color, 2.0)
	draw_line(Vector2(-r.x * 0.75, 0), Vector2(r.x * 0.75, 0), Color(0.65, 0.7, 0.72, 0.2), 2.0)

func _draw_rope() -> void:
	for i in range(5):
		var radius := size.x * (0.16 + float(i) * 0.055)
		draw_arc(Vector2.ZERO, radius, 0.15, TAU * 0.95, 42, Color(0.63, 0.48, 0.28, 0.92), 3.0)
	draw_line(Vector2(size.x * 0.22, size.y * 0.08), Vector2(size.x * 0.48, -size.y * 0.18), Color(0.63, 0.48, 0.28, 0.92), 3.0)

func _draw_barrier() -> void:
	var rect := Rect2(-size / 2, size)
	draw_rect(rect, Color(0.11, 0.12, 0.13, 0.88))
	for i in range(4):
		var x := -size.x * 0.45 + float(i) * size.x * 0.3
		draw_line(Vector2(x, size.y * 0.45), Vector2(x + size.x * 0.2, -size.y * 0.45), accent_color, 7.0)
	draw_rect(rect, Color(0.02, 0.02, 0.025, 0.85), false, 2.0)

func _draw_dock_edge() -> void:
	var rect := Rect2(-size / 2, size)
	draw_rect(rect, Color(0.045, 0.052, 0.06, 0.92))
	draw_rect(Rect2(Vector2(-size.x * 0.5, -size.y * 0.5), Vector2(size.x, 8)), Color(0.42, 0.49, 0.52, 0.65))
	for i in range(10):
		var x := -size.x * 0.48 + float(i) * size.x * 0.105
		draw_line(Vector2(x, -size.y * 0.5), Vector2(x + 18, size.y * 0.5), Color(0.11, 0.13, 0.15, 0.55), 2.0)

func _draw_office_clutter() -> void:
	draw_rect(Rect2(-size / 2, size), Color(0.11, 0.08, 0.05, 0.72))
	draw_rect(Rect2(Vector2(-size.x * 0.35, -size.y * 0.28), Vector2(size.x * 0.42, size.y * 0.22)), Color(0.82, 0.77, 0.63, 0.78))
	draw_rect(Rect2(Vector2(size.x * 0.08, -size.y * 0.18), Vector2(size.x * 0.28, size.y * 0.32)), Color(0.23, 0.28, 0.32, 0.78))
	draw_line(Vector2(-size.x * 0.28, -size.y * 0.12), Vector2(size.x * 0.02, -size.y * 0.12), Color(0.12, 0.1, 0.08, 0.5), 1.5)

func _draw_evidence_card() -> void:
	draw_rect(Rect2(-size / 2, size), Color(0.92, 0.84, 0.55, 0.92))
	draw_rect(Rect2(-size / 2, size), Color(0.18, 0.13, 0.05, 0.78), false, 1.5)
	draw_circle(Vector2(-size.x * 0.25, -size.y * 0.15), 3.0, Color(0.08, 0.07, 0.04, 0.8))
	draw_line(Vector2(-size.x * 0.1, -size.y * 0.18), Vector2(size.x * 0.28, -size.y * 0.18), Color(0.18, 0.13, 0.05, 0.45), 1.0)

func _draw_work_lamp() -> void:
	draw_circle(Vector2.ZERO, size.x * 0.22, Color(1.0, 0.72, 0.32, 0.8))
	draw_circle(Vector2.ZERO, size.x * 0.11, Color(1.0, 0.88, 0.54, 0.92))
	draw_line(Vector2.ZERO, Vector2(size.x * 0.42, -size.y * 0.28), Color(0.1, 0.08, 0.06, 0.75), 4.0)

func _draw_tape() -> void:
	draw_line(Vector2(-size.x * 0.5, 0), Vector2(size.x * 0.5, 0), Color(0.95, 0.72, 0.22, 0.9), 5.0)
	for i in range(7):
		var x := -size.x * 0.45 + float(i) * size.x * 0.15
		draw_line(Vector2(x, -4), Vector2(x + 22, 4), Color(0.08, 0.07, 0.04, 0.65), 2.0)

func _draw_flat_ellipse(center: Vector2, radius: Vector2, color: Color) -> void:
	var points := PackedVector2Array()
	for i in range(36):
		var angle := TAU * float(i) / 36.0
		points.append(center + Vector2(cos(angle) * radius.x, sin(angle) * radius.y))
	draw_colored_polygon(points, color)
