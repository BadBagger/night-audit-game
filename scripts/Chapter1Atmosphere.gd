extends Node2D
class_name Chapter1Atmosphere

var rain_seed := 1909
var rain_lines := 90
var rain_scroll_speed := 54.0
var rain_phase := 0.0
var scene_size := Vector2(2560, 1440)
var puddles: Array = []
var light_pools: Array = []

func _ready() -> void:
	z_index = 35
	add_to_group("chapter1_atmosphere")
	queue_redraw()

func _process(delta: float) -> void:
	rain_phase = fmod(rain_phase + rain_scroll_speed * delta, scene_size.y)
	queue_redraw()

func configure(new_puddles: Array, new_light_pools: Array) -> void:
	puddles = new_puddles
	light_pools = new_light_pools
	queue_redraw()

func _draw() -> void:
	_draw_puddles()
	_draw_light_pools()
	_draw_rain()
	_draw_vignette()

func _draw_puddles() -> void:
	for puddle in puddles:
		var pos: Vector2 = puddle.get("pos", Vector2.ZERO)
		var radius: Vector2 = puddle.get("radius", Vector2(80, 22))
		var color: Color = puddle.get("color", Color(0.42, 0.55, 0.62, 0.18))
		_draw_flat_ellipse(pos, radius, color)
		draw_arc(pos, radius.x, 0.08, PI - 0.08, 30, Color(0.72, 0.82, 0.88, 0.16), 1.5)

func _draw_light_pools() -> void:
	for pool in light_pools:
		var pos: Vector2 = pool.get("pos", Vector2.ZERO)
		var radius: float = pool.get("radius", 160.0)
		var color: Color = pool.get("color", Color(1.0, 0.62, 0.24, 0.12))
		for i in range(5, 0, -1):
			var alpha := color.a * float(i) / 7.0
			draw_circle(pos, radius * float(i) / 5.0, Color(color.r, color.g, color.b, alpha))

func _draw_rain() -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = rain_seed
	for i in range(rain_lines):
		var start := Vector2(rng.randf_range(40.0, scene_size.x - 40.0), rng.randf_range(30.0, scene_size.y - 90.0))
		start.y = fmod(start.y + rain_phase, scene_size.y)
		var length := rng.randf_range(26.0, 72.0)
		var end := start + Vector2(-10.0, length)
		var alpha := rng.randf_range(0.08, 0.22)
		draw_line(start, end, Color(0.72, 0.82, 0.9, alpha), rng.randf_range(1.0, 1.8))

func _draw_vignette() -> void:
	var edge := Color(0.01, 0.014, 0.02, 0.38)
	draw_rect(Rect2(Vector2.ZERO, Vector2(scene_size.x, 120)), edge)
	draw_rect(Rect2(Vector2(0, scene_size.y - 140), Vector2(scene_size.x, 140)), edge)
	draw_rect(Rect2(Vector2.ZERO, Vector2(150, scene_size.y)), edge)
	draw_rect(Rect2(Vector2(scene_size.x - 180, 0), Vector2(180, scene_size.y)), edge)

func _draw_flat_ellipse(center: Vector2, radius: Vector2, color: Color) -> void:
	var points := PackedVector2Array()
	for i in range(40):
		var angle := TAU * float(i) / 40.0
		points.append(center + Vector2(cos(angle) * radius.x, sin(angle) * radius.y))
	draw_colored_polygon(points, color)
