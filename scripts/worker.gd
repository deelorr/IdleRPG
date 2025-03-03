extends CharacterBody2D

signal gathered_wood(wood)
#signal gathered_food(food)

@onready var agent = $NavigationAgent2D

@export var base_speed: float = 50.0
var speed: float = base_speed
@export var forest_position: Vector2 = Vector2(300, 320)
@export var worker_hut_position: Vector2 = Vector2(85, 140)  # Ensure inside NavigationRegion2D

var current_target: Vector2

func _ready():
	global_position = worker_hut_position  # Ensure worker starts inside NavigationRegion2D
	agent.path_desired_distance = 4.0  # Prevent jittering
	agent.target_desired_distance = 4.0  # Avoid stopping too early

	# Wait until NavigationServer has updated before setting target
	await get_tree().process_frame  # Ensures one frame passes for the nav system to sync
	await get_tree().process_frame  # Sometimes requires two frames for safe sync

	move_to_target(forest_position)


func _physics_process(_delta):
	if agent.is_navigation_finished():
		_on_reach_destination(2.0)
		return

	# Move worker towards next path position
	var next_position = agent.get_next_path_position()
	var direction = (next_position - global_position).normalized()
	velocity = direction * speed
	move_and_slide()
	
func move_to_target(target: Vector2):
	current_target = target
	agent.set_target_position(target)

func _on_reach_destination(delay: float):
	velocity = Vector2.ZERO
	if current_target == forest_position:
		await get_tree().create_timer(delay).timeout  # Simulate collecting wood
		move_to_target(worker_hut_position)
	else:
		await get_tree().create_timer(delay).timeout  # Simulate dropping off wood
		gathered_wood.emit(5)
		move_to_target(forest_position)
