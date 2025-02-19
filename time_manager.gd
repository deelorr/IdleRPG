extends Node

signal time_changed(time_of_day, day_count)

@export var real_seconds_per_in_game_minute := 12.0  # 12 real seconds = 1 in-game minute
@export var hours_in_day := 24  # Defines a full in-game day as 24 hours
@export var transition_duration := 0.1  # Controls how smooth the sunrise transition is
@export var time_speed_multiplier := 1.0  # Default time speed

var time_of_day := 0.0  # 0 = Morning, 1 = Night
var day_count := 1  # Tracks the in-game day
var direction := 1  # 1 = Day -> Night, -1 = Night -> Day
var last_displayed_minute := -1  # Tracks the last displayed in-game minute
var time_paused := false  # Tracks whether time is paused
var in_game_hours = int(time_of_day * hours_in_day)  # Scales time_of_day to 24-hour format
var in_game_minutes = int(fmod(time_of_day * hours_in_day * 60, 60))  # Gets the fractional minutes

func _process(delta):
	if time_paused:
		return  # Stop updating if time is paused

	# Adjust time based on speed multiplier
	time_of_day += ((delta / (real_seconds_per_in_game_minute * hours_in_day * 60)) * direction) * time_speed_multiplier

	# Handle day rollover
	if time_of_day >= 1.0:
		time_of_day = 0.0  # Reset to midnight
		day_count += 1  # Increment day counter

	# Recalculate current time values
	in_game_hours = int(time_of_day * hours_in_day)
	in_game_minutes = int(fmod(time_of_day * hours_in_day * 60, 60))

	if in_game_minutes != last_displayed_minute:
		last_displayed_minute = in_game_minutes
		emit_signal("time_changed", time_of_day, day_count)

func skip_hours(hours: int) -> void:
	time_of_day += float(hours) / hours_in_day
	if time_of_day >= 1.0:
		time_of_day -= 1.0
		day_count += 1
	print("Skipped ", hours, " hour. New Time: ", time_of_day * 24, " Day:", day_count)
	#update_clock_label()
	emit_signal("time_changed", time_of_day, day_count)
