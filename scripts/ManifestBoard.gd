extends CanvasLayer
class_name ManifestBoardUI

signal solved
signal closed

var panel: Panel
var status_label: Label
var donation_buttons: Dictionary = {}
var account_button: Button
var flagged: Dictionary = {"G1": false, "G2": false, "G3": false, "G4": false, "account": false}

const DELAYS = [
	{"id": "D1", "time": "Mon 09:00"},
	{"id": "D2", "time": "Tue 14:00"},
	{"id": "D3", "time": "Thu 03:00"},
]
const DONATIONS = [
	{"id": "G1", "time": "Mon 11:30", "note": "2.5h after D1, D1 is flagged"},
	{"id": "G2", "time": "Tue 15:00", "note": "1h after D2, but D2 isn't flagged"},
	{"id": "G3", "time": "Thu 04:00", "note": "1h after D3, D3 is flagged"},
	{"id": "G4", "time": "Fri 20:00", "note": "no delay event nearby at all"},
]

func _ready() -> void:
	layer = 15
	visible = false

func open() -> void:
	flagged = {"G1": false, "G2": false, "G3": false, "G4": false, "account": false}
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
	panel.offset_top = -270
	panel.offset_bottom = 270
	add_child(panel)

	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.075, 0.078, 0.098, 0.98)
	style.border_color = Color(0.851, 0.522, 0.184)
	style.set_border_width_all(2)
	panel.add_theme_stylebox_override("panel", style)

	var title := Label.new()
	title.text = "STRIKE FUND MANIFEST"
	title.position = Vector2(20, 16)
	title.add_theme_color_override("font_color", Color(0.851, 0.522, 0.184))
	panel.add_child(title)

	status_label = Label.new()
	status_label.text = "Delay events -- D1 %s (Mick flagged it), D2 %s (not flagged), D3 %s (Mick flagged it). Flag every donation within 6h of a FLAGGED delay, then flag the shared account." % [DELAYS[0]["time"], DELAYS[1]["time"], DELAYS[2]["time"]]
	status_label.position = Vector2(20, 44)
	status_label.custom_minimum_size = Vector2(580, 56)
	status_label.autowrap_mode = TextServer.AUTOWRAP_WORD
	status_label.add_theme_font_size_override("font_size", 12)
	status_label.add_theme_color_override("font_color", Color(0.7, 0.73, 0.8))
	panel.add_child(status_label)

	donation_buttons = {}
	var y := 118
	for d in DONATIONS:
		var btn := Button.new()
		btn.toggle_mode = true
		btn.position = Vector2(20, y)
		btn.custom_minimum_size = Vector2(580, 40)
		btn.text = "Flag donation %s -- %s (%s)" % [d["id"], d["time"], d["note"]]
		var did: String = d["id"]
		btn.toggled.connect(func(pressed): _on_donation_toggled(did, pressed))
		panel.add_child(btn)
		donation_buttons[did] = btn
		y += 48

	account_button = Button.new()
	account_button.toggle_mode = true
	account_button.position = Vector2(20, y + 8)
	account_button.custom_minimum_size = Vector2(580, 40)
	account_button.text = "Flag shared account: G1 and G3 both route through X-4471"
	account_button.toggled.connect(func(pressed): _on_account_toggled(pressed))
	panel.add_child(account_button)

	var close_btn := Button.new()
	close_btn.text = "Close"
	close_btn.position = Vector2(20, y + 58)
	close_btn.pressed.connect(func(): _close())
	panel.add_child(close_btn)

func _on_donation_toggled(id: String, pressed: bool) -> void:
	flagged[id] = pressed
	_check_solved()

func _on_account_toggled(pressed: bool) -> void:
	flagged["account"] = pressed
	_check_solved()

func _check_solved() -> void:
	var correct: bool = flagged["G1"] and flagged["G3"] and flagged["account"] and not flagged["G2"] and not flagged["G4"]
	if correct:
		status_label.text = "Three findings logged: G1, G3, and the shared account. That's the pattern."
		GameState.play_sfx("res://sfx/ui/board_solve_stinger_v01.ogg")
		solved.emit()
	elif flagged["G2"] or flagged["G4"]:
		status_label.text = "One of those doesn't actually line up with a flagged delay event -- check the timing again."

func _close() -> void:
	visible = false
	closed.emit()
