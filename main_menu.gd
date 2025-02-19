extends Control

@onready var load_game_button = $VBoxContainer/LoadGameButton

const GAME_SCENE = "res://main_screen.tscn"

func _ready():
	# Disable load button if no save file exists
	if not FileAccess.file_exists("user://savegame.json"):
		load_game_button.disabled = true

# Start a new game
func _on_new_game_button_pressed():
	# Erase any existing save file (optional, to ensure a fresh start)
	if FileAccess.file_exists("user://savegame.json"):
		DirAccess.remove_absolute("user://savegame.json")
	get_tree().change_scene_to_file(GAME_SCENE)

# Load saved game
func _on_load_game_button_pressed():
	get_tree().change_scene_to_file(GAME_SCENE)
	SaveSystem.load_game()

# Quit the game
func _on_quit_button_pressed():
	get_tree().quit()
