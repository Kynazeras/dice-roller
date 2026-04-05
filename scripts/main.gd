extends Node2D

@onready var dice_buttons: HBoxContainer = %DiceButtons
@onready var goal_label: Label = %GoalLabel
@onready var goal_bar: ProgressBar = %GoalBar
@onready var total_label: Label = %TotalLabel
@onready var roll_history_container: RollHistoryContainer = %RollHistoryContainer
@onready var current_round_label: Label = %CurrentRoundLabel
@onready var current_day_label: Label = %CurrentDayLabel

const DAYS_OF_WEEK = ["Mon", "Tue", "Wed", "Thu", "Fri", "Sat", "Sun"]


var dice_button_scene: PackedScene = preload("res://scenes/dice_button.tscn")


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	for child in dice_buttons.get_children():
		child.queue_free() 
	GameManager.round_started.connect(_on_round_started)
	GameManager.round_ended.connect(_on_round_ended)
	GameManager.roll_completed.connect(_on_roll_completed)
	GameManager.game_over.connect(_on_game_over)
	GameManager.shop_opened.connect(_on_shop_opened)
	GameManager.modifier_reward_offered.connect(_on_modifier_reward_offered)
	print(GameManager.game_state.current_round)
	# TODO: revisit this
	if GameManager.game_state.total_rolled == 0:
		GameManager.start_new_game()
	else:
		GameManager.start_round(GameManager.game_state.current_round + 1)

	_populate_dice_buttons()


func _populate_dice_buttons() -> void:
	for dice in PlayerManager.player_state.player_dice:
		var dice_button: DiceButton = dice_button_scene.instantiate()
		dice_button.dice = dice
		dice_button.dice_selected.connect(_on_dice_selected)
		dice_buttons.add_child(dice_button)


func _on_round_started(_round_index: int, goal: int) -> void:
	current_round_label.text = "Round: %d" % (_round_index + 1)
	current_day_label.text = "Day: %s" % DAYS_OF_WEEK[0]
	goal_label.text = "Goal: %d" % goal
	goal_bar.value = 0
	goal_bar.max_value = goal
	total_label.text = ""


func _on_round_ended(_round_index: int, _result: GameManager.RoundResult) -> void:
	goal_label.text = "Goal: -"
	goal_bar.value = 0
	goal_bar.max_value = 1
	total_label.text = "Total: -"


func _on_health_changed(_new_health: int, _change: int) -> void:
	# You could add some animation or effects here based on the change
	pass


func _on_money_changed(_new_money: int) -> void:
	# You could add some animation or effects here based on the money change
	pass


func _on_game_over(_win: bool) -> void:
	pass


func _on_shop_opened(_items: Array) -> void:
	# You would implement your shop UI logic here to display the items
	pass


func _on_modifier_reward_offered(_modifiers: Array) -> void:
	# You would implement your modifier reward UI logic here to display the offered modifiers
	pass


func _on_roll_completed(_roll_result: RollResult, round_total: int) -> void:
	total_label.text = "%d" % round_total
	goal_bar.value = round_total
	current_day_label.text = "Day: %s" % DAYS_OF_WEEK[GameManager.game_state.round_state.rolls.size() % DAYS_OF_WEEK.size()]



func _on_dice_selected(dice: Dice) -> void:
	GameManager.player_roll(dice)
