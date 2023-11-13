extends TextureRect
const RETICLE_RADIUS := 0.77
const RETICLE_OFFSET := 0.6
const NOISE_SPEED := 10.0
var new_scale := 1.0
var cur_scale := 1.0
var cur_pos := Vector2(0.5,0.5)
var total_size := Vector2(200,200):
	set(value):
		total_size = value
		if get_parent():
			size = total_size
			_half_size = total_size * 0.5
var _half_size = total_size * 0.5
var _time := 0.0

@onready var mat : ShaderMaterial = material
@onready var noise := FastNoiseLite.new()
# Called when the node enters the scene tree for the first time.
func _ready():
	Input.set_mouse_mode(Input.MOUSE_MODE_HIDDEN)
	Globals.Reticle = self
	noise.noise_type = FastNoiseLite.TYPE_SIMPLEX
	noise.fractal_type = FastNoiseLite.FRACTAL_NONE
	noise.frequency = 0.16
	mat.set_shader_parameter("reticle_radius",RETICLE_RADIUS)
	mat.set_shader_parameter("reticle_offset",RETICLE_OFFSET)
	total_size = total_size

func _input(event):
	if event is InputEventMouseMotion:
		position = event.position - _half_size

func _physics_process(delta):
	_time += delta
	cur_scale = lerp(cur_scale,new_scale * 0.125,0.1)
	cur_pos = get_noise_from_seed(Vector2i(1,2))
	cur_pos.x *= PI * 0.5
	cur_pos.y = lerp(cur_pos.y,0.0,max(0.0,0.75 - cur_scale))
	mat.set_shader_parameter("scale",cur_scale)
	mat.set_shader_parameter("optic_position",cur_pos)

func get_noise_from_seed(_seed : Vector2i) -> Vector2:
	var new = Vector2.ZERO
	var speed = _time * NOISE_SPEED
	noise.seed = _seed.x
	new.x = noise.get_noise_1d(speed)
	noise.seed = _seed.y
	new.y = noise.get_noise_1d(speed)
	return new

func resolve_position() -> Vector2:
	var dist = cur_pos.y * RETICLE_RADIUS * cur_scale * RETICLE_OFFSET
	var offset = Vector2(cos(cur_pos.x) * dist, sin(cur_pos.x) * dist)
	return position + _half_size + offset * total_size
