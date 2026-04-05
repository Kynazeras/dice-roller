extends Node

const SCENE_DIRECTORY: String = "res://scenes/"

var available_scenes: Array = []


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	available_scenes = get_scenes_from_directory()
	GameManager.game_over.connect(_on_game_over)


func get_current_scene() -> String:
	var current_scene: Node = get_tree().current_scene
	if current_scene:
		print("current scene: %s" % current_scene.name)
		return current_scene.name
	return ""


func change_scene(scene_name: String) -> void:
	if scene_name in available_scenes:
		get_tree().change_scene_to_file(scene_name)
	else:
		push_error("SceneManager: Scene '%s' not found in available scenes" % scene_name)


func get_scenes_from_directory() -> Array:
	var scenes = []
	var dir = DirAccess.open(SCENE_DIRECTORY)
	if dir:
		dir.list_dir_begin()
		var file_name = dir.get_next()
		while file_name != "":
			if file_name.ends_with(".tscn"):
				scenes.append(SCENE_DIRECTORY + file_name)
			file_name = dir.get_next()
		dir.list_dir_end()
	return scenes


func _on_game_over(_win: bool) -> void:
	get_tree().change_scene_to_file("res://scenes/game_over_ui.tscn")