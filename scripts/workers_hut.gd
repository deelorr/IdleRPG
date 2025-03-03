extends Area2D

@onready var sprite = $BuildingSprite
@onready var menu = $WorkerHutStats
@onready var wood_button = $WorkerHutStats/WoodButton
@onready var food_button = $WorkerHutStats/FoodButton
@onready var worker = $Worker

var hut_wood: int = 0
var max_wood: int = 250

var hut_food: int = 0
var max_food: int = 250

func _ready():
	connect("input_event", _on_input_event)
	worker.gathered_wood.connect(_on_gathered_wood)

func _process(_delta):
	update_labels()

func update_labels():
	wood_button.text = "Wood: " + str(int(hut_wood))
	food_button.text = "Food: " + str(int(hut_food))

func _on_input_event(_viewport, event, _shape_idx):
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		highlight()
		toggle_menu()
		
func _on_gathered_wood(wood):
	hut_wood += wood
	
func highlight():
	sprite.modulate = Color(1.2, 1.2, 1.2, 1)  #Lighten
	await get_tree().create_timer(0.2).timeout
	sprite.modulate = Color(1, 1, 1, 1)  #Reset

func toggle_menu():
	if menu.visible:
		hide_menu()
	else:
		show_menu()

func show_menu():
	menu.visible = true
	menu.scale = Vector2(0, 0)
	var tween = get_tree().create_tween()
	tween.tween_property(menu, "scale", Vector2(1, 1), 0.3).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)

func hide_menu():
	var tween = get_tree().create_tween()
	tween.tween_property(menu, "scale", Vector2(0, 0), 0.2).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_IN)
	await tween.finished
	menu.visible = false
		
func _notification(what):
	if what == NOTIFICATION_APPLICATION_PAUSED:
		SaveManager.save_game(TimeManager.day_count, TimeManager.time_of_day)

func _on_collect_button_pressed() -> void:
	Global.total_city_food += hut_food
	Global.total_city_wood += hut_wood
	hut_food = 0
	hut_wood = 0
	update_labels()
