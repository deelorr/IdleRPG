extends Control

@export var show_debug_grid := true
@export var tree_spawn_area: Area2D
@export var bush_spawn_area: Area2D
@export var occupied_cells := {}

@onready var camera := $Camera2D

const GRID_SIZE := 16

func _process(_delta):
	if show_debug_grid:
		queue_redraw()

func _draw():
	if not show_debug_grid:
		return

	var zoom = camera.default_zoom if camera else Vector2(1, 1)

	draw_debug_grid_for_spawn_area(tree_spawn_area, Color(0.2, 0.8, 0.2, 0.6), Color.RED, zoom)
	draw_debug_grid_for_spawn_area(bush_spawn_area, Color(0.2, 0.2, 0.8, 0.6), Color.ORANGE_RED, zoom)

func draw_debug_grid_for_spawn_area(
	spawn_area: Area2D,
	color_available: Color,
	color_occupied: Color,
	zoom: Vector2
) -> void:
	if not spawn_area or spawn_area.get_child_count() == 0:
		return

	var shape_node := spawn_area.get_child(0) as CollisionShape2D
	if not shape_node:
		return

	var shape := shape_node.shape as RectangleShape2D
	if not shape:
		return

	var rect := shape.get_rect()
	var top_left := spawn_area.to_global(rect.position)
	var bottom_right := spawn_area.to_global(rect.end)

	top_left.x = floor(top_left.x / GRID_SIZE) * GRID_SIZE
	top_left.y = floor(top_left.y / GRID_SIZE) * GRID_SIZE
	bottom_right.x = ceil(bottom_right.x / GRID_SIZE) * GRID_SIZE
	bottom_right.y = ceil(bottom_right.y / GRID_SIZE) * GRID_SIZE

	var rect_size := bottom_right - top_left
	var columns := int(rect_size.x / GRID_SIZE)
	var rows := int(rect_size.y / GRID_SIZE)

	for col in range(columns):
		for row in range(rows):
			var world_pos := top_left + Vector2(col * GRID_SIZE, row * GRID_SIZE)
			var screen_pos := world_pos / zoom  # draw at screen-space size

			var color := color_occupied if occupied_cells.has(world_pos) else color_available
			draw_rect(Rect2(screen_pos.floor(), Vector2(GRID_SIZE, GRID_SIZE) / zoom), color, false)
