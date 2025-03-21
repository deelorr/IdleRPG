extends Node

const SAVE_PATH: String = "user://savegame.json"
const GRID_SIZE = 16  # Size of each "grid" cell

@onready var clock_label: Label = $UI/Overlay/Panel/ClockPanel/ClockLabel
@onready var tree_timer: Timer = $TreeTimer
@onready var tree_spawn_area: Area2D = $TreeSpawnArea
@onready var tree_scene = preload("res://scenes/Tree.tscn")
@onready var bush_timer: Timer = $BushTimer
@onready var bush_spawn_area: Area2D = $BushSpawnArea
@onready var bush_scene = preload("res://scenes/Bush.tscn")

@onready var worker_hut1_scene := $WorkerHut
@onready var worker_hut2_scene := $WorkerHut2
@onready var worker_hut3_scene := $WorkerHut3

var occupied_cells = {}  # Stores occupied grid positions
var max_trees: int = 20
var max_bushes: int = 20

func _ready() -> void:
	for i in 15:
		spawn_resource(tree_scene, tree_spawn_area, "tree", max_trees)
	for i in 15:
		spawn_resource(bush_scene, bush_spawn_area, "bush", max_bushes)

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

func spawn_resource(
	scene: PackedScene,
	spawn_area: Node2D,
	group_name: String,
	max_count: int ):
		
	if not spawn_area:
		print("ERROR: No spawn area assigned for ", group_name)
		return
	
	var current_count = get_tree().get_nodes_in_group(group_name).size()
	if current_count >= max_count:
		print("Reached max %s limit: %d" % [group_name, max_count])
		return

	# Get the shape bounds
	var shape_node = spawn_area.get_child(0)  # Should be CollisionShape2D
	if not shape_node or not (shape_node is CollisionShape2D):
		print("ERROR: SpawnArea for %s must have a CollisionShape2D!" % group_name)
		return

	var rect = shape_node.shape.get_rect()
	var top_left = spawn_area.to_global(rect.position)
	var bottom_right = spawn_area.to_global(rect.end)

	# Generate valid grid positions
	var grid_positions = generate_grid_positions(top_left, bottom_right)
	if grid_positions.is_empty():
		print("WARNING: No available grid spaces for ", group_name)
		return

	# Pick random position
	var spawn_point = grid_positions.pick_random()
	occupied_cells[spawn_point] = true

	var new_resource = scene.instantiate() as StaticBody2D
	add_child(new_resource)
	new_resource.global_position = spawn_point
	new_resource.scale = Vector2(2.0, 2.0)
	new_resource.add_to_group(group_name)

# Generate grid-aligned positions inside the BushSpawnArea bounds
func generate_grid_positions(top_left: Vector2, bottom_right: Vector2):
	var valid_positions = []

	for x in range(int(top_left.x), int(bottom_right.x), GRID_SIZE):
		for y in range(int(top_left.y), int(bottom_right.y), GRID_SIZE):
			var grid_pos = Vector2(x, y)

			# Ensure position isn't occupied
			if not occupied_cells.has(grid_pos):
				valid_positions.append(grid_pos)

	return valid_positions

func _on_tree_timer_timeout():
	spawn_resource(tree_scene, tree_spawn_area, "tree", max_trees)

func _on_bush_timer_timeout():
	spawn_resource(bush_scene, bush_spawn_area, "bush", max_bushes)
