extends Node

signal roll_completed(results: RollResult)
signal reroll_completed(old_result: RollResult, new_result: RollResult)
signal round_total_changed(new_total: int)

var player_dice: Array[Dice] = []
var modifiers: Array[RollModifier] = []


func roll(dice: Dice, round_state: RoundState) -> RollResult:
	var result = RollResult.new()
	result.dice = dice
	result.raw_value = dice.roll()
	result.is_max = dice.check_max_value(result.raw_value)
	result.final_value = result.raw_value

	# Apply modifiers to the roll result
	for modifier in GameManager.game_state.active_modifiers:
		result = modifier.apply(result)
	
	round_state.rolls.append(result)
	round_total_changed.emit(round_state.get_total())
	roll_completed.emit(result)
	return result

func reroll_last(dice: Dice, round_state: RoundState) -> RollResult:
	if round_state.last_roll == null:
		push_warning("DiceRollManager: No previous roll to reroll")
		return null
	
	var old_result = round_state.last_roll
	var new_result = roll(dice, round_state)
	
	reroll_completed.emit(old_result, new_result)
	round_total_changed.emit(round_state.total)
	return new_result
