@tool
class_name AggroSystem extends Area3D
@onready var collider_shape :SphereShape3D = $CollisionShape3D.shape
@export var range := 5.0:
	set(value):
		range = value
		collider_shape.radius = range
var inside = []

func _on_body_entered(body):
	if body != get_parent():
		inside.append(body)


func _on_body_exited(body):
	inside.erase(body)
