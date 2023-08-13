extends Widget
const SPEED = 5.0
const JUMP_VELOCITY = 12.5
@export var direction : Vector2
@export var jumping : bool
@onready var camera = $"Shakable Camera"
var is_owner = false
var _camera_offset = Vector3(0,2,0.0)
var _prev_data
# Called when the node enters the scene tree for the first time.
func _ready():
	super._ready()
	is_owner = get_multiplayer_authority() == multiplayer.get_unique_id()
	camera._camera.current = is_owner

@rpc("call_local","reliable")
func sync_input(dir,jump):
	direction = dir
	if jump and is_on_floor():
		velocity.y = JUMP_VELOCITY

func _input(_event):
	if not is_owner:
		return
	var dir = Input.get_vector("Move_Left","Move_Right","Move_Up","Move_Down")
	var jump_press = Input.is_action_just_pressed("Jump")
	if dir != direction or jump_press:
		rpc("sync_input",dir,jump_press)

@rpc("unreliable")
func _update_data(buf : PackedByteArray):
	_prev_data = [global_position,rotation.y]
	global_position = Vector3(buf.decode_half(0),buf.decode_half(2),buf.decode_half(4))
	rotation.y = buf.decode_half(6)

func _physics_process(delta):
	if multiplayer.is_server():
		if not is_on_floor():
			velocity.y -= Globals.Gravity * delta
		velocity.x = direction.x * SPEED
		velocity.z = direction.y * SPEED
		if velocity.is_equal_approx(Vector3.ZERO):
			_prev_data = null
			return
		move_and_slide()
		var buf = PackedByteArray()
		buf.resize(8)
		buf.encode_half(0,global_position.x)
		buf.encode_half(2,global_position.y)
		buf.encode_half(4,global_position.z)
		buf.encode_half(6,rotation.y)
		_prev_data = [global_position,rotation.y]
		rpc("_update_data",buf)

func _process(_delta):
	if is_owner:
		camera.position = lerp(camera.position,position,0.1)+_camera_offset
	if _prev_data:
		var fract = clamp(Engine.get_physics_interpolation_fraction(),0,1)
		var rot = _model.rotation
		rot.y = lerp(_prev_data[1],rotation.y,fract)
		UpdateModel(
			_prev_data[0].lerp(global_position,fract),
			rot
		)
