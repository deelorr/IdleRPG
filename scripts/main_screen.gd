extends Node

const SAVE_PATH = "user://savegame.json"

@onready var sun_light := $DirectionalLight2D
@onready var sky_tint := $CanvasLayer/ColorRect
@onready var world_env := $WorldEnvironment
@onready var clock_label := $CanvasLayer/Control/MenuContainer/HBoxContainer/VBoxContainer2/ClockPanel/ClockLabel
@onready var menu := $CanvasLayer/Control/MenuContainer/HBoxContainer/VBoxContainer2/Menu/MenuPanel
@onready var speed_button := $CanvasLayer/Control/MenuContainer/HBoxContainer/VBoxContainer2/Menu/MenuPanel/VBoxContainer/SpeedButton

# Nodes for the offline popup
@onready var offline_food_label := $CanvasLayer/Control/OfflinePopupPanel/VBoxContainer/OfflineFoodLabel
@onready var offline_wood_label := $CanvasLayer/Control/OfflinePopupPanel/VBoxContainer/OfflineWoodLabel
@onready var offline_popup_panel := $CanvasLayer/Control/OfflinePopupPanel

func _ready():
	# Connect the time update signal
	TimeManager.time_updated.connect(_on_time_changed)
	# Force an initial update when the game starts
	_on_time_changed(int(TimeManager.time_of_day * TimeManager.HOURS_IN_DAY), 0, TimeManager.day_count)
	
	# Check for a save file. If one exists, load it and then show the offline earnings popup if there are earnings.
	if FileAccess.file_exists(SAVE_PATH):
		SaveManager.load_game()  # This should update Global.offline_wood and Global.offline_food
		# Only show the popup if offline earnings were earned (you can adjust the condition as needed)
		if Global.offline_wood > 0 or Global.offline_food > 0:
			show_offline_earnings_popup()

func show_offline_earnings_popup():
	# Update the labels with the offline earnings
	offline_wood_label.text = "Wood Earned: " + str(Global.offline_wood)
	offline_food_label.text = "Food Earned: " + str(Global.offline_food)
	# Show the popup in the center of the screen
	offline_popup_panel.popup_centered()

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

func _on_skip_hour_pressed() -> void:
	TimeManager.skip_hours(1)

func _on_save_pressed():
	SaveManager.save_game(TimeManager.day_count, TimeManager.time_of_day)
	print("SAVED GAME AT DAY ", TimeManager.day_count, TimeManager.time_of_day)
	
func toggle_menu():
	if menu.visible:
		hide_menu()
	else:
		show_menu()

func show_menu():
	menu.visible = true
	menu.scale = Vector2(0, 0)
	var tween = get_tree().create_tween()
	tween.tween_property(menu, "scale", Vector2(1, 1), 0.3).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)

func hide_menu():
	var tween = get_tree().create_tween()
	tween.tween_property(menu, "scale", Vector2(0, 0), 0.2).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_IN)
	await tween.finished
	menu.visible = false

func _on_save_button_pressed() -> void:
	SaveManager.save_game(TimeManager.day_count, TimeManager.time_of_day)

func _on_speed_button_pressed() -> void:
	if TimeManager.time_speed_multiplier == 1.0:
		TimeManager.speed_up_time(2)
		speed_button.text = "Speed x2"
	else:
		TimeManager.speed_up_time(1)
		speed_button.text = "Speed x1"

func _on_skip_button_pressed():
	TimeManager.skip_hours(1)

func _on_menu_pressed():
	toggle_menu()
