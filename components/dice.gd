class_name Dice extends Resource

enum Type { D4 = 4, D6 = 6, D8 = 8, D10 = 10, D12 = 12, D20 = 20 }

@export var type: Type = Type.D6
@export var id: String = ""
@export var name: String = ""
@export var sides: int = 6
@export var faces: Array[int] = []

var _rng: RandomNumberGenerator

func _init(dice_type: Type = Type.D6) -> void:
	type = dice_type
	_rng = RandomNumberGenerator.new()
	_rng.randomize()


static func from_dict(data: Dictionary) -> Dice:
	var dice := Dice.new()
	var sides_value: int = data.get("sides", 6)
	dice.type = sides_value as Type
	dice.id = data.get("id", "")
	dice.name = data.get("name", "")
	dice.sides = sides_value
	# dice.faces = data.get("faces", [])
	return dice

func roll() -> int:
	if faces.size() > 0:
		return faces[_rng.randi_range(0, faces.size() - 1)]
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
