extends Node

signal time_updated(in_game_hours: int, in_game_minutes: int, day: int)

const TIME_SCALE_FACTOR: float = 0.0001
const HOURS_IN_DAY: float = 24.0

var time_of_day: float = 0.0  # 0.0 to 1.0 (midnight) to 1.0 (end of day)
var day_count: int = 1
var time_paused: bool = false
#var time_speed_multiplier: float = 1.0

func _process(delta):
	if not time_paused:
		# Update time progression
		time_of_day += (delta * TIME_SCALE_FACTOR)  
		
		# Ensure we loop time correctly
		if time_of_day >= 1.0:
			time_of_day = 0.0
			day_count += 1  # Move to next day

		emit_time_update()  # Send signal every update

func emit_time_update():
	var in_game_hours = int(time_of_day * HOURS_IN_DAY)
	var in_game_minutes = int(fmod(time_of_day * HOURS_IN_DAY * 60, 60))
	time_updated.emit(in_game_hours, in_game_minutes, day_count)
	#emit_signal("time_updated", in_game_hours, in_game_minutes, day_count) old signal

func skip_hours(hours: int):
	time_of_day += hours / HOURS_IN_DAY
	if time_of_day >= 1.0:
		time_of_day -= 1.0
		day_count += 1
	emit_time_update()
