class_name PlayerState
extends Resource


@export var health: int = 100
@export var max_health: int = 100
@export var money: int = 0
@export var player_dice: Array[Dice] = []
@export var active_modifiers: Array[RollModifier] = []


static func from_dict(dict: Dictionary) -> PlayerState:
	var state := PlayerState.new()
	state.health = dict.get("health", 100)
	state.max_health = dict.get("max_health", 100)
	state.money = dict.get("money", 0)

	# Load player dice
	state.player_dice = []
	var dice_array: Array = dict.get("player_dice", [])
	for dice_dict in dice_array:
		var dice: Dice = Dice.from_dict(dice_dict)
		state.player_dice.append(dice)

	# Load active modifiers
	state.active_modifiers = []
	var modifiers_array: Array = dict.get("active_modifiers", [])
	for mod_dict in modifiers_array:
		var mod: RollModifier = RollModifier.from_dict(mod_dict)
		state.active_modifiers.append(mod)

	return state
