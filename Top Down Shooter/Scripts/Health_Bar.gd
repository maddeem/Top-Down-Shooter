extends MeshInstance3D
var override := false:
	set(value):
		override = value
		if value:
			set_process(false)
			set_instance_shader_parameter("alpha",1.0)
		else:
			display_time = display_time
var display_time := -1.0:
	set(value):
		display_time = value
		set_process(display_time > -1.0)
		set_instance_shader_parameter("alpha",ease(clamp(display_time+1.0,0.0,1.0),0.2))


func SetPercent(new_value : float):
	set_instance_shader_parameter("percent",new_value)

func _ready():
	SetPercent(1.0)

func _process(delta):
	display_time -= delta
