# tree.gd
extends ResourceTarget

@onready var wood_label: Label = $Label

func _ready() -> void:
	resource_type = "wood"
	max_amount = 12  # Or any number you want per tree
	super._ready()
	
func _process(_delta):
	wood_label.text = str(current_amount)
