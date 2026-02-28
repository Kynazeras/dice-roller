class_name RollHistoryContainer
extends PanelContainer

@onready var rolls: VBoxContainer = %Rolls

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	reset_history()
	DiceRollManager.roll_completed.connect(_on_roll_completed)


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass


func add_roll_result(dice_type: int, result: int) -> void:
	var label := Label.new()
	label.theme_type_variation = "DicierLabel"
	label.text = "%d_ON_D%d" % [result, dice_type]
	label.horizontal_alignment = HorizontalAlignment.HORIZONTAL_ALIGNMENT_CENTER
	rolls.add_child(label)
	

func reset_history() -> void:
	for child in rolls.get_children():
		child.queue_free()

func _on_roll_completed(result: RollResult) -> void:
	add_roll_result(result.dice.type as int, result.raw_value)
