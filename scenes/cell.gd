extends Area2D

signal cell_clicked(cell)

const COLOR_DEFAULT = Color(0.9, 0.9, 0.9)
const COLOR_HOVER = Color(0.7, 0.85, 1.0)
const COLOR_SELECTED = Color(0.3, 0.6, 1.0)
const COLOR_EMPTY = Color(0.4, 0.4, 0.4)        # darker grey for empty cells
const COLOR_AVAILABLE = Color(0.6, 1.0, 0.6)    # green — merc can act this turn
const COLOR_UNAVAILABLE = Color(0.7, 0.7, 0.7)  # dim — merc can't act this turn
const COLOR_TARGETED = Color(1.0, 0.4, 0.4)     # red — this cell will be hit
const COLOR_SWAP_TARGET = Color(1.0, 0.85, 0.3) # yellow — valid swap target

var is_selected := false
var is_available := false  # whether this cell's merc can act this turn
var is_targeted := false   # whether this cell is being targeted by an attack
var is_swap_target := false # whether this cell is a valid swap destination

# The merc occupying this cell (null if empty)
var merc: Merc = null

@onready var color_rect: ColorRect = $ColorRect

func _ready():
	_update_default_color()
	mouse_entered.connect(_on_mouse_entered)
	mouse_exited.connect(_on_mouse_exited)
	input_event.connect(_on_input_event)

func _on_mouse_entered():
	if not is_selected:
		color_rect.color = COLOR_HOVER

func _on_mouse_exited():
	if not is_selected:
		_update_default_color()

func _on_input_event(_viewport, event, _shape_idx):
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		var grid_pos = get_meta("grid_pos")
		print("Cell clicked: row ", grid_pos.x, ", col ", grid_pos.y)
		if merc:
			print("  Merc: ", merc.data.merc_name, " | HP:", merc.current_hp, " | AP:", merc.current_ap)
		cell_clicked.emit(self)

func set_selected(selected: bool):
	is_selected = selected
	if selected:
		color_rect.color = COLOR_SELECTED
	else:
		_update_default_color()

# Place a merc into this cell
func place_merc(new_merc: Merc):
	merc = new_merc
	add_child(merc)
	_update_default_color()

# Remove and return the merc from this cell
func remove_merc() -> Merc:
	var removed = merc
	if merc:
		remove_child(merc)
		merc = null
	_update_default_color()
	return removed

func has_merc() -> bool:
	return merc != null and merc.is_alive

func set_available(available: bool):
	is_available = available
	_update_default_color()

func set_targeted(targeted: bool):
	is_targeted = targeted
	_update_default_color()

func set_swap_target(swap: bool):
	is_swap_target = swap
	_update_default_color()

func _update_default_color():
	if is_selected:
		return
	if is_targeted:
		color_rect.color = COLOR_TARGETED
	elif is_swap_target:
		color_rect.color = COLOR_SWAP_TARGET
	elif not has_merc():
		color_rect.color = COLOR_EMPTY
	elif is_available:
		color_rect.color = COLOR_AVAILABLE
	else:
		color_rect.color = COLOR_UNAVAILABLE
