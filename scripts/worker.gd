extends CharacterBody2D
class_name Worker

@onready var face_sprite: Sprite2D = $FaceSprite
@onready var animations: AnimationPlayer = $AnimationPlayer
@onready var action_label: Label = $ActionLabel
@onready var worker_panel := $WorkerPanel
@onready var worker_level := $WorkerPanel/VBoxContainer/WorkerLevel
@onready var carried_wood_label := $WorkerPanel/VBoxContainer/GridContainer/WorkerFoodAmount
@onready var carried_food_label := $WorkerPanel/VBoxContainer/GridContainer/WorkerWoodAmount
@onready var tree_chop_timer: Timer = $TreeChopTimer
@onready var bush_chop_timer: Timer = $BushChopTimer
@onready var target_line: Line2D = $TargetLine


var speed: float = 150.0
var base_wood_capacity: int = 24
var base_food_capacity: int = 24
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
	carried_wood_label.text = " %d / %d" % [carried_wood, get_wood_capacity()]
	carried_food_label.text = " %d / %d" % [carried_food, get_food_capacity()]

func _physics_process(_delta: float) -> void:
	match current_state:
		WorkerState.FINDING:
			if is_instance_valid(target_resource):
				if target_resource.has_method("get_gather_position"):
					move_to_target(target_resource.get_gather_position())
				else:
					move_to_target(target_resource.global_position)
			else:
				target_resource = null
				current_state = WorkerState.IDLE

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
	update_target_line()


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
	velocity = direction * speed * TimeManager.time_speed_multiplier
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
		tree_chop_timer.wait_time = 1.0 / TimeManager.time_speed_multiplier
		tree_chop_timer.start()
		flash_text(resource_type)
	elif resource_type == WorkerJob.GATHER_FOOD and bush_chop_timer.is_stopped():
		velocity = Vector2.ZERO
		bush_chop_timer.wait_time = 1.0 / TimeManager.time_speed_multiplier
		bush_chop_timer.start()
		flash_text(resource_type)

func flash_text(resource_type: WorkerJob) -> void:
	var message = "+2 Wood!!" if resource_type == WorkerJob.GATHER_WOOD else "+2 Food!!"
	action_label.text = message
	await get_tree().create_timer(0.5 / TimeManager.time_speed_multiplier).timeout
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
		target_resource.targeted_by = self  # Track the worker
		current_state = WorkerState.FINDING

func _on_tree_chop_timer_timeout() -> void:
	action_label.text = ""

	if target_resource:
		var chunk_size := 2  # Amount gathered per tick
		var amount_collected = target_resource.reduce_amount(chunk_size)
		carried_wood += amount_collected

		if amount_collected > 0:
			flash_text(WorkerJob.GATHER_WOOD)

		var tree_depleted = target_resource.is_depleted()
		if tree_depleted:
			target_resource.is_targeted = false
			target_resource.targeted_by = null
			target_resource.queue_free()
			target_resource = null
		else:
			target_resource.is_targeted = false
			target_resource.targeted_by = null

	if carried_wood >= get_wood_capacity():
		current_state = WorkerState.RETURNING
	elif target_resource == null:
		find_target_resource()
		if target_resource:
			current_state = WorkerState.FINDING
		else:
			current_state = WorkerState.RETURNING
	else:
		tree_chop_timer.start()

func _on_bush_chop_timer_timeout() -> void:
	action_label.text = ""

	if target_resource:
		var chunk_size := 2  # Amount gathered per tick
		var amount_collected = target_resource.reduce_amount(chunk_size)
		carried_food += amount_collected

		if amount_collected > 0:
			flash_text(WorkerJob.GATHER_FOOD)

		var bush_depleted = target_resource.is_depleted()
		if bush_depleted:
			target_resource.is_targeted = false
			target_resource.targeted_by = null
			target_resource.queue_free()
			target_resource = null
		else:
			target_resource.is_targeted = false
			target_resource.targeted_by = null

	if carried_food >= get_food_capacity():
		current_state = WorkerState.RETURNING
	elif target_resource == null:
		find_target_resource()
		if target_resource:
			current_state = WorkerState.FINDING
		else:
			current_state = WorkerState.RETURNING
	else:
		bush_chop_timer.start()


func _on_input_event(_viewport, event, _shape_idx):
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		worker_panel.visible = !worker_panel.visible  # Toggles visibility

func get_wood_capacity() -> int:
	return base_wood_capacity + (current_level - 1) * 2  # +2 capacity per level

func get_food_capacity() -> int:
	return base_food_capacity + (current_level - 1) * 1  # +1 capacity per level

func update_target_line():
	if is_instance_valid(target_resource):
		target_line.points = [Vector2.ZERO, target_resource.global_position - global_position]
	else:
		target_line.clear_points()
