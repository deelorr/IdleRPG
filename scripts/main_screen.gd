extends Node

const SAVE_PATH: String = "user://savegame.json"

@onready var clock_label: Label = $UI/Overlay/Panel/ClockPanel/ClockLabel
@onready var tree_timer: Timer = $TreeTimer
@onready var tree_scene = preload("res://scenes/Tree.tscn")
@onready var bush_scene = preload("res://scenes/Bush.tscn")
@onready var spawn_area_polygon: Polygon2D = $TheWoods
@onready var food_spawn: Polygon2D = $TheFoods

@export var max_trees: int = 30
@export var max_bushes: int = 30

func _ready() -> void:
	for i in 15:
		spawn_tree()
	for i in 15:
		spawn_bush()
	TimeManager.time_updated.connect(_on_time_changed)
	_on_time_changed(int(TimeManager.time_of_day * TimeManager.HOURS_IN_DAY), 0, TimeManager.day_count)
	
	if FileAccess.file_exists(SAVE_PATH):
		SaveManager.load_game()

func _on_time_changed(in_game_hours: int, in_game_minutes: int, _new_day: int) -> void:
	clock_label.text = "%02d:%02d" % [in_game_hours, in_game_minutes]

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
	spawn_tree()

func spawn_bush():
	var current_bush_count = get_tree().get_nodes_in_group("bush").size()
	if current_bush_count >= max_bushes:
		print("Reached max tree limit: ", max_bushes)
		return

	var new_bush = bush_scene.instantiate() as StaticBody2D
	add_child(new_bush)

	# Try to find a non-overlapping position
	var max_attempts = 100  # Prevent infinite loops
	var spawn_point: Vector2
	var found_valid_position = false

	for i in max_attempts:
		var temp_point = get_random_point_in_polygon(spawn_area_polygon.polygon)
		if not is_position_overlapping(temp_point):  # Check if this position is valid
			spawn_point = temp_point
			found_valid_position = true
			break  # Stop searching once a valid spot is found

	if not found_valid_position:
		print("WARNING: Could not find non-overlapping spawn position!")
		return  # Exit function to prevent spawning in a bad location

	new_bush.global_position = spawn_area_polygon.to_global(spawn_point)
	new_bush.scale = Vector2(2.0, 2.0)
	
	new_bush.add_to_group("bush")
	print("Bush spawned at: ", new_bush.global_position)

func spawn_tree():
	var current_tree_count = get_tree().get_nodes_in_group("tree").size()
	if current_tree_count >= max_trees:
		print("Reached max tree limit: ", max_trees)
		return

	var new_tree = tree_scene.instantiate() as StaticBody2D
	add_child(new_tree)

	# Try to find a non-overlapping position
	var max_attempts = 100  # Prevent infinite loops
	var spawn_point: Vector2
	var found_valid_position = false

	for i in max_attempts:
		var temp_point = get_random_point_in_polygon(spawn_area_polygon.polygon)
		if not is_position_overlapping(temp_point):  # Check if this position is valid
			spawn_point = temp_point
			found_valid_position = true
			break  # Stop searching once a valid spot is found

	if not found_valid_position:
		print("WARNING: Could not find non-overlapping spawn position!")
		return  # Exit function to prevent spawning in a bad location

	new_tree.global_position = spawn_area_polygon.to_global(spawn_point)
	new_tree.scale = Vector2(2.0, 2.0)
	
	new_tree.add_to_group("tree")
	print("Tree spawned at: ", new_tree.global_position)

func is_position_overlapping(position: Vector2, min_distance: float = 100.0) -> bool:
	for tree in get_tree().get_nodes_in_group("tree"):
		if tree.global_position.distance_to(position) < min_distance:
			return true  # Overlapping
	return false  # Safe

func get_random_point_in_polygon(polygon: PackedVector2Array) -> Vector2:
	var rect = Rect2(polygon[0], Vector2.ZERO)
	for point in polygon:
		rect = rect.expand(point)

	var random_point: Vector2
	var max_attempts = 100
	for i in max_attempts:
		random_point = Vector2(
			randf_range(rect.position.x, rect.end.x),
			randf_range(rect.position.y, rect.end.y)
		)
		if Geometry2D.is_point_in_polygon(random_point, polygon):
			return random_point

	push_warning("Could not find valid point in polygon after max attempts.")
	return rect.position
