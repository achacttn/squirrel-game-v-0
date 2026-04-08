# MercData — defines what a mercenary IS (its template/blueprint).
#
# This is like a character sheet. It doesn't track runtime state
# (current HP, current AP) — that's the Merc scene's job later.
# This just defines the merc's base identity and stats.
#
# Each merc in the roster will be a .tres file using this resource.
# Example: data/mercs/swordsman.tres, data/mercs/gunslinger.tres

class_name MercData
extends Resource

# === Identity ===
@export var merc_name: String = ""
@export_multiline var description: String = ""
@export var icon: Texture2D   # Placeholder art — load from res://assets/icons/

# === Weapon ===
# Determines the targeting pattern when attacking the enemy grid.
# Sword = single target, Spear = 2 in a row, Gun = full row,
# Cannon = cross (+), etc.
enum WeaponType { SWORD, SPEAR, GUN, CANNON, STAFF, BOW }
@export var weapon_type: WeaponType = WeaponType.SWORD

# === Core Stats ===
@export_group("Stats")
@export var max_hp: int = 100          # Health pool
@export var atk: int = 10              # Base attack damage
@export var def: int = 5               # Damage reduction
@export var spd_min: int = 65           # Minimum AP gained per turn
@export var spd_max: int = 85           # Maximum AP gained per turn
@export var crit: float = 0.05         # Critical hit chance (0.0 to 1.0)
@export var crit_dmg: float = 1.5      # Critical hit damage multiplier
@export var acc: float = 0.95          # Accuracy / hit chance (0.0 to 1.0)
@export var eva: float = 0.05          # Evasion chance (0.0 to 1.0)
@export var armor: float = 0.0         # Damage reduction percentage (0.0 to 1.0)
@export var magic: float = 0.0         # Magic damage and resistance multiplier (for elemental attacks, etc.)

# === AP ===
@export_group("Action Points")
@export var starting_ap: int = 0       # AP the merc starts the match with
# spd (above) determines how much AP is gained each turn.
# 100 AP required to be eligible for activation.

# === Abilities ===
# Placeholder for now — abilities will be their own Resource type later.
# Every merc gets Guard and Swap for free; these are the unique ones.
@export_group("Abilities")
@export var ability_names: PackedStringArray = []
