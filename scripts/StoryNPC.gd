extends Area2D
class_name StoryNPC

signal interacted

var npc_name: String = "NPC"

func _ready() -> void:
	var shape := CircleShape2D.new()
	shape.radius = 16
	var col := CollisionShape2D.new()
	col.shape = shape
	add_child(col)
	queue_redraw()

func _draw() -> void:
	draw_circle(Vector2(0, -18), 9, Color(0.043, 0.047, 0.063))
	var coat := PackedVector2Array([Vector2(-11, -8), Vector2(11, -8), Vector2(15, 20), Vector2(-15, 20)])
	draw_colored_polygon(coat, Color(0.043, 0.047, 0.063))
	draw_polyline(PackedVector2Array([Vector2(11, -8), Vector2(15, 20)]), Color(0.851, 0.522, 0.184), 2.0)

func interact() -> void:
	interacted.emit()
