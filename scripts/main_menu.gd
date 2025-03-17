extends Control

const MAIN_SCREEN: String = "res://scenes/MainScreen.tscn"

@onready var fade_rect: ColorRect = $FadeRect
@onready var tap_label: Label = $TapLabel

var fade_duration: float = 0.3
var pulse_duration: float = 0.5

func _ready() -> void:
	fade_rect.modulate.a = 0.0  # Ensure float precision
	tap_label.modulate.a = 1.0
	pulse_label()

func pulse_label() -> void:
	var tween := create_tween().set_loops()  # Infinite loop
	tween.tween_property(tap_label, "modulate:a", 0.0, pulse_duration)\
		.set_trans(Tween.TRANS_SINE)\
		.set_ease(Tween.EASE_IN_OUT)
	tween.tween_property(tap_label, "modulate:a", 1.0, pulse_duration)\
		.set_trans(Tween.TRANS_SINE)\
		.set_ease(Tween.EASE_IN_OUT)

func _input(event: InputEvent) -> void:
	if event is InputEventScreenTouch and event.is_pressed() or \
	   event is InputEventMouseButton and event.is_pressed() and event.button_index == MOUSE_BUTTON_LEFT:
		# Disable input cleanly
		set_process_input(false)
		await fade_out()
		load_game()

func fade_out() -> void:
	var tween := create_tween()
	tween.tween_property(fade_rect, "modulate:a", 1.0, fade_duration)\
		.set_trans(Tween.TRANS_LINEAR)\
		.set_ease(Tween.EASE_IN)
	await tween.finished

func load_game() -> void:
	if FileAccess.file_exists("user://savegame.json"):
		get_tree().change_scene_to_file(MAIN_SCREEN)
		SaveManager.load_game()
	else:
		get_tree().change_scene_to_file(MAIN_SCREEN)
