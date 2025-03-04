extends Node2D

@onready var sprite = $BuildingSprite
@onready var menu = $WorkerHutStats
@onready var wood_button = $WorkerHutStats/WoodButton

@export var max_workers: int = 3  # Allow multiple workers per hut
@export var worker_scene: PackedScene  # Assign Worker.tscn in the Inspector

var workers: Array = []
var hut_wood: int = 0
var max_wood: int = 250

@export var forest_waypoint: Vector2 = Vector2(300, 320)
@export var hut_waypoint: Vector2 = Vector2(85, 140)

func _ready():
	connect("input_event", _on_input_event)

	# Spawn initial workers
	for i in range(max_workers):
		spawn_worker()

func spawn_worker():
	if workers.size() >= max_workers:
		print("Worker hut is full!")
		return
	
	var worker = worker_scene.instantiate()

	# Randomized spawn offset (prevents stacking)
	var spawn_offset = Vector2(randi_range(-5, 5), randi_range(-5, 5))
	worker.global_position = hut_waypoint + spawn_offset  

	# Assign movement waypoints dynamically
	worker.hut_waypoint = hut_waypoint
	worker.forest_waypoint = forest_waypoint + spawn_offset  # Prevent exact overlap

	worker.gathered_wood.connect(_on_gathered_wood)

	get_parent().add_child.call_deferred(worker)  # Add worker to scene
	workers.append(worker)

func _on_gathered_wood(wood):
	hut_wood += wood
	update_labels()

func update_labels():
	wood_button.text = "Wood: " + str(hut_wood)

func change_worker_speed(multiplier: int):
	# Ensure all workers update their speed
	for worker in workers:
		if worker != null:
			worker.speed = worker.base_speed * multiplier

func _on_input_event(_viewport, event, _shape_idx):
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		highlight()
		toggle_menu()

func highlight():
	sprite.modulate = Color(1.2, 1.2, 1.2, 1)
	await get_tree().create_timer(0.2).timeout
	sprite.modulate = Color(1, 1, 1, 1)

func toggle_menu():
	menu.visible = !menu.visible

func _on_collect_button_pressed():
	Global.total_city_wood += hut_wood
	hut_wood = 0
	update_labels()
