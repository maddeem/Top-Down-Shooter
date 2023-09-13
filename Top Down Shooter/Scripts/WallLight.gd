class_name WallLight extends Widget
var is_ready := false
@export var color := Color(1,1,1,0):
	set(value):
		color = value
		if not is_ready:
			return
		$Model/OmniLight3D.light_color = color
#		var mat : StandardMaterial3D = $Model.get_surface_override_material(1)
#		mat.emission = color
#		mat.albedo_color = color

func _ready():
	super()
	is_ready = true
	color = color
