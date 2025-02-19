extends Node

@onready var sun_light := $DirectionalLight2D
@onready var sky_tint := $CanvasLayer/ColorRect
@onready var world_env := $WorldEnvironment
@onready var clock_label := $CanvasLayer/ClockLabel

func _ready():
	clock_label.text = "Day %d, %02d:%02d" % [TimeManager.day_count, TimeManager.in_game_hours, TimeManager.in_game_minutes]
	TimeManager.time_changed.connect(Callable (self, "_on_time_changed"))
	
func _on_time_changed(new_time: float, new_day: int) -> void:
	var in_game_hours = int(new_time * TimeManager.hours_in_day)
	var in_game_minutes = int(fmod(new_time * TimeManager.hours_in_day * 60, 60))
	var time_text = "Day %d, %02d:%02d" % [new_day, in_game_hours, in_game_minutes]
	clock_label.text = time_text
	
func _process(delta):
	# **Smooth Sunrise and Sunset**
	var sunrise_start = 5.0  # When the sun starts rising (5:00 AM)
	var sunrise_end = 8.0  # When full brightness is reached (8:00 AM)
	var sunset_start = 18.0  # When the sun starts setting (6:00 PM)
	var sunset_end = 21.0  # When it's fully dark (9:00 PM)

	var day_brightness = 1.2  # Max brightness at noon
	var night_brightness = 0.4  # Min brightness at midnight

	if TimeManager.in_game_hours >= sunrise_start and TimeManager.in_game_hours <= sunrise_end:
		var t = (TimeManager.in_game_hours - sunrise_start) / (sunrise_end - sunrise_start)
		sun_light.energy = lerp(night_brightness, day_brightness, t)
		world_env.environment.ambient_light_energy = lerp(0.3, 1.0, t)  # Adjust ambient light
		sky_tint.color = Color(0.1, 0.1, 0.3, 0.6).lerp(Color(0.2, 0.6, 1.0, 0.3), t)  # Smoothly change sky

	elif TimeManager.in_game_hours >= sunset_start and TimeManager.in_game_hours <= sunset_end:
		var t = (TimeManager.in_game_hours - sunset_start) / (sunset_end - sunset_start)
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
				TimeManager.skip_hours(1)
			KEY_D:  # Skip 1 Full Day
				TimeManager.skip_hours(24)

# ⏩ Speed Toggle Button
func _on_button_pressed() -> void:
	if TimeManager.time_speed_multiplier == 1.0:
		TimeManager.time_speed_multiplier = 2.0
		$CanvasLayer/Control/Buttons/SpeedButton.text = "Speed: x2"
	else:
		TimeManager.time_speed_multiplier = 1.0
		$CanvasLayer/Control/Buttons/SpeedButton.text = "Speed: x1"

func _on_skip_hour_pressed() -> void:
	TimeManager.skip_hours(1)

func _on_save_pressed():
	SaveSystem.save_game(TimeManager.day_count, TimeManager.time_of_day)
	print("SAVED GAME AT DAY ", TimeManager.day_count, TimeManager.time_of_day)
