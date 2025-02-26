extends Area2D

@onready var sprite = $BuildingSprite
@onready var menu = $WorkerHutStats
@onready var wood_button = $WorkerHutStats/WoodButton
@onready var food_button = $WorkerHutStats/FoodButton

var wood: float = 0.0
var wood_per_second: float = 0.5
var max_wood: float = 250.0

var food: float = 0.0
var food_per_second: float = 0.75
var max_food: float = 250.0

func _ready():
	connect("input_event", _on_input_event)

func _process(delta):
	wood = clamp(wood + wood_per_second * delta, 0, max_wood)
	food = clamp(food + food_per_second * delta, 0, max_food)
	update_labels()

func update_labels():
	wood_button.text = "Wood: " + str(int(wood))
	food_button.text = "Food: " + str(int(food))

func _on_input_event(_viewport, event, _shape_idx):
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		highlight()
		toggle_menu()

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

func _on_wood_button_pressed() -> void:
	wood = clamp(wood + 1, 0, max_wood)
	update_labels()

func _on_food_button_pressed() -> void:
	food = clamp(food + 1, 0, max_food)
	update_labels()

func _on_collect_button_pressed() -> void:
	Global.total_city_food += food
	Global.total_city_wood += wood
	food = 0
	wood = 0
	update_labels()
