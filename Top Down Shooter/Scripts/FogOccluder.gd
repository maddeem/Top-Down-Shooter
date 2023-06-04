@tool
extends Node3D
const FOLDER_PATH = "res://Assets/OccluderTextures/"
@export_range(0,128) var Occlusion_Height : int = 1:
	set(value):
		Occlusion_Height = value
		if _last_Y:
			add_to_group("UpdateOccluders")
## Accepts only TGA files, transparent pixels do not occlude. The occlusion texture is centered on the node.
@export_file("*.tga") var Occluder_Texture = FOLDER_PATH:
	set(value):
		Occluder_Texture = value
		if _last_Y:
			add_to_group("UpdateOccluders")
		if value == FOLDER_PATH or value == null:
			Occlusion_Points = null
			return
		else:
			if Cache.exists(Occluder_Texture):
				Occlusion_Points = Cache.read_from(Occluder_Texture)
				return
		#This is expensive for larger textures, so we cache the results. The caching
		#Is done at run time, but I can look into making the cache be part of the loading
		#phase
		Occlusion_Points = []
		var img : Image = load(Occluder_Texture).get_image()
		img.decompress()
		var size = Vector2i(img.get_width(),img.get_height())
		var half = size/2
		for x in size.x:
			for y in size.y:
				if img.get_pixel(x,y).a != 0:
					Occlusion_Points.append(Vector2i(x,y)-half)
		Cache.write_to(Occluder_Texture,Occlusion_Points)

## Automatically generated from the Occluder texture. Do not modify unless you know what you are doing.
@export var Occlusion_Points = []
var Last_Points_Modified = []
var Last_Position
var _last_Y

func _physics_process(_delta) -> void:
	var cur_pos = Vector2i(round(global_position.x),round(global_position.z))
	if cur_pos != Last_Position or _last_Y != global_position.y:
		Last_Position = cur_pos
		_last_Y = global_position.y
		add_to_group("UpdateOccluders")