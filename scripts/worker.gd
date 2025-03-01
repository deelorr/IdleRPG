extends CharacterBody2D

@onready var agent = $NavigationAgent2D

@export var speed: float = 50.0
var forest_position = Vector2(11,-100)

func _ready():
	agent.target_position = forest_position

func _process(delta):
	if agent.is_navigation_finished():
		return

	var direction = (agent.get_next_path_position() - global_position).normalized()
	velocity = direction * speed
	move_and_slide()
