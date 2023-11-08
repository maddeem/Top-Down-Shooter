extends Node
@onready var Gravity = ProjectSettings.get_setting("physics/3d/default_gravity")
const GAME_SCENE = preload("res://Scenes/WorldScene.tscn")
const BUFFER_SIZE = 2
const NETWORK_UPDATE_SCALE = 0.05
var FogOfWar
var HeightTerrain
var World
var TimeElapsed = 0.0
var NavigationRegion
var WidgetParent
var CreepHandler
var Reticle = null;
var TicksPerSecond = ProjectSettings.get_setting("physics/common/physics_ticks_per_second")
var LocalPlayerBit : int
var LocalVisionBit : int
var LocalPlayer : Player = null

func _process(delta):
	TimeElapsed += delta
	#If  we don't do this, the fog of war will not render causing errors
	match DisplayServer.window_get_mode():
		DisplayServer.WINDOW_MODE_MINIMIZED:
			RenderingServer.force_draw()
