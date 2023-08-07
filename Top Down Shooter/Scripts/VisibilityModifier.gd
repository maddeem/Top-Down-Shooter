extends Node3D
class_name VisibilityModifier
## Controls the radius in which the visibility modifier will have effect.
@export_range(0,999) var Radius : int = 10:
	set(value):
		Radius = value
@export_range(0,255) var Vision_Height : float = 0:
	set(value):
		Vision_Height = value
		if _last_Y:
			_update_adjuste_height()
## Automatically converted to the bit value of the player so the shader knows who to render this for
@export_range(0,Config.MAX_PLAYERS-1) var Owner = 0:
	set(value):
		Owner = value
		if Cache.exists("bit",Owner):
			Owner_Bit_Value = Cache.read_from("bit",Owner)
		else:
			Owner_Bit_Value = pow(2,Owner)
			Cache.write_to("bit",Owner,Owner_Bit_Value)
var Adjusted_Vision_Height
var _last_Y
var Owner_Bit_Value

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
	Adjusted_Vision_Height = (global_position.y + Vision_Height) / 63.75

func _ready() -> void:
	set_notify_transform(true)
	Owner = Owner
	_last_Y = global_position.y
	_update_adjuste_height()
	add_to_group("VisibilityModifiers")

func _notification(what: int) -> void:
	if what == NOTIFICATION_TRANSFORM_CHANGED and _last_Y != global_position.y:
		_last_Y = global_position.y
		_update_adjuste_height()
