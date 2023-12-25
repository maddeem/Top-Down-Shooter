extends Node
var Port : int
var Peer := ENetMultiplayerPeer.new()
var Players : Array = []
var In_Lobby = false
var Lobby_Host = false
var Game_Started = false
var done_loading_count = 0
signal connected_to_lobby
signal failed_to_connect
signal peer_joined_lobby
signal peer_left_lobby
signal disconnected
signal game_loading
signal game_starting
signal peer_name_updated

func reset():
	if Peer != null:
		multiplayer.multiplayer_peer = OfflineMultiplayerPeer.new()
	Players = []
	In_Lobby = false
	Lobby_Host = false
	Game_Started = false
	done_loading_count = 0

func close_server():
	if Peer != null:
		multiplayer.multiplayer_peer = null
	In_Lobby = false
	Lobby_Host = false
	Peer = ENetMultiplayerPeer.new()
	var err = Peer.create_server(Port,1)
	multiplayer.multiplayer_peer = Peer
	return err

func disconnect_player(id):
	Peer.disconnect_peer(id)

@rpc("authority","call_local","reliable")
func _done_loading():
	emit_signal("game_starting")

@rpc("any_peer","call_local","reliable")
func _count_loading():
	done_loading_count += 1
	if done_loading_count >= Players.size():
		_done_loading.rpc()

@rpc("authority","call_local","reliable")
func start_game():
	Game_Started = true
	Lobby.lobbies_open = {}
	Lobby.multiplayer.multiplayer_peer = null
	Lobby.Peer = null
	emit_signal("game_loading")

@rpc("any_peer","reliable")
func send_name(which : String):
	var id = multiplayer.get_remote_sender_id()
	var ip = Peer.get_peer(id).get_remote_address()
	Lobby.rpc_id(1,"send_lobby_player_data",id,which,ip)
	emit_signal("peer_name_updated",id,which)

func _ready():
	reset()
	Lobby.connect("account_validation",func(target_id: int, is_valid : bool):
		if is_valid:
			print("user valid")
		else:
			var p : ENetPacketPeer = Peer.get_peer(target_id)
			p.peer_disconnect()
		)
	Lobby.connect("port_open",func():
		Port = Lobby.Port_UDP
		Peer = ENetMultiplayerPeer.new()
		var err = Peer.create_server(Port,1)
		multiplayer.multiplayer_peer = Peer
		return err
	)
	multiplayer.connected_to_server.connect(func():
		print("Connected to lobby owner!")
		emit_signal("connected_to_lobby")
		In_Lobby = true
		Game_Started = false
	)
	multiplayer.connection_failed.connect(func(_id):
		print("Failed connection to lobby owner!")
		emit_signal("failed_to_connect")
	)
	multiplayer.server_disconnected.connect(func():
		print("Disconnected from the lobby!")
		emit_signal("disconnected",In_Lobby)
		In_Lobby = false
		Game_Started = false
		)

func _peer_connected(id):
	if Game_Started:
		disconnect_player(id)
		return
	print(str(id)+" joined the lobby.")
	emit_signal("peer_joined_lobby",id)
func _peer_disconnected(id):
	if In_Lobby:
		print(str(id)+" left the lobby.")
		emit_signal("peer_left_lobby",id)
	else:
		print(str(id)+" left the game.")

func create_server():
	done_loading_count = 0
	if Peer != null:
		Peer.close()
	multiplayer.multiplayer_peer = null
	Peer = ENetMultiplayerPeer.new()
	var err = Peer.create_server(Port,12)
	multiplayer.multiplayer_peer = Peer
	Peer.peer_connected.connect(_peer_connected)
	Peer.peer_disconnected.connect(_peer_disconnected)
	In_Lobby = true
	Lobby_Host = true
	Game_Started = false
	return err
