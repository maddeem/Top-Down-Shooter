extends Node3D
var astar := AStarGrid2D.new()
@export var cell_size : Vector2 = Vector2(0.5,0.5):
	set(value):
		cell_size = value
		astar.cell_size = value

@export var size : Vector2 = Vector2(512,512):
	set(value):
		size = value
		astar.size = value * 2

func _ready():
	size = size
	cell_size = cell_size
	astar.diagonal_mode = AStarGrid2D.DIAGONAL_MODE_ONLY_IF_NO_OBSTACLES
	astar.jumping_enabled = true
	update_grid()

func update_grid():
	astar.offset = -(Vector2(position.x,position.z) + size * cell_size)
	astar.update()

func get_point_path(start_position : Vector2, end_position : Vector2) -> PackedVector2Array:
	start_position += size
	end_position += size
	var path = astar.get_point_path(Vector2i(start_position.round()),Vector2i(end_position.round()))
	for i in path.size():
		path[i] /= cell_size
	return path
