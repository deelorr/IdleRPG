extends CharacterBody2D

# Signal emitted when wood is deposited (optional, for future use)
signal gathered_wood(wood_amount: int)

# Node references
@onready var sprite: Sprite2D = $Sprite2D
@onready var tree_search_timer: Timer = $Timer

# Variables
var hut_reference: Node = null          # Reference to the hut the worker belongs to
var target_tree: Node2D = null          # Current target tree to chop
var speed: float = 100.0                # Movement speed
var wood_per_trip: int = 10             # Wood gathered per tree
var carried_wood: int = 0               # Wood currently carried
var current_state: String = "idle"      # States: "idle", "going_to_tree", "returning_to_hut"

# Called when the node enters the scene tree
func _ready() -> void:
	tree_search_timer.timeout.connect(find_target_tree)

# Physics process for movement and state management
func _physics_process(delta: float) -> void:
	match current_state:
		"going_to_tree":
			if target_tree:
				move_to_target(target_tree.global_position)
		"returning_to_hut":
			move_to_target(hut_reference.hut_waypoint)
		"idle":
			find_target_tree()
			if target_tree:
				current_state = "going_to_tree"

# Move towards a target position
func move_to_target(target: Vector2) -> void:
	var direction = (target - global_position).normalized()
	velocity = direction * speed
	move_and_slide()
	sprite.rotation = direction.angle()  # Rotate sprite to face movement direction

	# Check if close enough to the target
	if global_position.distance_to(target) < 10.0:
		if current_state == "going_to_tree":
			chop_tree()
		elif current_state == "returning_to_hut":
			deposit_wood()

# Chop the target tree and gather wood
func chop_tree() -> void:
	if target_tree:
		target_tree.queue_free()         # Remove the tree from the scene
		carried_wood += wood_per_trip    # Add wood to carried amount
		target_tree = null               # Clear the target
		current_state = "returning_to_hut"

# Deposit wood at the hut
func deposit_wood() -> void:
	if carried_wood > 0:
		hut_reference.hut_wood += carried_wood  # Add wood to hut's storage
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
