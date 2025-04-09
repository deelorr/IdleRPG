extends StaticBody2D
class_name WorkerHut

# === NODE REFERENCES ===
# Sprites
@onready var sprite: Sprite2D = $WorkerHutSprite

# UI Elements: Main Menu Panel and Buttons
@onready var menu: Control = $MenuPanel
@onready var wood_button: Button = $MenuPanel/MarginContainer/VBoxContainer/WorkerHutStats/WoodButton
@onready var food_button: Button = $MenuPanel/MarginContainer/VBoxContainer/WorkerHutStats/FoodButton

# Worker UI Components
@onready var worker_buttons = [
	$MenuPanel/MarginContainer/VBoxContainer/WorkerButtons/Worker1/Worker1Button,
	$MenuPanel/MarginContainer/VBoxContainer/WorkerButtons/Worker2/Worker2Button,
	$MenuPanel/MarginContainer/VBoxContainer/WorkerButtons/Worker3/Worker3Button ]
@onready var fire_buttons = [
	$MenuPanel/MarginContainer/VBoxContainer/WorkerButtons/Worker1/Worker1FireButton,
	$MenuPanel/MarginContainer/VBoxContainer/WorkerButtons/Worker2/Worker2FireButton,
	$MenuPanel/MarginContainer/VBoxContainer/WorkerButtons/Worker3/Worker3FireButton ]
@onready var worker_state_labels = [
	$MenuPanel/MarginContainer/VBoxContainer/WorkerButtons/Worker1/Worker1StateLabel,
	$MenuPanel/MarginContainer/VBoxContainer/WorkerButtons/Worker2/Worker2StateLabel,
	$MenuPanel/MarginContainer/VBoxContainer/WorkerButtons/Worker3/Worker3StateLabel ]
@onready var worker_job_labels = [
	$MenuPanel/MarginContainer/VBoxContainer/WorkerButtons/Worker1/JobLabel,
	$MenuPanel/MarginContainer/VBoxContainer/WorkerButtons/Worker2/JobLabel,
	$MenuPanel/MarginContainer/VBoxContainer/WorkerButtons/Worker3/JobLabel ]
@onready var worker_level_labels = [
	$MenuPanel/MarginContainer/VBoxContainer/WorkerButtons/Worker1/LevelLabel,
	$MenuPanel/MarginContainer/VBoxContainer/WorkerButtons/Worker2/LevelLabel,
	$MenuPanel/MarginContainer/VBoxContainer/WorkerButtons/Worker3/LevelLabel ]
@onready var worker_carried_wood_labels = [
	$MenuPanel/MarginContainer/VBoxContainer/WorkerButtons/Worker1/WoodLabel,
	$MenuPanel/MarginContainer/VBoxContainer/WorkerButtons/Worker2/WoodLabel,
	$MenuPanel/MarginContainer/VBoxContainer/WorkerButtons/Worker3/WoodLabel ]
@onready var worker_carried_food_labels = [
	$MenuPanel/MarginContainer/VBoxContainer/WorkerButtons/Worker1/FoodLabel,
	$MenuPanel/MarginContainer/VBoxContainer/WorkerButtons/Worker2/FoodLabel,
	$MenuPanel/MarginContainer/VBoxContainer/WorkerButtons/Worker3/FoodLabel ]

# Scene/Position References
@onready var worker_scene = preload("res://scenes/ForestWorker.tscn")
@onready var spawn_marker: Marker2D = $SpawnMarker
@onready var menu_anchor: Marker2D = $MenuAnchor

# === GAME STATE VARIABLES ===
var workers: Array = []
var max_workers: int = 3
var hut_wood: int = 0
var hut_food: int = 0

# === GAME LOOP ===
func _physics_process(_delta: float) -> void:
	update_resource_buttons()
	update_worker_ui()

# === UI UPDATE FUNCTIONS ===
func update_resource_buttons() -> void:
	wood_button.text = "Wood: %d" % hut_wood
	food_button.text = "Food: %d" % hut_food

func update_worker_ui() -> void:
	for i in range(max_workers):
		if i < workers.size():
			update_worker_slot(i, workers[i])
		else:
			clear_worker_slot(i)

func update_worker_slot(index: int, worker: Worker) -> void:
	worker_state_labels[index].text = str(worker.WorkerState.keys()[worker.current_state])
	worker_job_labels[index].text = str(worker.WorkerJob.keys()[worker.current_job])
	worker_level_labels[index].text = "LVL: %d" % worker.current_level
	worker_carried_wood_labels[index].text = "%d / %d" % [worker.carried_wood, worker.get_wood_capacity()]
	worker_carried_food_labels[index].text = "%d / %d" % [worker.carried_food, worker.get_food_capacity()]

	if worker.face_sprite and worker.face_sprite.texture:
		worker_buttons[index].icon = worker.face_sprite.texture
		worker_buttons[index].text = ""
	else:
		worker_buttons[index].icon = null
		worker_buttons[index].text = "Worker %d" % (index + 1)

	fire_buttons[index].visible = true

func clear_worker_slot(index: int) -> void:
	worker_state_labels[index].text = ""
	worker_job_labels[index].text = ""
	worker_level_labels[index].text = ""
	worker_carried_wood_labels[index].text = ""
	worker_carried_food_labels[index].text = ""

	worker_buttons[index].icon = null
	worker_buttons[index].text = "Add Worker"

	fire_buttons[index].visible = false

func update_worker_spawn_buttons() -> void:
	for i in range(worker_buttons.size()):
		worker_buttons[i].disabled = (workers.size() != i)
	if workers.size() >= max_workers:
		for button in worker_buttons:
			button.disabled = true

# === UI INTERACTIONS (CLICK EVENTS) ===
func _input_event(_viewport, event: InputEvent, _shape_idx) -> void:
	if event is InputEventMouseButton and event.is_pressed() and event.button_index == MOUSE_BUTTON_LEFT:
		highlight()
		toggle_menu()

func highlight() -> void:
	sprite.modulate = Color(1.2, 1.2, 1.2, 1)
	await get_tree().create_timer(0.2).timeout
	sprite.modulate = Color(1, 1, 1, 1)

func toggle_menu() -> void:
	var tween := create_tween()
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

# === BUTTON ACTIONS ===
func _on_collect_button_pressed() -> void:
	Global.total_city_wood += hut_wood
	Global.total_city_food += hut_food
	hut_wood = 0
	hut_food = 0
	update_resource_buttons()

# Worker Spawn Buttons
func _on_worker_1_button_pressed(): on_worker_button_pressed(0)
func _on_worker_2_button_pressed(): on_worker_button_pressed(1)
func _on_worker_3_button_pressed(): on_worker_button_pressed(2)

func on_worker_button_pressed(index: int) -> void:
	if workers.size() == index:
		spawn_worker()
		update_worker_spawn_buttons()
		update_resource_buttons()
	else:
		print("Worker slot %d cannot be filled right now. Current worker count: %d" % [index + 1, workers.size()])

func spawn_worker() -> void:
	if workers.size() >= max_workers:
		print("Worker hut is full!")
		return

	var worker = worker_scene.instantiate() as CharacterBody2D
	worker.global_position = spawn_marker.global_position
	worker.scale = Vector2(2.0, 2.0)
	worker.home_hut = self
	get_parent().add_child.call_deferred(worker)
	workers.append(worker)

# Worker Fire Buttons
func _on_worker_1_fire_button_pressed(): on_worker_fire_button_pressed(0)
func _on_worker_2_fire_button_pressed(): on_worker_fire_button_pressed(1)
func _on_worker_3_fire_button_pressed(): on_worker_fire_button_pressed(2)

func on_worker_fire_button_pressed(index: int) -> void:
	if index >= 0 and index < workers.size():
		fire_worker(index)

func fire_worker(index: int) -> void:
	if index < 0 or index >= workers.size():
		print("Invalid worker index!")
		return

	var worker_to_fire = workers[index]
	if worker_to_fire and is_instance_valid(worker_to_fire):
		worker_to_fire.queue_free()
	workers.remove_at(index)
	clear_worker_slot(index)
	update_worker_spawn_buttons()
	update_resource_buttons()

# Worker Switch Job Buttons
func _on_worker_1_switch_job_button_pressed(): on_worker_switch_job_pressed(0)
func _on_worker_2_switch_job_button_pressed(): on_worker_switch_job_pressed(1)
func _on_worker_3_switch_job_button_pressed(): on_worker_switch_job_pressed(2)

func on_worker_switch_job_pressed(index: int) -> void:
	switch_worker_job(index)

func switch_worker_job(index: int) -> void:
	if index >= 0 and index < workers.size():
		var worker = workers[index]
		if worker.target_resource:
			worker.target_resource.is_targeted = false
			worker.target_resource.targeted_by = null
			worker.target_resource = null
		worker.pending_job_switch = true
		worker.return_to_hut()
		update_resource_buttons()
	else:
		print("Invalid worker index: ", index)
