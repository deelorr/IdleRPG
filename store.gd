extends Area2D

@onready var sprite = $Sprite2D  # Adjust if your sprite is named differently
@onready var menu = $Menu  # Adjust if the menu node is named differently
@onready var button1 = $Menu/GridContainer/Button

var gold: int = 500
var gold_per_second: int = 5  # Adjust how much gold you gain per second

func _ready():
	connect("input_event", _on_input_event)

func _on_input_event(viewport, event, shape_idx):
	if event is InputEventMouseButton and event.pressed:
		if event.button_index == MOUSE_BUTTON_LEFT:  # Only reacts to left-click
			print("Building clicked!")  # Debug check
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
	
	button1.text = str(int(gold))  # Force update when opening menu

func hide_menu():
	var tween = get_tree().create_tween()
	tween.tween_property(menu, "scale", Vector2(0, 0), 0.2).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_IN)
	await tween.finished
	menu.visible = false

func _on_timer_timeout() -> void:
	gold += gold_per_second
	button1.text = str(gold)
	
func _notification(what):
	if what == NOTIFICATION_WM_CLOSE_REQUEST:  # When the player closes the game
		save_last_time()
		get_tree().quit()

func save_last_time():
	var file = FileAccess.open("user://save_data.cfg", FileAccess.WRITE)
	file.store_line(str(Time.get_unix_time_from_system()))  # Save the current timestamp
	file.store_line(str(gold))  # Save current gold
	file.close()
