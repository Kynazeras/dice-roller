class_name GameState
extends Resource


@export var total_rolled: int = 0
@export var money_spent: int = 0
@export var current_round: int = 0
@export var round_state: RoundState


static func from_dict(dict: Dictionary) -> GameState:
	var state := GameState.new()
	state.total_rolled = dict.get("total_rolled", 0)
	state.money_spent = dict.get("money_spent", 0)
	state.current_round = dict.get("current_round", 0)

	# Load round state
	if dict.has("round_state"):
		state.round_state = RoundState.from_dict(dict["round_state"])
	else:
		state.round_state = RoundState.new()

	return state