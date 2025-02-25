extends Area2D

@onready var sprite = $BuildingSprite
@onready var menu = $HomeBaseStats
@onready var gold_button = $HomeBaseStats/GoldButton

var gold = Global.total_city_gold
var food = Global.total_city_food
var wood = Global.total_city_wood

func _ready():
	connect("input_event", _on_input_event)
	
func _process(_delta: float) -> void:
	gold_button.text = "Gold: " + str(gold)

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
		
func _notification(what):
	if what == NOTIFICATION_APPLICATION_PAUSED:
		# Save the game state when the app goes to the background
		SaveManager.save_game(TimeManager.day_count, TimeManager.time_of_day)
