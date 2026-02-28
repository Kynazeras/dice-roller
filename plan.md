Plan: DiceRollManager Autoload Architecture
With multiple UI panels, cross-scene mechanics, persistent dice, stat tracking, and modifier support all in scope, the current pattern of main.gd creating a throwaway Dice per press and manually wiring everything becomes unscalable fast. The solution is a central autoload that owns the roll pipeline and broadcasts results via signals.

Steps

Create components/roll_result.gd — a lightweight Resource data class with fields: dice: Dice, raw_value: int, final_value: int, is_max: bool, and timestamp: float. This becomes the single contract all systems receive instead of raw ints.

Create components/roll_modifier.gd — a base Resource class with a single overridable method apply(result: RollResult) -> RollResult. Subclass this for bonuses, curses, streak multipliers, etc. Keeps modifiers composable and data-driven.

Create autoloads/dice_roll_manager.gd — the autoload. Responsibilities:

Owns player_dice: Array[Dice] — the persistent set the player manages
Owns modifiers: Array[RollModifier] — applied in order on every roll
Owns history: Array[RollResult] — drives combos/streaks/reroll budget
Exposes roll(dice: Dice) -> RollResult — runs the pipeline and emits
Emits signal roll_completed(result: RollResult) — the single broadcast all systems hook into
Helper get_streak() -> int, get_history_sum() -> int, etc. for mechanic queries
Register the autoload in project.godot as DiceRollManager.

Update dice_button.gd — change @export var dice_type to @export var dice: Dice. On press, call DiceRollManager.roll(dice) directly instead of emitting roll_requested. This makes the button own a reference to a real persistent dice object.

Simplify main.gd — remove _on_roll_requested, _handle_roll_result, and all inline Dice creation. Connect to DiceRollManager.roll_completed and update UI from the RollResult fields. Game state logic (current_total, goal comparisons) stays here — main is still the scene authority, just no longer the roll authority.

Update roll_history_container.gd — connect to DiceRollManager.roll_completed in _ready() instead of being called imperatively by main. This decouples it completely and lets it work identically in any future scene.

Verification

Roll a die → DiceRollManager.roll_completed fires, total updates, history entry appears, without main.gd touching Dice directly
Add a test modifier (e.g. +2 bonus) → final_value differs from raw_value and all UI reads final_value
Confirm history persists if you add a second scene and switch back
Decisions

RollResult as a Resource over a plain Dictionary — typed, serializable, and subclass-friendly for future save data
Modifier pipeline on the manager, not on Dice itself — keeps Dice a pure data/RNG object; upgrades and curses are game-layer concerns, not dice-layer ones
DiceButton holds a Dice reference (not just a type) — necessary for persistent dice with individual stats/upgrades; the scene editor can assign them as exported Resources
Claude Sonnet 4.6 • 1x