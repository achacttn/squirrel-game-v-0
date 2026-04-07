extends Node2D

const CellScene = preload("res://scenes/cell.tscn")

const CELL_SIZE = 100
const CELL_GAP = 4
const ROWS = 3
const COLS = 3

# Track the currently selected cell so we can deselect it
# when a different one is clicked
var selected_cell: Area2D = null

func _ready():
	_build_grid()

func _build_grid():
	for row in ROWS:
		for col in COLS:
			var cell = CellScene.instantiate()

			cell.position = Vector2(
				col * (CELL_SIZE + CELL_GAP),
				row * (CELL_SIZE + CELL_GAP)
			)

			cell.set_meta("grid_pos", Vector2i(row, col))

			# Connect each cell's clicked signal to our handler.
			# This is the Grid listening for "any cell was clicked" —
			# later this is where merc selection, targeting, and
			# swap logic will plug in.
			cell.cell_clicked.connect(_on_cell_clicked)

			add_child(cell)

func _on_cell_clicked(cell):
	# If clicking the already-selected cell, deselect it
	if cell == selected_cell:
		cell.set_selected(false)
		selected_cell = null
		return

	# Deselect the previous cell (if any)
	if selected_cell:
		selected_cell.set_selected(false)

	# Select the new cell
	cell.set_selected(true)
	selected_cell = cell
