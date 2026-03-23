class_name PlantHealth
extends Control

@onready var health_bar: ProgressBar = %HealthBar
@onready var health_value: Label = %HealthValue


func _ready() -> void:
	GameManager.round_ended.connect(_on_round_ended)
	PlayerManager.health_component.health_changed.connect(_on_health_changed)
	update_health_bar()


func _on_health_changed(_current_amount: int, _max_amount: int) -> void:
	update_health_bar()


func _on_round_ended(_round_index: int, round_result: GameManager.RoundResult) -> void:
	var damage: int = PlayerManager.health_component.calculate_round_damage(round_result)
	PlayerManager.health_component.take_damage(damage)


func update_health_bar() -> void:
	health_bar.value = PlayerManager.health_component.current_health
	health_bar.max_value = PlayerManager.health_component.max_health
	health_value.text = "%d / %d" % ([PlayerManager.health_component.current_health, PlayerManager.health_component.max_health])
