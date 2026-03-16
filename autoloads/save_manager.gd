extends Node


func save_game() -> void:
	var save_data: Dictionary = {
		"game_state": GameManager.game_state.to_dict()
	}
	var save_json: String = JSON.stringify(save_data)
	var save_path: String = "user://save_game.json"
	var file: FileAccess = FileAccess.open(save_path, FileAccess.WRITE)
	if file == null:
		push_error("SaveManager: Failed to open save file for writing: %s" % save_path)
		return
	file.store_string(save_json)
	file.close()
	print("Game saved successfully to %s" % save_path)


func load_game() -> void:
	var save_path: String = "user://save_game.json"
	if not has_save():
		push_warning("SaveManager: No save file found at %s" % save_path)
		return
	var file: FileAccess = FileAccess.open(save_path, FileAccess.READ)
	if file == null:
		push_error("SaveManager: Failed to open save file for reading: %s" % save_path)
		return
	var save_json: String = file.get_as_text()
	file.close()
	var json: JSON = JSON.new()
	var error: int = json.parse(save_json)
	if error != OK:
		push_error("SaveManager: Failed to parse save file JSON: %s" % json.get_error_message())
		return
	var save_data: Dictionary = json.get_data()
	if not save_data.has("game_state"):
		push_error("SaveManager: Save data missing 'game_state' key")
		return
	var game_state_dict: Dictionary = save_data["game_state"]
	var loaded_game_state: GameState = GameState.from_dict(game_state_dict)
	GameManager.load_game_state(loaded_game_state)
	print("Game loaded successfully from %s" % save_path)


func has_save() -> bool:
	var save_path: String = "user://save_game.json"
	return FileAccess.file_exists(save_path)


func delete_save() -> void:
	var save_path: String = "user://save_game.json"
	if FileAccess.file_exists(save_path):
		var error: int = DirAccess.remove_absolute(save_path)
		if error != OK:
			push_error("SaveManager: Failed to delete save file: %s" % save_path)
		else:
			print("Save file deleted successfully: %s" % save_path)
	else:
		push_warning("SaveManager: No save file to delete at %s" % save_path)