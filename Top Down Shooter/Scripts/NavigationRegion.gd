extends Node3D
var astar := AStarGrid2D.new()
var disable_weight = {}
var queue = []
var thread : Thread

@export var size : Vector2 = Vector2(512,512):
	set(value):
		size = value * 2
		var half = size/2
		astar.region = Rect2(half.x,half.y,size.x,size.y)
		astar.offset = -(Vector2(position.x,position.z) + size - Vector2(0.5,0.5))

func _ready():
	size = size
	astar.diagonal_mode = AStarGrid2D.DIAGONAL_MODE_ONLY_IF_NO_OBSTACLES
	astar.default_compute_heuristic = AStarGrid2D.HEURISTIC_MANHATTAN
	#astar.jumping_enabled = true
	astar.update()
	thread = Thread.new()

var neighbor = [Vector2i(1,0),Vector2i(-1,0),Vector2i(0,1),Vector2i(0,-1)]
func _find_nearby_open_point(point : Vector2i) -> Vector2i:
	if not astar.is_point_solid(point):
		return point
	var list = []
	var next_list = [point]
	var has = {}
	while true:
		list = next_list
		next_list = []
		for p in list:
			for n in neighbor:
				var a = p + n
				if astar.is_point_solid(a):
					if not has.has(a):
						has[a] = true
						next_list.append(a)
				else:
					return a
	return Vector2i.ZERO

func get_point_path(start_position : Vector2, end_position : Vector2) -> PackedVector2Array:
	start_position = _find_nearby_open_point(Vector2i((start_position + size - Vector2(0.5,0.5)).round()))
	end_position = _find_nearby_open_point(Vector2i((end_position + size - Vector2(0.5,0.5)).round()))
	var path = astar.get_point_path(start_position,end_position)
	return path


func _finish_thread_task(u : Unit, start_position : Vector2, end_position : Vector2):
	u.set_path(get_point_path(start_position,end_position))
	queue.pop_front()

func unit_threaded_path(u : Unit, start_position : Vector2, end_position : Vector2):
	queue.append([u,start_position,end_position])

func _process(_delta):
	if not thread.is_alive() and queue.size() > 0:
		var data = queue[0]
		if thread.is_started():
			thread.wait_to_finish()
		thread.start(_finish_thread_task.bind(data[0],data[1],data[2]),Thread.PRIORITY_LOW)
	for blocker in get_tree().get_nodes_in_group("UpdateBlockers"):
		blocker.remove_from_group("UpdateBlockers")
		#Block_Points
		for point in blocker.Last_Points_Modified:
			if disable_weight.has(point):
				disable_weight[point] -= 1
				if disable_weight[point] == 0:
					disable_weight.erase(point)
					astar.set_point_solid(point,false)
		blocker.Last_Points_Modified = []
		var pos = blocker.Last_Position
		for point in blocker.Block_Points:
			var adjusted = pos + point + Vector2i(size)
			if disable_weight.has(adjusted):
				disable_weight[adjusted] += 1
			else:
				disable_weight[adjusted] = 1
				astar.set_point_solid(adjusted,true)
			blocker.Last_Points_Modified.append(adjusted)
