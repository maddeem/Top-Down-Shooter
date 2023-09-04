extends Node
@onready var vp = $SubViewport
@export var Dimensions = Vector2i(1024,1024):
	set(value):
		Dimensions = value
		half_dimensions = value / 2
		img = Image.create(Dimensions.x,Dimensions.y,false,Image.FORMAT_RGBA8)
		img.fill(Color(0,0,0,0))
		data_img = Image.create(Dimensions.x,Dimensions.y,false,Image.FORMAT_RGB8)
		data_img.fill(Color(0.0,0.0,0.0))
		vp.size = Dimensions
		$SubViewport/PreviousIteration.texture = ImageTexture.create_from_image(img)
var half_dimensions
var img : Image
var data_img : Image
var counts = {}
var _update_required = false


func _ready():
	Dimensions = Dimensions 

func update_point(point : Vector2, add : int):
	_update_required = true
	point = Vector2i(point) + half_dimensions
	if not counts.has(point):
		counts[point] = 0
	counts[point] += add
	var count = counts[point]
	match count:
		1:
			data_img.set_pixelv(point,Color(1.0,0,0.0,0.0))
		0:
			data_img.set_pixelv(point,Color(0.0,0,0.0,0.0))

var update_viewport = 0
func _physics_process(_delta):
	update_viewport += 1
	if update_viewport > 3:
		update_viewport = 0
		RenderingServer.global_shader_parameter_set("CreepData",ImageTexture.create_from_image(vp.get_texture().get_image()))
		if _update_required:
			_update_required = false
			RenderingServer.global_shader_parameter_set("CreepDataIn",ImageTexture.create_from_image(data_img))
