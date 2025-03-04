extends StaticBody2D

# Typed node references
@onready var sprite: Sprite2D = $BuildingSprite
@onready var menu: Control = $HomeBaseStats
@onready var gold_button: Button = $HomeBaseStats/GoldButton
@onready var food_button: Button = $HomeBaseStats/FoodButton
@onready var wood_button: Button = $HomeBaseStats/WoodButton

# Export variables for editor tweaking
@export var highlight_color: Color = Color(1.2, 1.2, 1.2, 1)
@export var highlight_duration: float = 0.2

func _ready() -> void:
	input_event.connect(_on_input_event)
	# Initial UI update
	update_resource_display()
	# Connect to Global resource change signal (if it exists)
	if Global.has_signal("resources_changed"):
		Global.resources_changed.connect(update_resource_display)

func  _process(_delta):
	update_resource_display()

# Update UI when resources change
func update_resource_display() -> void:
	gold_button.text = "Gold: %d" % Global.total_city_gold
	wood_button.text = "Wood: %d" % Global.total_city_wood
	food_button.text = "Food: %d" % Global.total_city_food

func _on_input_event(_viewport: Node, event: InputEvent, _shape_idx: int) -> void:
	if event is InputEventMouseButton and event.is_pressed() and event.button_index == MOUSE_BUTTON_LEFT:
		highlight()
		toggle_menu()

func highlight() -> void:
	sprite.modulate = highlight_color
	await get_tree().create_timer(highlight_duration, false, true).timeout  # Pausable, one-shot timer
	sprite.modulate = Color.WHITE

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

func _notification(what: int) -> void:
	if what == NOTIFICATION_APPLICATION_PAUSED:
		SaveManager.save_game(TimeManager.day_count, TimeManager.time_of_day)
	elif what == NOTIFICATION_APPLICATION_RESUMED:
		update_resource_display()
