class_name Dice extends Resource

enum Type { D4 = 4, D6 = 6, D8 = 8, D10 = 10, D12 = 12, D20 = 20 }

@export var type: Type = Type.D6

var _rng: RandomNumberGenerator

func _init(dice_type: Type = Type.D6) -> void:
	type = dice_type
	_rng = RandomNumberGenerator.new()
	_rng.randomize()

func roll() -> int:
	return _rng.randi_range(1, type)

func roll_multiple(count: int) -> Array[int]:
	var results: Array[int] = []
	for i in count:
		results.append(roll())
	return results

func get_sides() -> int:
	return type as int


func check_max_value(result: int) -> bool:
	return result == type as int
