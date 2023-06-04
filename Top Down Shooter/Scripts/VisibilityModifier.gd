extends Node3D
class_name VisibilityModifier
## Controls the radius in which the visibility modifier will have effect.
@export_range(0,999) var Radius : int = 10:
	set(value):
		Radius = value
@export_range(0,256) var Vision_Height : int = 256:
	set(value):
		Vision_Height = value
		if _last_Y:
			_update_adjuste_height()

var Adjusted_Vision_Height
var _last_Y

func IsPointVisible(pos : Vector3):
	var Fog = Globals.FogOfWar
	var Map : Image = Fog.occluder_image_map
	var p0 : Vector2i = Fog.Position_To_Pixel(global_position)
	var p1 : Vector2i = Fog.Position_To_Pixel(pos)
	var dx = abs(p1.x - p0.x)
	var dy = -abs(p1.y - p0.y)
	var err = dx + dy
	var e2 = 2 * err
	var sx = 1 if p0[0] < p1[0] else -1
	var sy = 1 if p0[1] < p1[1] else -1
	while true:
		if Adjusted_Vision_Height < Map.get_pixelv(p0).r:
			return false
		elif p0 == p1:
			return true
		e2 = 2 * err
		if e2 >= dy:
			err += dy
			p0[0] += sx
		if e2 <= dx:
			err += dx
			p0[1] += sy

func _update_adjuste_height():
	Adjusted_Vision_Height = clamp((global_position.y + Vision_Height)*0.0078125,0.0,1.0)

func _ready() -> void:
	_update_adjuste_height()
	add_to_group("VisibilityModifiers")

func _physics_process(delta) -> void:
	if _last_Y != global_position.y:
		_last_Y = global_position.y
		_update_adjuste_height()
	#ONLY FOR TESTING!
	var vp = get_viewport()
	var cam = vp.get_camera_3d()
	var pos1 = cam.unproject_position(global_position)
	var pos2 = vp.get_mouse_position()
	var dir = pos1.direction_to(pos2)
	dir = Vector3(dir.x,0,dir.y) * 5 * delta
	position += dir
	cam.position += dir
