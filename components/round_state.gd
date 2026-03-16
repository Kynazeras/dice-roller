class_name RoundState
extends Resource

@export var round_index: int = 0
@export var goal: int = 10
@export var rolls: Array[RollResult] = []
@export var rerolls_used: int = 0
@export var free_rerolls: int = 1
@export var last_roll: RollResult


static func from_dict(dict: Dictionary) -> RoundState:
	var rs := RoundState.new()
	rs.round_index = dict.get("round_index", 0)
	rs.goal = dict.get("goal", 10)
	rs.rerolls_used = dict.get("rerolls_used", 0)
	rs.free_rerolls = dict.get("free_rerolls", 1)

	# Load rolls
	rs.rolls = []
	var rolls_array: Array = dict.get("rolls", [])
	for roll_dict in rolls_array:
		var roll: RollResult = RollResult.from_dict(roll_dict)
		rs.rolls.append(roll)

	# Load last roll
	if dict.has("last_roll"):
		rs.last_roll = RollResult.from_dict(dict["last_roll"])
	else:
		rs.last_roll = null

	return rs


func get_total() -> int:
	var total: int = 0
	for roll in rolls:
		total += roll.final_value
	return total


func get_reroll_cost(game_config: GameConfig) -> int:
	return game_config.get_reroll_cost(rerolls_used)


func can_reroll(game_config: GameConfig, current_money: int) -> bool:
	return rerolls_used < free_rerolls or game_config.get_reroll_cost(rerolls_used) <= current_money