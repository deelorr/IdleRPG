extends CharacterBody2D

@onready var face_sprite: Sprite2D = $FaceSprite
@onready var animations: AnimationPlayer = $AnimationPlayer
@onready var action_label: Label = $ActionLabel
@onready var worker_panel := $WorkerPanel
@onready var worker_level := $WorkerPanel/VBoxContainer/WorkerLevel
@onready var carried_wood_label := $WorkerPanel/VBoxContainer/WorkerWood
@onready var carried_food_label := $WorkerPanel/VBoxContainer/WorkerFood
@onready var tree_chop_timer: Timer = $TreeChopTimer
@onready var bush_chop_timer: Timer = $BushChopTimer

var speed: float = 150.0
var wood_per_trip: int = 6
var food_per_trip: int = 6
var carried_wood: int = 0
var carried_food: int = 0
var current_state: WorkerState = WorkerState.IDLE
var current_job: WorkerJob = WorkerJob.GATHER_WOOD
var target_resource: ResourceTarget = null
var home_hut: WorkerHut = null
var current_level: int = 1

enum WorkerState {
	GATHERING,
	IDLE,
	FINDING,
	RETURNING
}

enum WorkerJob {
	GATHER_WOOD,
	GATHER_FOOD,
}

func update_worker_panel():
	worker_level.text = "Level: " + str(current_level)
	carried_food_label.text ="Food: " + str(carried_food)
	carried_wood_label.text = "Wood: " + str(carried_wood)

func _physics_process(_delta: float) -> void:
	match current_state:
		WorkerState.FINDING:
			move_to_target(target_resource.global_position)
		WorkerState.GATHERING:
			gather_resource(current_job)
		WorkerState.RETURNING:
			move_to_target(home_hut.spawn_marker.global_position)
		WorkerState.IDLE:
			find_target_resource()
			if target_resource:
				current_state = WorkerState.FINDING
			else:
				current_state = WorkerState.RETURNING
	move_and_slide()
	update_animation()
	update_worker_panel()

func update_animation() -> void:
	if current_state == WorkerState.GATHERING:
		animations.play("RESET")  # Placeholder for "chopping" animation
	elif velocity.length() > 0:
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
		animations.stop()  # Placeholder for "idle" animation

func move_to_target(target: Vector2) -> void:
	var direction = (target - global_position).normalized()
	velocity = direction * speed
	var distance = global_position.distance_to(target)
	if distance < 15.0:
		if current_state == WorkerState.FINDING:
			current_state = WorkerState.GATHERING
		elif current_state == WorkerState.RETURNING:
			deposit_resource(current_job)

func gather_resource(resource_type: WorkerJob) -> void:
	if not target_resource:
		return

	# Start the correct timer based on resource type.
	if resource_type == WorkerJob.GATHER_WOOD and tree_chop_timer.is_stopped():
		velocity = Vector2.ZERO
		tree_chop_timer.start()
		flash_text(resource_type)
	elif resource_type == WorkerJob.GATHER_FOOD and bush_chop_timer.is_stopped():
		velocity = Vector2.ZERO
		bush_chop_timer.start()
		flash_text(resource_type)

func flash_text(resource_type: WorkerJob) -> void:
	var flash_times = 3
	var flash_duration = 3.0 / (flash_times * 2)  # Duration for half-cycle flash
	var message = "+2 Wood!!" if resource_type == WorkerJob.GATHER_WOOD else "+2 Food!!"

	# Use 'range(flash_times)' for looping in GDScript.
	for i in range(flash_times):
		action_label.text = message
		await get_tree().create_timer(flash_duration).timeout
		action_label.text = ""
		await get_tree().create_timer(flash_duration).timeout

	# Clear text explicitly after the flash sequence.
	action_label.text = ""

func deposit_resource(resource_type: WorkerJob) -> void:
	if resource_type == WorkerJob.GATHER_WOOD and carried_wood > 0:
		home_hut.hut_wood += carried_wood
		carried_wood = 0
	elif resource_type == WorkerJob.GATHER_FOOD and carried_food > 0:
		home_hut.hut_food += carried_food
		carried_food = 0
	current_state = WorkerState.IDLE  # Return to idle after deposit

func find_target_resource() -> void:
	if not is_inside_tree():
		await ready  # Ensure the node is fully in the scene tree

	var resource_group = ""
	match current_job:
		WorkerJob.GATHER_WOOD:
			resource_group = "tree"
		WorkerJob.GATHER_FOOD:
			resource_group = "bush"
	
	var closest_resource: Node2D = null
	var closest_dist: float = INF

	for resource in get_tree().get_nodes_in_group(resource_group):
		# Skip resources already targeted by other workers.
		if resource.is_targeted:
			continue

		var dist = global_position.distance_to(resource.global_position)
		if dist < closest_dist:
			closest_dist = dist
			closest_resource = resource

	if closest_resource:
		target_resource = closest_resource
		target_resource.is_targeted = true  # Mark resource as targeted immediately
		current_state = WorkerState.FINDING

func _on_tree_chop_timer_timeout() -> void:
	action_label.text = ""
	if target_resource:
		target_resource.queue_free()  # Remove the gathered resource
		carried_wood += wood_per_trip
		target_resource = null  # Clear the target
	current_state = WorkerState.RETURNING  # Head back to deposit resources


func _on_bush_chop_timer_timeout() -> void:
	action_label.text = ""
	if target_resource:
		target_resource.queue_free()  # Remove the gathered resource
		carried_food += food_per_trip
		target_resource = null  # Clear the target
	current_state = WorkerState.RETURNING  # Head back to deposit resources


func _on_input_event(_viewport, event, _shape_idx):
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		worker_panel.visible = !worker_panel.visible  # Toggles visibility
