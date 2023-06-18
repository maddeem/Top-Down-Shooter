extends Node
var FogOfWar
var TimeElapsed = 0.0
var LocalPlayerBit : int = 1:
	set(value):
		LocalPlayerBit = value
		RenderingServer.global_shader_parameter_set("FogPlayerBit", LocalPlayerBit)

func _process(delta):
	TimeElapsed += delta
