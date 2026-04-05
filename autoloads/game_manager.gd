extends Node

signal round_started(round_index: int, goal: int)
signal round_ended(round_index: int, result: RoundResult)
signal roll_started(dice: Dice)
signal roll_completed(roll_result: RollResult, round_total: int)
signal money_changed(new_money: int)
signal game_over(win: bool)
signal shop_opened(items: Array[ShopItem])
signal modifier_reward_offered(modifiers: Array[RollModifier])

enum State {
	IDLE,
	ROUND_ACTIVE,
	ROLLING,
	ROUND_RESULT,
	SHOP,
	MODIFIER_REWARD,
	GAME_OVER
}

enum RoundResult {
	UNDER,
	OVER,
	EXACT,
}

var current_state: State = State.IDLE
var game_state: GameState = GameState.new()
var roll_timer: Timer = Timer.new()

var _pending_roll_result: RollResult = null
var _pending_round_total: int = 0


var round_history: Array = [] # This will store summaries of each round for the round summary screen

func _ready() -> void:
	roll_timer.wait_time = GameConfigManager.get_roll_animation_time()
	roll_timer.one_shot = true
	add_child(roll_timer)
	roll_timer.timeout.connect(_on_roll_animation_finished)


func start_new_game() -> void:
	game_state = GameState.new()
	game_state.total_rolled = 0
	game_state.money_spent = 0
	game_state.current_round = 0
	round_history.clear()

	PlayerManager.initialize_player()
	start_round(game_state.current_round)


func start_round(index: int) -> void:
	game_state.current_round = index

	var round_config: Dictionary = GameConfigManager.get_round_config(index)
	print(round_config)
	var goal: int = round_config.get("goal", 10)
	var free_rerolls: int = round_config.get("free_rerolls", 1)

	# Create a fresh RoundState for this round
	var rs := RoundState.new()
	rs.round_index = index
	rs.goal = goal
	rs.rolls = []
	rs.rerolls_used = 0
	rs.free_rerolls = free_rerolls
	rs.last_roll = null
	game_state.round_state = rs

	current_state = State.ROUND_ACTIVE
	round_started.emit(index, goal)


func player_roll(dice: Dice) -> void:
	if current_state != State.ROUND_ACTIVE:
		push_warning("GameManager: Cannot roll dice when not in an active round")
		return
	
	current_state = State.ROLLING
	var result: RollResult = DiceRollManager.roll(dice, game_state.round_state)
	_pending_roll_result = result
	_pending_round_total += result.final_value
	roll_started.emit(dice)
	roll_timer.start()
	game_state.round_state.rolls.append(result)
	game_state.round_state.last_roll = result
	game_state.total_rolled += result.final_value


func get_potential_round_result() -> RoundResult:
	var total: int = game_state.round_state.get_total()
	var goal: int = game_state.round_state.goal
	if total == goal:
		return RoundResult.EXACT
	elif total > goal:
		return RoundResult.OVER
	else:
		return RoundResult.UNDER


func player_reroll():
	var result: RollResult = DiceRollManager.reroll_last(game_state.round_state.last_roll.dice, game_state.round_state)
	game_state.round_state.rolls.pop_back() # Remove the old roll
	game_state.round_state.rolls.append(result) # Add the new roll
	game_state.round_state.last_roll = result
	game_state.total_rolled += result.final_value - result.raw_value # Adjust total rolled by the difference

	_pending_roll_result = result
	_pending_round_total += result.final_value
	roll_started.emit(result.dice)
	roll_timer.start()


func _on_roll_animation_finished() -> void:
	current_state = State.ROUND_ACTIVE
	roll_completed.emit(_pending_roll_result, _pending_round_total)
	check_round_end()


func check_round_end() -> void:
	if game_state.round_state.rolls.size() == GameConfigManager.get_max_rolls_per_round():
		end_round(get_potential_round_result())
	# var total: int = game_state.round_state.get_total()
	# var goal: int = game_state.round_state.goal
	# if total == goal:
	# 	end_round(RoundResult.EXACT)
	# elif total > goal:
	# 	end_round(RoundResult.OVER)


func player_stop() -> void:
	if current_state != State.ROUND_ACTIVE:
		push_warning("GameManager: Cannot stop when not in an active round")
		return
	
	end_round(RoundResult.UNDER)


func update_round_history(result: RoundResult, damage: int) -> void:
	var summary: RoundSummaryData = RoundSummaryData.new()
	summary.round_index = game_state.current_round
	summary.result = result
	summary.total = game_state.round_state.get_total()
	summary.goal = game_state.round_state.goal
	summary.damage = damage
	round_history.append(summary)


func end_round(result: RoundResult) -> void:
	# TODO: emit money changed for playe state
	# game_state.money += game_state.round_state.get_total()
	var round_damage: int = PlayerManager.health_component.calculate_round_damage(result)
	update_round_history(result, round_damage) # Placeholder damage value until we decide how to handle health changes on the round summary screen
	_pending_round_total = 0
	_pending_roll_result = null
	round_ended.emit(game_state.current_round, result)
	if PlayerManager.health_component.current_health > 0:
		SceneManager.change_scene("res://scenes/round_summary.tscn")
	else:
		current_state = State.GAME_OVER
		game_over.emit(false)
	
		
func select_modifier_reward(modifier: RollModifier) -> void:
	if current_state != State.MODIFIER_REWARD:
		push_warning("GameManager: Cannot select modifier reward when not in modifier reward state")
		return
	
	game_state.active_modifiers.append(modifier)
	open_shop()


func open_shop() -> void:
	current_state = State.SHOP
	shop_opened.emit(GameConfigManager.get_shop_items_for_round(game_state.current_round))


func buy_item(item: ShopItem) -> void:
	if current_state != State.SHOP:
		push_warning("GameManager: Cannot buy item when not in shop state")
		return
	
	if game_state.money < item.cost:
		push_warning("GameManager: Not enough money to buy item '%s'" % item.name)
		return
	
	game_state.money -= item.cost
	money_changed.emit(game_state.money)
	if(item.item_type == 'dice'):
		var dice_def: Dictionary = GameConfigManager.get_dice_def(item.item_id)
		if dice_def.is_empty():
			push_error("GameManager: Dice '%s' not found in catalog" % item.item_id)
			return
		var dice: Dice = Dice.from_dict(dice_def)
		game_state.player_dice.append(dice)
	elif(item.item_type == 'modifier'):
		var modifier_def: Dictionary = GameConfigManager.get_modifier_def(item.item_id)
		if modifier_def.is_empty():
			push_error("GameManager: Modifier '%s' not found in catalog" % item.item_id)
			return
		var modifier: RollModifier = RollModifier.from_dict(modifier_def)
		game_state.active_modifiers.append(modifier)
	else:
		push_warning("GameManager: Unknown shop item type '%s' for item '%s'" % [item.item_type, item.name])


func close_shop() -> void:
	if current_state != State.SHOP:
		push_warning("GameManager: Cannot close shop when not in shop state")
		return
	
	start_round(game_state.current_round + 1)


func load_game_state(saved_state: GameState) -> void:
	game_state = saved_state
	current_state = State.ROUND_ACTIVE
