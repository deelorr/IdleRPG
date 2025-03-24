# bush.gd
extends ResourceTarget

func _ready() -> void:
	resource_type = "food"
	max_amount = 10  # Adjust as needed
	super._ready()
