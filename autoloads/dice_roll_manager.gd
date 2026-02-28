extends Node

signal roll_completed(results: RollResult)

var player_dice: Array[Dice] = []
var modifiers: Array[RollModifier] = []
var history: Array[RollResult] = []


func roll(dice: Dice) -> RollResult:
	var result = RollResult.new()
	result.dice = dice
	result.raw_value = dice.roll()
	result.is_max = dice.check_max_value(result.raw_value)
	result.final_value = result.raw_value

	# Apply modifiers to the roll result
	for modifier in modifiers:
		result = modifier.apply(result)
	
	history.append(result)
	roll_completed.emit(result)
	return result


func get_history_sum() -> int:
	var total = 0
	for result in history:
		total += result.final_value
	return total


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.

