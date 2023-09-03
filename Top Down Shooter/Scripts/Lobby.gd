extends Node
@export var LOBBY_SERVER_IP = "97.93.138.100"
@export var LOBBY_SERVER_PORT = 5781
var UNPN_Handler
var Port_UDP
var Peer := ENetMultiplayerPeer.new()
var Server := ENetMultiplayerPeer.new()
var lobbies_open = {}
var _target_ip
var _target_port
var _ping_timer = Timer.new()
var server_api = MultiplayerAPI.create_default_interface()
var ping_thread := Thread.new()
enum LOBBY_STATE{
	NEW,
	DELETE,
	UPDATE,
	GET_ALL_DATA
}
signal port_open
signal sever_setup
signal lobby_creation_success
signal new_lobby_discovered
signal lobby_updated
signal lobby_closed
signal connected_to_lobby_server
signal lobby_ping_updated

func _ports_ready(err,_tcp,udp):
	if err != OK:
		print(err)
	else:
		print("Ports have been setup through UPNP
			UDP: "+str(udp))
		Port_UDP = udp
		emit_signal("port_open")
		start_lobby_server_connection()

@rpc("authority","reliable")
func send_desired_port(_port):
	pass

func start_lobby_server_connection():
	_target_ip = LOBBY_SERVER_IP
	_target_port = LOBBY_SERVER_PORT
	_connect()

func _threaded_ping():
	var results = {}
	for id in lobbies_open:
		var lobby = lobbies_open[id]
		var output = []
		OS.execute('ping', ['-n', '2', '-l', '1', lobby.ip], output,true)
		var tar : String = output[0]
		var pos = tar.find("Average = ")
		if pos != -1:
			results[id] = int(tar.substr(pos + 10))
		else:
			results[id] = -1
	ping_thread.call_deferred("wait_to_finish")
	for id in results:
		call_deferred("emit_signal","lobby_ping_updated",id,results[id])

func _ready():
	add_child(_ping_timer)
	_ping_timer.start()
	_ping_timer.wait_time = 3
	_ping_timer.timeout.connect(func():
		if not ping_thread.is_alive() or not ping_thread.is_started():
			ping_thread = Thread.new()
			ping_thread.start(_threaded_ping,Thread.PRIORITY_LOW)
		)
	get_tree().set_multiplayer(server_api, self.get_path())
#	UNPN_Handler = load("res://Scenes/UPNP.tscn").instantiate()
#	add_child(UNPN_Handler)
#	UNPN_Handler.connect("upnp_completed",_ports_ready)
#	UNPN_Handler.start()
	multiplayer.server_disconnected.connect(func():
		Peer = null
		multiplayer.multiplayer_peer = null
		print("Lobby Server Disconnected")
		_connect()
	)
	multiplayer.connected_to_server.connect(func():
		print("Connected to lobby server!")
		emit_signal("connected_to_lobby_server")
		rpc_id(1,"send_desired_port",Port_UDP)
	)
	multiplayer.connection_failed.connect(func(_id):
		print("failed connection to server")
		_connect()
	)
	Network.connect("peer_joined_lobby",func(_id):
		var lobby_owner = Peer.get_unique_id()
		var lobby = lobbies_open[lobby_owner]
		lobby.player_count += 1
		rpc_id(1,"update_lobby",LOBBY_STATE.UPDATE,lobby,lobby_owner)
		)
	Network.connect("peer_left_lobby",func(_id):
		var lobby_owner = Peer.get_unique_id()
		var lobby = lobbies_open[lobby_owner]
		lobby.player_count -= 1
		rpc_id(1,"update_lobby",LOBBY_STATE.UPDATE,lobby,lobby_owner)
		)
	await get_tree().create_timer(1).timeout
	_ports_ready(OK,5110,5110)

@rpc("any_peer","reliable")
func update_lobby(state,data,_id = 0):
	match state:
		LOBBY_STATE.NEW:
			lobbies_open[_id] = data
			if _id == Peer.get_unique_id():
				if Network.create_server() == OK:
					emit_signal("lobby_creation_success")
			else:
				emit_signal("new_lobby_discovered",data,_id)
		LOBBY_STATE.DELETE:
			lobbies_open.erase(_id)
			emit_signal("lobby_closed",_id)
		LOBBY_STATE.GET_ALL_DATA:
			lobbies_open = data
			for lobby in data:
				emit_signal("new_lobby_discovered",data[lobby],lobby)
		LOBBY_STATE.UPDATE:
			lobbies_open[_id] = data
			emit_signal("lobby_updated",data,_id)

@rpc("any_peer","reliable")
func create_lobby():
	pass

func _connect(source : Node = self):
	print("Connect Attempt: ",_target_ip, _target_port)
	Peer = ENetMultiplayerPeer.new()
	var err = Peer.create_client(_target_ip, _target_port)
	source.multiplayer.multiplayer_peer = Peer
	return err

func join_lobby(lobby):
	_target_ip = lobby.ip
	_target_port = int(lobby.port)
	_connect(Network)
