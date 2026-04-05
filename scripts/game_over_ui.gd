class_name GameOverUI
extends Control

@onready var new_game_button: Button = %NewGameButton

func _ready() -> void:
	new_game_button.pressed.connect(_on_new_game_button_pressed)


func _on_new_game_button_pressed() -> void:
	GameManager.game_state = GameState.new()
	print(GameManager.game_state.total_rolled)  # Reset the game state
	SceneManager.change_scene("res://scenes/main.tscn")
