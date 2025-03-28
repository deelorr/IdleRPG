extends Node

signal time_updated(in_game_hours: int, in_game_minutes: int, day: int)

const TIME_SCALE_FACTOR: float = 0.0001
const HOURS_IN_DAY: float = 24.0

var time_of_day: float = 0.0  # 0.0 (midnight) to 1.0 (end of day)
var day_count: int = 1
var time_paused: bool = false
var time_speed_multiplier: float = 1.0

func _process(delta: float) -> void:
	if not time_paused:
		time_of_day += delta * TIME_SCALE_FACTOR * time_speed_multiplier
		if time_of_day >= 1.0:
			time_of_day = 0.0
			day_count += 1
		emit_time_update()

func emit_time_update() -> void:
	var in_game_hours := int(time_of_day * HOURS_IN_DAY)
	var in_game_minutes := int(fmod(time_of_day * HOURS_IN_DAY * 60, 60))
	time_updated.emit(in_game_hours, in_game_minutes, day_count)

func skip_hours(hours: int) -> void:
	time_of_day += hours / HOURS_IN_DAY
	if time_of_day >= 1.0:
		time_of_day -= 1.0
		day_count += 1
	emit_time_update()

func speed_up_time(multiplier: int) -> void:
	time_speed_multiplier = float(multiplier)  # Cast to float for consistency
