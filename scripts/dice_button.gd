@tool
class_name DiceButton
extends Button

@export var dice: Dice

signal dice_selected(dice: Dice)

func _ready() -> void:
	pressed.connect(_on_pressed)
	GameManager.roll_started.connect(_on_roll_started)
	GameManager.roll_completed.connect(_on_roll_completed)
	if dice:
		text = "Roll a D%d" % dice.sides

func _on_pressed() -> void:
	emit_signal("dice_selected", dice)


func _on_roll_started(_dice: Dice) -> void:
	disabled = true


func _on_roll_completed(_result: RollResult, _total: int) -> void:
	disabled = false
