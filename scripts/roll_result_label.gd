class_name RollResultLabel
extends Label


var _animating_dice: Dice = Dice.new()
var _is_animating: bool = false
var _anim_accumulator: float = 0.0


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	GameManager.roll_started.connect(_on_roll_started)
	GameManager.roll_completed.connect(_on_roll_completed)


func _on_roll_started(dice: Dice) -> void:
	_animating_dice = dice
	_is_animating = true
	_anim_accumulator = 0.0


func _process(delta: float) -> void:
	if not _is_animating:
		return
	var remaining := GameManager.roll_timer.time_left
	var interval := remap(remaining, GameManager.roll_timer.wait_time, 0.0, 0.05, 0.3)  # fast → slow
	_anim_accumulator += delta
	if _anim_accumulator >= interval:
		_anim_accumulator -= interval
		var random_face: int = randi_range(1, _animating_dice.sides)
		set_result_text(random_face, _animating_dice.sides)


func _on_roll_completed(result: RollResult, _total: int) -> void:
	_is_animating = false
	set_result_text(result.final_value, result.dice.sides)

func _on_roll_timer_timeout() -> void:
	text = ""


func set_result_text(final_value: int, sides: int) -> void:
	var result_text: String = ""
	if !final_value:
		result_text = "0_ON_D%d" % sides
	else:
		result_text = "%d_ON_D%d" % [final_value, sides]
	text = result_text
