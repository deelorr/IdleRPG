extends CharacterBody2D

signal gathered_wood(wood_amount: int)

@onready var navigation_agent: NavigationAgent2D = $NavigationAgent2D

var target_waypoint: Vector2
var hut_waypoint: Vector2
var forest_waypoint: Vector2
var speed: float = 100.0
var wood_per_trip: int = 10

func _ready() -> void:
	target_waypoint = forest_waypoint
	navigation_agent.set_target_position(target_waypoint)
	navigation_agent.path_desired_distance = 10.0
	navigation_agent.target_desired_distance = 15.0  # Reduced for precision

func _physics_process(_delta: float) -> void:
	if navigation_agent.is_navigation_finished():
		print("Reached: ", global_position, " Target was: ", target_waypoint)
		if target_waypoint == forest_waypoint:
			gathered_wood.emit(wood_per_trip)
			target_waypoint = hut_waypoint
		else:
			target_waypoint = forest_waypoint
		navigation_agent.set_target_position(target_waypoint)
		return

	var next_position = navigation_agent.get_next_path_position()
	var direction = (next_position - global_position).normalized()
	velocity = direction * speed
	move_and_slide()
