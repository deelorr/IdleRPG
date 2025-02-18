extends Camera2D

@export var drag_sensitivity := 1.0  # Adjust for touch drag speed
@export var zoom_speed := 0.1        # Adjust zoom sensitivity
@export var min_zoom := 1.0          # Min zoom level
@export var max_zoom := 3.0          # Max zoom level
@export var inertia_damping := 0.9   # Damping factor for inertia (0.0 - 1.0)
@export var edge_pan_speed := 200.0  # Speed for edge panning
@export var edge_pan_margin := 25    # Pixels near edge to trigger panning

var velocity := Vector2.ZERO
var is_dragging := false

func _process(delta):
	# Apply inertia (smooth stopping effect)
	if velocity.length() > 0.1:
		position += velocity * delta
		velocity *= inertia_damping
	else:
		velocity = Vector2.ZERO  # Stop small movements

	# Ensure camera stays within limits
	position.x = clamp(position.x, limit_left, limit_right)
	position.y = clamp(position.y, limit_top, limit_bottom)

	# **PC ONLY: Edge Panning**
	if OS.has_feature("pc"):
		var mouse_pos = get_viewport().get_mouse_position()
		var screen_size = get_viewport_rect().size
		var pan_vector = Vector2.ZERO

		if mouse_pos.x < edge_pan_margin:
			pan_vector.x = -1
		elif mouse_pos.x > screen_size.x - edge_pan_margin:
			pan_vector.x = 1
		if mouse_pos.y < edge_pan_margin:
			pan_vector.y = -1
		elif mouse_pos.y > screen_size.y - edge_pan_margin:
			pan_vector.y = 1
		
		position += pan_vector * edge_pan_speed * delta

func _input(event):
	# **Mobile Drag Only**
	if event is InputEventScreenDrag:
		velocity = -event.relative * drag_sensitivity  # Inverted for natural movement
		position += velocity

	# **Handle Zooming (Mouse Wheel & Touch Pinch)**
	if event is InputEventMouseButton and OS.has_feature("pc"):
		var mouse_world_pos = get_global_mouse_position()  # Get world position of the mouse before zooming
		var zoom_before = zoom

		if event.button_index == MOUSE_BUTTON_WHEEL_UP:
			zoom -= Vector2(zoom_speed, zoom_speed)
		elif event.button_index == MOUSE_BUTTON_WHEEL_DOWN:
			zoom += Vector2(zoom_speed, zoom_speed)

		# Clamp zoom level
		zoom = zoom.clamp(Vector2(min_zoom, min_zoom), Vector2(max_zoom, max_zoom))

		# Adjust camera position to zoom towards mouse position
		var mouse_world_pos_after = get_global_mouse_position()
		position -= (mouse_world_pos_after - mouse_world_pos)

	elif event is InputEventMagnifyGesture:  # Pinch-to-zoom on mobile
		zoom = (zoom / event.factor).clamp(Vector2(min_zoom, min_zoom), Vector2(max_zoom, max_zoom))
