extends Node
@onready var UNPN_Handler = $UPNP
var Peer : ENetMultiplayerPeer
var Port
var LobbyData
signal PlayerConnects(player)
signal PlayerLeaves(player)

func _ports_ready(err,port):
	if err != OK:
		print(err)
	else:
		print("Ports have been setup through UPNP
			UDP: "+str(port)+"
			TCP: "+str(port))
		_host(port,4095)
		print("Server start success!")

func _ready():
	UNPN_Handler.connect("upnp_completed",_ports_ready)
	UNPN_Handler.start()

func _host(port,max_clients):
	Peer = ENetMultiplayerPeer.new()
	Peer.create_server(port,max_clients)
	multiplayer.multiplayer_peer = Peer
	Peer.peer_connected.connect(func(id):
		print(str(id)+" joined the game.")
	)
	Peer.peer_disconnected.connect(func(id):
		print(str(id)+" left the game.")
	)

#func connect_to_server(ip = "localhost", port = DEFAULT_PORT):
#	multiplayer_peer = ENetMultiplayerPeer.new()
#	multiplayer_peer.create_client(ip, port)
#	multiplayer.multiplayer_peer = multiplayer_peer
#	multiplayer.server_disconnected.connect(func():
#		multiplayer_peer = null
#		emit_signal("ServerDisconnected")
#	)
