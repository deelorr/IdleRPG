extends Control

# Path to your main game scene
const GAME_SCENE = "res://main_screen.tscn"

func _ready():
	# Connect buttons
	$VBoxContainer/NewGameButton.pressed.connect(_on_new_game_pressed)
	$VBoxContainer/LoadGameButton.pressed.connect(_on_load_game_pressed)
	$VBoxContainer/QuitButton.pressed.connect(_on_quit_pressed)
	
	# Disable load button if no save file exists
	if not FileAccess.file_exists("res://savegame.json"):
		$VBoxContainer/LoadGameButton.disabled = true

# Start a new game
func _on_new_game_pressed():
	# Erase any existing save file (optional, to ensure a fresh start)
	if FileAccess.file_exists("res://savegame.json"):
		DirAccess.remove_absolute("res://savegame.json")
	
	get_tree().change_scene_to_file(GAME_SCENE)

# Load saved game
func _on_load_game_pressed():
	get_tree().change_scene_to_file(GAME_SCENE)
	call_deferred("_delayed_load")  # Calls load function AFTER scene transition

func _delayed_load():
	if SaveSystem:
		SaveSystem.load_game()
	else:
		print("Error: TimeManager still not available after scene load.")

# Quit the game
func _on_quit_pressed():
	get_tree().quit()
