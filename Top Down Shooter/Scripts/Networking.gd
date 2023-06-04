extends Node
@export var LOBBY_SERVER_IP = "97.93.138.100"
@export var LOBBY_SERVER_PORT = 5781
@onready var UNPN_Handler = $UPNP
var Port_UDP
var Port_TCP
var Peer : ENetMultiplayerPeer


func _ports_ready(err,tcp,udp):
	if err != OK:
		print(err)
	else:
		print("Ports have been setup through UPNP
			UDP: "+str(udp)+"
			TCP: "+str(tcp))
		Port_UDP = udp
		Port_TCP = tcp
		_connect()
		print("Server start success!")

func _ready():
	UNPN_Handler.connect("upnp_completed",_ports_ready)
	UNPN_Handler.start()

func _connect():
	Peer = ENetMultiplayerPeer.new()
	Peer.create_client(LOBBY_SERVER_IP, LOBBY_SERVER_PORT)
	multiplayer.multiplayer_peer = Peer
	multiplayer.server_disconnected.connect(func():
		Peer = null
	)
