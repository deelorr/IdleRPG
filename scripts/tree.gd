extends StaticBody2D

class_name TreeClass

var max_wood: int = 30
var current_wood: int

func _ready():
	current_wood = max_wood
