extends Camera2D

@export var transition_speed: float = 5.0  #Speed of camera movement (higher = faster)
@export var zoom_out_level: float = 1.8 #Zoom level when camera is moving
@export var default_zoom: Vector2 = Vector2(2, 2)  #Zoom level when camera is stationary

const MOVE_THRESHOLD: float = 5.0

var section_positions := {
	"woods": Vector2(0, 0),          #Section 1 - Woods
	"desert": Vector2(548, 0),       #Section 2 - Desert
	"section_3": Vector2(0, 960),    #Section 3
	"section_4": Vector2(548, 960),  #Section 4
	"home": Vector2(290, 430)        #Section 5 - Home base
}

var target_position: Vector2
var is_moving: bool = false

func _ready() -> void:
	target_position = section_positions["home"]
	position = target_position

func _process(delta: float) -> void:
	var transition_step = delta * transition_speed
	var ease_factor = 1.0 - pow(1.0 - transition_step, 3)
	var distance_to_target = position.distance_to(target_position)
	if distance_to_target > MOVE_THRESHOLD:
		is_moving = true
	else:
		is_moving = false
		position = target_position

	var target_zoom = (Vector2.ONE * zoom_out_level) if is_moving else default_zoom
	zoom = zoom.lerp(target_zoom, ease_factor)
	
	position = position.lerp(target_position, ease_factor)

func _on_the_woods_button_pressed():
	target_position = section_positions["woods"]

func _on_the_desert_button_pressed():
	target_position = section_positions["desert"]

func _on_section_3_button_pressed():
	target_position = section_positions["section_3"]

func _on_section_4_button_pressed():
	target_position = section_positions["section_4"]

func _on_home_base_pressed():
	target_position = section_positions["home"]
