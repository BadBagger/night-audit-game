extends Node2D
class_name Prop

var size: Vector2 = Vector2(100, 60)
var color: Color = Color.WHITE
var outline: Color = Color(0, 0, 0, 0)

func _ready() -> void:
	queue_redraw()

func _draw() -> void:
	var rect := Rect2(-size / 2, size)
	draw_rect(rect, color)
	if outline.a > 0.0:
		draw_rect(rect, outline, false, 2.0)
