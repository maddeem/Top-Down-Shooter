@tool
extends Node3D
const FOLDER_PATH = "res://Assets/PathingTextures/"
@onready var debug = $MeshInstance3D
## Accepts only TGA files, transparent pixels do not occlude. The occlusion texture is centered on the node.
@export_file("*.tga") var Blocker_Texture = FOLDER_PATH:
	set(value):
		Blocker_Texture = value
		add_to_group("UpdateBlockers")
		var img : Image = load(Blocker_Texture).get_image()
		if debug:
			debug.get_surface_override_material(0).albedo_texture = load(Blocker_Texture)
			debug.scale = Vector3(img.get_width(),1,img.get_height())
		if value == FOLDER_PATH or value == null:
			Block_Points = null
			return
		else:
			if Cache.exists("blockers",Blocker_Texture):
				Block_Points = Cache.read_from("blockers",Blocker_Texture)
				return
		#This is expensive for larger textures, so we cache the results. The caching
		#Is done at run time, but I can look into making the cache be part of the loading
		#phase
		Block_Points = []
		img.decompress()
		var size = Vector2i(img.get_width(),img.get_height())
		var half = size/2
		for x in size.x:
			for y in size.y:
				if img.get_pixel(x,y).a != 0:
					Block_Points.append(Vector2i(x,y)-half)
		Cache.write_to("blockers",Blocker_Texture,Block_Points)

## Automatically generated from the Occluder texture. Do not modify unless you know what you are doing.
@export var Block_Points = []
var Last_Points_Modified = []
var Last_Position

func _ready():
	Blocker_Texture = Blocker_Texture
	set_notify_transform(true)
	_notification(NOTIFICATION_TRANSFORM_CHANGED)

func _notification(what: int) -> void:
	if what == NOTIFICATION_TRANSFORM_CHANGED:
		var cur_pos = Vector2i(Vector2(global_position.x+0.5,global_position.z).round())
		if cur_pos != Last_Position:
			Last_Position = cur_pos
			add_to_group("UpdateBlockers")
