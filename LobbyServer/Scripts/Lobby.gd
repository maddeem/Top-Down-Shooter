extends Node
var UNPN_Handler
var Peer := ENetMultiplayerPeer.new()
var Port
var LobbyData = {}
var hosted_status = {}
var player_desired_port = {}
var server_api = MultiplayerAPI.create_default_interface()
enum LOBBY_STATE{
	NEW,
	DELETE,
	UPDATE,
	GET_ALL_DATA
}

func _ports_ready(err,port):
	if err != OK:
		print(err)
	else:
		print("Ports have been setup through UPNP
			UDP: "+str(port)+"
			TCP: "+str(port))
		_host(port,4095)
		print("Server start success!")

@rpc("any_peer","reliable")
func update_lobby(state,data,id):
	if id != multiplayer.get_remote_sender_id():
		return
	match state:
		LOBBY_STATE.UPDATE:
			if LobbyData.has(id):
				LobbyData[id] = data
				rpc("update_lobby",state,data,id)
		LOBBY_STATE.DELETE:
			if LobbyData.has(id):
				rpc("update_lobby",LOBBY_STATE.DELETE,LobbyData[id],id)
				LobbyData.erase(id)

@rpc("any_peer","reliable")
func create_lobby():
	var sender = multiplayer.get_remote_sender_id()
	if player_desired_port.has(sender) == false:
		print("Error! Desired Port not recieved. Refusing to create lobby!")
		return
	var enet_sender : ENetPacketPeer = Peer.get_peer(sender)
	var address = enet_sender.get_remote_address()
	var port = str(player_desired_port[sender])
	var lobby = { 
		"ip" = address,
		"port" = port,
		"player_count" = 1
	}
	rpc("update_lobby",LOBBY_STATE.NEW,lobby,sender)
	print(str(sender) + " created lobby")
	LobbyData[sender] = lobby
	

func _ready():
	get_tree().set_multiplayer(server_api, self.get_path())
	UNPN_Handler = load("res://Scenes/UPNP.tscn").instantiate()
	add_child(UNPN_Handler)
	UNPN_Handler.connect("upnp_completed",_ports_ready)
	UNPN_Handler.start()

@rpc("any_peer","reliable")
func send_desired_port(port):
	var id = multiplayer.get_remote_sender_id()
	player_desired_port[id] = port

func _host(port,max_clients):
	Peer.create_server(port,max_clients)
	multiplayer.multiplayer_peer = Peer
	Peer.peer_connected.connect(func(id):
		print(str(id)+" connected.")
		rpc_id(id,"update_lobby",LOBBY_STATE.GET_ALL_DATA,LobbyData)
	)
	Peer.peer_disconnected.connect(func(id):
		print(str(id)+" disconnected.")
		player_desired_port.erase(id)
		if LobbyData.has(id):
			rpc("update_lobby",LOBBY_STATE.DELETE,LobbyData[id],id)
			LobbyData.erase(id)
	)
