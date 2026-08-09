extends Area2D
class_name ClueObject

var clue_id: String = ""
var tag: String = ""
var label: String = ""
var examine_text: String = ""
var examine_audio: String = ""
var examine_sfx: String = ""
var color: Color = Color(0.851, 0.522, 0.184)
var examined := false

func _ready() -> void:
	var shape := CircleShape2D.new()
	shape.radius = 16
	var col := CollisionShape2D.new()
	col.shape = shape
	add_child(col)
	queue_redraw()

func _draw() -> void:
	var c := color
	if examined:
		c = c.darkened(0.55)
	draw_circle(Vector2.ZERO, 6, c)
	draw_arc(Vector2.ZERO, 11, 0, TAU, 20, c, 1.5)

func interact() -> void:
	if examined:
		GameState.show_message.emit("", "(Already logged: %s)" % label, "")
		return
	examined = true
	queue_redraw()
	if examine_sfx != "":
		GameState.play_sfx(examine_sfx, -5.0)
	GameState.add_clue(clue_id, tag, label)
	GameState.show_message.emit("DANA", examine_text, examine_audio)
