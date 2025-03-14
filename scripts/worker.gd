extends CharacterBody2D

@onready var face_sprite: Sprite2D = $FaceSprite
@onready var chop_timer: Timer = $TreeChopTimer
@onready var animations: AnimationPlayer = $AnimationPlayer
@onready var action_label: Label = $ActionLabel

var workers_hut: WorkerHut
var target_resource: Node2D = null  # Can be either a tree or a bush

var speed: float = 50.0                  # Movement speed
var resource_per_trip: int = 6           # Amount gathered per resource
var carried_resource: int = 0            # Currently carried wood/food
var current_state: String = "idle"       # States: "chopping", "idle", "going_to_resource", "returning"

enum JobType { CHOP_WOOD, GATHER_FOOD }
var current_job: JobType = JobType.CHOP_WOOD  # Default to wood chopping

# Called every frame
func _physics_process(_delta: float) -> void:
	match current_state:
		"going_to_resource":
			if target_resource:
				move_to_target(target_resource.global_position)
		"chopping":
			velocity = Vector2.ZERO
		"returning_to_hut":
			move_to_target(workers_hut.marker.global_position)
		"idle":
			find_target_resource()
			if target_resource:
				current_state = "going_to_resource"
			else:
				velocity = Vector2.ZERO

	move_and_slide()
	update_animation()

# Moves towards a target position
func move_to_target(target: Vector2) -> void:
	var direction = (target - global_position).normalized()
	velocity = direction * speed
	move_and_slide()

	# Check if close enough to interact
	if global_position.distance_to(target) < 10.0:
		if current_state == "going_to_resource":
			start_gathering()
		elif current_state == "returning_to_hut":
			deposit_resource()

# Finds the closest valid tree or bush
func find_target_resource() -> void:
	var closest_resource: Node2D = null
	var closest_dist: float = INF
	var resource_group = "tree" if current_job == JobType.CHOP_WOOD else "bush"

	for resource in get_tree().get_nodes_in_group(resource_group):
		if resource.is_targeted:
			continue

		var dist = global_position.distance_to(resource.global_position)
		if dist < closest_dist:
			closest_dist = dist
			closest_resource = resource

	if closest_resource:
		target_resource = closest_resource
		target_resource.is_targeted = true  # Mark as targeted
		current_state = "going_to_resource"

# Starts the gathering process
func start_gathering() -> void:
	if target_resource and chop_timer.is_stopped():
		velocity = Vector2.ZERO
		chop_timer.start()
		current_state = "chopping"
		flash_gather_text()

# Flashes "+2 Wood!!" or "+2 Food!!" while gathering
func flash_gather_text() -> void:
	var flash_times = 3
	var flash_duration = 3.0 / (flash_times * 2)
	var message = "+2 Wood!!" if current_job == JobType.CHOP_WOOD else "+2 Food!!"

	for i in flash_times:
		action_label.text = message
		await get_tree().create_timer(flash_duration).timeout
		action_label.text = ""
		await get_tree().create_timer(flash_duration).timeout

	action_label.text = ""

# Deposits gathered wood or food
func deposit_resource() -> void:
	if carried_resource > 0:
		if current_job == JobType.CHOP_WOOD:
			workers_hut.hut_wood += carried_resource
		else:
			workers_hut.hut_food += carried_resource

	carried_resource = 0
	current_state = "idle"

# When gathering timer ends
func _on_tree_chop_timer_timeout():
	action_label.text = ""

	# ✅ Fix: Ensure worker properly collects food before moving
	if target_resource:
		carried_resource += resource_per_trip  # ✅ Make sure food is added
		target_resource.queue_free()  # ✅ Remove tree/bush from scene
		target_resource = null  # ✅ Clear the target
		current_state = "returning_to_hut"  # ✅ Now properly returns after gathering


# Updates animations based on velocity
func update_animation() -> void:
	if current_state == "chopping":
		animations.play("RESET")  # Placeholder for chopping animation
	elif velocity.length() > 0:
		var anim_direction = velocity.normalized()
		if abs(anim_direction.x) > abs(anim_direction.y):
			animations.play("walk_right" if anim_direction.x > 0 else "walk_left")
		else:
			animations.play("walk_down" if anim_direction.y > 0 else "walk_up")
	else:
		animations.stop()
