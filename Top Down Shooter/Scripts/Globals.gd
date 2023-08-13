extends Node
@onready var Gravity = ProjectSettings.get_setting("physics/3d/default_gravity")
var FogOfWar
var HeightTerrain
var TimeElapsed = 0.0
var NavigationRegion
var LocalPlayerBit : int = 1:
	set(value):
		LocalPlayerBit = value
		RenderingServer.global_shader_parameter_set("FogPlayerBit", LocalPlayerBit)

func _process(delta):
	TimeElapsed += delta

func _ready():
	pass
