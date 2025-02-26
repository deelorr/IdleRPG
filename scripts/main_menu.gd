extends Control

const GAME_SCENE = "res://scenes/MainScreen.tscn"

@onready var fade_rect = $FadeRect
@onready var tap_label = $TapLabel

func _ready():
	# Enable input processing
	set_process_input(true)
	
	# Ensure the fade rect starts fully transparent and the label is visible.
	fade_rect.modulate.a = 0
	tap_label.modulate.a = 1
	
	# Start the pulsing effect on the tap label.
	pulse_label()

func pulse_label():
	var tween = get_tree().create_tween()
	# Tween the label's alpha from 1 to 0 over 0.5 seconds...
	tween.tween_property(tap_label, "modulate:a", 0.0, 0.5)
	# ...then chain another tween from 0 back to 1 over 0.5 seconds.
	tween.chain().tween_property(tap_label, "modulate:a", 1.0, 0.5)
	await tween.finished
	# When done, start the pulse again.
	pulse_label()

func _input(event):
	# Detect a tap (screen touch or mouse click)
	if (event is InputEventScreenTouch and event.pressed) or (event is InputEventMouseButton and event.pressed):
		# Disable further input to prevent multiple triggers.
		set_process_input(false)
		
		# Optionally play a tap sound if available.
		
		# Fade out the screen before transitioning by tweening the alpha of the fade rect.
		var tween = get_tree().create_tween()
		tween.tween_property(fade_rect, "modulate:a", 1, 0.3)
		await tween.finished
		
		# Transition to the main game scene.
		if FileAccess.file_exists("user://savegame.json"):
			get_tree().change_scene_to_file(GAME_SCENE)
			SaveManager.load_game()
		else:
			get_tree().change_scene_to_file(GAME_SCENE)
