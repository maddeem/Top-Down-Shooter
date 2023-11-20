extends Node
var UNPN_Handler
var Peer := ENetMultiplayerPeer.new()
var Port
var LobbyData = {}
var hosted_status = {}
var player_desired_port = {}
var server_api = MultiplayerAPI.create_default_interface()
var save_dirty = false
var save_time := 0.0
const SAVE_DIR = "C://Users//dezma//Saved Games//userdata.save"
const SAVE_PERIOD := 1.0
const MAX_ACCOUNTS_PER_IP := 3
enum LOBBY_STATE{
	NEW,
	DELETE,
	UPDATE,
	GET_ALL_DATA
}

enum ACCOUNT_STATE{
	USERNAME_TAKEN,
	CREATION_SUCCESS,
	MAX_ACCOUNTS,
	LOGIN_SUCCESS,
	LOGIN_FAILED,
	ALREADY_LOGGED_IN
}
var id_to_username = {}
var username_last_ip = {}
var users = {}
var logged_in = {}
var ip_counter = {}

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
		"owner" = id_to_username[sender],
		"ip" = address,
		"port" = port,
		"player_count" = 1
	}
	rpc("update_lobby",LOBBY_STATE.NEW,lobby,sender)
	print(lobby.owner + " created lobby")
	LobbyData[sender] = lobby
	
func save():
	var file = FileAccess.open(SAVE_DIR, FileAccess.WRITE)
	for user in users:
		file.store_line(user)
		file.store_line(JSON.stringify(users[user]))
	file.close()

func _ready():
	get_tree().set_auto_accept_quit(false)
	if FileAccess.file_exists(SAVE_DIR):
		var file = FileAccess.open(SAVE_DIR, FileAccess.READ)
		while not file.eof_reached():
			var data = JSON.new()
			var username = file.get_line()
			var output = data.parse(file.get_line())
			if output == OK:
				users[username] = data.data
				if ip_counter.has(users[username].ip):
					ip_counter[users[username].ip] += 1
				else:
					ip_counter[users[username].ip] = 1
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
		if player_desired_port.has(id):
			player_desired_port.erase(id)
		if LobbyData.has(id):
			rpc("update_lobby",LOBBY_STATE.DELETE,LobbyData[id],id)
			LobbyData.erase(id)
		if id_to_username.has(id):
			var username = id_to_username[id]
			logged_in.erase(username)
			print(username+" disconnected.")
			await get_tree().create_timer(10).timeout
			if not logged_in.has(username):
				id_to_username.erase(id)
				username_last_ip.erase(username)
		else:
			print(str(id)+" disconnected.")
	)

@rpc("any_peer","reliable")
func get_response(_state : int):
	pass

@rpc("any_peer","reliable")
func create_account(username : String, password : String):
	var id = multiplayer.get_remote_sender_id()
	var ip = Peer.get_peer(id).get_remote_address().sha256_text()
	if not ip_counter.has(ip):
		ip_counter[ip] = 0
	if users.has(username):
		get_response.rpc_id(id,ACCOUNT_STATE.USERNAME_TAKEN)
	else:
		if ip_counter[ip] <= MAX_ACCOUNTS_PER_IP:
			ip_counter[ip] += 1
			users[username] = {
				"password" = password.sha256_text(),
				"ip" = ip
				}
			save_dirty = true
			get_response.rpc_id(id,ACCOUNT_STATE.CREATION_SUCCESS)
		else:
			get_response.rpc_id(id,ACCOUNT_STATE.MAX_ACCOUNTS)

@rpc("any_peer","reliable")
func is_valid_username(_target_id: int, _is_valid : bool):
	pass

@rpc("any_peer","reliable")
func send_lobby_player_data(target_id: int, username : String, ip : String):
	var id = multiplayer.get_remote_sender_id()
	if username_last_ip.has(username):
		is_valid_username.rpc_id(id,target_id,username_last_ip[username] == ip.sha256_text())
	else:
		is_valid_username.rpc_id(id,target_id,false)

@rpc("any_peer","reliable")
func login_account(username : String, password : String):
	var id = multiplayer.get_remote_sender_id()
	if users.has(username):
		if users[username].password == password.sha256_text():
			if logged_in.has(username):
				get_response.rpc_id(id,ACCOUNT_STATE.ALREADY_LOGGED_IN)
			else:
				id_to_username[id] = username
				logged_in[username] = true
				username_last_ip[username] = Peer.get_peer(id).get_remote_address().sha256_text()
				print(username + " logged in on")
				get_response.rpc_id(id,ACCOUNT_STATE.LOGIN_SUCCESS)
		else:
			get_response.rpc_id(id,ACCOUNT_STATE.LOGIN_FAILED)
	else:
		get_response.rpc_id(id,ACCOUNT_STATE.LOGIN_FAILED)

func _process(delta):
	save_time -= delta
	if save_time < 0 and save_dirty:
		save()
		save_dirty = false
		save_time = SAVE_PERIOD
