extends Node
var id2widget = {}
var _id_count = 0
var _recycle_list = []
var packed_movement_data := PackedByteArray()

func reset():
	await get_tree().create_timer(1).timeout
	id2widget = {}
	_id_count = 0
	_recycle_list = []
	packed_movement_data = PackedByteArray()

func _ready():
	var count = 1
	for path in Utility.dir_contents("res://Editables/Widgets"):
		path = path.replace(".remap","")
		Cache.write_to("WidgetID",path,count)
		Cache.write_to("WidgetID",count,path)
		count += 1
	for path in Utility.dir_contents("res://Scenes/Widgets"):
		path = path.replace(".remap","")
		Cache.write_to("WidgetID",count,path)
		Cache.write_to("WidgetID",path,count)
		count += 1

func swap_id_path(path_or_id):
	return Cache.read_from("WidgetID",path_or_id)

@rpc("authority","call_local","reliable")
func create_widget_at(id : int, pos : Vector3) -> Widget:
	var new : Widget = load(swap_id_path(id)).instantiate()
	Globals.World.add_child(new)
	new.move_instantly(pos)
	return new

@rpc("authority","call_local","reliable")
func create_unit_at(id : int,pos : Vector3,player_owner : int):
	var new = create_widget_at(id,pos)
	new.player_owner = player_owner
	return new

func Instance2Node(inst :int) -> Node:
	if id2widget.has(inst):
		return id2widget[inst]
	else:
		return null

func get_new_id(source : Node) -> int:
	var id
	source.tree_exiting.connect(recycle_id.bind(source))
	if _recycle_list.size() == 0:
		_id_count += 1
		id = _id_count
	else:
		id = _recycle_list.pop_back()
	id2widget[id] = source
	return id

func recycle_id(source : Node):
	_recycle_list.append(source.instance_id)
	id2widget.erase(source.instance_id)

func dispatch_data(inst : int, func_id : int, args : Variant):
		if args is Array:
			Instance2Node(inst).callv(int2method(inst,func_id),args)
		elif args != null:
			Instance2Node(inst).call(int2method(inst,func_id),args)
		else:
			Instance2Node(inst).call(int2method(inst,func_id))

@rpc("any_peer","call_local","reliable")
func sclr(inst : int, func_id : int, args : Variant):
	dispatch_data(inst,func_id,args)

@rpc("any_peer","call_remote","reliable")
func scrr(inst : int, func_id : int, args : Variant):
	dispatch_data(inst,func_id,args)
	
@rpc("any_peer","call_local","unreliable")
func sclu(inst : int, func_id : int, args : Variant):
	dispatch_data(inst,func_id,args)

@rpc("any_peer","call_remote","unreliable")
func scru(inst : int, func_id : int, args : Variant):
	dispatch_data(inst,func_id,args)

func method2int(inst : int, method : String):
	var source = Instance2Node(inst)
	var path = "widgetmethods"+source.scene_file_path
	if Cache.exists(path,method):
		return Cache.read_from(path,method)
	var i = 0
	for which in source.get_method_list():
		if which.name == method:
			Cache.write_to(path,method,i)
			return i
		i += 1
	return -1

func int2method(inst : int, method_id: int) -> String:
	var source = Instance2Node(inst)
	var path = "widgetid2method"+source.scene_file_path
	if Cache.exists(path,method_id):
		return Cache.read_from(path,method_id)
	var method_name = source.get_method_list()[method_id].name
	Cache.write_to(path,method_id,method_name)
	return method_name

func _get_buff(inst : int, func_name : String) -> PackedByteArray:
	var buf = PackedByteArray()
	buf.resize(4)
	buf.encode_u16(0,inst)
	buf.encode_u16(2,method2int(inst,func_name))
	return buf

func server_call(inst : int, func_name : String, args : Variant = null, local := true, reliable := true):
	if multiplayer.is_server():
		if local:
			if reliable:
				sclr.rpc(inst,method2int(inst,func_name),args)
			else:
				sclu.rpc(inst,method2int(inst,func_name),args)
		else:
			if reliable:
				scrr.rpc(inst,method2int(inst,func_name),args)
			else:
				scru.rpc(inst,method2int(inst,func_name),args)

func peer_call(inst : int, func_name : String, args : Variant = null, reliable := true, local := false):
	if local:
		if reliable:
			sclr.rpc_id(1,inst,method2int(inst,func_name),args)
		else:
			sclu.rpc_id(1,inst,method2int(inst,func_name),args)
	else:
		if reliable:
			scrr.rpc_id(1,inst,method2int(inst,func_name),args)
		else:
			scru.rpc_id(1,inst,method2int(inst,func_name),args)

@rpc("any_peer","reliable","call_local")
func anyone_server_recieve(inst : int, func_name : String, args : Variant = null):
	server_call(inst,func_name,args,true)

func anyone_call(inst : int, func_name : String, args : Variant = null):
	if multiplayer.is_server():
		server_call(inst,func_name,args,true)
	else:
		anyone_server_recieve.rpc_id(1,inst,func_name,args)

func queue_movement(source : Widget):
	var buf = PackedByteArray()
	buf.resize(10)
	buf.encode_u16(0,source.instance_id)
	buf.encode_half(2,source.global_position.x)
	buf.encode_half(4,source.global_position.y)
	buf.encode_half(6,source.global_position.z)
	buf.encode_half(8,source.rotation.y)
	packed_movement_data.append_array(buf)

func _process(_delta):
	if packed_movement_data.size() > 0:
		if multiplayer.is_server():
			unpack_movement_data.rpc(packed_movement_data)
		else:
			unpack_movement_data.rpc_id(1,packed_movement_data)
	packed_movement_data = PackedByteArray()
	
@rpc("any_peer","reliable","call_remote")
func unpack_movement_data(data : PackedByteArray):
	var size = data.size()
	var pos = 0
	var sender = multiplayer.get_remote_sender_id()
	while pos < size:
		var inst : Widget = Instance2Node(data.decode_u16(pos))
		if inst:
			inst.set_next_transform(
				sender,
				Vector3(data.decode_half(pos+2),data.decode_half(pos+4),data.decode_half(pos+6)),
				data.decode_half(pos+8)
			)
		pos += 10
