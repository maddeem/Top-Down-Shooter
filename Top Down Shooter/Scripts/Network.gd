extends Node
var Port
var Peer := ENetMultiplayerPeer.new()
var Players : Array = []
var In_Lobby = false
var Lobby_Host = false
signal connected_to_lobby
signal failed_to_connect
signal peer_joined_lobby
signal peer_left_lobby
signal disconnected

func close_server():
	if Peer != null:
		Peer.close()
	Peer = ENetMultiplayerPeer.new()
	var err = Peer.create_server(Port,1)
	multiplayer.multiplayer_peer = Peer
	In_Lobby = false
	Lobby_Host = false
	return err

func disconnect_player(id):
	Peer.disconnect_peer(id)

func _ready():
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
	)
	multiplayer.connection_failed.connect(func(_id):
		print("Failed connection to lobby owner!")
		emit_signal("failed_to_connect")
	)
	multiplayer.server_disconnected.connect(func():
		print("Disconnected from the lobby!")
		emit_signal("disconnected",In_Lobby)
		In_Lobby = false
		)

func _peer_connected(id):
	print(str(id)+" joined the lobby.")
	emit_signal("peer_joined_lobby",id)

func _peer_disconnected(id):
	if In_Lobby:
		print(str(id)+" left the lobby.")
		emit_signal("peer_left_lobby",id)
	else:
		print(str(id)+" left the game.")

func create_server():
	if Peer != null:
		Peer.close()
	Peer = ENetMultiplayerPeer.new()
	var err = Peer.create_server(Port,12)
	multiplayer.multiplayer_peer = Peer
	Peer.peer_connected.connect(_peer_connected)
	Peer.peer_disconnected.connect(_peer_disconnected)
	In_Lobby = true
	Lobby_Host = true
	return err
