extends Node

const SAVE_PATH = "user://savegame.json"

# Save game state: day, time, wood, food, and the timestamp
func save_game(day: int, time: float):
	var current_time = Time.get_unix_time_from_system()  # Get the current time
	# Save the current totals of wood and food along with other state data
	var save_data = {
		"day": day,
		"time": time,
		"timestamp": current_time,
		"wood": Global.total_city_wood,
		"food": Global.total_city_food
	}

	var file = FileAccess.open(SAVE_PATH, FileAccess.WRITE)
	if file:
		file.store_string(JSON.stringify(save_data))
		file.close()
		print("Game saved successfully!", "Day:", day, "Time:", time, "Timestamp:", current_time, "Wood:", Global.total_city_wood, "Food:", Global.total_city_food)
	else:
		print("Failed to save game!")

# Load game state and apply offline earnings for gold, wood, and food
func load_game():
	if not FileAccess.file_exists(SAVE_PATH):
		print("No save file found!")
		return null  # No save file

	var file = FileAccess.open(SAVE_PATH, FileAccess.READ)
	if file:
		var save_data = JSON.parse_string(file.get_as_text())
		file.close()
		
		if save_data == null:
			print("Failed to parse save file!")
			return null

		print("Game loaded successfully!")
		# Restore day and time
		TimeManager.day_count = save_data.get("day")
		TimeManager.time_of_day = save_data.get("time")
		# Restore saved wood and food totals
		Global.total_city_wood = save_data.get("wood", 0)
		Global.total_city_food = save_data.get("food", 0)

		# Calculate offline time
		var last_timestamp = save_data.get("timestamp")
		var current_timestamp = Time.get_unix_time_from_system()
		var time_passed = current_timestamp - last_timestamp  # Time in seconds
		print("Time passed while offline:", time_passed, "seconds")

		apply_offline_earnings(time_passed)
	else:
		print("Failed to load game!")
		return null

# Apply offline earnings to gold, wood, and food based on offline time
func apply_offline_earnings(time_passed: int):
	# Define production rates per second for each resource
	var wood_per_second = 5  
	var food_per_second = 5  

	# Calculate offline earnings
	var offline_wood = wood_per_second * time_passed
	var offline_food = food_per_second * time_passed
	
	# Optional: Cap offline earnings (e.g., maximum income for 10 hours)
	var max_hours = 5
	offline_wood = min(offline_wood, wood_per_second * (max_hours * 3600))
	offline_food = min(offline_food, food_per_second * (max_hours * 3600))

	# Add the offline earnings to the current totals
	Global.total_city_wood += offline_wood
	Global.total_city_food += offline_food

	print("Offline earnings applied: +", offline_wood, "wood, and", offline_food, "food")
