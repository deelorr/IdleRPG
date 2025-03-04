extends CharacterBody2D

signal gathered_wood(wood)

@onready var agent = $NavigationAgent2D

@export var base_speed: float = 50.0
var speed: float = base_speed

# Assigned dynamically by WorkerHut
var forest_waypoint: Vector2
var hut_waypoint: Vector2

var is_waiting: bool = false  # Prevent movement during collection/unloading
var current_target: Vector2

func _ready():
	agent.path_desired_distance = 4.0
	agent.target_desired_distance = 4.0

	# Ensure NavigationServer is updated before moving
	await get_tree().process_frame
	await get_tree().process_frame

	move_to_target(forest_waypoint)

func _physics_process(_delta):
	if is_waiting: return  # Stop movement during collection/unloading

	if agent.is_navigation_finished():
		_on_reach_destination()
		return

	var next_position = agent.get_next_path_position()
	var direction = (next_position - global_position).normalized()
	velocity = direction * speed
	move_and_slide()

func move_to_target(target: Vector2):
	current_target = target
	agent.set_target_position(target)

func _on_reach_destination():
	velocity = Vector2.ZERO
	
	# Worker actions at waypoints
	if current_target == forest_waypoint:
		is_waiting = true
		await get_tree().create_timer(2.0).timeout  # Simulate gathering
		move_to_target(hut_waypoint)  # Go back to hut
		is_waiting = false
	else:
		is_waiting = true
		await get_tree().create_timer(2.0).timeout  # Simulate unloading
		gathered_wood.emit(5)
		move_to_target(forest_waypoint)  # Repeat cycle
		is_waiting = false
