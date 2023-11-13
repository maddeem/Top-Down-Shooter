@tool
extends Node3D
class_name VisionBlocker
const FOLDER_PATH = "res://Assets/PathingTextures/"
@onready var debug = $MeshInstance3D
@export var disabled := false:
	set(value):
		disabled = value
		add_to_group("UpdateOccluders")
@export_range(0,255) var Occlusion_Height : float = 1.0:
	set(value):
		Occlusion_Height = value
		if _last_Y != null:
			_update_occlusion_height()
## Accepts only TGA files, transparent pixels do not occlude. The occlusion texture is centered on the node.
@export_file("*.tga") var Occluder_Texture = FOLDER_PATH:
	set(value):
		Occluder_Texture = value
		if Last_Rotation == null:
			return
		var img= load(Occluder_Texture)
		if img == null:
			return
		img = img.get_image()
		img = img.duplicate()
		img.decompress()
		if debug:
			debug.get_surface_override_material(0).albedo_texture = load(Occluder_Texture)
			debug.scale = Vector3(img.get_width(),1,img.get_height()) / global_transform.basis.get_scale()
		if _last_Y != null:
			add_to_group("UpdateOccluders")
		if value == FOLDER_PATH or value == null:
			Occlusion_Points = null
			return
		else:
			if Cache.exists("occluders",Occluder_Texture):
				Occlusion_Points = Cache.read_from("occluders",Occluder_Texture+str(Last_Rotation))
				return
		#This is expensive for larger textures, so we cache the results. The caching
		#Is done at run time, but I can look into making the cache be part of the loading
		#phase
		Occlusion_Points = []
		for i in Last_Rotation:
			img.rotate_90(COUNTERCLOCKWISE)
		var size = Vector2i(img.get_width(),img.get_height())
		var half = size/2
		for x in size.x:
			for y in size.y:
				if img.get_pixel(x,y).a != 0:
					Occlusion_Points.append((Vector2i(x,y)-half))
		Cache.write_to("occluders",Occluder_Texture+str(Last_Rotation),Occlusion_Points)

## Automatically generated from the Occluder texture. Do not modify unless you know what you are doing.
@export var Occlusion_Points = []
var Last_Points_Modified = []
var Last_Position
var Last_Rotation
var Adjusted_Occlusion_Height : Color
var Previous_Occlusion_Height
var _last_Y

func _ready():
	set_notify_transform(true)
	_notification(NOTIFICATION_TRANSFORM_CHANGED)

func _update_occlusion_height():
	var this_max = clamp((global_position.y + Occlusion_Height)/63.75,0.0,4.0)
	Adjusted_Occlusion_Height = Color(0,0,0,0)
	for i in 4:
		var next = this_max - 1.0
		if next > 0:
			Adjusted_Occlusion_Height[i] = 1.0
			this_max -= 1.0
		else:
			Adjusted_Occlusion_Height[i] = this_max
			break
	add_to_group("UpdateOccluders")

func _notification(what: int) -> void:
	if what == NOTIFICATION_TRANSFORM_CHANGED:
		var cur_pos = Vector2i(Vector2(global_position.x,global_position.z).round())
		if cur_pos != Last_Position:
			Last_Position = cur_pos
			add_to_group("UpdateOccluders")
		if _last_Y != global_position.y:
			_last_Y = global_position.y
			_update_occlusion_height()
		var cur_angle = wrapi(round(global_rotation_degrees.y/90)+1,0,4)
		if Last_Rotation != cur_angle:
			Last_Rotation = cur_angle
			Occluder_Texture = Occluder_Texture
