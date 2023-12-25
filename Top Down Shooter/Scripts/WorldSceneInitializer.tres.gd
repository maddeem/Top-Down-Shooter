extends Node3D

func game_starting():
	PlayerLib.create_players()

func _ready():
	Globals.TimeElapsed = 0
	Globals.HeightTerrain = $HTerrain
	Globals.World = self
	Globals.CreepHandler = $Creep
	Globals.NavigationRegion = $NavigationRegion
	Network.connect("game_starting",game_starting)
	Network.rpc_id(1,"_count_loading")
