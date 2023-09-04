class_name CreepSpawner extends Node3D
@export var radius : float = 10.0:
	set(value):
		radius = value
		radius_squared = radius * radius
@export var spread_period : float = 0.5
@export var grow_per_tick : int = 1
var grow_tick = 0.0
var radius_squared
const neighbors = [Vector2(0,1),Vector2(1,0),Vector2(-1,0),Vector2(0,-1)]
var points = []
var check = {}
var next_points = []
var last_updated = []
var dying = false
var death_tick = 0

func _process(delta):
	grow_tick += delta
	if grow_tick >= spread_period:
		grow_tick = 0.0
		if dying:
			for i in log(points.size()) * grow_per_tick * 10:
				var pop = points.pop_back()
				if pop:
					Globals.CreepHandler.update_point(pop,-1)
		else:
			for i in grow_per_tick:
				grow()

func _ready():
	radius = radius
	set_notify_transform(true)
	_notification(NOTIFICATION_TRANSFORM_CHANGED)
	next_points.append(Last_Position)

func is_point_valid(point : Vector2):
	return not check.has(point) and point.distance_squared_to(Last_Position) <= radius_squared

func grow():
	var size = next_points.size()
	var added = []
	if size == 0:
		return
	last_updated = []
	for i in size:
		if randf() > 0.5:
			var next = next_points.pop_at(randi_range(0,size-1))
			size -= 1
			for n in neighbors:
				var p = n + next
				if is_point_valid(p):
					check[p] = true
					added.append(p)
					Globals.CreepHandler.update_point(p,1)
					points.append(p)
					last_updated.append(p)
	next_points = next_points + added

func kill():
	dying = true

var Last_Position := Vector2.ZERO
func _notification(what: int) -> void:
	if what == NOTIFICATION_TRANSFORM_CHANGED:
		var cur_pos = Vector2(global_position.x,global_position.z).round()
		if cur_pos != Last_Position:
			Last_Position = cur_pos
			next_points.append(Last_Position)
			for p in points:
				var dist = p.distance_squared_to(Last_Position)
				if dist > radius_squared:
					Globals.CreepHandler.update_point(p,-1)
					points.erase(p)
					check.erase(p)
			for p in last_updated:
				if p.distance_squared_to(Last_Position) > radius_squared:
					next_points.append(p)
			grow()

