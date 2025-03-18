extends CharacterBody2D

@onready var face_sprite: Sprite2D = $FaceSprite
@onready var tree_chop_timer: Timer = $TreeChopTimer
@onready var animations: AnimationPlayer = $AnimationPlayer
@onready var action_label: Label = $ActionLabel

var home_hut: WorkerHut
var target_resource: ResourceTarget
var speed: float = 50.0                 # Movement speed
var wood_per_trip: int = 6              # Wood gathered per tree
var food_per_trip: int = 6
var carried_wood: int = 0               # Wood currently carried
var carried_food: int = 0
var current_state := PlayerState.IDLE
var current_job = JobType.CHOP_WOOD

enum PlayerState {
	CHOPPING,
	IDLE,
	FINDING,
	RETURNING
}

enum JobType {
	CHOP_WOOD, 
	GATHER_FOOD,
}

func _physics_process(_delta: float) -> void:
	match current_state:
		PlayerState.FINDING:
			if target_resource:
				move_to_target(target_resource.global_position)
		PlayerState.CHOPPING:
			velocity = Vector2.ZERO
		PlayerState.RETURNING:
			move_to_target(home_hut.spawn_marker.global_position)
		PlayerState.IDLE:
			find_target_tree()
			if target_resource:
				current_state = PlayerState.FINDING
			else:
				velocity = Vector2.ZERO
	move_and_slide()
	update_animation()

func update_animation() -> void:
	if current_state == PlayerState.CHOPPING:
		animations.play("RESET") # Placeholder for chopping animation later
	if velocity.length() > 0:
		var anim_direction = velocity.normalized()
		if abs(anim_direction.x) > abs(anim_direction.y):
			if anim_direction.x > 0:
				animations.play("walk_right")
			else:
				animations.play("walk_left")
		else:
			if anim_direction.y > 0:
				animations.play("walk_down")
			else:
				animations.play("walk_up")
	else:
		animations.stop()

func move_to_target(target: Vector2) -> void:
	var direction = (target - global_position).normalized()
	velocity = direction * speed
	move_and_slide()

	# Check if close enough to the target
	if global_position.distance_to(target) < 10.0:
		if current_state == PlayerState.FINDING:
			chop_tree()
		elif current_state == PlayerState.RETURNING:
			deposit_wood()

func chop_tree() -> void:
	if target_resource and tree_chop_timer.is_stopped():
		velocity = Vector2.ZERO
		tree_chop_timer.start()
		current_state = PlayerState.CHOPPING
		flash_chopped_text()

func flash_chopped_text() -> void:
	var flash_times = 3
	var flash_duration = 3.0 / (flash_times * 2)  # Calculate half-cycle duration
	
	for i in flash_times:
		action_label.text = "+2 Wood!!"
		await get_tree().create_timer(flash_duration).timeout
		action_label.text = ""
		await get_tree().create_timer(flash_duration).timeout
		
	# Reset or clear the text after flashing
	action_label.text = ""

func deposit_wood() -> void:
	if carried_wood > 0:
		home_hut.hut_wood += carried_wood  # Add wood to hut's storage
		carried_wood = 0                        # Reset carried wood
	current_state = PlayerState.IDLE                    # Return to idle state

func find_target_resource() -> void:
	if current_job == JobType.CHOP_WOOD:
		find_target_tree()
	elif current_job == JobType.GATHER_FOOD:
		find_target_food()

func find_target_food() -> void:
	if not is_inside_tree():
		await ready  # Ensure the node is fully in the scene tree

	var closest_food: Node2D = null
	var closest_dist: float = INF

	for food in get_tree().get_nodes_in_group("food"):
		# Skip food sources already targeted by other workers
		if food.is_targeted:
			continue

		var dist = global_position.distance_to(food.global_position)
		if dist < closest_dist:
			closest_dist = dist
			closest_food = food

	if closest_food:
		target_resource = closest_food  # Assign as target resource
		target_resource.is_targeted = true  # Mark food as targeted immediately
		current_state = PlayerState.FINDING

func find_target_tree() -> void:
	if not is_inside_tree():
		await ready  # Ensure the node is fully in the scene tree

	var closest_tree: Node2D = null
	var closest_dist: float = INF

	for tree in get_tree().get_nodes_in_group("tree"):
		# Skip trees already targeted by other workers
		if tree.is_targeted:
			continue

		var dist = global_position.distance_to(tree.global_position)
		if dist < closest_dist:
			closest_dist = dist
			closest_tree = tree

	if closest_tree:
		target_resource = closest_tree
		target_resource.is_targeted = true  # Mark tree as targeted immediately

func _on_tree_chop_timer_timeout():
	action_label.text = ""
	target_resource.queue_free()         # Remove the tree from the scene
	carried_wood += wood_per_trip    # Add wood to carried amount
	target_resource = null               # Clear the target
	current_state = PlayerState.RETURNING


func _on_bush_chop_timer_timeout() -> void:
	action_label.text = ""
	target_resource.queue_free()         # Remove the tree from the scene
	carried_food += food_per_trip    # Add wood to carried amount
	target_resource = null               # Clear the target
	current_state = PlayerState.RETURNING
