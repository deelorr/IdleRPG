extends Camera2D

@onready var ui_node: CanvasLayer = $"../UI"

var section_positions: Dictionary = {
	"woods": Vector2.ZERO,
	"home": Vector2(544, 0),
	"snow": Vector2(0, 1008),
	"cave": Vector2(544, 1008),
}

var target_position: Vector2 = section_positions["home"]
var is_moving: bool = false
var default_zoom: Vector2 = Vector2(2, 2) 
var transition_speed: float = 5.0 
var zoom_out_level: float = 1.8

func _ready() -> void:
	ui_node.camera_target.connect(_on_camera_target)

func _on_camera_target(target: String) -> void:
	if section_positions.has(target) and target_position != section_positions[target]:
		target_position = section_positions[target]
		animate_camera()

func animate_camera() -> void:
	if is_moving:
		return
	
	is_moving = true
	var tween := create_tween()
	
	# Zoom out during movement
	tween.tween_property(self, "zoom", Vector2.ONE * zoom_out_level, 0.3 / transition_speed)\
		.set_trans(Tween.TRANS_CUBIC)\
		.set_ease(Tween.EASE_OUT)
	
	# Move to target position in parallel
	tween.parallel().tween_property(self, "position", target_position, 1.0 / transition_speed)\
		.set_trans(Tween.TRANS_CUBIC)\
		.set_ease(Tween.EASE_OUT)
	
	# Zoom back to default after movement
	tween.tween_property(self, "zoom", default_zoom, 0.3 / transition_speed)\
		.set_trans(Tween.TRANS_CUBIC)\
		.set_ease(Tween.EASE_IN_OUT)
	
	await tween.finished
	is_moving = false
