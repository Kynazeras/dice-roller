# Plan: Data-Driven Dice Roller Core Architecture

**TL;DR**: Restructure the project around a JSON-configured, signal-driven architecture with four autoloads (`GameConfig`, `GameManager`, `DiceRollManager`, `SaveManager`), a central `GameState` resource, and a clean round loop. All tunable values (goals, health, shop items, dice, modifiers) live in JSON files for rapid playtesting. The existing `Dice`/`RollResult`/`RollModifier` resources get extended, and new resources (`GameState`, `RoundState`, `ShopItem`) are added. Save/load serializes `GameState` to `user://` as JSON.

---

## Step 1 — JSON Data Layer

Create a `data/` directory with four JSON config files:

- `data/game_config.json` — top-level tunables: `starting_health`, `starting_money`, `starting_dice` (array of dice IDs), `rounds` (array of objects with `goal`, `free_rerolls`), `reroll_cost_base`, `reroll_cost_scaling` (cost = base + scaling \* rerolls_bought_this_round). Rounds have no roll limit — the player's health is the risk constraint.
- `data/dice_catalog.json` — all dice definitions keyed by ID: `id`, `name`, `sides` (int for standard, or explicit `faces` array for custom), `behavior` (enum: `"standard"`, `"exploding"`, `"weighted"`), `cost`, `rarity`, `description`. Starting dice like `"d4"` and `"d6"` referenced by ID in game_config.
- `data/modifier_catalog.json` — all modifiers keyed by ID: `id`, `name`, `type` (`"numeric"` or `"conditional"`), `scope` (`"permanent"` or `"round"`), `flat_bonus`, `multiplier`, `min_value`, `max_value`, `trigger` (for conditional: `"on_max_roll"`, `"first_roll"`, `"always"`, etc.), `trigger_effect` (what happens when triggered), `cost`, `rarity`, `description`.
- `data/shop_config.json` — `items_per_shop` (how many items offered), `modifier_reward_choices` (how many modifiers to offer on exact goal), `shop_pool` (array of item refs with type `"dice"` or `"modifier"` + the catalog ID), `rarity_weights` (base weights by tier: `{"common": 60, "uncommon": 25, "rare": 12, "legendary": 3}`), and `rarity_weights_by_round` (optional overrides keyed by round index string, e.g. `"5": {"common": 40, ...}` — the highest key ≤ current round is used, falling back to base weights). Rarity on individual items in the dice/modifier catalogs is a **string tier** (`"common"`, `"uncommon"`, `"rare"`, `"legendary"`).

## Step 2 — GameConfig Autoload

New file: `autoloads/game_config.gd`

- Loads all four JSON files on `_ready()` using `FileAccess` + `JSON.parse_string()`.
- Exposes typed accessors: `get_round_config(round_index) -> Dictionary`, `get_dice_def(id) -> Dictionary`, `get_modifier_def(id) -> Dictionary`, `get_shop_pool() -> Array`, `get_game_config() -> Dictionary`.
- Validates JSON structure on load and pushes errors for missing keys.
- Registered as autoload in `project.godot`.

## Step 3 — Refactor Dice Resource

File: `components/dice.gd`

- Replace the `Type` enum with a data-driven approach: store `id: String`, `name: String`, `sides: int`, `faces: Array[int]` (empty = standard 1..sides), `behavior: String`.
- Add a static factory: `static func from_dict(data: Dictionary) -> Dice` that constructs a Dice from a JSON dictionary.
- Rework `roll() -> int` to: if `faces` is populated, pick randomly from `faces`; if `behavior == "exploding"`, reroll on max and add; otherwise standard `randi_range(1, sides)`.
- Keep `_rng` for deterministic seeding (useful for replays/testing).

## Step 4 — Extend RollModifier

File: `components/roll_modifier.gd`

- Add fields: `id: String`, `modifier_name: String`, `type: String`, `scope: String`, `trigger: String`, `min_value: int`, `max_value: int`, `description: String`.
- Add `static func from_dict(data: Dictionary) -> RollModifier`.
- Refactor `apply(result: RollResult) -> RollResult` to: check trigger condition first (e.g. `"on_max_roll"` → only apply if `result.is_max`), then apply numeric effects (multiplier → flat_bonus → clamp to min/max).
- Create concrete subclass examples in `components/modifiers/` for any behavior that can't be expressed purely through data (e.g., a `streak_modifier.gd` that checks consecutive max rolls).

## Step 5 — New Resources

### GameState

New file: `components/game_state.gd` — `class_name GameState extends Resource`

Fields: `health: int`, `max_health: int`, `money: int`, `total_rolled: int` (lifetime sum of all rolls for money tracking), `money_spent: int`, `current_round: int`, `player_dice: Array[Dice]`, `player_modifiers: Array[RollModifier]`, `round_state: RoundState`.

Methods: `get_available_money() -> int` (= total_rolled - money_spent), `apply_health_change(amount: int)`, `to_dict() -> Dictionary`, `static func from_dict(data: Dictionary) -> GameState`.

### RoundState

New file: `components/round_state.gd` — `class_name RoundState extends Resource`

Fields: `round_index: int`, `goal: int`, `rolls: Array[RollResult]`, `rolls_used: int`, `rerolls_used: int`, `free_rerolls: int`, `last_roll: RollResult`.

Methods: `get_total() -> int`, `can_reroll() -> bool`, `get_reroll_cost() -> int` (uses GameConfig's base + scaling formula). There is no roll limit — the player decides when to stop, with health as the risk constraint.

### ShopItem

New file: `components/shop_item.gd` — `class_name ShopItem extends Resource`

Fields: `item_type: String` ("dice" or "modifier"), `item_id: String`, `cost: int`, `rarity: String`, `display_name: String`, `description: String`.

Factory: `static func from_dict(data: Dictionary) -> ShopItem`.

## Step 6 — Refactor DiceRollManager

File: `autoloads/dice_roll_manager.gd`

- Keep as the roll pipeline autoload, but make it round-aware.
- New signals: `roll_completed(result: RollResult)` (existing), `reroll_completed(old_result: RollResult, new_result: RollResult)`, `round_total_changed(new_total: int)`.
- `roll(dice: Dice, round_state: RoundState) -> RollResult` — creates result, applies all `GameState.player_modifiers` (checking scope/trigger), updates `round_state` (appends to rolls, increments rolls_used, sets last_roll), adds `result.final_value` to `GameState.total_rolled`, emits signals.
- `reroll_last(dice: Dice, round_state: RoundState) -> RollResult` — removes last roll from round_state, rolls fresh, deducts reroll cost from money if not free, increments rerolls_used, emits `reroll_completed`.
- Remove `history` and `get_history_sum()` — this responsibility moves to `GameState` and `RoundState`.
- Remove `player_dice` and `modifiers` arrays — these move to `GameState`.

## Step 7 — GameManager Autoload

New file: `autoloads/game_manager.gd`

This is the **core game loop orchestrator**. Holds the authoritative `GameState` instance.

**Signals**: `round_started(round_index: int, goal: int)`, `round_ended(round_index: int, result: String)` (result = "exact", "under", "over"), `health_changed(new_health: int, change: int)`, `money_changed(new_money: int)`, `game_over(won: bool)`, `shop_opened(items: Array[ShopItem])`, `modifier_reward_offered(modifiers: Array[RollModifier])`.

**State enum**: `IDLE`, `ROUND_ACTIVE`, `ROUND_RESULT`, `SHOP`, `MODIFIER_REWARD`, `GAME_OVER`.

**Methods**:

- `start_new_game()` — initializes `GameState` from `GameConfig` (starting health, money=0, starting dice, round 0), emits `round_started`.
- `start_round(index: int)` — creates a fresh `RoundState` from `GameConfig.get_round_config(index)`, sets state to `ROUND_ACTIVE`.
- `player_roll(dice: Dice)` — delegates to `DiceRollManager.roll()`, then checks: over goal → end round "over"; exact goal → end round "exact". Otherwise continues (no roll limit — player chooses when to stop).
- `player_reroll()` — delegates to `DiceRollManager.reroll_last()`, same checks after.
- `player_stop()` — ends round "under".
- `end_round(result: String)` — calculates health change based on result type and the formulas from the spec; applies to `GameState`; emits `round_ended` + `health_changed`; if exact → transition to `MODIFIER_REWARD`; else → check if player dead → `GAME_OVER` or transition to `SHOP`.
- `select_modifier_reward(modifier: RollModifier)` — adds to player_modifiers, transitions to `SHOP`.
- `open_shop()` — selects `items_per_shop` items via weighted rarity selection (see Rarity Selection Algorithm below), emits `shop_opened`.
- `buy_item(item: ShopItem) -> bool` — checks affordability, deducts cost, adds dice/modifier to GameState, emits `money_changed`.
- `close_shop()` — advances to next round or game over if final round beaten.
- `load_game(save_data: Dictionary)` — restores GameState, resumes at appropriate state.

### Rarity Selection Algorithm

Used by both `open_shop()` and `modifier_reward_offered`:

1. **Determine active weights** — find the highest `rarity_weights_by_round` key ≤ `GameState.current_round`. Fall back to base `rarity_weights` if none match.
2. **Weighted random pick of a rarity tier** — sum all weights (e.g. 60+25+12+3 = 100), roll a random number 0–(sum-1), walk the tiers until cumulative weight exceeds the roll. This yields a rarity string like `"rare"`.
3. **Filter the pool** — from `shop_pool` (for shops) or `modifier_catalog` (for rewards), collect all items matching that rarity.
4. **Pick randomly within the tier** — uniform random from the filtered list.
5. **Repeat without replacement** — for `items_per_shop` or `modifier_reward_choices` times, removing picked items so no duplicates appear in one offering.
6. **Fallback** — if a selected rarity tier has no remaining items, re-roll the tier.

## Step 8 — SaveManager Autoload

New file: `autoloads/save_manager.gd`

- `save_game()` — serializes `GameManager.game_state.to_dict()` + current game manager state to `user://save.json` via `FileAccess` + `JSON.stringify()`.
- `load_game() -> Dictionary` — reads and parses `user://save.json`, returns the dictionary (GameManager handles restoration).
- `has_save() -> bool` — checks if save file exists.
- `delete_save()` — removes save file (on game completion or player request).
- Registered as autoload in `project.godot`.

## Step 9 — Refactor main.gd

File: `scripts/main.gd`

- Strip out game logic (health calc, win/loss). `main.gd` becomes a **pure UI controller**.
- Connect to `GameManager` signals: `round_started`, `round_ended`, `health_changed`, `money_changed`, `game_over`, `shop_opened`, `modifier_reward_offered`.
- `_ready()` → create dice buttons only for `GameState.player_dice` (not all dice types). Add a "Stop" button and a "Reroll" button with dynamic cost label.
- Signal handlers update labels, progress bar, enable/disable buttons based on game state.
- Delegate all actions to `GameManager`: roll → `GameManager.player_roll(dice)`, reroll → `GameManager.player_reroll()`, stop → `GameManager.player_stop()`.

## Step 10 — Refactor DiceButton

File: `scripts/dice_button.gd`

- Emit a signal `dice_selected(dice: Dice)` instead of calling `DiceRollManager` directly.
- `main.gd` connects this signal and delegates to `GameManager.player_roll(dice)`.
- Button enabled/disabled state driven by `GameManager.state == ROUND_ACTIVE`.

## Step 11 — Shop UI

New scene: `scenes/shop.tscn` + `scripts/shop.gd`

- A panel/popup that displays offered `ShopItem`s with name, description, cost, and a "Buy" button.
- Shows player's current money.
- Connects to `GameManager.shop_opened` to populate items.
- Buy button calls `GameManager.buy_item(item)`, updates UI on success/failure.
- "Continue" button calls `GameManager.close_shop()`.
- Healing items are just shop items with `item_type = "healing"` and a `heal_amount` field in the modifier catalog.

## Step 12 — Modifier Reward UI

New scene or integrated into main.

- When player hits exact goal, `GameManager` emits `modifier_reward_offered` with 2-3 random modifiers.
- UI shows a pick-one-of-N panel. Player selects, calls `GameManager.select_modifier_reward(modifier)`.

## Step 13 — Update Scene Tree

File: `scenes/main.tscn`

- Add UI elements: health bar/label, money label, round counter label, "Stop Round" button, "Reroll" button with cost display.
- Remove the 6 static DiceButton children (they're unused anyway — recreated in code).
- Add `ShopPanel` as a hidden child that toggles visibility on shop signals.
- Add `ModifierRewardPanel` similarly.

## Step 14 — Register New Autoloads

File: `project.godot`

Add to the autoload section (load order matters):

1. `GameConfig` — first, since others depend on data
2. `DiceRollManager` — already exists
3. `GameManager` — depends on GameConfig and DiceRollManager
4. `SaveManager` — depends on GameManager

---

## Verification

- **Unit-test round outcomes**: Manually set `RoundState` totals and call `end_round()` with each result type ("exact", "under", "over"). Verify health changes match the formulas:
  - Under: `-(goal - total)`
  - Over: `-(goal - 2 * total)` (note: this is negative since total > goal, so the absolute penalty = `2 * total - goal`)
  - Exact: `0`
- **JSON tuning loop**: Edit `data/game_config.json` to change round 1 goal from e.g. 10 to 5. Run the game, confirm the goal label shows 5.
- **Shop flow**: Play to round end, confirm shop appears with the correct number of random items. Buy a die, confirm it appears in the dice button bar next round.
- **Reroll**: During a round, roll once, press reroll, confirm last roll is replaced and total updates. Confirm second reroll shows a cost and deducts money.
- **Save/load**: Mid-round, trigger save (via debug key or UI). Quit and relaunch. Load save, confirm round/health/money/dice inventory are restored.
- **Custom dice**: Add a `"d3"` entry in `dice_catalog.json` with `"faces": [1, 2, 3]`. Add it to the shop pool. Buy it, roll it, confirm values are always 1-3.
- **Modifier flow**: Hit an exact goal, confirm modifier reward panel appears. Pick a modifier, confirm it applies to subsequent rolls.

---

## Decisions

- **JSON over .tres** for all game data — enables hand-editing and version-control-friendly diffs for rapid playtesting.
- **GameManager as orchestrator** — `main.gd` becomes a pure view; all game logic flows through `GameManager` signals so any UI can react without coupling.
- **Reroll replaces last roll only** — simpler UX, no picker UI needed.
- **Money = lifetime roll total minus spending** — tracked via `total_rolled` and `money_spent` on `GameState`, not recomputed from history.
- **Dice refactored from enum to data-driven** — breaking change to `Dice.Type`, but necessary for custom dice support. All existing `Dice.Type` references in `scripts/main.gd` and `scripts/dice_button.gd` will be replaced with ID-based lookup.
- **Four autoloads** with clear separation: config loading → roll mechanics → game flow → persistence.
