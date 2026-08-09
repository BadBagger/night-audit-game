extends Sprite2D

var asset_path := ""
var asset_id := ""

func configure(path: String, sprite_scale: Vector2 = Vector2.ONE, flip_sprite: bool = false, rotation_deg: float = 0.0) -> void:
	asset_path = path
	asset_id = _asset_id_from_path(path)
	texture = load(path)
	scale = sprite_scale
	flip_h = flip_sprite
	rotation_degrees = rotation_deg
	add_to_group("reusable_prop_sprite")

func _asset_id_from_path(path: String) -> String:
	var parts := path.split("/")
	var props_index := parts.find("props")
	if props_index >= 0 and props_index + 1 < parts.size():
		return parts[props_index + 1]
	return ""
