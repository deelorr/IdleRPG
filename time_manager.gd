extends Node

var current_day: int = 1
var current_time: float = 0.0

func _ready():
	# Load saved data only if the player chooses "Load Game"
	if SaveSystem.load_game():
		load_progress()

func load_progress():
	var loaded_data = SaveSystem.load_game()
	if loaded_data:
		current_day = loaded_data.get("day", 1)
		current_time = loaded_data.get("time", 0.0)

		update_clock()  # Refresh the UI after loading

func save_progress():
	SaveSystem.save_game(current_day, current_time)

func update_clock():
	var hours = int(current_time)
	var minutes = int((current_time - hours) * 60)
	var formatted_time = "%02d:%02d" % [hours, minutes]
	
	var clock_label = get_node_or_null("CanvasLayer/ClockLabel")  # Adjust path if needed
	if clock_label:
		clock_label.text = formatted_time
	else:
		print("Error: Clock UI node not found in scene!")
