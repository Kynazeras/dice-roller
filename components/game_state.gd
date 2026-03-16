class_name GameState
extends Resource

@export var health: int = 100
@export var max_health: int = 100
@export var money: int = 0
@export var total_rolled: int = 0
@export var money_spent: int = 0
@export var current_round: int = 0
@export var player_dice: Array[Dice] = []
@export var active_modifiers: Array[RollModifier] = []
@export var round_state: RoundState


static func from_dict(dict: Dictionary) -> GameState:
	var state := GameState.new()
	state.health = dict.get("health", 100)
	state.max_health = dict.get("max_health", 100)
	state.money = dict.get("money", 0)
	state.total_rolled = dict.get("total_rolled", 0)
	state.money_spent = dict.get("money_spent", 0)
	state.current_round = dict.get("current_round", 0)

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

	# Load round state
	if dict.has("round_state"):
		state.round_state = RoundState.from_dict(dict["round_state"])
	else:
		state.round_state = RoundState.new()

	return state