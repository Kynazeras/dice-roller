class_name HealthBar
extends ProgressBar


func _ready() -> void:
	max_value = GameConfigManager.get_starting_health()
	value = max_value
	GameManager.health_changed.connect(_on_health_changed)


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass


func _on_health_changed(new_health: int, change: int) -> void:
	value = new_health
