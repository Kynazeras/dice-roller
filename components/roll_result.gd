extends Resource
class_name RollResult

@export var dice: Dice
@export var raw_value: int
@export var final_value: int 
@export var is_max: bool
@export var timestamp: float


static func from_dict(dict: Dictionary) -> RollResult:
	var result := RollResult.new()
	result.dice = Dice.from_dict(dict.get("dice", {}))
	result.raw_value = dict.get("raw_value", 0)
	result.final_value = dict.get("final_value", 0)
	result.is_max = dict.get("is_max", false)
	result.timestamp = dict.get("timestamp", 0.0)
	return result