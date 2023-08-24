extends Node
signal upnp_completed(error,tcp,udp)
@export var Port_Name = "TopDownShooter"
var _upnp = UPNP.new()
var _peer_tester := UDPServer.new()
var _gateway
var _thread : Thread = null
var _udp_port
var _tcp_port

func _explore_port(size : int, which_protocol : String) -> int:
	for port in range(2000,2000+size):
		var err = _gateway.add_port_mapping(port,port,Port_Name+"_"+which_protocol,which_protocol,0)
		if err == OK:
			var err2 = _peer_tester.listen(port)
			if err2 == OK:
				return port
		else:
			push_error(str(err))
			_gateway.delete_port_mapping(port,which_protocol)
	return -1

func _upnp_setup() -> void:
	var err= _upnp.discover()
	if err != OK:
		push_error(str(err))
		_thread.wait_to_finish()
		call_deferred("emit_signal","upnp_completed",err,-1,-1)
		return
	_gateway = _upnp.get_gateway()
	if _gateway and _gateway.is_valid_gateway():
		_udp_port = _explore_port(1000,"UDP")
		if _tcp_port == -1:
			err = "No TCP ports available in range"
			push_error(err)
		if _udp_port == -1:
			err = "No UDP ports available in range"
			push_error(err)
		_peer_tester.stop()
		_peer_tester = null
		call_deferred("emit_signal","upnp_completed",err,_tcp_port,_udp_port)

func start():
	_thread = Thread.new()
	_thread.start(_upnp_setup)



func _on_tree_exiting():
	_thread.wait_to_finish()
	if _udp_port and _udp_port > 0:
		_upnp.delete_port_mapping(_udp_port,"UDP")
	if _tcp_port and _tcp_port > 0:
		_upnp.delete_port_mapping(_udp_port,"TCP")
