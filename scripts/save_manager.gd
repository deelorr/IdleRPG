extends Node

const SAVE_PATH = "user://savegame.json"

func save_game(day: int, time: float):
	var current_time = Time.get_unix_time_from_system()
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

func reset_save():
	if FileAccess.file_exists(SAVE_PATH):
		var dir = DirAccess.open("user://")
		if dir:
			var result = dir.remove(SAVE_PATH)
			if result == OK:
				print("Save file deleted successfully.")
			else:
				print("Failed to delete save file! Error code:", result)

	# Reset all relevant global variables
	Global.total_city_wood = 0
	Global.total_city_food = 0
	TimeManager.day_count = 1
	TimeManager.time_of_day = 0

	# Force a full scene reload
	await get_tree().process_frame  # Ensure the deletion completes before reloading
	get_tree().reload_current_scene()
	
	print("New game started: Save data cleared and scene reloaded.")

func load_game():
	if not FileAccess.file_exists(SAVE_PATH):
		print("No save file found!")
		return null

	var file = FileAccess.open(SAVE_PATH, FileAccess.READ)
	if file:
		# Explicitly cast to Dictionary to avoid Variant inference
		var save_data = JSON.parse_string(file.get_as_text()) as Dictionary
		file.close()
		
		if save_data == null:
			print("Failed to parse save file!")
			return null

		print("Game loaded successfully!")
		TimeManager.day_count = save_data.get("day")
		TimeManager.time_of_day = save_data.get("time")
		Global.total_city_wood = save_data.get("wood", 0)
		Global.total_city_food = save_data.get("food", 0)

		#Calculate offline time
		var last_timestamp = save_data.get("timestamp")
		var current_timestamp = Time.get_unix_time_from_system()
		var time_passed = current_timestamp - last_timestamp  #Time in seconds
		print("Time passed while offline:", time_passed, "seconds")

		apply_offline_earnings(time_passed)
	else:
		print("Failed to load game!")
		return null

func apply_offline_earnings(time_passed: int):
	var wood_per_second = 5
	var food_per_second = 5

	var offline_wood = wood_per_second * time_passed
	var offline_food = food_per_second * time_passed

	var max_hours = 5
	offline_wood = min(offline_wood, wood_per_second * (max_hours * 3600))
	offline_food = min(offline_food, food_per_second * (max_hours * 3600))

	Global.total_city_wood += offline_wood
	Global.total_city_food += offline_food

	Global.offline_wood = offline_wood
	Global.offline_food = offline_food
