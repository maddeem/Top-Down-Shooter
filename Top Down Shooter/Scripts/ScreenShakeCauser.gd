extends Area3D
@onready var shape :SphereShape3D = $CollisionShape3D.shape

@rpc("call_local")
func cause_shake(intensity : float, radius : float) -> void:
	shape.radius = radius
	await get_tree().create_timer(0.02).timeout
	for body in get_overlapping_areas():
		if body.has_method("add_shake"):
			body.add_shake(intensity)
