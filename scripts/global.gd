extends Node

signal resource_changed(resource: String, amount: int)

var currently_open_hut: Node = null

var total_city_gold: int = 0
var total_city_wood: int = 0
var total_city_food: int = 0
