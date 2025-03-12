extends StaticBody2D

class_name TreeClass

var is_targeted: bool = false

var max_wood: int = 30
var current_wood: int

func _ready():
	current_wood = max_wood
