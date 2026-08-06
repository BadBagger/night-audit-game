extends CanvasLayer
class_name DeductionBoardUI

signal solved
signal closed

var panel: Panel
var slot_buttons: Array = []
var selected_slot_index := -1
var slots := []
var status_label: Label

func _ready() -> void:
	layer = 15
	visible = false

func open(slot_defs: Array) -> void:
	slots = []
	for s in slot_defs:
		slots.append({"tag": s["tag"], "label": s["label"], "filled": ""})
	selected_slot_index = -1
	_build_ui()
	visible = true

func _build_ui() -> void:
	if panel:
		panel.queue_free()

	panel = Panel.new()
	panel.anchor_left = 0.5
	panel.anchor_right = 0.5
	panel.anchor_top = 0.5
	panel.anchor_bottom = 0.5
	panel.offset_left = -320
	panel.offset_right = 320
	panel.offset_top = -280
	panel.offset_bottom = 280
	add_child(panel)

	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.075, 0.078, 0.098, 0.98)
	style.border_color = Color(0.851, 0.522, 0.184)
	style.set_border_width_all(2)
	panel.add_theme_stylebox_override("panel", style)

	var title := Label.new()
	title.text = "DEDUCTION BOARD"
	title.position = Vector2(20, 16)
	title.add_theme_color_override("font_color", Color(0.851, 0.522, 0.184))
	panel.add_child(title)

	status_label = Label.new()
	status_label.text = "Select a slot, then choose the clue that fits."
	status_label.position = Vector2(20, 44)
	status_label.custom_minimum_size = Vector2(580, 20)
	status_label.add_theme_font_size_override("font_size", 13)
	status_label.add_theme_color_override("font_color", Color(0.7, 0.73, 0.8))
	panel.add_child(status_label)

	slot_buttons = []
	var y := 80
	for i in range(slots.size()):
		var s = slots[i]
		var btn := Button.new()
		btn.position = Vector2(20, y)
		btn.custom_minimum_size = Vector2(580, 40)
		btn.text = "%s  ->  [ empty ]" % s["label"]
		var idx := i
		btn.pressed.connect(func(): _select_slot(idx))
		panel.add_child(btn)
		slot_buttons.append(btn)
		y += 50

	var clue_title := Label.new()
	clue_title.text = "Evidence"
	clue_title.position = Vector2(20, y + 10)
	clue_title.add_theme_color_override("font_color", Color(0.851, 0.522, 0.184))
	panel.add_child(clue_title)

	var cy := y + 36
	for clue_id in GameState.collected_clues.keys():
		var c = GameState.collected_clues[clue_id]
		var cbtn := Button.new()
		cbtn.position = Vector2(20, cy)
		cbtn.custom_minimum_size = Vector2(580, 34)
		cbtn.text = c["label"]
		var c_tag: String = c["tag"]
		var c_label: String = c["label"]
		cbtn.pressed.connect(func(): _assign_clue(c_tag, c_label))
		panel.add_child(cbtn)
		cy += 38

	var close_btn := Button.new()
	close_btn.text = "Close board"
	close_btn.position = Vector2(20, cy + 10)
	close_btn.pressed.connect(func(): _close())
	panel.add_child(close_btn)

func _select_slot(i: int) -> void:
	selected_slot_index = i
	status_label.text = "Slot selected: %s. Now click the matching evidence below." % slots[i]["label"]

func _assign_clue(tag: String, label: String) -> void:
	if selected_slot_index == -1:
		status_label.text = "Select a slot first."
		return
	var slot = slots[selected_slot_index]
	if slot["tag"] == tag:
		slot["filled"] = label
		slot_buttons[selected_slot_index].text = "%s  ->  %s" % [slot["label"], label]
		status_label.text = "That fits."
		selected_slot_index = -1
		_check_solved()
	else:
		status_label.text = "Doesn't fit. \"%s\" isn't the connection this slot needs." % label

func _check_solved() -> void:
	for s in slots:
		if s["filled"] == "":
			return
	status_label.text = "Board complete."
	GameState.play_sfx("res://sfx/ui/board_solve_stinger_v01.ogg")
	solved.emit()

func _close() -> void:
	visible = false
	closed.emit()
