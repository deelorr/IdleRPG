extends Area2D

@onready var sprite = $BuildingSprite
@onready var menu = $WorkerHutStats
@onready var wood_button = $WorkerHutStats/WoodButton
@onready var food_button = $WorkerHutStats/FoodButton

var wood: int = 0
var wood_per_second: int = 5
var max_wood: int = 250

var food: int = 0
var food_per_second: int = 5
var max_food: int = 250

func _ready():
	connect("input_event", _on_input_event)

func _on_input_event(_viewport, event, _shape_idx):
	if event is InputEventMouseButton and event.pressed:
		if event.button_index == MOUSE_BUTTON_LEFT:  # Only reacts to left-click
			highlight()
			toggle_menu()

func highlight():
	sprite.modulate = Color(1.2, 1.2, 1.2, 1)  # Lighten the sprite
	await get_tree().create_timer(0.2).timeout  # Keep it lit briefly
	sprite.modulate = Color(1, 1, 1, 1)  # Reset to normal

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

#func _notification(what):
	#if what == NOTIFICATION_APPLICATION_PAUSED:  # iPhone swipe-out or backgrounded
		#SaveManager.save_game(TimeManager.day_count, TimeManager.time_of_day)
		#get_tree().quit()
		
func _notification(what):
	if what == NOTIFICATION_APPLICATION_PAUSED:
		# Save the game state when the app goes to the background
		SaveManager.save_game(TimeManager.day_count, TimeManager.time_of_day)

func _on_wood_button_pressed() -> void:
	wood = clamp(wood + 1, 0, max_wood)
	wood_button.text = "Wood: " + str(wood)

func _on_food_button_pressed() -> void:
	food = clamp(food + 1, 0, max_food)
	food_button.text = "Food: " + str(food)

func _on_collect_button_pressed() -> void:
	Global.total_city_food += food
	food = 0
	food_button.text = "Food: " + str(food)
	Global.total_city_wood += wood
	wood = 0
	wood_button.text = "Wood: " + str(wood)

func _on_food_timer_timeout() -> void:
	food = clamp(food + food_per_second, 0, max_food)
	food_button.text = "Food: " + str(food)

func _on_wood_timer_timeout() -> void:
	wood = clamp(wood + wood_per_second, 0, max_wood)
	wood_button.text = "Wood: " + str(wood)
