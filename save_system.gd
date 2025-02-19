extends Node

const SAVE_PATH = "res://savegame.json"

# Call this function to save the time and day
func save_game(day: int, time: float):
	var save_data = {
		"day": day,
		"time": time
	}

	var file = FileAccess.open(SAVE_PATH, FileAccess.WRITE)
	if file:
		file.store_string(JSON.stringify(save_data))
		file.close()
		print("Game saved successfully!")
	else:
		print("Failed to save game!")

# Call this function to load the time and day
func load_game():
	if not FileAccess.file_exists(SAVE_PATH):
		print("No save file found!")
		return null  # No save file, return nothing

	var file = FileAccess.open(SAVE_PATH, FileAccess.READ)
	if file:
		var save_data = JSON.parse_string(file.get_as_text())
		file.close()
		
		if save_data == null:
			print("Failed to parse save file!")
			return null

		print("Game loaded successfully!")
		#return save_data  # Return the loaded data as a dictionary
		TimeManager.day_count = save_data.get("day")
		TimeManager.time_of_day = save_data.get("time")
		TimeManager.update_clock()
		
	else:
		print("Failed to load game!")
		return null
	
