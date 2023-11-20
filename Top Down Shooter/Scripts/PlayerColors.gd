@tool
extends Node
var img = Image.create(Config.MAX_PLAYERS,1,false,Image.FORMAT_RGBA8)
@export var player_colors : PackedColorArray = [
	Color("ff0303"),
	Color("0042ff"),
	Color("1be7ba"),
	Color("550081"),
	Color("fefc00"),
	Color("fe890d"),
	Color("21bf00"),
	Color("e45caf"),
	Color("939596"),
	Color("7ebff1"),
	Color("106247"),
	Color("4f2b05"),
	Color("9c0000"),
	Color("0000c3"),
	Color("00ebff"),
	Color("bd00ff"),
	Color("ecce87"),
	Color("f7a58b"),
	Color("bfff81"),
	Color("dbb8eb"),
	Color("4f5055"),
	Color("ecf0ff"),
	Color("00781e"),
	Color("a56f34")
]:
	set(value):
		player_colors = value
		var i = 0
		for col in player_colors:
			img.set_pixel(i,0,col)
			i += 1
		output = ImageTexture.create_from_image(img)
		if not Engine.is_editor_hint():
			RenderingServer.global_shader_parameter_set("PlayerColors",output)
@export var output : ImageTexture
func _ready():
	player_colors = player_colors
