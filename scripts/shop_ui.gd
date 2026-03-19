extends Control


@onready var proceed_button: Button = %ProceedButton

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	proceed_button.pressed.connect(_on_proceed_pressed)


func _on_proceed_pressed() -> void:
	SceneManager.change_scene("res://scenes/main.tscn")
