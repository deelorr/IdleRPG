extends StaticBody2D
class_name ResourceTarget

@onready var gather_point = $GatherPoint

@export var max_amount: int = 0
@export var resource_type: String = ""

var current_amount: int
var is_targeted: bool = false
var targeted_by: Worker = null  # Track the actual worker

func _ready() -> void:
	name = "_resource"
	current_amount = max_amount

func get_gather_position() -> Vector2:
	return gather_point.global_position

func reduce_amount(amount: int) -> int:
	var collected = min(current_amount, amount)
	current_amount -= collected
	return collected

func is_depleted() -> bool:
	return current_amount <= 0
