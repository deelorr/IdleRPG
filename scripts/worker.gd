extends CharacterBody2D

# Signal emitted when wood is deposited (optional, for future use)
signal gathered_wood(wood_amount: int)

# Node references
@onready var sprite: Sprite2D = $Sprite2D
@onready var tree_search_timer: Timer = $TreeSearchTimer
@onready var tree_chop_timer: Timer = $TreeChopTimer
@onready var animations: AnimationPlayer = $AnimationPlayer
@onready var action_label: Label = $ActionLabel

# Variables
var workers_hut: WorkerHut   #Reference to the hut the worker belongs to
var target_tree: TreeClass   #Current target tree to chop
var speed: float = 20.0                # Movement speed
var wood_per_trip: int = 6             # Wood gathered per tree
var carried_wood: int = 0               # Wood currently carried
var current_state: String = "idle"      # States: "idle", "going_to_tree", "returning_to_hut"

# Physics process for movement and state management
func _physics_process(delta: float) -> void:
	match current_state:
		"going_to_tree":
			if target_tree:
				move_to_target(target_tree.global_position)
		"chopping_tree":
			velocity = Vector2.ZERO
		"returning_to_hut":
			move_to_target(workers_hut.hut_waypoint)
		"idle":
			find_target_tree()
			if target_tree:
				current_state = "going_to_tree"
	move_and_slide()
	update_animation()

# Update animations based on velocity
func update_animation() -> void:
	if current_state == "chopping_tree":
		animations.play("RESET") # Placeholder for chop
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

# Move towards a target position
func move_to_target(target: Vector2) -> void:
	var direction = (target - global_position).normalized()
	velocity = direction * speed
	move_and_slide()

	# Check if close enough to the target
	if global_position.distance_to(target) < 10.0:
		if current_state == "going_to_tree":
			chop_tree()
		elif current_state == "returning_to_hut":
			deposit_wood()

# Chop the target tree and gather wood
func chop_tree() -> void:
	if target_tree and tree_chop_timer.is_stopped():
		velocity = Vector2.ZERO
		tree_chop_timer.start()
		current_state = "chopping_tree"  # Add this line
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

# Deposit wood at the hut
func deposit_wood() -> void:
	if carried_wood > 0:
		workers_hut.hut_wood += carried_wood  # Add wood to hut's storage
		carried_wood = 0                        # Reset carried wood
	current_state = "idle"                      # Return to idle state

# Find the closest tree to target
func find_target_tree() -> void:
	if not is_inside_tree():
		await ready  # Ensure the node is fully in the scene tree

	var closest_tree: Node2D = null
	var closest_dist: float = INF

	# Search through all nodes in the "tree" group
	for tree in get_tree().get_nodes_in_group("tree"):
		var dist = global_position.distance_to(tree.global_position)
		if dist < closest_dist:
			closest_dist = dist
			closest_tree = tree

	# Set the closest tree as the target
	if closest_tree:
		target_tree = closest_tree

func _on_tree_chop_timer_timeout():
	action_label.text = ""
	target_tree.queue_free()         # Remove the tree from the scene
	carried_wood += wood_per_trip    # Add wood to carried amount
	target_tree = null               # Clear the target
	current_state = "returning_to_hut"

func _on_tree_search_timer_timeout():
	find_target_tree()
