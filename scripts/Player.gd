extends CharacterBody2D

const SPEED := 170.0
const FOOTSTEP_INTERVAL := 0.38

var nearby_interactables: Array = []
var reach: Area2D
var movement_bounds: Rect2 = Rect2()
var walkable_areas: Array = []
var blocked_areas: Array = []
var character_visual: AnimatedCharacter2D
var use_placeholder_art := true
var footstep_sound: AudioStream = null
var footstep_player: AudioStreamPlayer
var _footstep_timer := 0.0

func _ready() -> void:
	add_to_group("player")
	footstep_player = AudioStreamPlayer.new()
	add_child(footstep_player)
	var body_shape := CapsuleShape2D.new()
	body_shape.radius = 10
	body_shape.height = 26
	var col := CollisionShape2D.new()
	col.shape = body_shape
	add_child(col)

	reach = Area2D.new()
	var reach_shape := CircleShape2D.new()
	reach_shape.radius = 40
	var reach_col := CollisionShape2D.new()
	reach_col.shape = reach_shape
	reach.add_child(reach_col)
	add_child(reach)
	reach.area_entered.connect(_on_reach_entered)
	reach.area_exited.connect(_on_reach_exited)

	queue_redraw()

func set_character_visual(visual: AnimatedCharacter2D) -> void:
	if character_visual != null and character_visual.get_parent() == self:
		character_visual.queue_free()
	character_visual = visual
	use_placeholder_art = false
	add_child(character_visual)
	queue_redraw()

func _draw() -> void:
	if not use_placeholder_art:
		return
	var coat := PackedVector2Array([Vector2(-10, -6), Vector2(10, -6), Vector2(13, 18), Vector2(-13, 18)])
	draw_colored_polygon(coat, Color(0.043, 0.047, 0.063))
	draw_polyline(PackedVector2Array([Vector2(10, -6), Vector2(13, 18)]), Color(0.851, 0.522, 0.184), 2.0)
	draw_circle(Vector2(0, -18), 8, Color(0.043, 0.047, 0.063))

func _physics_process(delta: float) -> void:
	var previous_position := position
	var dir := Vector2.ZERO
	if Input.is_key_pressed(KEY_W) or Input.is_key_pressed(KEY_UP):
		dir.y -= 1
	if Input.is_key_pressed(KEY_S) or Input.is_key_pressed(KEY_DOWN):
		dir.y += 1
	if Input.is_key_pressed(KEY_A) or Input.is_key_pressed(KEY_LEFT):
		dir.x -= 1
	if Input.is_key_pressed(KEY_D) or Input.is_key_pressed(KEY_RIGHT):
		dir.x += 1
	if dir != Vector2.ZERO:
		velocity = dir.normalized() * SPEED
		if character_visual:
			character_visual.play_walk(dir)
		_footstep_timer += delta
		if _footstep_timer >= FOOTSTEP_INTERVAL and footstep_sound:
			_footstep_timer = 0.0
			footstep_player.stream = footstep_sound
			footstep_player.play()
	else:
		velocity = Vector2.ZERO
		_footstep_timer = FOOTSTEP_INTERVAL
		if character_visual:
			character_visual.play_idle()
	move_and_slide()

	if movement_bounds.size != Vector2.ZERO:
		position.x = clamp(position.x, movement_bounds.position.x, movement_bounds.end.x)
		position.y = clamp(position.y, movement_bounds.position.y, movement_bounds.end.y)
	if not can_stand_at(position):
		position = previous_position

func _on_reach_entered(area: Area2D) -> void:
	if area.has_method("interact"):
		nearby_interactables.append(area)

func _on_reach_exited(area: Area2D) -> void:
	nearby_interactables.erase(area)

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo and event.keycode == KEY_E:
		if nearby_interactables.size() > 0:
			if character_visual:
				character_visual.play_interact()
			nearby_interactables[0].interact()

func can_stand_at(candidate: Vector2) -> bool:
	if walkable_areas.size() > 0:
		var inside_walkable := false
		for area in walkable_areas:
			if area.has_point(candidate):
				inside_walkable = true
				break
		if not inside_walkable:
			return false
	for area in blocked_areas:
		if area.has_point(candidate):
			return false
	return true
