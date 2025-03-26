# bush.gd
extends ResourceTarget

@onready var food_label: Label = $Label

func _ready() -> void:
	super._ready()
	name = "bush"

func _process(_delta):
	food_label.text = str(current_amount)
