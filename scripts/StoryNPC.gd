extends Area2D
class_name StoryNPC

signal interacted

var npc_name: String = "NPC"
var interact_enabled := true
var character_visual: AnimatedCharacter2D
var use_placeholder_art := true

func _ready() -> void:
	var shape := CircleShape2D.new()
	shape.radius = 16
	var col := CollisionShape2D.new()
	col.shape = shape
	add_child(col)
	queue_redraw()

func set_character_visual(visual: AnimatedCharacter2D) -> void:
	if character_visual != null and character_visual.get_parent() == self:
		character_visual.queue_free()
	character_visual = visual
	use_placeholder_art = false
	add_child(character_visual)
	queue_redraw()

func play_idle() -> void:
	if character_visual:
		character_visual.play_idle()

func play_talk() -> void:
	if character_visual:
		character_visual.play_talk()

func _draw() -> void:
	if not use_placeholder_art:
		return
	draw_circle(Vector2(0, -18), 9, Color(0.043, 0.047, 0.063))
	var coat := PackedVector2Array([Vector2(-11, -8), Vector2(11, -8), Vector2(15, 20), Vector2(-15, 20)])
	draw_colored_polygon(coat, Color(0.043, 0.047, 0.063))
	draw_polyline(PackedVector2Array([Vector2(11, -8), Vector2(15, 20)]), Color(0.851, 0.522, 0.184), 2.0)

func interact() -> void:
	if not interact_enabled:
		return
	interacted.emit()
