@tool
extends Node3D
const FOLDER_PATH = "res://Assets/PathingTextures/"
@onready var debug = $MeshInstance3D
@export var disabled := false:
	set(value):
		disabled = value
		add_to_group("UpdateBlockers")
## Accepts only TGA files, transparent pixels do not occlude. The occlusion texture is centered on the node.
@export_file("*.tga") var Blocker_Texture = FOLDER_PATH:
	set(value):
		Blocker_Texture = value
		if Last_Rotation == null:
			return
		add_to_group("UpdateBlockers")
		var img : Image = load(Blocker_Texture).get_image()
		img.decompress()
		match Last_Rotation:
			1:
				img.rotate_90(COUNTERCLOCKWISE)
			2: 
				img.rotate_180()
			3:
				img.rotate_90(CLOCKWISE)
		if debug:
			debug.get_surface_override_material(0).albedo_texture = load(Blocker_Texture)
			debug.scale = Vector3(img.get_width(),1,img.get_height()) / global_transform.basis.get_scale()
		if value == FOLDER_PATH or value == null:
			Block_Points = null
			return
		else:
			if Cache.exists("blockers",Blocker_Texture):
				Block_Points = Cache.read_from("blockers",Blocker_Texture+str(Last_Rotation))
				return
		#This is expensive for larger textures, so we cache the results. The caching
		#Is done at run time, but I can look into making the cache be part of the loading
		#phase
		Block_Points = []
		var size = Vector2i(img.get_width(),img.get_height())
		var half = size/2
		for x in size.x:
			for y in size.y:
				if img.get_pixel(x,y).a != 0:
					Block_Points.append(Vector2i(x,y)-half)
		Cache.write_to("blockers",Blocker_Texture+str(Last_Rotation),Block_Points)

## Automatically generated from the Occluder texture. Do not modify unless you know what you are doing.
@export var Block_Points = []
var Last_Points_Modified = []
var Last_Position
var Last_Rotation

func _ready():
	set_notify_transform(true)
	_notification(NOTIFICATION_TRANSFORM_CHANGED)

func _notification(what: int) -> void:
	if what == NOTIFICATION_TRANSFORM_CHANGED:
		var cur_pos = Vector2i(Vector2(global_position.x,global_position.z).floor())
		var cur_angle = wrapi(round(global_rotation_degrees.y/90)+1,0,4)
		if Last_Rotation != cur_angle:
			Last_Rotation = cur_angle
			Blocker_Texture = Blocker_Texture
		if cur_pos != Last_Position:
			Last_Position = cur_pos
			add_to_group("UpdateBlockers")
