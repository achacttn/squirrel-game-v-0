extends Node2D

const CellScene = preload("res://scenes/cell.tscn")

const CELL_SIZE = 100
const CELL_GAP = 4
const ROWS = 3
const COLS = 3

@export var mirrored := false  # When true, row order is flipped so front row is at top

# Emitted when a cell is clicked during gameplay — Main listens for this
# to process actions (attack, guard, swap, etc.)
signal cell_clicked_for_action(cell)

var selected_cell: Area2D = null

# 2D array to access cells by position: cells[row][col]
var cells: Array = []

func _ready():
	_build_grid()

func _build_grid():
	for row in ROWS:
		var row_array := []
		for col in COLS:
			var cell = CellScene.instantiate()

			# When mirrored, flip row order so front row (row 2) renders at top
			var visual_row = (ROWS - 1 - row) if mirrored else row
			cell.position = Vector2(
				col * (CELL_SIZE + CELL_GAP),
				visual_row * (CELL_SIZE + CELL_GAP)
			)

			cell.set_meta("grid_pos", Vector2i(row, col))
			cell.cell_clicked.connect(_on_cell_clicked)
			add_child(cell)
			row_array.append(cell)
		cells.append(row_array)

# Place a merc at a specific grid position
func place_merc_at(row: int, col: int, merc_data: MercData, is_main: bool = false):
	var cell = cells[row][col]
	var merc = Merc.new()
	merc.data = merc_data
	merc.is_main_character = is_main
	cell.place_merc(merc)

# Get the cell at a grid position
func get_cell(row: int, col: int):
	return cells[row][col]

func _on_cell_clicked(cell):
	if cell == selected_cell:
		cell.set_selected(false)
		selected_cell = null
		return

	if selected_cell:
		selected_cell.set_selected(false)

	cell.set_selected(true)
	selected_cell = cell
	cell_clicked_for_action.emit(cell)

# Highlight cells whose mercs are available to act this turn
func highlight_available(available_mercs: Array):
	for row in cells:
		for cell in row:
			if cell.has_merc():
				cell.set_available(cell.merc in available_mercs)
			else:
				cell.set_available(false)

# Clear all availability highlights
func clear_highlights():
	for row in cells:
		for cell in row:
			cell.set_available(false)

# Find the cell containing a specific merc
func find_cell_for_merc(merc: Merc):
	for row in cells:
		for cell in row:
			if cell.merc == merc:
				return cell
	return null

# Show which cells would be hit by an attack (red highlight)
func show_targets(target_positions: Array[Vector2i]):
	clear_targets()
	for pos in target_positions:
		if pos.x >= 0 and pos.x < ROWS and pos.y >= 0 and pos.y < COLS:
			cells[pos.x][pos.y].set_targeted(true)

# Clear all target highlights
func clear_targets():
	if selected_cell:
		selected_cell.set_selected(false)
		selected_cell = null
	for row in cells:
		for cell in row:
			cell.set_targeted(false)

# Show swap targets (yellow highlight)
func show_swap_targets(positions: Array[Vector2i]):
	clear_swap_targets()
	for pos in positions:
		cells[pos.x][pos.y].set_swap_target(true)

func clear_swap_targets():
	for row in cells:
		for cell in row:
			cell.set_swap_target(false)

# Get all cells that have a living merc (for swap targeting), excluding the source cell
func get_swap_targets(pos: Vector2i) -> Array[Vector2i]:
	var targets: Array[Vector2i] = []
	for row in ROWS:
		for col in COLS:
			if Vector2i(row, col) != pos and cells[row][col].has_merc():
				targets.append(Vector2i(row, col))
	return targets

# Swap the mercs in two cells
func swap_mercs(pos_a: Vector2i, pos_b: Vector2i):
	var cell_a = cells[pos_a.x][pos_a.y]
	var cell_b = cells[pos_b.x][pos_b.y]

	var merc_a = cell_a.remove_merc()
	var merc_b = cell_b.remove_merc()

	if merc_b:
		cell_a.place_merc(merc_b)
	if merc_a:
		cell_b.place_merc(merc_a)
