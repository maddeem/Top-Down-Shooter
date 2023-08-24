extends Node
signal upnp_completed(error,port)
@export var Port = [5781]
@export var Port_Name = "TopDownShooter_Server"
var _upnp = UPNP.new()
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

func start() -> void:
	var err= _upnp.discover()
	if err != OK:
		push_error(str(err))
		call_deferred("emit_signal","upnp_completed",err,err,-1)
		return
	if _upnp.get_gateway() and _upnp.get_gateway().is_valid_gateway():
		_udp_port = _explore_port(Port,"UDP")
		_tcp_port = _explore_port(Port,"TCP")
		if _udp_port == -1:
			err = "UDP port unavailable: "+str(Port)
			push_error(err)
		if _tcp_port == -1:
			err = "TCP port unavailable: "+str(Port)
			push_error(err)
		call_deferred("emit_signal","upnp_completed",err,_udp_port)

func _on_tree_exiting():
	_upnp.delete_port_mapping(_udp_port,"UDP")
	_upnp.delete_port_mapping(_tcp_port,"TCP")
