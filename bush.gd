extends StaticBody2D

class_name BushClass

var is_targeted: bool = false

var max_food: int = 30
var current_food: int

func _ready():
	current_food = max_food
