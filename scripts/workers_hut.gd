extends StaticBody2D

class_name WorkerHut

@onready var sprite: Sprite2D = $WorkerHutSprite
@onready var menu: Control = $MenuPanel

@onready var wood_button: Button = $MenuPanel/VBoxContainer/WorkerHutStats/WoodButton
@onready var food_button: Button = $MenuPanel/VBoxContainer/WorkerHutStats/FoodButton

@onready var worker1_button: Button = $MenuPanel/VBoxContainer/WorkerButtons/Worker1/Worker1Button
@onready var worker1_state_lable: Label = $MenuPanel/VBoxContainer/WorkerButtons/Worker1/Worker1StateLabel

@onready var worker2_button: Button = $MenuPanel/VBoxContainer/WorkerButtons/Worker2/Worker2Button
@onready var worker2_state_lable: Label = $MenuPanel/VBoxContainer/WorkerButtons/Worker2/Worker2StateLabel

@onready var worker3_button: Button = $MenuPanel/VBoxContainer/WorkerButtons/Worker3/Worker3Button
@onready var worker3_state_lable: Label = $MenuPanel/VBoxContainer/WorkerButtons/Worker3/Worker3StateLabel

@onready var worker_scene = preload("res://scenes/Worker.tscn")

#@onready var tilemap: TileMapLayer = $TilemapLayers/Ground
#@export var tile_position: Vector2
#var hut_waypoint: Vector2 # Where workers return to

var workers: Array = []       # List of spawned workers
var current_workers: int = 1
var max_workers: int = 3      # Maximum number of workers

var hut_wood: int = 0         # Wood stored in the hut
var max_wood: int = 30        # Maximum wood capacity (not enforced here)

var hut_food: int = 0
var max_food: int = 30

func _ready() -> void:
	#hut_waypoint = tilemap.map_to_local(tile_position)
	worker1_button.disabled = true
	worker2_button.disabled = false
	worker3_button.disabled = true
	for i in range(current_workers):
		spawn_worker()       # Spawn initial workers

func _physics_process(delta):
	update_labels()

# Spawn a new worker
func spawn_worker() -> void:
	if workers.size() >= max_workers:
		print("Worker hut is full!")
		return
	
	var worker = worker_scene.instantiate() as CharacterBody2D
	var spawn_offset := Vector2(randi_range(-20, 20), randi_range(-20, 20))
	worker.global_position = self.global_position  # Spawn near hut
	worker.workers_hut = self                            # Link worker to this hut
	get_parent().add_child.call_deferred(worker)         # Add to scene
	workers.append(worker)                               # Track worker

# Update UI labels
func update_labels() -> void:
	wood_button.text = "Wood: " + str(hut_wood)

	for i in workers.size():
		var worker = workers[i]

		# Adjusted paths considering your real UI structure:
		var button_path = "MenuPanel/VBoxContainer/WorkerButtons/Worker%d/Worker%dButton" % [i + 1, i + 1]
		var label_path = "MenuPanel/VBoxContainer/WorkerButtons/Worker%d/Worker%dStateLabel" % [i + 1, i + 1]

		var worker_button = get_node_or_null(button_path) as Button
		var worker_state_label = get_node_or_null(label_path) as Label

		if worker_button and worker.face_sprite and worker.face_sprite.texture:
			worker_button.icon = worker.face_sprite.texture

		if worker_state_label:
			match worker.current_state:
				"chopping_tree":
					worker_state_label.text = "Chopping"
				"going_to_tree":
					worker_state_label.text = "Finding"
				"returning_to_hut":
					worker_state_label.text = "Returning"
				_:
					worker_state_label.text = "Idle"

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

func _on_worker_2_button_pressed():
	spawn_worker()
	await get_tree().process_frame  # Wait one frame to ensure nodes are initialized
	await get_tree().process_frame  # Wait one frame to ensure nodes are initialized
	worker2_button.disabled = true
	
	if workers.size() > 1 and workers[1].face_sprite and workers[1].face_sprite.texture:
		worker2_button.icon = workers[1].face_sprite.texture
	else:
		print("Worker2 face_sprite or texture not ready yet.")
	
	worker3_button.disabled = false

func _on_worker_3_button_pressed():
	spawn_worker()
	await get_tree().process_frame  # Wait one frame to ensure nodes are initialized
	await get_tree().process_frame  # Wait one frame to ensure nodes are initialized
	worker3_button.disabled = true

	if workers.size() > 2 and workers[2].face_sprite and workers[2].face_sprite.texture:
		worker3_button.icon = workers[2].face_sprite.texture
	else:
		print("Worker3 face_sprite or texture not ready yet.")
