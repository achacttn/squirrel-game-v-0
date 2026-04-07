extends Area2D

signal cell_clicked(cell)

# Colors for different cell states.
# Later these will be replaced with proper art/shaders,
# but for prototyping, color changes make it obvious what's happening.
const COLOR_DEFAULT = Color(0.9, 0.9, 0.9)     # light grey
const COLOR_HOVER = Color(0.7, 0.85, 1.0)       # light blue
const COLOR_SELECTED = Color(0.3, 0.6, 1.0)     # blue

# Track whether this cell is currently selected
var is_selected := false

# Reference to the ColorRect child — we'll grab it in _ready
@onready var color_rect: ColorRect = $ColorRect

func _ready():
	# @onready means color_rect is set when _ready runs —
	# before this point, child nodes aren't guaranteed to exist yet.
	color_rect.color = COLOR_DEFAULT

	# Connect hover signals — Area2D has built-in mouse_entered/exited
	mouse_entered.connect(_on_mouse_entered)
	mouse_exited.connect(_on_mouse_exited)
	input_event.connect(_on_input_event)

func _on_mouse_entered():
	if not is_selected:
		color_rect.color = COLOR_HOVER

func _on_mouse_exited():
	if not is_selected:
		color_rect.color = COLOR_DEFAULT

func _on_input_event(_viewport, event, _shape_idx):
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		var grid_pos = get_meta("grid_pos")
		print("Cell clicked: row ", grid_pos.x, ", col ", grid_pos.y)
		cell_clicked.emit(self)

# Called by the Grid when this cell is selected or deselected
func set_selected(selected: bool):
	is_selected = selected
	color_rect.color = COLOR_SELECTED if selected else COLOR_DEFAULT
