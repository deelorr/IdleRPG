extends CharacterBody2D

@onready var agent = $NavigationAgent2D

@export var speed: float = 50.0
@export var forest_position: Vector2 = Vector2(300, 320)
@export var worker_hut_position: Vector2 = Vector2(85, 140)  # Ensure inside NavigationRegion2D

var current_target: Vector2

func _ready():
	global_position = worker_hut_position  # Ensure worker starts inside NavigationRegion2D
	agent.path_desired_distance = 4.0  # Prevent jittering
	agent.target_desired_distance = 4.0  # Avoid stopping too early

	move_to_target(forest_position)

func _physics_process(delta):
	if agent.is_navigation_finished():
		_on_reach_destination()
		return

	# Move worker towards next path position
	var next_position = agent.get_next_path_position()
	var direction = (next_position - global_position).normalized()
	velocity = direction * speed
	move_and_slide()

func move_to_target(target: Vector2):
	current_target = target
	agent.set_target_position(target)

func _on_reach_destination():
	velocity = Vector2.ZERO  # Stop movement
	if current_target == forest_position:
		await get_tree().create_timer(2).timeout  # Simulate collecting wood
		move_to_target(worker_hut_position)  # Return to hut
	else:
		await get_tree().create_timer(2).timeout  # Simulate dropping off wood
		Global.total_city_wood += 1 # Add to city total
		move_to_target(forest_position)  # Go back to the forest
