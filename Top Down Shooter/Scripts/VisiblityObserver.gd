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
			if Cache.exists("bit",Owner):
				Owner_Bit_Value = Cache.read_from("bit",Owner)
			else:
				Owner_Bit_Value = int(pow(2,Owner))
				Cache.write_to("bit",Owner,Owner_Bit_Value)
signal visibility_update(state)

func _ready():
	Owner = Owner
	set_notify_transform(true)
	_notification(NOTIFICATION_TRANSFORM_CHANGED)

func _notification(what: int) -> void:
	if what == NOTIFICATION_TRANSFORM_CHANGED:
		if global_position.round() != _last_position:
			_last_position = global_position.round()
			add_to_group("UpdateObservers")
