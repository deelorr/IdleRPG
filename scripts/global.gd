extends Node

signal resource_changed(resource: String, amount: int)

var currently_open_hut: Node = null

#region GLOBAL TOTALS
var total_city_gold: int = 0
var total_city_wood: int = 0
var total_city_food: int = 0
#endregion

#region GAME PAUSING LOGIC
var is_game_paused: bool = false

func pause_game():
	is_game_paused = true
	get_tree().paused = true

func unpause_game():
	is_game_paused = false
	get_tree().paused = false

func toggle_pause():
	is_game_paused = !is_game_paused
	get_tree().paused = is_game_paused
	print("Is paused:", get_tree().paused)
#endregion
