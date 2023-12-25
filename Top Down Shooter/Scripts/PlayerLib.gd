extends Node
var PlayerSpawnPoints : Array = []
var PlayerByIndex = {}
var PlayerById = {}
var HumanPlayers : Array[Player] = []
var AllPlayers : Array[Player] = []
var PlayerCount : int = 0
var PLAYER_NEUTRAL : Player
var PLAYER_HOSTILE : Player
var PLAYER_THRUL : Player
var PLAYER_SHIP : Player
enum {
	HUMAN,
	COMPUTER
}
signal initialized

func reset():
	for p in AllPlayers:
		p.queue_free()
	PlayerSpawnPoints = []
	PlayerById = {}
	PlayerById = {}
	HumanPlayers = []
	AllPlayers = []
	PlayerCount = 0
	PLAYER_NEUTRAL = create_player(30,30,COMPUTER,"Neutral")
	PLAYER_HOSTILE = create_player(29,29,COMPUTER, "Hostile")
	PLAYER_THRUL = create_player(28,28,COMPUTER, "Thrul")
	PLAYER_SHIP = create_player(27,27,COMPUTER, "Ship Systems")

func create_player(id : int, index : int, controller : int, player_name : String = "") -> Player:
	var new = Player.new()
	if player_name == "":
		player_name = "None"
	new.name = player_name
	new.id = id
	new.index = index
	new.bit_id = Utility.get_bit(index)
	new.controller = controller
	PlayerById[id] = new
	PlayerByIndex[index] = new
	AllPlayers.append(new)
	add_child(new)
	if multiplayer and id == multiplayer.get_unique_id():
		Globals.LocalPlayer = new
	return new

func create_players():
	var i = 0
	for player in Network.Players:
		var new = create_player(player,i,HUMAN,Lobby.slot_names[player])
		i += 1
		HumanPlayers.append(new)
	if multiplayer.is_server():
		for player in HumanPlayers:
			var j = randi_range(0,PlayerSpawnPoints.size()-1)
			NetworkFactory.create_unit_at.rpc(
				NetworkFactory.swap_id_path("res://Editables/Widgets/PlayerUnits/SpaceMarine.tscn"),
				PlayerSpawnPoints.pop_at(j),
				player.index
			)
	for player1 in HumanPlayers:
		player1.set_alliance_both(PLAYER_SHIP,true,false)
		for player2 in HumanPlayers:
			if player1 != player2:
				player1.set_player_ally(player2,true)
				player1.set_player_visible(player2,false)
	for player1 in AllPlayers:
		if player1 != PLAYER_NEUTRAL:
			player1.set_alliance_both(PLAYER_NEUTRAL,true,false)
		if player1 != PLAYER_HOSTILE:
			player1.set_alliance_both(PLAYER_HOSTILE,false,false)
	PLAYER_THRUL.set_alliance_both(PLAYER_SHIP,false,false)
	PlayerCount = Network.Players.size()
	emit_signal("initialized")

func _ready():
	reset()
	Network.peer_left_lobby.connect(func(_id):
		if PlayerById.has(_id):
			var p : Player = PlayerById[_id]
			NetworkFactory.server_call(p.main_unit.instance_id, "_death")
		)
