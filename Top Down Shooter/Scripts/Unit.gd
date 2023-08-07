extends Widget
@export var Speed := 5.0
var _path
var _path_ind : int
var _prev_data

func set_path_target(target : Vector2):
	_path_ind = 0
	_path = Globals.NavigationRegion.get_point_path(Vector2(position.x,position.z),target)

func _ready():
	_model.top_level = true
	add_to_group("Units")

func _input(event):
	if event.is_action_pressed("Mouse_Right"):
		var cast = Utility.raycast_from_mouse(self,1000,1)
		set_path_target(Vector2(cast.position.x,cast.position.z))
		
func _get_path_dir() -> Vector2:
	if _path != null:
		var pos = Vector2(global_position.x,global_position.z)
		var tar = _path[_path_ind]
		var dir = pos.direction_to(tar)
		if tar.distance_squared_to(pos) < 0.1:
			_path_ind += 1
			if _path_ind == _path.size():
				_path = null
		return dir
	else:
		return Vector2.ZERO

@rpc("unreliable")
func _update_data(buf : PackedByteArray):
	_prev_data = [global_position,rotation.y]
	global_position = Vector3(buf.decode_half(0),buf.decode_half(2),buf.decode_half(4))
	rotation.y = buf.decode_half(6)

func _physics_process(delta):
	if multiplayer.is_server():
		if not is_on_floor():
			velocity.y -= Globals.Gravity * delta
		var dir = _get_path_dir()
		velocity.x = dir.x * Speed
		velocity.z = dir.y * Speed
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
	if _prev_data:
		var fract = clamp(Engine.get_physics_interpolation_fraction(),0,1)
		_model.global_position = _prev_data[0].lerp(global_position,fract)
		_model.rotation.y = lerp(_prev_data[1],rotation.y,fract)
