# Targeting — determines which enemy grid cells a weapon can target.
#
# Two concepts:
#   - VALID TARGETS: cells the player can click to aim at (shown in red)
#   - HIT PATTERN: cells that actually take damage once a target is chosen
#
# Example: Gun's valid targets are 3 rows. Player picks a row.
#          Hit pattern = all 3 cells in that row.
#
# Grid layout reminder (each player's 3x3):
#   Row 0 = back row (ranged)
#   Row 1 = mid row
#   Row 2 = front row (melee)
#   Col 0 = left, Col 1 = center, Col 2 = right

class_name Targeting
extends RefCounted

# Returns all cells the player can click to aim at.
# These are shown as red highlights on the enemy grid.
static func get_valid_targets(weapon: MercData.WeaponType, attacker_pos: Vector2i) -> Array[Vector2i]:
	var row = attacker_pos.x
	var col = attacker_pos.y

	match weapon:
		MercData.WeaponType.SWORD:
			# Can target any cell in the enemy front row
			return [Vector2i(2, 0), Vector2i(2, 1), Vector2i(2, 2)]
		MercData.WeaponType.SPEAR:
			# Can target any column — will hit front + mid in that column
			return [Vector2i(2, 0), Vector2i(2, 1), Vector2i(2, 2)]
		MercData.WeaponType.GUN:
			# Can target any column — will hit all 3 cells in that column (shoots through ranks)
			return [Vector2i(2, 0), Vector2i(2, 1), Vector2i(2, 2)]
		MercData.WeaponType.AXE:
			# Can target any row — will hit all 3 cells in that row (horizontal sweep)
			return [Vector2i(0, col), Vector2i(1, col), Vector2i(2, col)]
		MercData.WeaponType.CANNON:
			# Can target any cell — cross pattern radiates from chosen cell
			return _all_cells()
		MercData.WeaponType.STAFF:
			# Can target any cell on the grid (most flexible)
			return _all_cells()
		MercData.WeaponType.BOW:
			# Can target any single cell (long range, precise)
			return _all_cells()

	return []

# Returns the cells that actually take damage when the player
# confirms their chosen target cell.
static func get_hit_cells(weapon: MercData.WeaponType, chosen_target: Vector2i) -> Array[Vector2i]:
	var row = chosen_target.x
	var col = chosen_target.y

	match weapon:
		MercData.WeaponType.SWORD:
			# Hits the single chosen cell
			return [chosen_target]
		MercData.WeaponType.SPEAR:
			# Hits front + mid row in the chosen column
			return [Vector2i(2, col), Vector2i(1, col)]
		MercData.WeaponType.GUN:
			# Hits the entire column of the chosen cell (shoots through front → mid → back)
			return [Vector2i(0, col), Vector2i(1, col), Vector2i(2, col)]
		MercData.WeaponType.AXE:
			# Hits the entire row of the chosen cell (horizontal sweep)
			return [Vector2i(row, 0), Vector2i(row, 1), Vector2i(row, 2)]
		MercData.WeaponType.CANNON:
			# Cross/plus pattern centered on chosen cell
			var targets: Array[Vector2i] = [chosen_target]
			for offset in [Vector2i(-1, 0), Vector2i(1, 0), Vector2i(0, -1), Vector2i(0, 1)]:
				var target = chosen_target + offset
				if _in_bounds(target):
					targets.append(target)
			return targets
		MercData.WeaponType.STAFF:
			# Hits the single chosen cell
			return [chosen_target]
		MercData.WeaponType.BOW:
			# Hits the single chosen cell
			return [chosen_target]

	return []

static func _all_cells() -> Array[Vector2i]:
	var cells: Array[Vector2i] = []
	for r in 3:
		for c in 3:
			cells.append(Vector2i(r, c))
	return cells

static func _in_bounds(pos: Vector2i) -> bool:
	return pos.x >= 0 and pos.x < 3 and pos.y >= 0 and pos.y < 3
