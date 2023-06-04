extends Node3D
class_name VisibilityModifier
## Controls the radius in which the visibility modifier will have effect.
@export_range(0,999) var Radius : int = 10:
	set(value):
		Radius = value
		add_to_group("VisibilityModifiers")

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	Radius = Radius

func _physics_process(delta) -> void:
	#ONLY FOR TESTING!
	var vp = get_viewport()
	var cam = vp.get_camera_3d()
	var pos1 = cam.unproject_position(global_position)
	var pos2 = vp.get_mouse_position()
	var dir = pos1.direction_to(pos2)
	dir = Vector3(dir.x,0,dir.y) * 5 * delta
	position += dir
	cam.position += dir
