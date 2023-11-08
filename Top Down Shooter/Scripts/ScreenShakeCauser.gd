extends ShapeCast3D
@export var radius := 10.0

@rpc("call_local")
func cause_shake(intensity : float, based_on_distance := false, adds := false, rad := radius) -> void:
	shape.radius = rad
	enabled = true
	force_shapecast_update()
	await get_tree().create_timer(0.02).timeout
	for i in get_collision_count():
		var body = get_collider(i)
		if body.has_method("add_shake"):
			if based_on_distance:
				var dist = body.global_position.distance_squared_to(global_position)
				var ratio = 1.0 - dist/(rad*rad)
				ratio *= ratio * ratio
				body.add_shake(intensity * ratio, adds)
			else:
				body.add_shake(intensity, adds)
	enabled = false
