extends Node
class_name Pier9OcclusionController

var player: Node2D
var foreground_layer: CanvasItem
var mask_image: Image
var player_front_z := 50
var player_behind_z := 10
var foreground_z := 40
var sample_offset := Vector2(0, 18)

func setup(target_player: Node2D, target_foreground_layer: CanvasItem, trigger_mask: Texture2D) -> void:
	player = target_player
	foreground_layer = target_foreground_layer
	mask_image = trigger_mask.get_image()
	foreground_layer.z_index = foreground_z
	_update_depth()

func _process(_delta: float) -> void:
	_update_depth()

func _update_depth() -> void:
	if player == null or foreground_layer == null or mask_image == null:
		return
	var sample := player.global_position + sample_offset
	var x := clampi(roundi(sample.x), 0, mask_image.get_width() - 1)
	var y := clampi(roundi(sample.y), 0, mask_image.get_height() - 1)
	var in_trigger := mask_image.get_pixel(x, y).r > 0.5
	player.z_index = player_behind_z if in_trigger else player_front_z
