class_name RoundSummary
extends CanvasLayer


@onready var total_rolled_label: Label = %TotalRolled
@onready var health_gain_label: Label = %HealthGain

@onready var next_round_button: Button = %NextRoundButton

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	if GameManager.game_state:
		total_rolled_label.text = str(GameManager.round_history[GameManager.game_state.current_round].total)
		health_gain_label.text = str(GameManager.round_history[GameManager.game_state.current_round].damage)
	next_round_button.pressed.connect(_on_next_round_pressed)


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta: float) -> void:
	pass
	

func _on_next_round_pressed() -> void:
	SceneManager.change_scene("res://scenes/main.tscn")
