extends StaticBody2D

class_name WorkerHut

@onready var sprite: Sprite2D = $WorkerHutSprite
@onready var menu: Control = $WorkerHutStats
@onready var wood_button: Button = $WorkerHutStats/WoodButton
@onready var food_button: Button = $WorkerHutStats/FoodButton
@onready var worker_scene = preload("res://scenes/Worker.tscn")
@onready var tilemap: TileMapLayer = get_parent()

@export var tile_position: Vector2

var hut_waypoint: Vector2 # Where workers return to

var workers: Array = []       # List of spawned workers
var current_workers: int = 1
var max_workers: int = 3      # Maximum number of workers

var hut_wood: int = 0         # Wood stored in the hut
var max_wood: int = 30        # Maximum wood capacity (not enforced here)

var hut_food: int = 0
var max_food: int = 30

func _ready() -> void:
	hut_waypoint = tilemap.map_to_local(tile_position)
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
	var spawn_offset := Vector2(randi_range(-5, 5), randi_range(-5, 5))
	worker.global_position = hut_waypoint + spawn_offset  # Spawn near hut
	worker.workers_hut = self                            # Link worker to this hut
	get_parent().add_child.call_deferred(worker)         # Add to scene
	workers.append(worker)                               # Track worker

# Update UI labels
func update_labels() -> void:
	wood_button.text = "Wood: " + str(hut_wood)

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
