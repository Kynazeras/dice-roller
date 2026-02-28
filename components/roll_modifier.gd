class_name RollModifier extends Resource

@export var flat_bonus: int = 0
@export var multiplier: float = 1.0

func apply(result: RollResult) -> RollResult:
	result.final_value = int(result.final_value * multiplier) + flat_bonus
	return result