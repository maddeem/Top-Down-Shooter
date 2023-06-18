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
@export_range(0,Config.MAX_PLAYERS-1) var Owner = 0:
	set(value):
		Owner = value
		if Cache.exists("bit",Owner):
			Owner_Bit_Value = Cache.read_from("bit",Owner)
		else:
			Owner_Bit_Value = pow(2,Owner)
			Cache.write_to("bit",Owner,Owner_Bit_Value)
signal visibility_update(state)

func _ready():
	Owner = Owner
	set_notify_transform(true)
	_notification(NOTIFICATION_TRANSFORM_CHANGED)

func _notification(what: int) -> void:
	if what == NOTIFICATION_TRANSFORM_CHANGED:
		if global_position != _last_position:
			_last_position = global_position
			add_to_group("UpdateObservers")
