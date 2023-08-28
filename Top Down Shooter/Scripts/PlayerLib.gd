extends Node
var PlayerSpawnPoints : Array = []
var PlayerByIndex = {}
var PlayerById = {}
var AllPlayers : Array = []
var PlayerCount : int = 0
var UnitPath = preload("res://Scenes/Widgets/PlayerUnit.tscn")

@rpc("any_peer","reliable","call_local")
func _spawn_player_character(player : int, pos : Vector3, index : int):
	var p : Player = PlayerById[player]
	var new = UnitPath.instantiate()
	Globals.World.add_child(new)
	new.player_owner = p
	new.move_instantly(pos)
	Globals.World.move_child(new,index)


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
			_spawn_player_character.rpc(
				player.id,
				PlayerSpawnPoints.pop_at(j),
				Globals.World.get_child_count() + 1,
				)
	PlayerCount = Network.Players.size()
