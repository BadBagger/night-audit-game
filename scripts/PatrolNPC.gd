extends Area2D
class_name PatrolNPC

signal interacted
signal player_spotted

var npc_name: String = "NPC"

enum State { AT_A, TRANSIT_TO_B, AT_B, TRANSIT_TO_A }

var point_a: Vector2 = Vector2.ZERO
var point_b: Vector2 = Vector2.ZERO
var dwell_a: float = 25.0
var transit_time: float = 10.0
var dwell_b: float = 30.0

var state: int = State.AT_A
var state_timer: float = 0.0
var sight: Area2D
var character_visual: AnimatedCharacter2D
var use_placeholder_art := true

func _ready() -> void:
	position = point_a

	var shape := CircleShape2D.new()
	shape.radius = 16
	var col := CollisionShape2D.new()
	col.shape = shape
	add_child(col)

	sight = Area2D.new()
	var sight_shape := CircleShape2D.new()
	sight_shape.radius = 90
	var sight_col := CollisionShape2D.new()
	sight_col.shape = sight_shape
	sight.add_child(sight_col)
	add_child(sight)
	sight.body_entered.connect(_on_sight_body_entered)

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
	if use_placeholder_art:
		draw_circle(Vector2(0, -18), 9, Color(0.043, 0.047, 0.063))
		var coat := PackedVector2Array([Vector2(-11, -8), Vector2(11, -8), Vector2(15, 20), Vector2(-15, 20)])
		draw_colored_polygon(coat, Color(0.043, 0.047, 0.063))
		draw_polyline(PackedVector2Array([Vector2(11, -8), Vector2(15, 20)]), Color(0.851, 0.522, 0.184), 2.0)
	# sight-cone hint, only really meaningful when detection is active
	if is_detection_active():
		draw_arc(Vector2.ZERO, 90, 0, TAU, 32, Color(0.851, 0.522, 0.184, 0.12), 2.0)

func _process(delta: float) -> void:
	advance_patrol(delta)

func advance_patrol(delta: float) -> void:
	state_timer += delta
	match state:
		State.AT_A:
			play_idle()
			if state_timer >= dwell_a:
				state = State.TRANSIT_TO_B
				state_timer = 0.0
		State.TRANSIT_TO_B:
			if character_visual:
				character_visual.play_walk(point_b - point_a)
			position = point_a.lerp(point_b, min(state_timer / transit_time, 1.0))
			if state_timer >= transit_time:
				state = State.AT_B
				state_timer = 0.0
				position = point_b
		State.AT_B:
			play_idle()
			if state_timer >= dwell_b:
				state = State.TRANSIT_TO_A
				state_timer = 0.0
		State.TRANSIT_TO_A:
			if character_visual:
				character_visual.play_walk(point_a - point_b)
			position = point_b.lerp(point_a, min(state_timer / transit_time, 1.0))
			if state_timer >= transit_time:
				state = State.AT_A
				state_timer = 0.0
				position = point_a
	queue_redraw()

func is_detection_active() -> bool:
	# The crew-deck dwell (point B) is the one safe window in the loop --
	# everywhere else in the cycle she can plausibly notice someone.
	return state != State.AT_B

func _on_sight_body_entered(body: Node) -> void:
	if body.is_in_group("player") and is_detection_active():
		player_spotted.emit()

func interact() -> void:
	interacted.emit()
