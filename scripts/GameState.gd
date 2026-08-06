extends Node

signal show_message(title: String, body: String, audio: String)
signal clue_added(clue_id: String)

const REQUIRED_TAGS = ["cause_location_mismatch", "timeline_marker", "staging_evidence"]

const ACTION_EFFECTS = {
	"pay": {"trust": 1, "cash": -75},
	"lean": {"trust": -3, "cash": 0},
	"work": {"trust": 2, "cash": 0},
}

var collected_clues: Dictionary = {}
var cash: int = 400
var heat: int = 0
var npc_actions: Dictionary = {}
var ledger := {
	"trust": {"reyes": 0, "sal": 0, "priya": 0, "costigan": 0},
	"flags": {},
}

func apply_action(npc_id: String, action: String) -> void:
	npc_actions[npc_id] = action
	if not ledger["trust"].has(npc_id):
		ledger["trust"][npc_id] = 0
	var effect: Dictionary = ACTION_EFFECTS[action]
	ledger["trust"][npc_id] += effect["trust"]
	cash += effect["cash"]

func get_action(npc_id: String) -> String:
	return npc_actions.get(npc_id, "")

func add_clue(clue_id: String, tag: String, label: String) -> void:
	if collected_clues.has(clue_id):
		return
	collected_clues[clue_id] = {"tag": tag, "label": label}
	clue_added.emit(clue_id)

func has_all_required_clues() -> bool:
	var found := {}
	for c in collected_clues.values():
		found[c["tag"]] = true
	for t in REQUIRED_TAGS:
		if not found.has(t):
			return false
	return true

func set_flag(key: String, value) -> void:
	ledger["flags"][key] = value

func get_flag(key: String, default = null):
	return ledger["flags"].get(key, default)
