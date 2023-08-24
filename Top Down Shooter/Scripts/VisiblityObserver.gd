extends Node3D
class_name VisibilityObserver
var is_visible:
	set(value):
		if value != is_visible:
			is_visible = value
			visible = value
			emit_signal("visibility_update",value)
var _last_position : Vector3
var Previous_Grid_Position
var Owner_Bit_Value : int
@export_range(-1,Config.MAX_PLAYERS-1) var Owner = -1:
	set(value):
		Owner = value
		if Owner == -1:
			Owner_Bit_Value = Globals.LocalPlayerBit
		else:
			Owner_Bit_Value = Utility.get_bit(value)
signal visibility_update(state)

func _ready():
	Owner = Owner
	set_notify_transform(true)
	_notification(NOTIFICATION_TRANSFORM_CHANGED)

func _notification(what: int) -> void:
	if what == NOTIFICATION_TRANSFORM_CHANGED:
		var pos = (global_position + Vector3(0.5,0,0.5)).round()
		if pos != _last_position:
			_last_position = pos
			add_to_group("UpdateObservers")
