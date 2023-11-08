extends Node3D
class_name VisibilityModifier
@export_range(0,999) var Inner_Radius : int = 1
## Controls the radius in which the visibility modifier will have effect.
@export_range(0,999) var Radius : int = 10
@export_range(0,255) var Vision_Height : float = 0:
	set(value):
		Vision_Height = value
		if _last_Y:
			_update_adjuste_height()
##Field of view in radians
@export_range(0,PI) var FOV : float = PI
## Automatically converted to the bit value of the player so the shader knows who to render this for
@export_range(0,Config.MAX_PLAYERS-1) var Owner = 0:
	set(value):
		Owner = value
		Owner_Bit_Value = Utility.get_bit(value)
var Adjusted_Vision_Height
var _last_Y
var Owner_Bit_Value

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
