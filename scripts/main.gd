extends Node2D

@onready var dice_buttons: HBoxContainer = %DiceButtons
@onready var current_roll_label: Label = %CurrentRollLabel
@onready var goal_label: Label = %GoalLabel
@onready var goal_bar: ProgressBar = %GoalBar
@onready var total_label: Label = %TotalLabel
@onready var game_over_label: Label = %GameOverLabel
@onready var roll_history_container: RollHistoryContainer = %RollHistoryContainer

const GOAL: int = 15

var current_total: int = 0


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	goal_label.text = "Goal: %d" % GOAL
	goal_bar.max_value = GOAL
	goal_bar.value = 0
	total_label.text = "0"
	for child in dice_buttons.get_children():
		child.queue_free()
	add_standard_dice_buttons()
	DiceRollManager.roll_completed.connect(_on_roll_completed)


func _on_roll_completed(result: RollResult) -> void:
	if result.is_max:
		current_roll_label.add_theme_color_override("font_color", Color.RED)
	else:
		current_roll_label.remove_theme_color_override("font_color")
	
	current_roll_label.text = "Current Roll: %d" % result.final_value
	current_total += result.final_value
	total_label.text = "%d" % current_total
	goal_bar.value = current_total

	if current_total == GOAL:
		_game_over(true)
	elif current_total > GOAL:
		_game_over(false)


func _reset_game() -> void:
	await get_tree().create_timer(3.0).timeout
	game_over_label.text = ""
	current_total = 0
	current_roll_label.remove_theme_color_override("font_color")
	current_roll_label.text = "Current Roll: 0"
	total_label.text = "0"
	goal_bar.value = 0
	roll_history_container.reset_history()


func _game_over(win: bool) -> void:
	var result_text := "win :) " if win else "lose :( "
	total_label.text = ""
	game_over_label.text = "You %s! Final total: %d" % [result_text, current_total]
	_reset_game()


func add_dice_button(dice: Dice) -> void:
	var button := DiceButton.new()
	button.dice = dice
	dice_buttons.add_child(button)



func add_standard_dice_buttons() -> void:
	for dice_type in Dice.Type.values():
		add_dice_button(Dice.new(dice_type))
