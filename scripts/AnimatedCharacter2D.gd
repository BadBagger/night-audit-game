extends Node2D
class_name AnimatedCharacter2D

var sprite: AnimatedSprite2D
var visual_scale := 0.72
var visual_offset := Vector2(0, -72)
var current_mode := "idle"
var shadow_color := Color(0.0, 0.0, 0.0, 0.28)
var motion_strength := 1.0

var _last_walk_direction := Vector2.DOWN
var _motion_tween: Tween

func _ready() -> void:
	if sprite == null:
		sprite = AnimatedSprite2D.new()
		sprite.centered = true
		add_child(sprite)
	_apply_visual_transform()
	queue_redraw()

func setup_from_folders(root_path: String, animations: Dictionary, start_animation: String = "idle") -> void:
	if sprite == null:
		sprite = AnimatedSprite2D.new()
		sprite.centered = true
		add_child(sprite)

	var frames := SpriteFrames.new()
	for animation_name in animations.keys():
		var def: Dictionary = animations[animation_name]
		frames.add_animation(animation_name)
		frames.set_animation_speed(animation_name, def.get("fps", 6.0))
		frames.set_animation_loop(animation_name, def.get("loop", true))
		var source_folder: String = def.get("source", animation_name)
		var frame_paths := _collect_frame_paths("%s/%s" % [root_path, source_folder])
		for frame_path in frame_paths:
			var texture: Texture2D = load(frame_path)
			if texture:
				frames.add_frame(animation_name, texture)
		if frames.get_frame_count(animation_name) == 0:
			push_warning("No sprite frames found for %s at %s" % [animation_name, root_path])

	sprite.sprite_frames = frames
	_apply_visual_transform()
	if frames.has_animation(start_animation):
		sprite.play(start_animation)
		current_mode = start_animation
	queue_redraw()

func play_idle() -> void:
	_play_if_available("idle")

func play_walk(direction: Vector2 = Vector2.ZERO) -> void:
	if direction.x != 0:
		set_facing(direction.x)
	if direction.length_squared() > 0.001:
		_last_walk_direction = direction.normalized()
	_play_if_available("walk")

func play_talk() -> void:
	_play_if_available("talk")

func play_interact() -> void:
	_play_if_available("interact")

func set_facing(x_direction: float) -> void:
	if sprite == null or is_equal_approx(x_direction, 0.0):
		return
	sprite.flip_h = x_direction < 0.0

func _play_if_available(animation_name: String) -> void:
	if sprite == null or sprite.sprite_frames == null:
		return
	if not sprite.sprite_frames.has_animation(animation_name):
		return
	if current_mode == animation_name and sprite.is_playing():
		return
	sprite.play(animation_name)
	current_mode = animation_name
	_restart_motion_tween()

func _apply_visual_transform() -> void:
	if sprite == null:
		return
	sprite.scale = Vector2(visual_scale, visual_scale)
	sprite.position = visual_offset
	sprite.rotation = 0.0

func _restart_motion_tween() -> void:
	if sprite == null:
		return
	if _motion_tween:
		_motion_tween.kill()
	_apply_visual_transform()

	match current_mode:
		"walk":
			_motion_tween = create_tween().set_loops()
			_motion_tween.tween_property(sprite, "position", visual_offset + Vector2(0, -3.0 * motion_strength), 0.13).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
			_motion_tween.parallel().tween_property(sprite, "rotation", 0.018 * motion_strength, 0.13).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
			_motion_tween.tween_property(sprite, "position", visual_offset + Vector2(0, 1.0 * motion_strength), 0.13).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN)
			_motion_tween.parallel().tween_property(sprite, "rotation", -0.018 * motion_strength, 0.13).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN)
		"talk":
			_motion_tween = create_tween().set_loops()
			_motion_tween.tween_property(sprite, "position", visual_offset + Vector2(0, -1.4 * motion_strength), 0.22).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
			_motion_tween.tween_property(sprite, "position", visual_offset, 0.22).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN)
		"interact":
			_motion_tween = create_tween()
			_motion_tween.tween_property(sprite, "position", visual_offset + Vector2(0, 4.0 * motion_strength), 0.16).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
			_motion_tween.parallel().tween_property(sprite, "rotation", 0.02 * motion_strength, 0.16).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
			_motion_tween.tween_property(sprite, "position", visual_offset, 0.22).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN)
			_motion_tween.parallel().tween_property(sprite, "rotation", 0.0, 0.22).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN)
		_:
			_motion_tween = create_tween().set_loops()
			_motion_tween.tween_property(sprite, "position", visual_offset + Vector2(0, -0.9 * motion_strength), 0.9).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
			_motion_tween.tween_property(sprite, "position", visual_offset, 0.9).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN)

func _draw() -> void:
	var points := PackedVector2Array()
	for i in range(28):
		var angle := TAU * float(i) / 28.0
		points.append(Vector2(cos(angle) * 18.0 * visual_scale, sin(angle) * 6.0 * visual_scale))
	draw_colored_polygon(points, shadow_color)

func _collect_frame_paths(folder_path: String) -> Array:
	var paths := []
	var dir := DirAccess.open(folder_path)
	if dir == null:
		return paths

	dir.list_dir_begin()
	var file_name := dir.get_next()
	while file_name != "":
		if not dir.current_is_dir() and file_name.get_extension().to_lower() == "png":
			paths.append("%s/%s" % [folder_path, file_name])
		file_name = dir.get_next()
	dir.list_dir_end()
	paths.sort()
	return paths
