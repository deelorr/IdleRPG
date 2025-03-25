extends Control
class_name TextBox

signal finished

@onready var story_label: Label = $Panel/VBoxContainer/StoryLabel
@onready var speaker_label: Label = $Panel/VBoxContainer/SpeakerLabel
@onready var next_button: Button = $Panel/VBoxContainer/NextButton
@onready var box := $Panel


var lines: Array = []
var current_index := 0
var is_typing := false
var skip_typing := false
var text_speed := 0.03  # Seconds per character

func _ready():
	hide()

func fade_in():
	box.modulate.a = 0.0
	box.scale = Vector2(0.9, 0.9)
	show()

	var tween := create_tween()
	tween.tween_property(box, "modulate:a", 1.0, 0.3).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	tween.parallel().tween_property(box, "scale", Vector2(1, 1), 0.3).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)

func fade_out():
	var tween := create_tween()
	tween.tween_property(box, "modulate:a", 0.0, 0.2).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN)
	tween.parallel().tween_property(box, "scale", Vector2(0.9, 0.9), 0.2).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN)
	await tween.finished
	hide()

func show_text_sequence(text_lines: Array):
	lines = text_lines
	current_index = 0
	fade_in()
	show_line()
	
func _unhandled_input(event):
	if get_tree().paused or not visible:
		return
	
	if event is InputEventMouseButton and event.pressed:
		_on_next_button_pressed()
	elif event is InputEventKey and event.pressed:
		if event.keycode == KEY_SPACE or event.keycode == KEY_ENTER:
			_on_next_button_pressed()

func show_line():
	if current_index >= lines.size():
		await fade_out()
		finished.emit()
		return

	var line_data = lines[current_index]
	var speaker = ""
	var text = ""

	if typeof(line_data) == TYPE_STRING:
		speaker = "Narrator"
		text = line_data
	elif typeof(line_data) == TYPE_DICTIONARY:
		speaker = line_data.get("speaker", "???")
		text = line_data.get("text", "")

	speaker_label.text = speaker
	story_label.text = ""  # Clear first
	# Start typewriter effect
	type_text(text)

func type_text(full_text: String) -> void:
	is_typing = true
	skip_typing = false
	story_label.text = ""

	for i in full_text.length():
		if skip_typing:
			break
		story_label.text += full_text[i]
		await get_tree().create_timer(text_speed, false).timeout

	story_label.text = full_text
	is_typing = false


func _on_next_button_pressed():
	if is_typing:
		skip_typing = true
	else:
		current_index += 1
		show_line()
