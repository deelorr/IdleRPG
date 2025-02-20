extends Node

const SAVE_PATH = "user://savegame.json"

# Call this function to save the time, day, and last timestamp
func save_game(day: int, time: float):
	var save_data = {
		"day": day,
		"time": time,
		"timestamp": Time.get_unix_time_from_system()  # Store the current time
	}

	var file = FileAccess.open(SAVE_PATH, FileAccess.WRITE)
	if file:
		file.store_string(JSON.stringify(save_data))
		file.close()
		print("Game saved successfully!")
	else:
		print("Failed to save game!")


# Call this function to load the time, day, and calculate offline earnings
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
		TimeManager.day_count = save_data.get("day")
		TimeManager.time_of_day = save_data.get("time")

		# Load the last timestamp
		var last_timestamp = save_data.get("timestamp", 0)
		var current_timestamp = Time.get_unix_time_from_system()
		
		# Calculate time passed
		var time_passed = current_timestamp - last_timestamp  # Time in seconds
		print("Time passed while offline:", time_passed, "seconds")

		# Apply offline gold earnings
		apply_offline_earnings(time_passed)
		
	else:
		print("Failed to load game!")
		return null
		
func apply_offline_earnings(time_passed: int):
	var gold_per_second = 5  # Adjust based on upgrades if needed
	var offline_gold = gold_per_second * time_passed
	
	# Optional: Cap offline earnings (e.g., max 10 hours of income)
	var max_hours = 10
	var max_gold = gold_per_second * (max_hours * 3600)
	offline_gold = min(offline_gold, max_gold)

	# Apply earnings
	#GameManager.gold += offline_gold  # Make sure this matches how your game stores gold
	print("Offline earnings: +", offline_gold, " gold")
