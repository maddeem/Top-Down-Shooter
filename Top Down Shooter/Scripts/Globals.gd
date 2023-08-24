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
var PlayerCount = 0
var AllPlayers = []

func create_player() -> Player:
	var p = Player.new()
	PlayerCount += 1
	p.id = PlayerCount
	p.bit_id = Utility.get_bit(PlayerCount)
	return p

func _process(delta):
	TimeElapsed += delta

func _ready():
	pass
