@tool
extends CSGPolygon3D
@export var line_radius := 0.1:
	set(value):
		line_radius = value
@export var line_resolution := 180:
	set(value):
		line_resolution = value
var start_point : Vector3:
	set(value):
		start_point = value
		$Path3D.curve.set_point_position(0,value)
var end_point : Vector3:
	set(value):
		end_point = value
		$Path3D.curve.set_point_position(1,value)
	

func recalculate():
	var circle = PackedVector2Array()
	for degree in line_resolution:
		var x = line_radius * sin(PI * 2 * degree / line_resolution)
		var y = line_radius * cos(PI * 2 * degree / line_resolution)
		circle.append(Vector2(x,y))
	polygon = circle

func _process(delta):
	recalculate()
