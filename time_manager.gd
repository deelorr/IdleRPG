extends Node


@export var real_seconds_per_in_game_minute := 10.0  # 12 real seconds = 1 in-game minute
@export var hours_in_day := 24  # Defines a full in-game day as 24 hours
@export var transition_duration := 0.1  # Controls how smooth the sunrise transition is

var time_of_day := 0.0  # 0 = Morning, 1 = Night
var day_count := 1  # Tracks the in-game day
var direction := 1  # 1 = Day -> Night, -1 = Night -> Day
var last_displayed_minute := -1  # Tracks the last displayed in-game minute

@export var time_speed_multiplier := 1.0  # Default time speed

var time_paused := false  # Tracks whether time is paused

func update_clock():
	var hours = int(time_of_day)
	var minutes = int((time_of_day - hours) * 60)
	var formatted_time = "%02d:%02d" % [hours, minutes]
	
	var clock_label = get_node_or_null("CanvasLayer/ClockLabel")  # Adjust path if needed
	if clock_label:
		clock_label.text = formatted_time
	else:
		print("Error: Clock UI node not found in scene!")
