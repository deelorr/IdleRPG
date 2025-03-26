extends StaticBody2D
class_name WorkerHut

@onready var sprite: Sprite2D = $WorkerHutSprite
@onready var menu: Control = $MenuPanel
@onready var wood_button: Button = $MenuPanel/MarginContainer/VBoxContainer/WorkerHutStats/WoodButton
@onready var food_button: Button = $MenuPanel/MarginContainer/VBoxContainer/WorkerHutStats/FoodButton

@onready var worker1_state_label := $MenuPanel/MarginContainer/VBoxContainer/WorkerButtons/Worker1/Worker1StateLabel
@onready var worker2_state_label := $MenuPanel/MarginContainer/VBoxContainer/WorkerButtons/Worker2/Worker2StateLabel
@onready var worker3_state_label := $MenuPanel/MarginContainer/VBoxContainer/WorkerButtons/Worker3/Worker3StateLabel

@onready var worker1_level_label := $MenuPanel/MarginContainer/VBoxContainer/WorkerButtons/Worker1/LevelLabel
@onready var worker2_level_label := $MenuPanel/MarginContainer/VBoxContainer/WorkerButtons/Worker2/LevelLabel
@onready var worker3_level_label := $MenuPanel/MarginContainer/VBoxContainer/WorkerButtons/Worker3/LevelLabel

@onready var worker1_job_label := $MenuPanel/MarginContainer/VBoxContainer/WorkerButtons/Worker1/JobLabel
@onready var worker2_job_label := $MenuPanel/MarginContainer/VBoxContainer/WorkerButtons/Worker2/JobLabel
@onready var worker3_job_label := $MenuPanel/MarginContainer/VBoxContainer/WorkerButtons/Worker3/JobLabel

@onready var worker1_food_label := $MenuPanel/MarginContainer/VBoxContainer/WorkerButtons/Worker1/FoodLabel
@onready var worker2_food_label := $MenuPanel/MarginContainer/VBoxContainer/WorkerButtons/Worker2/FoodLabel
@onready var worker3_food_label := $MenuPanel/MarginContainer/VBoxContainer/WorkerButtons/Worker3/FoodLabel

@onready var worker1_wood_label := $MenuPanel/MarginContainer/VBoxContainer/WorkerButtons/Worker1/WoodLabel
@onready var worker2_wood_label := $MenuPanel/MarginContainer/VBoxContainer/WorkerButtons/Worker2/WoodLabel
@onready var worker3_wood_label := $MenuPanel/MarginContainer/VBoxContainer/WorkerButtons/Worker3/WoodLabel

@onready var worker1_button: Button = $MenuPanel/MarginContainer/VBoxContainer/WorkerButtons/Worker1/Worker1Button
@onready var worker2_button: Button = $MenuPanel/MarginContainer/VBoxContainer/WorkerButtons/Worker2/Worker2Button
@onready var worker3_button: Button = $MenuPanel/MarginContainer/VBoxContainer/WorkerButtons/Worker3/Worker3Button

@onready var worker_scene = preload("res://scenes/ForestWorker.tscn")
@onready var spawn_marker: Marker2D = $SpawnMarker
@onready var menu_anchor: Marker2D = $MenuAnchor

var worker_state_labels: Array = []
var worker_job_labels: Array = []
var worker_level_labels: Array = []
var worker_carried_wood_labels: Array = []
var worker_carried_food_labels: Array = []

var workers: Array = []
var current_workers: int = 1
var max_workers: int = 3
var hut_wood: int = 0
var max_wood: int = 30
var hut_food: int = 0
var max_food: int = 30

func _ready():
	# Initialize the arrays with the onready references.
	worker_state_labels = [worker1_state_label, worker2_state_label, worker3_state_label]
	worker_job_labels = [worker1_job_label, worker2_job_label, worker3_job_label]
	worker_level_labels = [worker1_level_label, worker2_level_label, worker3_level_label]
	worker_carried_wood_labels = [worker1_wood_label, worker2_wood_label, worker2_wood_label]
	worker_carried_food_labels = [worker1_food_label, worker2_food_label, worker3_food_label]

func _physics_process(_delta):
	update_labels()

func update_labels() -> void:
	wood_button.text = "Wood: " + str(hut_wood)
	food_button.text = "Food: " + str(hut_food)
	
	# Loop through each worker slot (assuming max_workers is the total number of slots)
	for i in range(max_workers):
		var worker = null  # Declare worker here so it is available in this iteration.
		
		if i < workers.size():
			worker = workers[i]
			worker_state_labels[i].text = str(worker.WorkerState.keys()[worker.current_state])
			worker_job_labels[i].text = str(worker.WorkerJob.keys()[worker.current_job])
			worker_level_labels[i].text = "LVL: " + str(worker.current_level)
			worker_carried_wood_labels[i].text = " %d / %d" % [worker.carried_wood, worker.get_wood_capacity()]
			worker_carried_food_labels[i].text = " %d / %d" % [worker.carried_food, worker.get_food_capacity()]
		else:
			worker_state_labels[i].text = ""
			worker_job_labels[i].text = ""
			worker_level_labels[i].text = ""
			worker_carried_food_labels[i].text = ""
			worker_carried_wood_labels[i].text = ""
			
		# Update the corresponding worker button and fire button.
		var button_path = "MenuPanel/VBoxContainer/WorkerButtons/Worker%d/Worker%dButton" % [i + 1, i + 1]
		var fire_button_path = "MenuPanel/VBoxContainer/WorkerButtons/Worker%d/Worker%dFireButton" % [i + 1, i + 1]
		
		var worker_button = get_node_or_null(button_path) as Button
		var worker_fire_button = get_node_or_null(fire_button_path) as Button
		
		if i < workers.size():
			if worker_button and worker:
				# Set the icon from the worker and clear text.
				if worker.face_sprite and worker.face_sprite.texture:
					worker_button.icon = worker.face_sprite.texture
					worker_button.text = ""
			if worker_fire_button:
				worker_fire_button.visible = true
		else:
			if worker_button:
				worker_button.icon = null
				worker_button.text = "Add Worker"
			if worker_fire_button:
				worker_fire_button.visible = false

func _input_event(_viewport, event: InputEvent, _shape_idx) -> void:
	if event is InputEventMouseButton and event.is_pressed() and event.button_index == MOUSE_BUTTON_LEFT:
		highlight()
		toggle_menu()

func highlight() -> void:
	sprite.modulate = Color(1.2, 1.2, 1.2, 1)  # Brighten
	await get_tree().create_timer(0.2).timeout
	sprite.modulate = Color(1, 1, 1, 1)        # Reset

func toggle_menu() -> void:
	var tween := create_tween()
	# If this menu is already open, close it and reset the global tracker
	if menu.visible:
		tween.tween_property(menu, "scale", Vector2.ZERO, 0.2).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_IN)
		await tween.finished
		menu.visible = false
		if Global.currently_open_hut == self:
			Global.currently_open_hut = null
	else:
		if Global.currently_open_hut and Global.currently_open_hut != self:
			Global.currently_open_hut.force_close_menu()
		Global.currently_open_hut = self
		menu.visible = true
		menu.global_position = menu_anchor.global_position
		menu.scale = Vector2.ZERO
		tween.tween_property(menu, "scale", Vector2.ONE, 0.3).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)

func force_close_menu() -> void:
	if menu.visible:
		menu.visible = false
		menu.scale = Vector2.ONE
		Global.currently_open_hut = null

func _on_collect_button_pressed() -> void:
	Global.total_city_wood += hut_wood  # Add hut_wood to global total
	Global.total_city_food += hut_food
	hut_wood = 0  # Reset hut wood
	hut_food = 0
	update_labels()  # Update UI

func spawn_worker() -> void:
	if workers.size() >= max_workers:
		print("Worker hut is full!")
		return
	
	var worker = worker_scene.instantiate() as CharacterBody2D
	worker.global_position = spawn_marker.global_position  # Spawn at marker
	worker.scale = Vector2(2.0, 2.0)  # Default scale for Characters
	worker.home_hut = self  # Link worker to this hut
	get_parent().add_child.call_deferred(worker)  # Add to scene
	workers.append(worker)  # Track worker

func update_worker_spawn_buttons() -> void:
	match workers.size():
		0:
			worker1_button.disabled = false
			worker2_button.disabled = true
			worker3_button.disabled = true
		1:
			worker1_button.disabled = true
			worker2_button.disabled = false
			worker3_button.disabled = true
		2:
			worker1_button.disabled = true
			worker2_button.disabled = true
			worker3_button.disabled = false
		3:
			worker1_button.disabled = true
			worker2_button.disabled = true
			worker3_button.disabled = true
		_:
			worker1_button.disabled = true
			worker2_button.disabled = true
			worker3_button.disabled = true

func _on_worker_1_button_pressed() -> void:
	if workers.size() == 0:
		spawn_worker()
		update_worker_spawn_buttons()
		update_labels()
	else:
		print("Worker slot 1 is already filled.")

func _on_worker_2_button_pressed() -> void:
	if workers.size() == 1:
		spawn_worker()
		update_worker_spawn_buttons()
		update_labels()
	else:
		print("Worker slot 2 cannot be filled right now. Current worker count: ", workers.size())

func _on_worker_3_button_pressed() -> void:
	if workers.size() == 2:
		spawn_worker()
		update_worker_spawn_buttons()
		update_labels()
	else:
		print("Worker slot 3 cannot be filled right now. Current worker count: ", workers.size())

func fire_worker(index: int) -> void:
	if index < 0 or index >= workers.size():
		print("Invalid worker index!")
		return

	var worker_to_fire = workers[index]
	if worker_to_fire and is_instance_valid(worker_to_fire):
		worker_to_fire.queue_free()  # Remove worker from scene
	workers.remove_at(index)  # Remove worker from the array
	update_labels()  # Update UI

func _on_worker_1_fire_button_pressed() -> void:
	if workers.size() > 0:
		fire_worker(0)
		update_worker_spawn_buttons()
		update_labels()

func _on_worker_2_fire_button_pressed() -> void:
	if workers.size() > 1:
		fire_worker(1)
		update_worker_spawn_buttons()
		update_labels()

func _on_worker_3_fire_button_pressed() -> void:
	if workers.size() > 2:
		fire_worker(2)
		update_worker_spawn_buttons()
		update_labels()

func switch_worker_job(index: int) -> void:
	if index >= 0 and index < workers.size():
		var worker = workers[index]
		# Clear the current target, if any.
		if worker.target_resource:
			worker.target_resource.is_targeted = false
			worker.target_resource.targeted_by = null
			worker.target_resource = null
		worker.pending_job_switch = true
		worker.return_to_hut()  # Sets state to RETURNING.
		update_labels()
	else:
		print("Invalid worker index: ", index)

func _on_worker_1_switch_job_button_pressed():
	switch_worker_job(0)

func _on_worker_2_switch_job_button_pressed():
	switch_worker_job(1)

func _on_worker_3_switch_job_button_pressed():
	switch_worker_job(2)
