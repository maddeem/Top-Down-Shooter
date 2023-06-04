extends Node
signal upnp_completed(error,tcp,udp)
@export var TCP_Port_Explore_Range = [
	80, 81, 443, 3478, 3479, 3480, 8080, 3074, 5223
]
@export var UDP_Port_Explore_Range = [
	3074, 3075, 3478, 3479
]
@export var Port_Name = "TopDownShooter"
var _upnp = UPNP.new()
var _thread : Thread = null
var _udp_port
var _tcp_port

func _explore_port(list : Array, which_protocol : String) -> int:
	for port in list:
		var err = _upnp.add_port_mapping(port,port,Port_Name+"_"+which_protocol,which_protocol,0)
		if err == OK:
			return port
		else:
			_upnp.add_port_mapping(port,port,"",which_protocol)
	return -1

func _upnp_setup() -> void:
	var err= _upnp.discover()
	if err != OK:
		push_error(str(err))
		emit_signal("upnp_completed",err,-1,-1)
		return
	if _upnp.get_gateway() and _upnp.get_gateway().is_valid_gateway():
		_udp_port = _explore_port(UDP_Port_Explore_Range,"UDP")
		_tcp_port = _explore_port(TCP_Port_Explore_Range,"TCP")
		if _tcp_port == -1:
			err = "No TCP ports available in range: "+str(TCP_Port_Explore_Range)
			push_error(err)
		if _udp_port == -1:
			err = "No UDP ports available in range: "+str(UDP_Port_Explore_Range)
			push_error(err)
		emit_signal("upnp_completed",err,_tcp_port,_udp_port)

func start():
	_thread = Thread.new()
	_thread.start(_upnp_setup)


func _on_tree_exiting():
	_thread.wait_to_finish()
	if _udp_port and _udp_port > 0:
		_upnp.delete_port_mapping(_udp_port,"UDP")
	if _tcp_port and _tcp_port > 0:
		_upnp.delete_port_mapping(_udp_port,"TCP")
