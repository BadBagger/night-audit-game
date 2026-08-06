extends CanvasLayer
class_name TicketBoardUI

signal solved(ticket_number: int)
signal closed

var panel: Panel
var status_label: Label
var ticket_buttons: Array = []

const TICKETS = [
	{"number": 3312, "day_label": "Mon", "day_num": 12},
	{"number": 4471, "day_label": "Tue", "day_num": 13},
	{"number": 5206, "day_label": "Tue", "day_num": 13},
	{"number": 1180, "day_label": "Wed", "day_num": 14},
]
const CORRECT_TICKET := 5206

func _ready() -> void:
	layer = 15
	visible = false

func open() -> void:
	_build_ui()
	visible = true

func _digit_sum(n: int) -> int:
	var s := 0
	var v := n
	while v > 0:
		s += v % 10
		v = v / 10
	return s

func _build_ui() -> void:
	if panel:
		panel.queue_free()

	panel = Panel.new()
	panel.anchor_left = 0.5
	panel.anchor_right = 0.5
	panel.anchor_top = 0.5
	panel.anchor_bottom = 0.5
	panel.offset_left = -300
	panel.offset_right = 300
	panel.offset_top = -230
	panel.offset_bottom = 230
	add_child(panel)

	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.075, 0.078, 0.098, 0.98)
	style.border_color = Color(0.851, 0.522, 0.184)
	style.set_border_width_all(2)
	panel.add_theme_stylebox_override("panel", style)

	var title := Label.new()
	title.text = "SAL'S INTAKE LEDGER"
	title.position = Vector2(20, 16)
	title.add_theme_color_override("font_color", Color(0.851, 0.522, 0.184))
	panel.add_child(title)

	status_label = Label.new()
	status_label.text = "\"Hot ones always land on Tues math -- check the 7s.\" Find the ticket Mick pawned."
	status_label.position = Vector2(20, 44)
	status_label.custom_minimum_size = Vector2(540, 40)
	status_label.autowrap_mode = TextServer.AUTOWRAP_WORD
	status_label.add_theme_font_size_override("font_size", 13)
	status_label.add_theme_color_override("font_color", Color(0.7, 0.73, 0.8))
	panel.add_child(status_label)

	ticket_buttons = []
	var y := 96
	for t in TICKETS:
		var btn := Button.new()
		btn.position = Vector2(20, y)
		btn.custom_minimum_size = Vector2(540, 46)
		btn.text = "Ticket #%d  --  intake %s the %dth" % [t["number"], t["day_label"], t["day_num"]]
		var tnum: int = t["number"]
		var dnum: int = t["day_num"]
		btn.pressed.connect(func(): _try_ticket(tnum, dnum))
		panel.add_child(btn)
		ticket_buttons.append(btn)
		y += 56

	var close_btn := Button.new()
	close_btn.text = "Close"
	close_btn.position = Vector2(20, y + 10)
	close_btn.pressed.connect(func(): _close())
	panel.add_child(close_btn)

func _try_ticket(ticket_number: int, day_num: int) -> void:
	var ds := _digit_sum(ticket_number)
	var lhs := ds % 7
	var rhs := day_num % 7
	if ticket_number == CORRECT_TICKET:
		status_label.text = "Digit sum %d mod 7 = %d. Day %d mod 7 = %d. That's the match." % [ds, lhs, day_num, rhs]
		GameState.play_sfx("res://sfx/ui/board_solve_stinger_v01.ogg")
		solved.emit(ticket_number)
	else:
		status_label.text = "Digit sum %d mod 7 = %d. Day %d mod 7 = %d. Doesn't line up. Try another." % [ds, lhs, day_num, rhs]

func _close() -> void:
	visible = false
	closed.emit()
