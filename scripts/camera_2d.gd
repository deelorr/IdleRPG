extends Camera2D

# Exported variables with proper typing and editor hints
@export_range(1.0, 10.0, 0.1) var transition_speed: float = 5.0  # Speed of camera movement (higher = faster)
@export_range(1.0, 3.0, 0.1) var zoom_out_level: float = 1.8    # Zoom level when camera is moving
@export var default_zoom: Vector2 = Vector2(2, 2)               # Zoom level when camera is stationary

# Constants with typing
const MOVE_THRESHOLD: float = 5.0

# Typed dictionary for clarity and safety
var section_positions: Dictionary = {
	"woods": Vector2.ZERO,
	"desert": Vector2(548, 0),
	"section_3": Vector2(0, 960),
	"section_4": Vector2(548, 960),
	"home": Vector2(290, 430)
}

# Typed variables
var target_position: Vector2 = Vector2.ZERO
var is_moving: bool = false

# Optional: Export a NodePath for the UI to avoid hardcoding
@export_node_path("CanvasLayer") var ui_path: NodePath = ^"../UI"

func _ready() -> void:
	# Set initial position
	target_position = section_positions["home"]
	position = target_position
	
	# Connect signal safely with error checking
	if ui_path:
		var ui_node: CanvasLayer = get_node_or_null(ui_path)
		assert(ui_node, "UI node not found at path: %s" % ui_path)
		ui_node.camera_target.connect(_on_camera_target)

func _on_camera_target(target: String) -> void:
	if section_positions.has(target) and target_position != section_positions[target]:
		target_position = section_positions[target]
		animate_camera()

func animate_camera() -> void:
	if is_moving:  # Prevent overlapping animations
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
