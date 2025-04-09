# tree.gd
extends ResourceTarget

@onready var wood_label: Label = $Label

func _ready() -> void:
	super._ready()
	name = "tree"
	
func _process(_delta):
	wood_label.text = str(current_amount)
	
