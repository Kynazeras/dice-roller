class_name HealthBar
extends ProgressBar

@onready var health_component: HealthComponent = %HealthComponent


func _ready() -> void:
	GameManager.round_ended.connect(_on_round_ended)
	health_component.health_changed.connect(_on_health_changed)
	update_health_bar()
	print(value)


func _on_health_changed(_current_amount: int, _max_amount: int) -> void:
	update_health_bar()


func _on_round_ended(_round_index: int, round_result: GameManager.RoundResult) -> void:
	health_component.take_damage(calculate_damage(round_result))


func calculate_damage(result: GameManager.RoundResult) -> int:
	match result:
		GameManager.RoundResult.EXACT:
			return 0
		GameManager.RoundResult.OVER:
			return (GameManager.game_state.round_state.get_total() - GameManager.game_state.round_state.goal) * 2
		GameManager.RoundResult.UNDER:
			return GameManager.game_state.round_state.goal - GameManager.game_state.round_state.get_total()
		_:
			push_warning("Plant: Invalid round result for damage calculation")
			return 0


func update_health_bar() -> void:
	value = health_component.current_health
	max_value = health_component.max_health