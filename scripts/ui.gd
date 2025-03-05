extends CanvasLayer

# Signal with typed parameter
signal camera_target(target: String)

# Typed node references
@onready var menu: Panel = $Control/MenuContainer/HBoxContainer/VBoxContainer2/Menu/MenuPanel
@onready var speed_button: Button = $Control/MenuContainer/HBoxContainer/VBoxContainer2/Menu/MenuPanel/VBoxContainer/SpeedButton

func _on_the_woods_button_pressed() -> void:
	camera_target.emit("woods")

func _on_the_desert_button_pressed() -> void:
	camera_target.emit("desert")

func _on_home_base_pressed() -> void:
	camera_target.emit("home")

func _on_section_3_button_pressed() -> void:
	camera_target.emit("section_3")

func _on_section_4_button_pressed() -> void:
	camera_target.emit("section_4")

func _on_menu_pressed() -> void:
	toggle_menu()

func _on_speed_button_pressed() -> void:
	if TimeManager.time_speed_multiplier == 1.0:
		TimeManager.speed_up_time(2)
		speed_button.text = "Speed x" + str(TimeManager.time_speed_multiplier)
	elif TimeManager.time_speed_multiplier == 2.0:
		TimeManager.speed_up_time(5)
		speed_button.text = "Speed x" + str(TimeManager.time_speed_multiplier)
	elif TimeManager.time_speed_multiplier == 5.0:
		TimeManager.speed_up_time(10)
		speed_button.text = "Speed x" + str(TimeManager.time_speed_multiplier)
	elif TimeManager.time_speed_multiplier == 10.0:
		TimeManager.speed_up_time(50)
		speed_button.text = "Speed x" + str(TimeManager.time_speed_multiplier)
	else:
		TimeManager.speed_up_time(1)
		speed_button.text = "Speed x" + str(TimeManager.time_speed_multiplier)

func _on_skip_button_pressed() -> void:
	TimeManager.skip_hours(1)

func _on_save_button_pressed() -> void:
	toggle_menu()
	SaveManager.save_game(TimeManager.day_count, TimeManager.time_of_day)
	print("SAVED GAME AT DAY ", TimeManager.day_count, TimeManager.time_of_day)

func _on_reset_pressed() -> void:
	toggle_menu()
	await get_tree().create_timer(0.3).timeout
	SaveManager.reset_save()

func toggle_menu() -> void:
	if menu.visible:
		hide_menu()
	else:
		show_menu()

func show_menu() -> void:
	menu.visible = true
	menu.scale = Vector2(0, 0)
	var tween = create_tween()
	tween.tween_property(menu, "scale", Vector2(1, 1), 0.3).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)

func hide_menu() -> void:
	var tween = create_tween()
	tween.tween_property(menu, "scale", Vector2(0, 0), 0.2).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_IN)
	await tween.finished
	menu.visible = false
