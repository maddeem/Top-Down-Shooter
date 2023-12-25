extends MeshInstance3D
var display_time := 0.0


func SetPercent(new_value : float):
	set_instance_shader_parameter("percent",new_value)

func _ready():
	SetPercent(1.0)

func _process(delta):
	display_time -= delta
	set_instance_shader_parameter("alpha",ease(clamp(display_time+1.0,0.0,1.0),0.2))
