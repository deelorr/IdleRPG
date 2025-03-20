extends Node2D

@export var grid_size: int = 32  # Match the grid size in spawn_bush()
var draw_grid = true  # Toggle grid visibility

func _draw():
	if not draw_grid:
		return

	# Ensure there's a valid shape
	if get_child_count() == 0 or not (get_child(0) is CollisionShape2D):
		print("ERROR: BushSpawnArea must have a CollisionShape2D!")
		return
	
	var shape_node = get_child(0) as CollisionShape2D
	var rect = shape_node.shape.get_rect()
	var top_left = rect.position
	var bottom_right = rect.end

	# Convert local positions to global
	var world_top_left = to_global(top_left)
	var world_bottom_right = to_global(bottom_right)

	# Draw vertical grid lines
	for x in range(int(world_top_left.x), int(world_bottom_right.x), grid_size):
		draw_line(Vector2(x, world_top_left.y), Vector2(x, world_bottom_right.y), Color(0, 1, 0), 1)

	# Draw horizontal grid lines
	for y in range(int(world_top_left.y), int(world_bottom_right.y), grid_size):
		draw_line(Vector2(world_top_left.x, y), Vector2(world_bottom_right.x, y), Color(0, 1, 0), 1)

func toggle_grid():
	draw_grid = !draw_grid
	queue_redraw()  # Refresh drawing when toggled
