extends StaticBody2D

class_name WorkerHut

@onready var sprite: Sprite2D = $WorkerHutSprite
@onready var menu: Control = $MenuPanel

@onready var wood_button: Button = $MenuPanel/VBoxContainer/WorkerHutStats/WoodButton
@onready var food_button: Button = $MenuPanel/VBoxContainer/WorkerHutStats/FoodButton

@onready var worker1_button: Button = $MenuPanel/VBoxContainer/WorkerButtons/Worker1/Worker1Button
@onready var worker2_button: Button = $MenuPanel/VBoxContainer/WorkerButtons/Worker2/Worker2Button
@onready var worker3_button: Button = $MenuPanel/VBoxContainer/WorkerButtons/Worker3/Worker3Button

@onready var worker_scene = preload("res://scenes/worker.tscn")

@onready var marker: Marker2D = $Marker2D

@onready var switch_job_button: Button = $MenuPanel/VBoxContainer/WorkerButtons/Worker1/SwitchJobButton


var workers: Array = []
var current_workers: int = 1
var max_workers: int = 3

var hut_wood: int = 0
var max_wood: int = 30

var hut_food: int = 0
var max_food: int = 30

func _ready() -> void:
	for i in range(current_workers):
		spawn_worker()
	update_worker_spawn_buttons()

func _physics_process(_delta):
	update_labels()

func spawn_worker() -> void:
	if workers.size() >= max_workers:
		print("Worker hut is full!")
		return
	
	var worker = worker_scene.instantiate() as CharacterBody2D
	worker.global_position = marker.global_position   # Spawn near hut
	worker.scale = Vector2(2.0, 2.0)
	worker.workers_hut = self                            # Link worker to this hut
	get_parent().add_child.call_deferred(worker)         # Add to scene
	workers.append(worker)                               # Track worker

# Update UI labels
func update_labels() -> void:
	wood_button.text = "Wood: " + str(hut_wood)
	
	# Loop through each worker slot (assuming max_workers is the total number of slots)
	for i in range(max_workers):
		var button_path = "MenuPanel/VBoxContainer/WorkerButtons/Worker%d/Worker%dButton" % [i + 1, i + 1]
		var label_path = "MenuPanel/VBoxContainer/WorkerButtons/Worker%d/Worker%dStateLabel" % [i + 1, i + 1]
		var fire_button_path = "MenuPanel/VBoxContainer/WorkerButtons/Worker%d/Worker%dFireButton" % [i + 1, i + 1]
		
		var worker_button = get_node_or_null(button_path) as Button
		var worker_state_label = get_node_or_null(label_path) as Label
		var worker_fire_button = get_node_or_null(fire_button_path) as Button
		
		if i < workers.size():
			# A worker exists in this slot
			var worker = workers[i]
			if worker_button:
				# Set the icon from the worker and clear text
				if worker.face_sprite and worker.face_sprite.texture:
					worker_button.icon = worker.face_sprite.texture
					worker_button.text = ""
			if worker_state_label:
				var job_text = "WOOD" if worker.current_job == worker.JobType.CHOP_WOOD else "FOOD"
				worker_state_label.text = job_text

			# Make the fire button visible when a worker exists in this slot
			if worker_fire_button:
				worker_fire_button.visible = true
		else:
			# No worker in this slot, so set the button text to "Add Worker"
			if worker_button:
				worker_button.icon = null
				worker_button.text = "Add Worker"
			if worker_state_label:
				worker_state_label.text = ""
			if worker_fire_button:
				worker_fire_button.visible = false

# Handle input events (e.g., clicking the hut)
func _input_event(_viewport: Node, event: InputEvent, _shape_idx: int) -> void:
	if not _left_mouse_click(event):
		return

	highlight()   # Visual feedback
	toggle_menu() # Show/hide menu

# Check for left mouse click
func _left_mouse_click(event: InputEvent) -> bool:
	return event is InputEventMouseButton and event.is_pressed() and event.button_index == MOUSE_BUTTON_LEFT

# Highlight the hut sprite briefly
func highlight() -> void:
	sprite.modulate = Color(1.2, 1.2, 1.2, 1)  # Brighten
	await get_tree().create_timer(0.2).timeout
	sprite.modulate = Color(1, 1, 1, 1)        # Reset

# Toggle the menu visibility
func toggle_menu() -> void:
	if menu.visible:
		hide_menu()
	else:
		show_menu()

# Show the menu with animation
func show_menu() -> void:
	menu.visible = true
	menu.scale = Vector2.ZERO
	var tween := create_tween()
	tween.tween_property(menu, "scale", Vector2.ONE, 0.3).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)

# Hide the menu with animation
func hide_menu() -> void:
	var tween := create_tween()
	tween.tween_property(menu, "scale", Vector2.ZERO, 0.2).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_IN)
	await tween.finished
	menu.visible = false

# Collect wood when the button is pressed
func _on_collect_button_pressed() -> void:
	Global.total_city_wood += hut_wood  # Add to global wood (assumes Global script exists)
	hut_wood = 0                       # Reset hut wood
	update_labels()                    # Update UI

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

func _on_worker_1_fire_button_pressed() -> void:
	# Fire the worker at index 0 if it exists.
	if workers.size() > 0:
		fire_worker(0)
		update_worker_spawn_buttons()
		update_labels()

func _on_worker_2_fire_button_pressed() -> void:
	# Fire the worker at index 1 if it exists.
	if workers.size() > 1:
		fire_worker(1)
		update_worker_spawn_buttons()
		update_labels()

func _on_worker_3_fire_button_pressed() -> void:
	# Fire the worker at index 2 if it exists.
	if workers.size() > 2:
		fire_worker(2)
		update_worker_spawn_buttons()
		update_labels()

func fire_worker(index: int) -> void:
	if index < 0 or index >= workers.size():
		print("Invalid worker index!")
		return

	var worker_to_fire = workers[index]
	if worker_to_fire and is_instance_valid(worker_to_fire):
		worker_to_fire.queue_free()  # Remove worker from scene
	workers.remove_at(index)  # Remove worker from the array
	update_labels()  # Update your UI, if needed
	
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

func _on_switch_job_button_pressed() -> void:
	for worker in workers:
		worker.current_job = worker.JobType.GATHER_FOOD if worker.current_job == worker.JobType.CHOP_WOOD else worker.JobType.CHOP_WOOD
		worker.find_target_resource()  # Immediately find new target

	update_labels()  # Refresh UI
