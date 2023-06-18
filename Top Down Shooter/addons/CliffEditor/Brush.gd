@tool
extends Node3D
var _image := Image.new()
var _scale := 1.0

# Called when the node enters the scene tree for the first time.
func _ready():
	_image = _image.create(1,1,true,Image.FORMAT_RGBA8)
	update_brush_size(1)

func update_brush_size(_size) -> PackedVector3Array:
	var bounds = Vector3(_size,0,_size) * 2
	var center = Vector2(_size,_size)
	var brush_points : PackedVector3Array = []
	_image.resize(bounds.x,bounds.z)
	_image.fill(Color(0,0,0,0))
	var _half = _scale / 2
	var r2 = _size
	if _size < 3:
		r2 *= .99
	for x in bounds.x:
		for y in bounds.z:
			var pos = Vector2(x,y)
			if pos.distance_squared_to(center) <= r2:
				_image.set_pixelv(Vector2i(pos),Color.TURQUOISE)
				brush_points.append((Vector3(x,0,y)-bounds/2)*_scale)
	scale = Vector3(_size,_size,_size) * _scale
	$MeshInstance3D.get_surface_override_material(0).albedo_texture = ImageTexture.create_from_image(_image)
	return brush_points
