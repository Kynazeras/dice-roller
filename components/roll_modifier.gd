class_name RollModifier extends Resource

@export var id: String = ""
@export var modifier_name: String = ""
@export var type: String = "" # e.g. "flat_bonus", "multiplier"
@export var scope: String = "" # e.g. "all", "max_only", "min_only"
@export var trigger: String = "" # e.g. "on_roll", "on_max", "on_min"
@export var min_value: int = 0
@export var max_value: int = 0
@export var description: String = ""
@export var flat_bonus: int = 0
@export var multiplier: float = 1.0


# TODO - Check trigger conditions before applying
func apply(result: RollResult) -> RollResult:
	result.final_value = int(result.final_value * multiplier) + flat_bonus
	return result


static func from_dict(data: Dictionary) -> RollModifier:
	var mod := RollModifier.new()
	mod.id = data.get("id", "")
	mod.modifier_name = data.get("modifier_name", "")
	mod.type = data.get("type", "")
	mod.scope = data.get("scope", "")
	mod.trigger = data.get("trigger", "")
	mod.min_value = data.get("min_value", 0)
	mod.max_value = data.get("max_value", 0)
	mod.description = data.get("description", "")
	mod.flat_bonus = data.get("flat_bonus", 0)
	mod.multiplier = data.get("multiplier", 1.0)
	return mod