extends Node

var player_state: PlayerState = PlayerState.new()
var health_component: HealthComponent = HealthComponent.new()


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta: float) -> void:
	pass


func initialize_player() -> void:
	player_state.health = GameConfigManager.get_starting_health()
	player_state.max_health = GameConfigManager.get_starting_health()
	player_state.money = 0
	player_state.player_dice = []
	for dice_id in GameConfigManager.get_starting_dice_ids():
		var dice_def: Dictionary = GameConfigManager.get_dice_def(dice_id)
		if dice_def.is_empty():
			push_error("GameManager: Starting dice '%s' not found in catalog" % dice_id)
			continue
		var dice: Dice = Dice.from_dict(dice_def)
		player_state.player_dice.append(dice)
	player_state.active_modifiers = []

	health_component.current_health = player_state.health
	health_component.max_health = player_state.max_health


func get_potentianl_round_damage(round_result: GameManager.RoundResult) -> int:
	return health_component.calculate_round_damage(round_result)
