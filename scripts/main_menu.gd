extends Control

const GAME_SCENE = "res://scenes/MainScreen.tscn"

@onready var fade_rect = $FadeRect
@onready var tap_label = $TapLabel

func _ready():
	set_process_input(true) #Enable input processing
	fade_rect.modulate.a = 0
	tap_label.modulate.a = 1
	pulse_label()

func pulse_label():
	var tween = get_tree().create_tween()
	tween.tween_property(tap_label, "modulate:a", 0.0, 0.5)
	tween.chain().tween_property(tap_label, "modulate:a", 1.0, 0.5)
	await tween.finished
	pulse_label()

func _input(event):
	if (event is InputEventScreenTouch and event.pressed) or (event is InputEventMouseButton and event.pressed):
		set_process_input(false)
		var tween = get_tree().create_tween()
		tween.tween_property(fade_rect, "modulate:a", 1, 0.3)
		await tween.finished
		
		if FileAccess.file_exists("user://savegame.json"):
			get_tree().change_scene_to_file(GAME_SCENE)
			SaveManager.load_game()
		else:
			get_tree().change_scene_to_file(GAME_SCENE)
