@tool
extends Node3D
var _image := Image.new()

func getGridPointsInCircle(radius: int) -> Array:
	if Cache.exists("CircleGridPoints",radius):
		return Cache.read_from("CircleGridPoints",radius)
	var gridPoints = []
	var x = 0
	var y = radius
	var decision = 5 / 4 - radius
	while x <= y:
		gridPoints.append(Vector2(  x,  y))
		gridPoints.append(Vector2( - x,  y))
		gridPoints.append(Vector2(  x, - y))
		gridPoints.append(Vector2( - x, - y))
		gridPoints.append(Vector2(  y,  x))
		gridPoints.append(Vector2( - y,  x))
		gridPoints.append(Vector2(  y, - x))
		gridPoints.append(Vector2( - y, - x))
		if decision < 0:
			decision += 2 * x + 1
		else:
			decision += 2 * (x - y) + 1
			y -= 1
		x += 1
	Cache.write_to("CircleGridPoints",radius,gridPoints)
	return gridPoints

# Called when the node enters the scene tree for the first time.
func _ready():
	_image = _image.create(1,1,true,Image.FORMAT_RGBA8)
	update_brush_size(1)

func update_brush_size(_size):
	var bounds = Vector2(_size,_size) * 2
	var center = Vector2(_size,_size)
	var points = []
	_image.resize(bounds.x,bounds.y)
	_image.fill(Color(0,0,0,0))
	var r2 = _size
	if _size < 3:
		r2 *= .99
	for x in bounds.x:
		for y in bounds.y:
			if Vector2(x,y).distance_squared_to(center) <= r2:
				_image.set_pixelv(Vector2i(x,y),Color.TURQUOISE)
	scale = Vector3(_size,_size,_size)
	$MeshInstance3D.get_surface_override_material(0).albedo_texture = ImageTexture.create_from_image(_image)
	
	
