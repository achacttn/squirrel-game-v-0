extends Node2D

@onready var grid_p1 = $PlayerGrid   # Left grid — always Player 1
@onready var grid_p2 = $EnemyGrid    # Right grid — always Player 2

# Each player has their own turn manager (independent turn counts + action scaling)
var tm_p1: TurnManager
var tm_p2: TurnManager

# These swap each turn — point to whoever is currently acting
var active_grid = null    # the grid whose mercs can be selected
var target_grid = null    # the grid that gets attacked
var active_tm: TurnManager = null

var current_player: int = 1  # 1 or 2

const TURN_TIMES: Array[float] = [15.0, 15.0]  # turn 1 and 2 get 15s, then 30s onwards
var turn_timer: Timer
var time_remaining: float = 0.0
var timer_label: Label

var active_merc: Merc = null
var active_cell = null

enum State { IDLE, SELECTING_ACTION, TARGETING_ATTACK, TARGETING_SWAP, GAME_OVER }
var current_state: State = State.IDLE

# UI elements
var info_label: Label
var next_turn_button: Button
var action_panel: VBoxContainer
var attack_button: Button
var guard_button: Button
var swap_button: Button
var p1_label: Label
var p2_label: Label
var state_label: Label
var game_over_label: Label

func _ready():
	# === Player 1 mercs (left grid) ===
	var swordsman  = load("res://data/mercs/swordsman.tres")
	var axeman     = load("res://data/mercs/axeman.tres")
	var shielder   = load("res://data/mercs/shielder.tres")
	var spearman   = load("res://data/mercs/spearman.tres")
	var bowman     = load("res://data/mercs/bowman.tres")
	var gunslinger = load("res://data/mercs/gunslinger.tres")
	var staffmage  = load("res://data/mercs/staffmage.tres")
	var cannoneer  = load("res://data/mercs/cannoneer.tres")
	var healer     = load("res://data/mercs/healer.tres")

	# Front row (row 2) — melee
	grid_p1.place_merc_at(2, 0, swordsman, true)
	grid_p1.place_merc_at(2, 1, axeman)
	grid_p1.place_merc_at(2, 2, shielder)
	# Mid row (row 1) — agi
	grid_p1.place_merc_at(1, 0, spearman)
	grid_p1.place_merc_at(1, 1, bowman)
	grid_p1.place_merc_at(1, 2, gunslinger)
	# Back row (row 0) — magic/support
	grid_p1.place_merc_at(0, 0, staffmage)
	grid_p1.place_merc_at(0, 1, cannoneer)
	grid_p1.place_merc_at(0, 2, healer)

	# === Player 2 mercs (right grid) ===
	var knight    = load("res://data/mercs/knight.tres")
	var berserker = load("res://data/mercs/berserker.tres")
	var paladin   = load("res://data/mercs/paladin.tres")
	var pirate    = load("res://data/mercs/pirate.tres")
	var chariot   = load("res://data/mercs/chariot.tres")
	var poseidon  = load("res://data/mercs/poseidon.tres")
	var priest    = load("res://data/mercs/priest.tres")
	var puppet    = load("res://data/mercs/puppet.tres")
	var heretic   = load("res://data/mercs/heretic.tres")

	# Front row (row 2) — melee
	grid_p2.place_merc_at(2, 0, knight, true)
	grid_p2.place_merc_at(2, 1, berserker)
	grid_p2.place_merc_at(2, 2, paladin)
	# Mid row (row 1) — agi
	grid_p2.place_merc_at(1, 0, pirate)
	grid_p2.place_merc_at(1, 1, chariot)
	grid_p2.place_merc_at(1, 2, poseidon)
	# Back row (row 0) — magic/support
	grid_p2.place_merc_at(0, 0, priest)
	grid_p2.place_merc_at(0, 1, puppet)
	grid_p2.place_merc_at(0, 2, heretic)

	# Turn managers — one per player
	tm_p1 = TurnManager.new()
	tm_p1.grid = grid_p1
	add_child(tm_p1)

	tm_p2 = TurnManager.new()
	tm_p2.grid = grid_p2
	add_child(tm_p2)

	# Both grids can emit clicks and hovers — we handle them based on whose turn it is
	grid_p1.cell_clicked_for_action.connect(_on_grid_p1_clicked)
	grid_p2.cell_clicked_for_action.connect(_on_grid_p2_clicked)
	grid_p1.cell_hovered_for_action.connect(_on_grid_p1_hovered)
	grid_p2.cell_hovered_for_action.connect(_on_grid_p2_hovered)
	grid_p1.cell_unhovered_for_action.connect(_on_grid_unhovered)
	grid_p2.cell_unhovered_for_action.connect(_on_grid_unhovered)

	_setup_ui()
	_start_player_turn(1)

func _setup_ui():
	info_label = Label.new()
	info_label.position = Vector2(50, 20)
	info_label.add_theme_font_size_override("font_size", 16)
	add_child(info_label)

	state_label = Label.new()
	state_label.position = Vector2(50, 50)
	state_label.add_theme_font_size_override("font_size", 13)
	add_child(state_label)

	p1_label = Label.new()
	p1_label.position = Vector2(100, 170)
	p1_label.add_theme_font_size_override("font_size", 14)
	add_child(p1_label)

	p2_label = Label.new()
	p2_label.position = Vector2(550, 170)
	p2_label.add_theme_font_size_override("font_size", 14)
	add_child(p2_label)

	next_turn_button = Button.new()
	next_turn_button.text = "End Turn"
	next_turn_button.position = Vector2(350, 550)
	next_turn_button.size = Vector2(120, 40)
	next_turn_button.pressed.connect(_on_end_turn_pressed)
	add_child(next_turn_button)

	action_panel = VBoxContainer.new()
	action_panel.position = Vector2(350, 250)
	action_panel.visible = false
	add_child(action_panel)

	var action_label = Label.new()
	action_label.text = "Actions:"
	action_label.add_theme_font_size_override("font_size", 14)
	action_panel.add_child(action_label)

	attack_button = Button.new()
	attack_button.text = "Attack"
	attack_button.custom_minimum_size = Vector2(120, 35)
	attack_button.pressed.connect(_on_attack_pressed)
	action_panel.add_child(attack_button)

	guard_button = Button.new()
	guard_button.text = "Guard"
	guard_button.custom_minimum_size = Vector2(120, 35)
	guard_button.pressed.connect(_on_guard_pressed)
	action_panel.add_child(guard_button)

	swap_button = Button.new()
	swap_button.text = "Swap"
	swap_button.custom_minimum_size = Vector2(120, 35)
	swap_button.pressed.connect(_on_swap_pressed)
	action_panel.add_child(swap_button)

	game_over_label = Label.new()
	game_over_label.position = Vector2(250, 80)
	game_over_label.add_theme_font_size_override("font_size", 32)
	game_over_label.visible = false
	add_child(game_over_label)

	# Turn timer — counts down each second, auto-ends turn at 0
	timer_label = Label.new()
	timer_label.position = Vector2(380, 20)
	timer_label.add_theme_font_size_override("font_size", 20)
	add_child(timer_label)

	turn_timer = Timer.new()
	turn_timer.wait_time = 1.0
	turn_timer.timeout.connect(_on_timer_tick)
	add_child(turn_timer)

# === Turn management ===

func _start_player_turn(player: int):
	current_player = player
	_cancel_action()

	if player == 1:
		active_grid = grid_p1
		target_grid = grid_p2
		active_tm = tm_p1
		p1_label.text = "PLAYER 1 [YOUR TURN]"
		p2_label.text = "PLAYER 2"
	else:
		active_grid = grid_p2
		target_grid = grid_p1
		active_tm = tm_p2
		p1_label.text = "PLAYER 1"
		p2_label.text = "PLAYER 2 [YOUR TURN]"

	# Connect turn manager signals (disconnect previous first)
	_disconnect_tm_signals()
	active_tm.turn_started.connect(_on_turn_started)
	active_tm.mercs_selected.connect(_on_mercs_selected)
	active_tm.action_used.connect(_on_action_used)
	active_tm.turn_ended.connect(_on_turn_ended)

	active_tm.start_turn()

	# Reset and start the turn timer — scales with turn count
	var turn_index = active_tm.turn_number - 1  # 0-based
	time_remaining = TURN_TIMES[turn_index] if turn_index < TURN_TIMES.size() else 30.0
	_update_timer_label()
	turn_timer.start()

func _on_timer_tick():
	time_remaining -= 1.0
	_update_timer_label()
	if time_remaining <= 0:
		turn_timer.stop()
		print("P%d: Time's up!" % current_player)
		active_tm.end_turn()

func _update_timer_label():
	timer_label.text = "Time: %ds" % int(time_remaining)
	# Turn red when low on time
	if time_remaining <= 5:
		timer_label.add_theme_color_override("font_color", Color.RED)
	else:
		timer_label.remove_theme_color_override("font_color")

func _disconnect_tm_signals():
	# Safely disconnect any existing connections
	for tm in [tm_p1, tm_p2]:
		if tm.turn_started.is_connected(_on_turn_started):
			tm.turn_started.disconnect(_on_turn_started)
		if tm.mercs_selected.is_connected(_on_mercs_selected):
			tm.mercs_selected.disconnect(_on_mercs_selected)
		if tm.action_used.is_connected(_on_action_used):
			tm.action_used.disconnect(_on_action_used)
		if tm.turn_ended.is_connected(_on_turn_ended):
			tm.turn_ended.disconnect(_on_turn_ended)

func _on_turn_started(_turn_number, _actions_available):
	_cancel_action()
	_update_info()

func _on_mercs_selected(available_mercs):
	active_grid.highlight_available(available_mercs)

func _on_action_used(_actions_remaining):
	_cancel_action()
	_update_info()
	active_grid.highlight_available(active_tm.available_mercs)

func _on_turn_ended():
	_cancel_action()
	active_grid.clear_highlights()
	# Switch to other player
	_start_player_turn(2 if current_player == 1 else 1)

func _on_end_turn_pressed():
	if current_state == State.GAME_OVER:
		return
	active_tm.end_turn()

# === Grid click handlers ===
# Both grids can be clicked. We decide what to do based on whose turn it is.

func _on_grid_p1_clicked(cell):
	if current_state == State.GAME_OVER:
		return
	if current_player == 1:
		_on_active_grid_clicked(cell)
	else:
		_on_target_grid_clicked(cell)

func _on_grid_p2_clicked(cell):
	if current_state == State.GAME_OVER:
		return
	if current_player == 2:
		_on_active_grid_clicked(cell)
	else:
		_on_target_grid_clicked(cell)

func _on_active_grid_clicked(cell):
	# Clicked on your own grid
	if current_state == State.TARGETING_ATTACK:
		_cancel_action()
		if cell.has_merc() and active_tm.is_merc_available(cell.merc):
			_select_merc(cell)
		return

	if current_state == State.TARGETING_SWAP:
		if cell.is_swap_target:
			var swap_pos = cell.get_meta("grid_pos")
			var active_pos = active_cell.get_meta("grid_pos")

			active_merc.spend_ap(50)
			cell.merc.spend_ap(50)

			print("%s swaps with %s!" % [active_merc.data.merc_name, cell.merc.data.merc_name])
			active_grid.swap_mercs(active_pos, swap_pos)
			active_grid.clear_swap_targets()

			var new_cell = active_grid.find_cell_for_merc(active_merc)
			_cancel_action()
			if active_tm.is_merc_available(active_merc):
				_select_merc(new_cell)
			return
		else:
			active_grid.clear_swap_targets()
			_cancel_action()
			if cell.has_merc() and active_tm.is_merc_available(cell.merc):
				_select_merc(cell)
			return

	if cell.has_merc() and active_tm.is_merc_available(cell.merc):
		_select_merc(cell)
	else:
		_cancel_action()

func _on_target_grid_clicked(cell):
	# Clicked on the opponent's grid
	if current_state != State.TARGETING_ATTACK:
		return
	if not cell.is_targeted:
		return

	target_grid.clear_hit_preview()

	var chosen_pos = cell.get_meta("grid_pos")
	var hit_cells = Targeting.get_hit_cells(active_merc.data.weapon_type, chosen_pos)

	print("P%d: %s attacks! Hit cells: %s" % [current_player, active_merc.data.merc_name, str(hit_cells)])

	for pos in hit_cells:
		var target_cell = target_grid.get_cell(pos.x, pos.y)
		if target_cell.has_merc():
			var dmg = target_cell.merc.take_damage(active_merc.data.atk)
			print("  Hit %s for %d damage! HP: %d" % [
				target_cell.merc.data.merc_name, dmg, target_cell.merc.current_hp
			])
			if not target_cell.merc.is_alive:
				print("  %s has been killed!" % target_cell.merc.data.merc_name)
				if target_cell.merc.is_main_character:
					_game_over("PLAYER %d WINS!" % current_player)
					return

	_commit_action()

# === Merc selection and actions ===

func _select_merc(cell):
	if active_grid.selected_cell:
		active_grid.selected_cell.set_selected(false)
	target_grid.clear_targets()

	active_merc = cell.merc
	active_cell = cell
	cell.set_selected(true)
	active_grid.selected_cell = cell
	current_state = State.SELECTING_ACTION
	action_panel.visible = true
	_update_state_label("P%d: Choose an action for %s" % [current_player, active_merc.data.merc_name])

func _cancel_action():
	active_merc = null
	active_cell = null
	current_state = State.IDLE
	action_panel.visible = false
	target_grid.clear_targets() if target_grid else null
	target_grid.clear_hit_preview() if target_grid else null
	active_grid.clear_swap_targets() if active_grid else null
	if active_grid and active_grid.selected_cell:
		active_grid.selected_cell.set_selected(false)
		active_grid.selected_cell = null
	_update_state_label("")

func _on_attack_pressed():
	if not active_merc:
		return
	var attacker_pos = active_cell.get_meta("grid_pos")
	var valid_targets = target_grid.get_valid_targets(active_merc.data.weapon_type, attacker_pos)
	target_grid.show_targets(valid_targets)
	current_state = State.TARGETING_ATTACK
	action_panel.visible = false
	_update_state_label("P%d: Click a red cell to attack (or click your grid to cancel)" % current_player)

func _on_guard_pressed():
	if not active_merc:
		return
	active_merc.set_guard()
	active_merc.spend_ap(50)
	print("P%d: %s guards!" % [current_player, active_merc.data.merc_name])
	active_tm.use_action(active_merc)

func _on_swap_pressed():
	if not active_merc:
		return
	var pos = active_cell.get_meta("grid_pos")
	var swap_targets = active_grid.get_swap_targets(pos)

	if swap_targets.is_empty():
		print("No adjacent mercs to swap with!")
		return

	active_grid.show_swap_targets(swap_targets)
	current_state = State.TARGETING_SWAP
	action_panel.visible = false
	_update_state_label("P%d: Click a yellow cell to swap with" % current_player)

func _commit_action():
	active_merc.spend_ap(100)
	active_tm.use_action(active_merc)

func _game_over(message: String):
	turn_timer.stop()
	_cancel_action()
	current_state = State.GAME_OVER
	grid_p1.clear_highlights()
	grid_p2.clear_highlights()
	grid_p1.clear_targets()
	grid_p2.clear_targets()
	action_panel.visible = false
	next_turn_button.visible = false
	game_over_label.text = message
	game_over_label.visible = true
	_update_state_label("Game over")
	print("=== %s ===" % message)

# === UI ===

func _update_info():
	info_label.text = "Player %d | Turn %d | Actions: %d/%d" % [
		current_player,
		active_tm.turn_number,
		active_tm.actions_remaining,
		active_tm.actions_this_turn
	]

func _update_state_label(text: String):
	state_label.text = text

# === Hover hit preview ===

func _on_grid_p1_hovered(cell):
	if current_state == State.TARGETING_ATTACK and current_player == 2:
		_show_hover_preview(cell)

func _on_grid_p2_hovered(cell):
	if current_state == State.TARGETING_ATTACK and current_player == 1:
		_show_hover_preview(cell)

func _show_hover_preview(cell):
	if not cell.is_targeted:
		return
	var chosen_pos = cell.get_meta("grid_pos")
	var hit_cells = Targeting.get_hit_cells(active_merc.data.weapon_type, chosen_pos)
	target_grid.show_hit_preview(hit_cells)

func _on_grid_unhovered(_cell):
	target_grid.clear_hit_preview() if target_grid else null
