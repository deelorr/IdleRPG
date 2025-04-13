extends Node2D

const SAVE_PATH: String = "user://savegame.json"
const GRID_SIZE = 16  # Size of each "grid" cell
const INITIAL_SPAWN_COUNT = 15

@export var show_debug_grid: bool = true
@export var debug_color_available: Color = Color.LIGHT_GRAY
@export var debug_color_occupied: Color = Color.RED
@onready var grid_debugger: Control = $GridDebugger

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

@onready var text_box := $UI/TextBox

var occupied_cells = {}
var max_trees: int = 20
var max_bushes: int = 20

func _ready() -> void:
	grid_debugger.tree_spawn_area = tree_spawn_area
	grid_debugger.bush_spawn_area = bush_spawn_area
	grid_debugger.occupied_cells = occupied_cells
	
	spawn_initial_resources()
	
	TimeManager.time_updated.connect(_on_time_changed) #Listen for time updates
	_on_time_changed(int(TimeManager.time_of_day * TimeManager.HOURS_IN_DAY), 0, TimeManager.day_count)
	
	if FileAccess.file_exists(SAVE_PATH):
		SaveManager.load_game()
		
	show_tutorial()

func _process(_delta: float) -> void:
	if show_debug_grid:
		queue_redraw()


func spawn_initial_resources():
	for i in INITIAL_SPAWN_COUNT:
		spawn_resource(tree_scene, tree_spawn_area, "tree", max_trees)
		spawn_resource(bush_scene, bush_spawn_area, "bush", max_bushes)

func _on_time_changed(in_game_hours: int, in_game_minutes: int, _new_day: int) -> void:
	clock_label.text = "%02d:%02d" % [in_game_hours, in_game_minutes]

func _input(event: InputEvent) -> void:
	if event is InputEventKey and event.is_pressed():
		match event.keycode:
			KEY_P:
				# Toggle pause
				TimeManager.time_paused = !TimeManager.time_paused
			KEY_H:
				# Skip 1 hour
				TimeManager.skip_hours(1)
			KEY_D:
				# Skip 24 hours (1 day)
				TimeManager.skip_hours(24)
			KEY_G:
				grid_debugger.show_debug_grid = !grid_debugger.show_debug_grid

func spawn_resource(
	scene: PackedScene, 
	spawn_area: Node2D, 
	group_name: String, 
	max_count: int) -> void:
	
	if not spawn_area:
		push_warning("Missing spawn area for %s" % group_name)
		return

	if get_tree().get_nodes_in_group(group_name).size() >= max_count:
		return

	var shape_node: CollisionShape2D = spawn_area.get_child(0)
	if not shape_node or not (shape_node is CollisionShape2D):
		push_warning("SpawnArea for %s needs a CollisionShape2D" % group_name)
		return

	var shape: RectangleShape2D = shape_node.shape as RectangleShape2D
	if not shape:
		push_warning("Shape for %s must be RectangleShape2D" % group_name)
		return

	var rect: Rect2 = shape.get_rect()
	var top_left: Vector2 = spawn_area.to_global(rect.position)
	var bottom_right: Vector2 = spawn_area.to_global(rect.end)

	var grid_positions: Array[Vector2] = generate_grid_positions(top_left, bottom_right)
	if grid_positions.is_empty():
		push_warning("No available grid positions for %s" % group_name)
		return

	var spawn_point: Vector2 = grid_positions.pick_random()
	occupied_cells[spawn_point] = true

	var new_resource: StaticBody2D = scene.instantiate() as StaticBody2D
	new_resource.global_position = spawn_point
	new_resource.scale = Vector2(2, 2)
	new_resource.add_to_group(group_name)
	add_child(new_resource)

func generate_grid_positions(top_left: Vector2, bottom_right: Vector2) -> Array[Vector2]:
	var valid_positions: Array[Vector2] = []

	for x in range(int(top_left.x), int(bottom_right.x), GRID_SIZE):
		for y in range(int(top_left.y), int(bottom_right.y), GRID_SIZE):
			var grid_pos: Vector2 = Vector2(x, y)
			if not occupied_cells.has(grid_pos):
				valid_positions.append(grid_pos)

	return valid_positions

func _on_tree_timer_timeout():spawn_resource(tree_scene, tree_spawn_area, "tree", max_trees)

func _on_bush_timer_timeout():spawn_resource(bush_scene, bush_spawn_area, "bush", max_bushes)

func show_tutorial():
	text_box.show_text_sequence([
		{"speaker": "Narrator", "text": "Welcome to your Home Base."},
		{"speaker": "Narrator", "text": "This is where you will store all the resources you gather."},
		{"speaker": "Narrator", "text": "Let's start collecting wood now."} ])
