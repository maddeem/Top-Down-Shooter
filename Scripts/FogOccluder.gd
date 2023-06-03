@tool
extends Node3D
const FOLDER_PATH = "res://Assets/OccluderTextures/"
## Accepts only TGA files, transparent pixels do not occlude. The occlusion texture is centered on the node.
@export_file("*.tga","*.png") var Occluder_Texture = FOLDER_PATH:
	set(value):
		Occluder_Texture = value
		if value == FOLDER_PATH or value == null:
			Occlusion_Points = null
			return
		else:
			if Cache.exists(Occluder_Texture):
				Occlusion_Points = Cache.read_from(Occluder_Texture)
				return
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

# Called when the node enters the scene tree for the first time.
func _ready():
	add_to_group("UpdateOccluders")

func _physics_process(_delta):
	var cur_pos = Vector2i(round(global_position.x),round(global_position.z))
	if cur_pos != Last_Position:
		Last_Position = cur_pos
		add_to_group("UpdateOccluders")
