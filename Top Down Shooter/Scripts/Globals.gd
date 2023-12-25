extends Node
@onready var Gravity = ProjectSettings.get_setting("physics/3d/default_gravity")
const GAME_SCENE = preload("res://Scenes/world_scene.tscn")
const BUFFER_SIZE = 2
const NETWORK_UPDATE_SCALE = 0.05
var FogOfWar
var HeightTerrain
var World : Node3D
var TimeElapsed = 0.0
var NavigationRegion
var WidgetParent
var CreepHandler
var MainMenu
var TicksPerSecond = ProjectSettings.get_setting("physics/common/physics_ticks_per_second")
var LocalPlayerBit : int
var LocalVisionBit : int
var LocalPlayer : Player = null
var MenuOpen := false

func _process(delta):
	TimeElapsed += delta
	#If  we don't do this, the fog of war will not render causing errors
	match DisplayServer.window_get_mode():
		DisplayServer.WINDOW_MODE_MINIMIZED:
			RenderingServer.force_draw()
func exit_game():
	World.queue_free()
	await World.tree_exited
	LocalPlayer = null
	LocalPlayerBit = 0
	LocalVisionBit = 0
	Network.reset()
	PlayerLib.reset()
	NetworkFactory.reset()
	Lobby.start_lobby_server_connection()
	MainMenu.reset()
	MainMenu.visible = true
