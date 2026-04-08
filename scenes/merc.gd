# Merc — a living mercenary on the grid.
#
# Holds runtime state (current HP, current AP) and a reference
# to its MercData blueprint (base stats, weapon type, etc.).
# This is what sits inside a Cell during a match.

class_name Merc
extends Node2D

# The blueprint — set this when spawning a merc
@export var data: MercData

# === Runtime state ===
var current_hp: int = 0
var current_ap: int = 0
var is_alive: bool = true
var is_main_character: bool = false
var is_guarding: bool = false  # 50% dmg reduction + crit immunity until next activation

# Visual — just a colored rectangle for now, same as cells.
# Later replaced with merc sprites/art.
var label: Label

func _ready():
	if data:
		_initialize()

func _initialize():
	current_hp = data.max_hp
	current_ap = data.starting_ap

	# Create a simple label showing the merc's name and HP.
	# This is temporary prototype UI — enough to see what's on the grid.
	label = Label.new()
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	label.position = Vector2(-45, -45)
	label.size = Vector2(90, 90)
	label.add_theme_font_size_override("font_size", 11)
	label.add_theme_color_override("font_color", Color.BLACK)
	# z_index ensures the label renders on top of the cell's ColorRect
	label.z_index = 1
	add_child(label)
	_update_label()

func _update_label():
	if not label or not data:
		return
	var mc_indicator = "[MC] " if is_main_character else ""
	var guard_indicator = " [G]" if is_guarding else ""
	label.text = "%s%s%s\nHP:%d\nAP:%d" % [mc_indicator, data.merc_name, guard_indicator, current_hp, current_ap]

# Called each turn to regenerate AP.
# AP gain is random within the merc's speed range — adds unpredictability
# to which mercs become available each turn.
func gain_ap():
	if not is_alive:
		return
	var ap_gain = randi_range(data.spd_min, data.spd_max)
	current_ap += ap_gain
	_update_label()
	return ap_gain

# Check if this merc has enough AP to be activated (100 AP threshold)
func can_activate() -> bool:
	return is_alive and current_ap >= 100

# Spend AP when the merc takes an action
func spend_ap(amount: int):
	current_ap -= amount
	_update_label()

# Take damage, accounting for defense and guard status
func take_damage(amount: int, is_crit: bool = false):
	# Guarding mercs are immune to crits
	if is_guarding and is_crit:
		is_crit = false

	var actual_damage = max(amount - data.def, 1)  # always deal at least 1

	# Guard halves incoming damage
	if is_guarding:
		actual_damage = max(actual_damage / 2, 1)

	current_hp -= actual_damage
	if current_hp <= 0:
		current_hp = 0
		is_alive = false
	_update_label()
	return actual_damage

# Called when this merc is activated — guard wears off
func on_activated():
	is_guarding = false
	_update_label()

func set_guard():
	is_guarding = true
	_update_label()
