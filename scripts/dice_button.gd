class_name DiceButton
extends Button

@export var dice: Dice = Dice.new(Dice.Type.D6)

func _ready() -> void:
	pressed.connect(_on_pressed)
	text = "Roll a D%d" % dice.type

func _on_pressed() -> void:
	DiceRollManager.roll(dice)
