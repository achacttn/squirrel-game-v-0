# TurnManager — orchestrates the turn-based game loop.
#
# Manages turn count, action scaling, AP distribution,
# and the random activation pool. This is the "game clock"
# that drives the match forward.

class_name TurnManager
extends Node

signal turn_started(turn_number: int, actions_available: int)
signal mercs_selected(available_mercs: Array)
signal action_used(actions_remaining: int)
signal turn_ended

# How many actions the player gets scales with turn number
const MIN_ACTIONS = 1
const MAX_ACTIONS = 5

var turn_number: int = 0
var actions_remaining: int = 0
var actions_this_turn: int = 0

# The mercs randomly selected as available this turn
var available_mercs: Array = []

# Reference to the grid — set by Main
var grid = null

func start_turn():
	turn_number += 1
	actions_this_turn = min(turn_number, MAX_ACTIONS)
	actions_remaining = actions_this_turn

	# Step 1: All living mercs gain AP
	_distribute_ap()

	# Step 2: Pool mercs with 100+ AP, randomly pick up to N
	_select_available_mercs()

	print("=== Turn %d === Actions: %d | Available mercs: %s" % [
		turn_number,
		actions_this_turn,
		", ".join(available_mercs.map(func(m): return m.data.merc_name))
	])

	turn_started.emit(turn_number, actions_this_turn)
	mercs_selected.emit(available_mercs)

func _distribute_ap():
	for row in grid.cells:
		for cell in row:
			if cell.has_merc():
				var gain = cell.merc.gain_ap()
				print("  %s gained %d AP → now %d AP" % [
					cell.merc.data.merc_name, gain, cell.merc.current_ap
				])

func _select_available_mercs():
	# Gather all mercs with 100+ AP
	var eligible: Array = []
	for row in grid.cells:
		for cell in row:
			if cell.has_merc() and cell.merc.can_activate():
				eligible.append(cell.merc)

	# Shuffle and pick up to actions_this_turn mercs
	eligible.shuffle()
	available_mercs = eligible.slice(0, actions_this_turn)

# Called when the player uses a merc's action
func use_action(merc: Merc):
	if merc not in available_mercs:
		print("That merc is not available this turn!")
		return false

	merc.on_activated()  # clears guard status
	available_mercs.erase(merc)
	actions_remaining -= 1

	print("  %s used! Actions remaining: %d" % [merc.data.merc_name, actions_remaining])
	action_used.emit(actions_remaining)

	if actions_remaining <= 0:
		end_turn()

	return true

# Player can also end their turn early (to guard remaining mercs, etc.)
func end_turn():
	available_mercs.clear()
	turn_ended.emit()
	print("=== Turn %d ended ===" % turn_number)

func is_merc_available(merc: Merc) -> bool:
	return merc in available_mercs
