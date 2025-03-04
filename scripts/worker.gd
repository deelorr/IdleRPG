extends CharacterBody2D

signal gathered_wood(wood_amount: int)

var target_waypoint: Vector2
var hut_waypoint: Vector2
var forest_waypoint: Vector2
var speed: float = 100.0
var wood_per_trip: int = 10

func _ready() -> void:
	target_waypoint = forest_waypoint

func _physics_process(_delta: float) -> void:
	var direction = (target_waypoint - global_position).normalized()
	velocity = direction * speed
	move_and_slide()
	
	if global_position.distance_to(target_waypoint) < 10:
		if target_waypoint == forest_waypoint:
			gathered_wood.emit(wood_per_trip)
			target_waypoint = hut_waypoint
		else:
			target_waypoint = forest_waypoint
