class_name GameConfig
extends Node

## Autoload that loads and exposes all JSON game data.
## Registered as "GameConfig" in project.godot.

const DATA_DIR := "res://data/"

var _game_config: Dictionary = {}
var _dice_catalog: Dictionary = {}
var _modifier_catalog: Dictionary = {}
var _shop_config: Dictionary = {}


func _ready() -> void:
	_game_config = _load_json("game_config.json")
	_dice_catalog = _load_json("dice_catalog.json")
	_modifier_catalog = _load_json("modifier_catalog.json")
	_shop_config = _load_json("shop_config.json")

	_validate_game_config()
	_validate_dice_catalog()
	_validate_modifier_catalog()
	_validate_shop_config()


# ── Top-level game config ──────────────────────────────────────────

func get_starting_health() -> int:
	return _game_config.get("starting_health", 100)


func get_starting_money() -> int:
	return _game_config.get("starting_money", 5)


func get_starting_dice_ids() -> Array:
	return _game_config.get("starting_dice", [])


func get_total_rounds() -> int:
	var rounds: Array = _game_config.get("rounds", [])
	return rounds.size()


func get_max_rolls_per_round() -> int:
	return _game_config.get("max_rolls_per_round", 7)

func get_reroll_cost_base() -> int:
	return _game_config.get("reroll_cost_base", 5)


func get_roll_animation_time() -> float:
	return _game_config.get("roll_animation_time", 2.0)


func get_reroll_cost_scaling() -> int:
	return _game_config.get("reroll_cost_scaling", 3)


func get_reroll_cost(rerolls_bought: int) -> int:
	return get_reroll_cost_base() + get_reroll_cost_scaling() * rerolls_bought


# ── Round config ───────────────────────────────────────────────────

func get_round_config(round_index: int) -> Dictionary:
	var rounds: Array = _game_config.get("rounds", [])
	if round_index < 0 or round_index >= rounds.size():
		push_error("GameConfig: Round index %d out of range (0-%d)" % [round_index, rounds.size() - 1])
		return {}
	return rounds[round_index]


func get_round_goal(round_index: int) -> int:
	return get_round_config(round_index).get("goal", 10)


func get_round_free_rerolls(round_index: int) -> int:
	return get_round_config(round_index).get("free_rerolls", 1)


# ── Dice catalog ───────────────────────────────────────────────────

func get_dice_def(dice_id: String) -> Dictionary:
	if not _dice_catalog.has(dice_id):
		push_error("GameConfig: Unknown dice ID '%s'" % dice_id)
		return {}
	return _dice_catalog[dice_id]


func get_all_dice_ids() -> Array:
	return _dice_catalog.keys()


func get_dice_by_rarity(rarity: String) -> Array:
	var results: Array = []
	for dice_id in _dice_catalog:
		var def: Dictionary = _dice_catalog[dice_id]
		if def.get("rarity", "") == rarity:
			results.append(def)
	return results


# ── Modifier catalog ──────────────────────────────────────────────

func get_modifier_def(modifier_id: String) -> Dictionary:
	if not _modifier_catalog.has(modifier_id):
		push_error("GameConfig: Unknown modifier ID '%s'" % modifier_id)
		return {}
	return _modifier_catalog[modifier_id]


func get_all_modifier_ids() -> Array:
	return _modifier_catalog.keys()


func get_modifiers_by_rarity(rarity: String) -> Array:
	var results: Array = []
	for mod_id in _modifier_catalog:
		var def: Dictionary = _modifier_catalog[mod_id]
		if def.get("rarity", "") == rarity:
			results.append(def)
	return results


# ── Shop config ───────────────────────────────────────────────────

func get_items_per_shop() -> int:
	return _shop_config.get("items_per_shop", 4)


func get_modifier_reward_choices() -> int:
	return _shop_config.get("modifier_reward_choices", 3)


func get_shop_pool() -> Array:
	return _shop_config.get("shop_pool", [])


func get_rarity_weights(round_index: int) -> Dictionary:
	var base_weights: Dictionary = _shop_config.get("rarity_weights", {
		"common": 60, "uncommon": 25, "rare": 12, "legendary": 3
	})

	var by_round: Dictionary = _shop_config.get("rarity_weights_by_round", {})
	var active_weights: Dictionary = base_weights

	# Find the highest round threshold that is <= current round
	var best_threshold := -1
	for key in by_round:
		var threshold := int(key)
		if threshold <= round_index and threshold > best_threshold:
			best_threshold = threshold
			active_weights = by_round[key]

	return active_weights


## Picks a random rarity string based on the given weights dictionary.
func _pick_rarity(weights: Dictionary) -> String:
	var total := 0
	for r in weights:
		total += int(weights[r])
	if total <= 0:
		return weights.keys()[0] if not weights.is_empty() else "common"
	var roll := randi() % total
	var cumulative := 0
	for r in weights:
		cumulative += int(weights[r])
		if roll < cumulative:
			return r
	return weights.keys().back()


## Generates shop items (dice + modifiers) for a given round using rarity weights.
func get_shop_items_for_round(round_index: int) -> Array[ShopItem]:
	var count: int = get_items_per_shop()
	var weights: Dictionary = get_rarity_weights(round_index)
	var items: Array[ShopItem] = []

	for i in count:
		var rarity: String = _pick_rarity(weights)
		var dice_pool: Array = get_dice_by_rarity(rarity)
		var mod_pool: Array = get_modifiers_by_rarity(rarity)
		var combined: Array = []
		for d in dice_pool:
			combined.append({"source": "dice", "def": d})
		for m in mod_pool:
			combined.append({"source": "modifier", "def": m})

		if combined.is_empty():
			continue

		var pick: Dictionary = combined[randi() % combined.size()]
		var item := ShopItem.new()
		item.rarity = rarity
		if pick["source"] == "dice":
			var def: Dictionary = pick["def"]
			item.item_type = "dice"
			item.item_id = def.get("id", "")
			item.cost = def.get("cost", 0)
			item.display_name = def.get("name", "")
			item.description = "A %s die with %d sides" % [rarity, def.get("sides", 0)]
		else:
			var def: Dictionary = pick["def"]
			item.item_type = "modifier"
			item.item_id = def.get("id", "")
			item.cost = def.get("cost", 0)
			item.display_name = def.get("name", "")
			item.description = def.get("description", "")

		items.append(item)

	return items


## Generates modifier reward choices for a given round using rarity weights.
## Only returns modifiers (not dice).
func get_modifier_rewards_for_round(round_index: int) -> Array[RollModifier]:
	var count: int = get_modifier_reward_choices()
	var weights: Dictionary = get_rarity_weights(round_index)
	var rewards: Array[RollModifier] = []

	for i in count:
		var rarity: String = _pick_rarity(weights)
		var pool: Array = get_modifiers_by_rarity(rarity)
		if pool.is_empty():
			# Fallback: pick any modifier from the catalog
			var all_ids: Array = get_all_modifier_ids()
			if all_ids.is_empty():
				continue
			var fallback_id: String = all_ids[randi() % all_ids.size()]
			pool = [get_modifier_def(fallback_id)]

		var def: Dictionary = pool[randi() % pool.size()]
		var modifier: RollModifier = RollModifier.from_dict(def)
		rewards.append(modifier)

	return rewards


# ── JSON loading ──────────────────────────────────────────────────

func _load_json(filename: String) -> Dictionary:
	var path := DATA_DIR + filename
	if not FileAccess.file_exists(path):
		push_error("GameConfig: File not found: %s" % path)
		return {}

	var file := FileAccess.open(path, FileAccess.READ)
	if file == null:
		push_error("GameConfig: Failed to open %s: %s" % [path, error_string(FileAccess.get_open_error())])
		return {}

	var text := file.get_as_text()
	file.close()

	var json := JSON.new()
	var error := json.parse(text)
	if error != OK:
		push_error("GameConfig: JSON parse error in %s at line %d: %s" % [path, json.get_error_line(), json.get_error_message()])
		return {}

	var data = json.get_data()
	if data is not Dictionary:
		push_error("GameConfig: Expected Dictionary as root of %s, got %s" % [path, typeof(data)])
		return {}

	return data


# ── Validation ────────────────────────────────────────────────────

func _validate_game_config() -> void:
	var required_keys := ["starting_health", "starting_dice", "rounds"]
	for key in required_keys:
		if not _game_config.has(key):
			push_warning("GameConfig: game_config.json missing key '%s', using default" % key)

	var rounds: Array = _game_config.get("rounds", [])
	for i in rounds.size():
		var round_def: Dictionary = rounds[i]
		if not round_def.has("goal"):
			push_warning("GameConfig: Round %d missing key 'goal'" % i)

	# Validate starting dice exist in catalog
	for dice_id in get_starting_dice_ids():
		if not _dice_catalog.has(dice_id):
			push_error("GameConfig: Starting dice '%s' not found in dice_catalog" % dice_id)


func _validate_dice_catalog() -> void:
	for dice_id in _dice_catalog:
		var def: Dictionary = _dice_catalog[dice_id]
		if not def.has("sides") and not def.has("faces"):
			push_error("GameConfig: Dice '%s' must have 'sides' or 'faces'" % dice_id)
		for key in ["name", "cost", "rarity"]:
			if not def.has(key):
				push_warning("GameConfig: Dice '%s' missing key '%s'" % [dice_id, key])


func _validate_modifier_catalog() -> void:
	for mod_id in _modifier_catalog:
		var def: Dictionary = _modifier_catalog[mod_id]
		for key in ["name", "type", "rarity"]:
			if not def.has(key):
				push_warning("GameConfig: Modifier '%s' missing key '%s'" % [mod_id, key])


func _validate_shop_config() -> void:
	if not _shop_config.has("rarity_weights"):
		push_warning("GameConfig: shop_config.json missing 'rarity_weights', using defaults")

	var pool: Array = _shop_config.get("shop_pool", [])
	for item in pool:
		var item_type: String = item.get("type", "")
		var item_id: String = item.get("id", "")
		if item_type == "dice" and not _dice_catalog.has(item_id):
			push_error("GameConfig: Shop pool references unknown dice '%s'" % item_id)
		elif item_type == "modifier" and not _modifier_catalog.has(item_id):
			push_error("GameConfig: Shop pool references unknown modifier '%s'" % item_id)