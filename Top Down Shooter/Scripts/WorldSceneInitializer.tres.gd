extends Node3D

func _ready():
	Globals.TimeElapsed = 0
	Globals.HeightTerrain = $HTerrain
	Globals.NavigationRegion = $NavigationRegion
	Globals.World = self
	Network.connect("game_starting",func():
		PlayerLib.create_players()
		)
	Network.rpc_id(1,"_count_loading")
