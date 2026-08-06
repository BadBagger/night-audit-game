extends CanvasLayer
class_name DialogueBoxUI

signal advanced
signal choice_made(id: String)

var panel: Panel
var name_label: Label
var text_label: Label
var choice_container: VBoxContainer
var hint_label: Label
var audio_player: AudioStreamPlayer

var queue: Array = []
var box_visible := false

func _ready() -> void:
	layer = 10

	audio_player = AudioStreamPlayer.new()
	add_child(audio_player)

	panel = Panel.new()
	panel.anchor_left = 0
	panel.anchor_right = 1
	panel.anchor_top = 1
	panel.anchor_bottom = 1
	panel.offset_top = -230
	panel.offset_bottom = -20
	panel.offset_left = 40
	panel.offset_right = -40
	add_child(panel)

	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.086, 0.094, 0.122, 0.96)
	style.border_color = Color(0.851, 0.522, 0.184)
	style.border_width_top = 2
	style.set_corner_radius_all(2)
	panel.add_theme_stylebox_override("panel", style)

	name_label = Label.new()
	name_label.position = Vector2(20, 10)
	name_label.add_theme_color_override("font_color", Color(0.851, 0.522, 0.184))
	panel.add_child(name_label)

	text_label = Label.new()
	text_label.position = Vector2(20, 38)
	text_label.custom_minimum_size = Vector2(860, 60)
	text_label.autowrap_mode = TextServer.AUTOWRAP_WORD
	text_label.add_theme_color_override("font_color", Color(0.937, 0.945, 0.965))
	panel.add_child(text_label)

	hint_label = Label.new()
	hint_label.text = "[space] continue"
	hint_label.position = Vector2(20, 178)
	hint_label.add_theme_font_size_override("font_size", 12)
	hint_label.add_theme_color_override("font_color", Color(0.6, 0.62, 0.68))
	panel.add_child(hint_label)

	choice_container = VBoxContainer.new()
	choice_container.position = Vector2(20, 104)
	choice_container.add_theme_constant_override("separation", 6)
	panel.add_child(choice_container)

	hide_box()

func hide_box() -> void:
	panel.visible = false
	box_visible = false
	audio_player.stop()

func show_box() -> void:
	panel.visible = true
	box_visible = true

func play(lines: Array) -> void:
	queue = lines.duplicate()
	_advance()

func _advance() -> void:
	_clear_choices()
	if queue.is_empty():
		hide_box()
		advanced.emit()
		return
	show_box()
	var line = queue.pop_front()
	name_label.text = line.get("speaker", "")
	text_label.text = line.get("text", "")

	audio_player.stop()
	var audio_path: String = line.get("audio", "")
	if audio_path != "" and ResourceLoader.exists(audio_path):
		var stream: AudioStream = load(audio_path)
		if stream:
			audio_player.stream = stream
			audio_player.play()

	if line.has("choices"):
		hint_label.visible = false
		for choice in line["choices"]:
			var btn := Button.new()
			btn.text = choice["label"]
			var choice_id: String = choice["id"]
			btn.pressed.connect(func(): _on_choice(choice_id))
			choice_container.add_child(btn)
	else:
		hint_label.visible = true

func _clear_choices() -> void:
	for c in choice_container.get_children():
		c.queue_free()

func _on_choice(id: String) -> void:
	_clear_choices()
	hide_box()
	choice_made.emit(id)

func _unhandled_input(event: InputEvent) -> void:
	if not box_visible:
		return
	if choice_container.get_child_count() > 0:
		return
	if event is InputEventKey and event.pressed and not event.echo:
		if event.keycode == KEY_SPACE or event.keycode == KEY_ENTER:
			_advance()
			get_viewport().set_input_as_handled()
