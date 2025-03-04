extends StaticBody2D

# Typed node references
@onready var sprite: Sprite2D = $BuildingSprite
@onready var menu: Control = $WorkerHutStats
@onready var wood_button: Button = $WorkerHutStats/WoodButton

# Exported variables for editor tweaking
@export var max_workers: int = 3  # Allow multiple workers per hut
@export var worker_scene: PackedScene  # Assign Worker.tscn in the Inspector
@export var max_wood: int = 250

# Waypoints (Forest & Hut)
@export var forest_waypoint: Vector2 = Vector2(150, 635)
@export var hut_waypoint: Vector2 = Vector2(65, 120)

var workers: Array = []
var hut_wood: int = 0

func _ready() -> void:
	input_event.connect(_on_input_event)  # Modern signal connection
	print("Menu node: ", menu, " Initial visibility: ", menu.visible)  # Check if menu is valid
	# Spawn initial workers
	for i in range(max_workers):
		spawn_worker()

func spawn_worker() -> void:
	if workers.size() >= max_workers:
		print("Worker hut is full!")
		return
	
	var worker = worker_scene.instantiate() as CharacterBody2D
	var spawn_offset := Vector2(randi_range(-20, 20), randi_range(-20, 20))
	worker.global_position = hut_waypoint + spawn_offset
	
	# Unique waypoints for each worker
	#var worker_hut_offset = Vector2(randi_range(-10, 10), randi_range(-10, 10))
	var worker_forest_offset = Vector2(randi_range(-30, 30), randi_range(-30, 30))
	worker.hut_waypoint = hut_waypoint 
	worker.forest_waypoint = forest_waypoint + worker_forest_offset
	
	worker.gathered_wood.connect(_on_gathered_wood)
	get_parent().add_child.call_deferred(worker)
	workers.append(worker)

func _on_gathered_wood(wood: int) -> void:
	if hut_wood + wood <= max_wood:
		hut_wood += wood
		update_labels()

func update_labels() -> void:
	wood_button.text = "Wood: " + str(hut_wood)

func _on_input_event(_viewport: Node, event: InputEvent, _shape_idx: int) -> void:
	if event is InputEventMouseButton and event.is_pressed() and event.button_index == MOUSE_BUTTON_LEFT:
		print("Input event triggered")
		highlight()
		toggle_menu()

func highlight() -> void:
	sprite.modulate = Color(1.2, 1.2, 1.2, 1)
	await get_tree().create_timer(0.2).timeout
	sprite.modulate = Color(1, 1, 1, 1)

func toggle_menu() -> void:
	if menu.visible:
		hide_menu()
	else:
		show_menu()

func show_menu() -> void:
	menu.visible = true
	menu.scale = Vector2.ZERO
	var tween := create_tween()
	tween.tween_property(menu, "scale", Vector2.ONE, 0.3).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)

func hide_menu() -> void:
	var tween := create_tween()
	tween.tween_property(menu, "scale", Vector2.ZERO, 0.2).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_IN)
	await tween.finished
	menu.visible = false

func _on_collect_button_pressed() -> void:
	Global.total_city_wood += hut_wood
	hut_wood = 0
	update_labels()
