extends Node
var id2widget = {}
var _id_count = 0
var _recycle_list = []
var server_cache_local = []
var server_cache_remote = []
var peer_cache = []


func _ready():
	var count = 1
	for path in Utility.dir_contents("res://Editables/Widgets"):
		Cache.write_to("WidgetID",path,count)
		Cache.write_to("WidgetID",count,path)
		count += 1
	for path in Utility.dir_contents("res://Scenes/Widgets"):
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
	new.player_owner = PlayerLib.PlayerById[player_owner]
	return new

func Instance2Widget(inst :int) -> Widget:
	return id2widget[inst]

func get_new_id(source : Widget) -> int:
	var id
	if _recycle_list.size() == 0:
		_id_count += 1
		id = _id_count
	else:
		id = _recycle_list.pop_back()
	id2widget[id] = source
	return id

func recycle_id(source : Widget):
	_recycle_list.append(source.instance_id)
	id2widget.erase(source.instance_id)

func dispatch_data(inst : int, func_id : int, args : Variant):
		if args is Array:
			Instance2Widget(inst).callv(int2method(inst,func_id),args)
		elif args != null:
			Instance2Widget(inst).call(int2method(inst,func_id),args)
		else:
			Instance2Widget(inst).call(int2method(inst,func_id))

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
	var source = Instance2Widget(inst)
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
	var source = Instance2Widget(inst)
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

func peer_call(inst : int, func_name : String, args : Variant = null, reliable := true):
	if reliable:
		scrr.rpc_id(1,inst,method2int(inst,func_name),args)
	else:
		scru.rpc_id(1,inst,method2int(inst,func_name),args)
