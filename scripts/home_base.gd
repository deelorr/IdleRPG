extends StaticBody2D

@onready var sprite: Sprite2D = $BuildingSprite
@onready var menu: Control = $HomeBaseStats
@onready var gold_button: Button = $HomeBaseStats/GoldButton
@onready var food_button: Button = $HomeBaseStats/FoodButton
@onready var wood_button: Button = $HomeBaseStats/WoodButton

func _ready() -> void:
	Global.resource_changed.connect(update_home_resource_display)
	update_home_resource_display()

func update_home_resource_display() -> void:
	gold_button.text = "Gold: %d" % Global.total_city_gold
	wood_button.text = "Wood: %d" % Global.total_city_wood
	food_button.text = "Food: %d" % Global.total_city_food

func _input_event(_viewport, event: InputEvent, _shape_idx) -> void:
	if event is InputEventMouseButton and event.is_pressed() and event.button_index == MOUSE_BUTTON_LEFT:
		highlight()
		toggle_menu()

func highlight() -> void:
	sprite.modulate = Color(1.2, 1.2, 1.2, 1)
	await get_tree().create_timer(0.2, false, true).timeout  # Pausable, one-shot timer
	sprite.modulate = Color.WHITE

func toggle_menu() -> void:
	var tween := create_tween()
	if menu.visible:
		tween.tween_property(menu, "scale", Vector2.ZERO, 0.2).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_IN)
		await tween.finished
		menu.visible = false
	else:
		menu.visible = true
		menu.scale = Vector2.ZERO
		tween.tween_property(menu, "scale", Vector2.ONE, 0.3).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)

func _notification(what: int) -> void:
	if what == NOTIFICATION_APPLICATION_PAUSED:
		SaveManager.save_game(TimeManager.day_count, TimeManager.time_of_day)
	elif what == NOTIFICATION_APPLICATION_RESUMED:
		update_home_resource_display()
