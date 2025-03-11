extends Node

# Constants with typing
const SAVE_PATH: String = "user://savegame.json"

# Typed node references
@onready var sun_light: DirectionalLight2D = $DirectionalLight2D
@onready var sky_tint: ColorRect = $TilemapLayers/ColorRect
@onready var world_env: WorldEnvironment = $WorldEnvironment
@onready var clock_label: Label = $UI/Control/MenuContainer/HBoxContainer/VBoxContainer2/ClockPanel/ClockLabel
@onready var offline_food_label: Label = $UI/Control/OfflinePopupPanel/VBoxContainer/OfflineFoodLabel
@onready var offline_wood_label: Label = $UI/Control/OfflinePopupPanel/VBoxContainer/OfflineWoodLabel
@onready var offline_popup_panel: PopupPanel = $UI/Control/OfflinePopupPanel

# Exported variables for editor tweaking
@export var day_brightness: float = 1.2
@export var night_brightness: float = 0.4

func _ready() -> void:
	# Connect signals with validation
	assert(TimeManager.time_updated, "TimeManager.time_updated signal not found!")
	TimeManager.time_updated.connect(_on_time_changed)
	_on_time_changed(int(TimeManager.time_of_day * TimeManager.HOURS_IN_DAY), 0, TimeManager.day_count)
	
	if FileAccess.file_exists(SAVE_PATH):
		SaveManager.load_game()
		if Global.offline_wood > 0 or Global.offline_food > 0:
			show_offline_earnings_popup()

func show_offline_earnings_popup() -> void:
	offline_wood_label.text = "Wood Earned: %d" % Global.offline_wood
	offline_food_label.text = "Food Earned: %d" % Global.offline_food
	offline_popup_panel.popup_centered()

func _on_time_changed(in_game_hours: int, in_game_minutes: int, new_day: int) -> void:
	clock_label.text = "Day %d, %02d:%02d" % [new_day, in_game_hours, in_game_minutes]
	update_lighting(in_game_hours)

func update_lighting(in_game_hours: int) -> void:
	const SUNRISE_START: float = 5.0
	const SUNRISE_END: float = 8.0
	const SUNSET_START: float = 18.0
	const SUNSET_END: float = 21.0
	
	var t: float
	if in_game_hours >= SUNRISE_START and in_game_hours <= SUNRISE_END:
		t = (in_game_hours - SUNRISE_START) / (SUNRISE_END - SUNRISE_START)
		sun_light.energy = lerp(night_brightness, day_brightness, t)
		world_env.environment.ambient_light_energy = lerp(0.3, 1.0, t)
		sky_tint.color = Color(0.1, 0.1, 0.3, 0.6).lerp(Color(0.2, 0.6, 1.0, 0.3), t)
	elif in_game_hours >= SUNSET_START and in_game_hours <= SUNSET_END:
		t = (in_game_hours - SUNSET_START) / (SUNSET_END - SUNSET_START)
		sun_light.energy = lerp(day_brightness, night_brightness, t)
		world_env.environment.ambient_light_energy = lerp(1.0, 0.3, t)
		sky_tint.color = Color(0.2, 0.6, 1.0, 0.3).lerp(Color(0.1, 0.1, 0.3, 0.6), t)
	else:
		sun_light.energy = night_brightness if (in_game_hours < SUNRISE_START or in_game_hours > SUNSET_END) else day_brightness
		world_env.environment.ambient_light_energy = 0.3 if (in_game_hours < SUNRISE_START or in_game_hours > SUNSET_END) else 1.0
		sky_tint.color = Color(0.1, 0.1, 0.3, 0.6) if (in_game_hours < SUNRISE_START or in_game_hours > SUNSET_END) else Color(0.2, 0.6, 1.0, 0.3)
	
	sun_light.rotation_degrees = lerp(-90.0, 90.0, TimeManager.time_of_day)

func _input(event: InputEvent) -> void:
	if event is InputEventKey and event.is_pressed():
		match event.keycode:
			KEY_P:
				TimeManager.time_paused = !TimeManager.time_paused
				print("Time Paused: %s" % TimeManager.time_paused)
			KEY_H:
				TimeManager.skip_hours(1)
			KEY_D:
				TimeManager.skip_hours(24)
