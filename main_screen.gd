extends Node

@onready var sun_light := $DirectionalLight2D
@onready var sky_tint := $CanvasLayer/ColorRect
@onready var world_env := $WorldEnvironment
@onready var clock_label := $CanvasLayer/ClockLabel
@onready var day_label := $CanvasLayer/DayLabel  # New UI Label for day counter


func _process(delta):
	if TimeManager.time_paused:
		return  # Stop updating if time is paused

	# Adjust time based on speed multiplier (5 in-game minutes = 1 real minute)
	TimeManager.time_of_day += ((delta / (TimeManager.real_seconds_per_in_game_minute * TimeManager.hours_in_day * 60)) * TimeManager.direction) * TimeManager.time_speed_multiplier

	# Smoothly transition into the next day instead of snapping
	if TimeManager.time_of_day >= 1.0:
		TimeManager.time_of_day = 0.0  # Reset to midnight
		TimeManager.day_count += 1  # Increment day counter

	# Convert `time_of_day` to in-game hours and minutes
	var in_game_hours = int(TimeManager.time_of_day * TimeManager.hours_in_day)  # Scales time_of_day to 24-hour format
	var in_game_minutes = int(fmod(TimeManager.time_of_day * TimeManager.hours_in_day * 60, 60))  # Gets the fractional minutes

	# Only update display if a full in-game minute has passed
	if in_game_minutes != TimeManager.last_displayed_minute:
		TimeManager.last_displayed_minute = in_game_minutes  # Store the new minute

		# Format time as `Day X, HH:MM`
		var time_text = "Day %d, %02d:%02d" % [TimeManager.day_count, in_game_hours, in_game_minutes]
		clock_label.text = time_text  # Update time display
		day_label.text = "Day: %d" % TimeManager.day_count  # Update day counter

	# **Smooth Sunrise and Sunset**
	var sunrise_start = 5.0  # When the sun starts rising (5:00 AM)
	var sunrise_end = 8.0  # When full brightness is reached (8:00 AM)
	var sunset_start = 18.0  # When the sun starts setting (6:00 PM)
	var sunset_end = 21.0  # When it's fully dark (9:00 PM)

	var day_brightness = 1.2  # Max brightness at noon
	var night_brightness = 0.4  # Min brightness at midnight

	if in_game_hours >= sunrise_start and in_game_hours <= sunrise_end:
		var t = (in_game_hours - sunrise_start) / (sunrise_end - sunrise_start)
		sun_light.energy = lerp(night_brightness, day_brightness, t)
		world_env.environment.ambient_light_energy = lerp(0.3, 1.0, t)  # Adjust ambient light
		sky_tint.color = Color(0.1, 0.1, 0.3, 0.6).lerp(Color(0.2, 0.6, 1.0, 0.3), t)  # Smoothly change sky

	elif in_game_hours >= sunset_start and in_game_hours <= sunset_end:
		var t = (in_game_hours - sunset_start) / (sunset_end - sunset_start)
		sun_light.energy = lerp(day_brightness, night_brightness, t)
		world_env.environment.ambient_light_energy = lerp(1.0, 0.3, t)
		sky_tint.color = Color(0.2, 0.6, 1.0, 0.3).lerp(Color(0.1, 0.1, 0.3, 0.6), t)

	# Update light angle for realistic sun movement
	sun_light.rotation_degrees = lerp(-90, 90, TimeManager.time_of_day)

# 🔧 Debugging Functions (Only Enabled if use_debug_options = true)
func _input(event):
	if event is InputEventKey and event.pressed:
		match event.keycode:
			KEY_P:  # Pause/Resume Time
				TimeManager.time_paused = !TimeManager.time_paused
				print("Time Paused: ", TimeManager.time_paused)
			KEY_H:  # Skip 1 Hour
				skip_hours(1)
			KEY_D:  # Skip 1 Full Day
				skip_hours(24)

# 🔄 Skip Time Forward
func skip_hours(hours: int):
	TimeManager.time_of_day += float(hours) / TimeManager.hours_in_day
	if TimeManager.time_of_day >= 1.0:
		TimeManager.time_of_day -= 1.0
		TimeManager.day_count += 1  # Increment day count if skipping past midnight
	
	# Update UI immediately after skipping hours
	var in_game_hours = int(TimeManager.time_of_day * TimeManager.hours_in_day)
	var in_game_minutes = int(fmod(TimeManager.time_of_day * TimeManager.hours_in_day * 60, 60))
	TimeManager.last_displayed_minute = in_game_minutes  # Sync the last displayed minute
	
	# Format and update the clock and day labels
	var time_text = "Day %d, %02d:%02d" % [TimeManager.day_count, in_game_hours, in_game_minutes]
	clock_label.text = time_text
	day_label.text = "Day: %d" % TimeManager.day_count
	
	print("Skipped", hours, "hours. New Time:", TimeManager.time_of_day * 24, "Day:", TimeManager.day_count)

# ⏩ Speed Toggle Button
func _on_button_pressed() -> void:
	if TimeManager.time_speed_multiplier == 1.0:
		TimeManager.time_speed_multiplier = 2.0
		$CanvasLayer/Control/Buttons/SpeedButton.text = "Speed: x2"
	else:
		TimeManager.time_speed_multiplier = 1.0
		$CanvasLayer/Control/Buttons/SpeedButton.text = "Speed: x1"

func _on_skip_hour_pressed() -> void:
	skip_hours(1)

func _on_save_pressed():
	SaveSystem.save_game(TimeManager.day_count, TimeManager.time_of_day)
	print("SAVED GAME AT DAY ", TimeManager.day_count, TimeManager.time_of_day)
