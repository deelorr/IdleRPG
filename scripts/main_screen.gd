extends Node

const SAVE_PATH: String = "user://savegame.json"

@onready var sun_light: DirectionalLight2D = $DirectionalLight2D
@onready var sky_tint: ColorRect = $TilemapLayers/ColorRect
@onready var world_env: WorldEnvironment = $WorldEnvironment
@onready var clock_label: Label = $UI/Overlay/Panel/ClockPanel/ClockLabel

@onready var offline_food_label: Label = $UI/Control/OfflinePopupPanel/VBoxContainer/OfflineFoodLabel
@onready var offline_wood_label: Label = $UI/Control/OfflinePopupPanel/VBoxContainer/OfflineWoodLabel
@onready var offline_popup_panel: PopupPanel = $UI/Control/OfflinePopupPanel

@export var day_brightness: float = 1.2
@export var night_brightness: float = 0.4

@onready var tree_timer: Timer = $TreeTimer
@onready var bush_timer: Timer = $BushTimer
@onready var tree_scene = preload("res://scenes/Tree.tscn")
@onready var bush_scene = preload("res://scenes/Bush.tscn")
@onready var tree_spawn_area: Polygon2D = $TheWoods
@onready var food_spawn_area: Polygon2D = $TheFoods
@export var max_trees: int = 20
@export var max_bushes: int = 20

func _ready() -> void:
	for i in 20:
		spawn_object(tree_scene, tree_spawn_area, "tree", max_trees, Vector2(2.0, 2.0))
	for i in 20:
		spawn_object(bush_scene, food_spawn_area, "bush", max_bushes, Vector2(2.0, 2.0))
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

func _on_time_changed(in_game_hours: int, in_game_minutes: int, _new_day: int) -> void:
	clock_label.text = "%02d:%02d" % [in_game_hours, in_game_minutes]
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

func _on_tree_timer_timeout():
	spawn_object(tree_scene, tree_spawn_area, "tree", max_trees, Vector2(2.0, 2.0))

func spawn_object(scene: PackedScene, spawn_area: Polygon2D, group: String, max_count: int, scale: Vector2, min_distance: float = 100.0) -> void:
	var current_count = get_tree().get_nodes_in_group(group).size()
	if current_count >= max_count:
		print("Reached max ", group, " limit: ", max_count)
		return

	var new_object = scene.instantiate()
	add_child(new_object)
	
	var max_attempts = 100  # Prevent infinite loops
	var spawn_point: Vector2
	var found_valid_position = false

	for i in range(max_attempts):
		var temp_point = get_random_point_in_polygon(spawn_area.polygon)
		if not is_position_overlapping(temp_point, min_distance, group):
			spawn_point = temp_point
			found_valid_position = true
			break

	if not found_valid_position:
		print("WARNING: Could not find non-overlapping spawn position for ", group)
		return

	new_object.global_position = spawn_area.to_global(spawn_point)
	new_object.scale = scale
	new_object.add_to_group(group)
	print(group, " spawned at: ", new_object.global_position)


func is_position_overlapping(position: Vector2, min_distance: float = 100.0, group: String = "tree") -> bool:
	for obj in get_tree().get_nodes_in_group(group):
		if obj.global_position.distance_to(position) < min_distance:
			return true
	return false


func get_random_point_in_polygon(polygon: PackedVector2Array) -> Vector2:
	var rect = Rect2(polygon[0], Vector2.ZERO)
	for point in polygon:
		rect = rect.expand(point)

	var random_point: Vector2
	var max_attempts = 100
	for i in range(max_attempts):
		random_point = Vector2(
			randf_range(rect.position.x, rect.end.x),
			randf_range(rect.position.y, rect.end.y)
		)
		if Geometry2D.is_point_in_polygon(random_point, polygon):
			return random_point

	push_warning("Could not find valid point in polygon after max attempts.")
	return rect.position
