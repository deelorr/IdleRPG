extends Node

@onready var sun_light := $DirectionalLight2D
@onready var sky_tint := $CanvasLayer/ColorRect
@onready var world_env := $WorldEnvironment
@onready var clock_label := $CanvasLayer/Control/MarginContainer/Buttons/ClockPanel/ClockLabel
@onready var speed_label := $CanvasLayer/Control/MarginContainer/Buttons/SpeedButton
@onready var city_wood := $CanvasLayer/Control/MarginContainer/Buttons/CityPanel/CityStats/CityWood
@onready var city_food := $CanvasLayer/Control/MarginContainer/Buttons/CityPanel/CityStats/CityFood

func _ready():
	# Connect the time update signal
	TimeManager.time_updated.connect(_on_time_changed)
	# Force an initial update when the game starts
	_on_time_changed(int(TimeManager.time_of_day * TimeManager.HOURS_IN_DAY), 0, TimeManager.day_count)

func _process(_delta: float) -> void:
	city_food.text = "Total Food: " + str(Global.total_city_food)
	city_wood.text = "Total Wood: " + str(Global.total_city_wood)

func _on_time_changed(in_game_hours: int, in_game_minutes: int, new_day: int) -> void:
	# Update the UI clock
	clock_label.text = "Day %d, %02d:%02d" % [new_day, in_game_hours, in_game_minutes]
	# Update lighting
	update_lighting(in_game_hours)

func update_lighting(in_game_hours: int):
	# Time ranges for transitions
	var sunrise_start = 5.0
	var sunrise_end = 8.0
	var sunset_start = 18.0
	var sunset_end = 21.0

	# Light intensities
	var day_brightness = 1.2
	var night_brightness = 0.4

	if in_game_hours >= sunrise_start and in_game_hours <= sunrise_end:
		# Morning transition (dawn)
		var t = (in_game_hours - sunrise_start) / (sunrise_end - sunrise_start)
		sun_light.energy = lerp(night_brightness, day_brightness, t)
		world_env.environment.ambient_light_energy = lerp(0.3, 1.0, t)
		sky_tint.color = Color(0.1, 0.1, 0.3, 0.6).lerp(Color(0.2, 0.6, 1.0, 0.3), t)

	elif in_game_hours >= sunset_start and in_game_hours <= sunset_end:
		# Evening transition (dusk)
		var t = (in_game_hours - sunset_start) / (sunset_end - sunset_start)
		sun_light.energy = lerp(day_brightness, night_brightness, t)
		world_env.environment.ambient_light_energy = lerp(1.0, 0.3, t)
		sky_tint.color = Color(0.2, 0.6, 1.0, 0.3).lerp(Color(0.1, 0.1, 0.3, 0.6), t)

	else:
		# Set brightness directly outside transition times
		if in_game_hours < sunrise_start or in_game_hours > sunset_end:
			# Night settings
			sun_light.energy = night_brightness
			world_env.environment.ambient_light_energy = 0.3
			sky_tint.color = Color(0.1, 0.1, 0.3, 0.6)
		else:
			# Day settings
			sun_light.energy = day_brightness
			world_env.environment.ambient_light_energy = 1.0
			sky_tint.color = Color(0.2, 0.6, 1.0, 0.3)

	# Update sun position to reflect the time of day
	sun_light.rotation_degrees = lerp(-90, 90, TimeManager.time_of_day)

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

func _on_speed_button_pressed() -> void:
	if TimeManager.time_speed_multiplier == 1.0:
		TimeManager.time_speed_multiplier = 2.0
		speed_label.text = "Speed: x2"
	else:
		TimeManager.time_speed_multiplier = 1.0
		speed_label.text = "Speed: x1"

func _on_skip_hour_pressed() -> void:
	TimeManager.skip_hours(1)

func _on_save_pressed():
	SaveManager.save_game(TimeManager.day_count, TimeManager.time_of_day)
	print("SAVED GAME AT DAY ", TimeManager.day_count, TimeManager.time_of_day)
