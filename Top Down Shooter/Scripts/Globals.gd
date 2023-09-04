extends Node
@onready var Gravity = ProjectSettings.get_setting("physics/3d/default_gravity")
const GAME_SCENE = preload("res://Scenes/WorldScene.tscn")
var FogOfWar
var HeightTerrain
var World
var TimeElapsed = 0.0
var NavigationRegion
var WidgetParent
var CreepHandler
var TicksPerSecond = ProjectSettings.get_setting("physics/common/physics_ticks_per_second")
var LocalPlayerBit : int:
	set(value):
		LocalPlayerBit = value
		RenderingServer.global_shader_parameter_set("FogPlayerBit", LocalPlayerBit)

func _process(delta):
	TimeElapsed += delta
	#If  we don't do this, the fog of war will not render causing errors
	match DisplayServer.window_get_mode():
		DisplayServer.WINDOW_MODE_MINIMIZED:
			RenderingServer.force_draw()
