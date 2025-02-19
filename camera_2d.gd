extends Camera2D

@export var transition_speed := 5.0  # Adjust for smooth movement speed
@export var zoom_out_level := 1.8  # Zoom out slightly (instead of 0.8)

# Define section positions
var section_1 := Vector2(0, 0)
var section_2 := Vector2(548, 0)
var section_3 := Vector2(0, 960)
var section_4 := Vector2(548, 960)

var target_position: Vector2 = section_1
var moving := false

func _ready():
	target_position = section_1  # Start at the current position

func _process(delta):
	var t = delta * transition_speed
	t = 1.0 - pow(1.0 - t, 3)  # Smooth easing
	# Check if camera is moving
	var distance = position.distance_to(target_position)
	if distance > 5:
		moving = true
	else:
		moving = false
	# Zoom out slightly while moving
	if moving:
		zoom = zoom.lerp(Vector2(zoom_out_level, zoom_out_level), t)
	else:
		zoom = zoom.lerp(Vector2(2,2), t)  # Return to default zoom
	# Move the camera smoothly
	position = position.lerp(target_position, t)

func _on_section_1_pressed():
	target_position = section_1

func _on_section_2_pressed():
	target_position = section_2

func _on_section_3_pressed():
	target_position = section_3

func _on_section_4_pressed():
	target_position = section_4
