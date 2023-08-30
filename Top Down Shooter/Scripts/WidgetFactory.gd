extends Node


# Called when the node enters the scene tree for the first time.
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
