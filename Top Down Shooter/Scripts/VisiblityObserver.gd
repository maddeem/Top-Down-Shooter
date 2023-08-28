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
signal visibility_update(state)

func _ready():
	set_notify_transform(true)
	_notification(NOTIFICATION_TRANSFORM_CHANGED)

func _notification(what: int) -> void:
	if what == NOTIFICATION_TRANSFORM_CHANGED:
		var pos = (global_position + Vector3(0.5,0,0.5)).round()
		if pos != _last_position:
			_last_position = pos
			add_to_group("UpdateObservers")
