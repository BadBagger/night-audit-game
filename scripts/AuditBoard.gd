extends CanvasLayer
class_name AuditBoardUI

signal solved
signal closed

var panel: Panel
var status_label: Label
var row_buttons: Dictionary = {}
var flagged: Dictionary = {}

const TRANSACTIONS = [
	{"id": "T1", "category": "payroll", "amount": 2400, "vendor": "Dockside Staffing", "account": "ACC-01"},
	{"id": "T2", "category": "supplies", "amount": 380, "vendor": "Harbor Supply Co", "account": "ACC-01"},
	{"id": "T3", "category": "catering", "amount": 1120, "vendor": "", "account": "ACC-02"},
	{"id": "T4", "category": "maintenance", "amount": 640, "vendor": "Bay Marine Repair", "account": "ACC-01"},
	{"id": "T5", "category": "maintenance", "amount": 900, "vendor": "Bay Marine Repair", "account": "X-4471"},
	{"id": "T6", "category": "wire", "amount": 9850, "vendor": "Internal Transfer", "account": "ACC-03"},
	{"id": "T7", "category": "wire", "amount": 9850, "vendor": "Internal Transfer", "account": "ACC-03"},
	{"id": "T8", "category": "wire", "amount": 9850, "vendor": "Internal Transfer", "account": "ACC-03"},
	{"id": "T9", "category": "payroll", "amount": 2550, "vendor": "Dockside Staffing", "account": "ACC-01"},
	{"id": "T10", "category": "supplies", "amount": 210, "vendor": "Harbor Supply Co", "account": "ACC-01"},
	{"id": "T11", "category": "wire", "amount": 4200, "vendor": "Internal Transfer", "account": "ACC-03"},
	{"id": "T12", "category": "catering", "amount": 95, "vendor": "Quickstop Deli", "account": "ACC-01"},
]

const REQUIRED = ["T3", "T5", "T6", "T7", "T8"]

func _ready() -> void:
	layer = 15
	visible = false

func open() -> void:
	flagged = {}
	for t in TRANSACTIONS:
		flagged[t["id"]] = false
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
	panel.offset_left = -340
	panel.offset_right = 340
	panel.offset_top = -260
	panel.offset_bottom = 260
	add_child(panel)

	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.075, 0.078, 0.098, 0.98)
	style.border_color = Color(0.851, 0.522, 0.184)
	style.set_border_width_all(2)
	panel.add_theme_stylebox_override("panel", style)

	var title := Label.new()
	title.text = "CALLOWAY STAR — SHIP'S LEDGER"
	title.position = Vector2(20, 12)
	title.add_theme_color_override("font_color", Color(0.851, 0.522, 0.184))
	panel.add_child(title)

	status_label = Label.new()
	status_label.text = "Flag every transaction that doesn't reconcile. Flagging a clean one also fails the audit."
	status_label.position = Vector2(20, 36)
	status_label.custom_minimum_size = Vector2(640, 32)
	status_label.autowrap_mode = TextServer.AUTOWRAP_WORD
	status_label.add_theme_font_size_override("font_size", 12)
	status_label.add_theme_color_override("font_color", Color(0.7, 0.73, 0.8))
	panel.add_child(status_label)

	row_buttons = {}
	var y := 78
	for t in TRANSACTIONS:
		var btn := Button.new()
		btn.toggle_mode = true
		btn.position = Vector2(20, y)
		btn.custom_minimum_size = Vector2(640, 27)
		btn.add_theme_font_size_override("font_size", 12)
		var vendor_str: String = t["vendor"] if t["vendor"] != "" else "— no vendor on file —"
		btn.text = "%s · %s · $%s · %s · %s" % [t["id"], t["category"], _comma(t["amount"]), vendor_str, t["account"]]
		var tid: String = t["id"]
		btn.toggled.connect(func(pressed): _on_toggled(tid, pressed))
		panel.add_child(btn)
		row_buttons[tid] = btn
		y += 32

	var close_btn := Button.new()
	close_btn.text = "Close ledger"
	close_btn.position = Vector2(20, y + 8)
	close_btn.pressed.connect(func(): _close())
	panel.add_child(close_btn)

func _comma(n: int) -> String:
	var s := str(n)
	var out := ""
	var count := 0
	for i in range(s.length() - 1, -1, -1):
		out = s[i] + out
		count += 1
		if count % 3 == 0 and i != 0:
			out = "," + out
	return out

func _on_toggled(id: String, pressed: bool) -> void:
	flagged[id] = pressed
	_check_solved()

func _check_solved() -> void:
	var flagged_ids: Array = []
	for id in flagged:
		if flagged[id]:
			flagged_ids.append(id)
	flagged_ids.sort()
	var required_sorted: Array = REQUIRED.duplicate()
	required_sorted.sort()

	if flagged_ids == required_sorted:
		status_label.text = "That's the pattern: a ghost vendor, a cross-account bleed, and a structuring run. Audit complete."
		GameState.play_sfx("res://sfx/ui/board_solve_stinger_v01.ogg")
		solved.emit()
	elif flagged_ids.size() > required_sorted.size():
		status_label.text = "Too many flags — at least one of those actually reconciles fine. Look again."
	# Otherwise: still mid-audit, no verdict yet -- let them keep working without a premature judgment.

func _close() -> void:
	visible = false
	closed.emit()
