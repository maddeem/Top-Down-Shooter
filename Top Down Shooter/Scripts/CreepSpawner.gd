class_name CreepSpawner extends Node3D
@export var radius : float = 10.0
@export var spread_per_second : float = 0.5
var Current_Radius : float = 0.0:
	set(value):
		if value == Current_Radius:
			return
		Current_Radius = value
		emit_signal("updated")

signal updated

func _process(delta):
	Current_Radius = min(radius,Current_Radius + spread_per_second * delta)

func get_data() -> Vector3:
	return Vector3(Last_Position.x,Last_Position.y,Current_Radius)

func _ready():
	Creep.add_spawner(self)
	set_notify_transform(true)
	_notification(NOTIFICATION_TRANSFORM_CHANGED)

var Last_Position := Vector2.ZERO
func _notification(what: int) -> void:
	if what == NOTIFICATION_TRANSFORM_CHANGED:
		var cur_pos = Vector2(global_position.x,global_position.z)
		if cur_pos != Last_Position:
			Last_Position = cur_pos
			emit_signal("updated")
