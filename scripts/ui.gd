extends CanvasLayer

signal camera_target(target: String)

@onready var menu: TabContainer = $Control/MenuContainer/HBoxContainer/VBoxContainer2/Menu/TabContainer
@onready var speed_button: Button = $Control/MenuContainer/HBoxContainer/VBoxContainer2/Menu/TabContainer/Debug/MarginContainer/DebugBox/SpeedButton
@onready var pause_button : Button = $Control/MenuContainer/HBoxContainer/VBoxContainer2/Menu/TabContainer/Settings/MarginContainer/SettingsBox/PauseButton
@onready var plus_hut_button: Button = $Control/MenuContainer/HBoxContainer/VBoxContainer2/Menu/TabContainer/Debug/MarginContainer/DebugBox/HBoxContainer/PlusHutButton
@onready var minus_hut_button: Button = $Control/MenuContainer/HBoxContainer/VBoxContainer2/Menu/TabContainer/Debug/MarginContainer/DebugBox/HBoxContainer/MinusHutButton

var current_hut_count: int = 1
const MAX_HUTS := 3

# Access worker huts via parent (MainScreen)
@onready var hut1: Node = get_parent().get_node("WorkerHut")
@onready var hut2: Node = get_parent().get_node("WorkerHut2")
@onready var hut3: Node = get_parent().get_node("WorkerHut3")

func _on_plus_hut_button_pressed() -> void:
	if current_hut_count < MAX_HUTS:
		current_hut_count += 1
		match current_hut_count:
			2:
				hut2.visible = true
			3:
				hut3.visible = true

func _on_minus_hut_button_pressed() -> void:
	if current_hut_count > 1:
		match current_hut_count:
			2:
				hut2.visible = false
			3:
				hut3.visible = false
		current_hut_count -= 1

func _on_the_woods_button_pressed() -> void:
	camera_target.emit("woods")

func _on_the_desert_button_pressed() -> void:
	camera_target.emit("desert")

func _on_home_base_pressed() -> void:
	camera_target.emit("home")

func _on_section_3_button_pressed() -> void:
	camera_target.emit("snow")

func _on_section_4_button_pressed() -> void:
	camera_target.emit("cave")

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
	var tween := create_tween()
	if menu.visible:
		tween.tween_property(menu, "scale", Vector2.ZERO, 0.2).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_IN)
		await tween.finished
		menu.visible = false
	else:
		menu.visible = true
		menu.scale = Vector2.ZERO
		tween.tween_property(menu, "scale", Vector2.ONE, 0.3).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)

func _on_pause_button_pressed():
	Global.toggle_pause()
	update_pause_button_text()
	
func update_pause_button_text():
	if Global.is_game_paused:
		pause_button.text = "Resume"
	else:
		pause_button.text = "Pause"
