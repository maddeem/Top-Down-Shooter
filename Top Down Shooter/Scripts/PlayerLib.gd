extends Node
var PlayerSpawnPoints : Array = []
var PlayerByIndex = {}
var PlayerById = {}
var AllPlayers : Array = []
var PlayerCount : int = 0


func create_players():
	var i = 0
	PlayerByIndex = {}
	PlayerById = {}
	for player in Network.Players:
		var new = Player.new()
		new.id = player
		new.index = i
		PlayerById[player] = new
		PlayerByIndex[i] = new
		new.bit_id = Utility.get_bit(i)
		i += 1
		AllPlayers.append(new)
	Globals.LocalPlayerBit = PlayerById[multiplayer.get_unique_id()].bit_id
	if multiplayer.is_server():
		for player in AllPlayers:
			var j = randi_range(0,PlayerSpawnPoints.size()-1)
			WidgetFactory.create_unit_at.rpc(
				WidgetFactory.swap_id_path("res://Scenes/Widgets/PlayerUnit.tscn"),
				PlayerSpawnPoints.pop_at(j),
				player.id
			)
	PlayerCount = Network.Players.size()
