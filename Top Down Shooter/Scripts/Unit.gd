extends Widget
@export var Speed := 5.0
@export var Turn_Speed := 3.0
@export var Movement_Angle = PI*.25
var _path
var _path_ind : int
var _prev_data

func set_path_target(target : Vector2):
	_path_ind = 0
	_path = Globals.NavigationRegion.get_point_path(Vector2(position.x,position.z),target)
	var size = _path.size()
	if size == 0:
		_path = null
		return
	_path.remove_at(0)
	if size == 1:
		_path = null

func _ready():
	super._ready()
	add_to_group("Units")

func _input(event):
	if event.is_action_pressed("Mouse_Right"):
		var cast = Utility.raycast_from_mouse(self,1000,1)
		set_path_target(Vector2(cast.position.x,cast.position.z))

func _is_facing_correctly(delta, dir : Vector2):
	var current_angle = atan2(dir.x,dir.y)
	var angle_diff = abs(Utility.angle_difference(rotation.y,current_angle))
	var delta_turn = Turn_Speed * delta
	if angle_diff < delta_turn:
		rotation.y = current_angle
	else:
		rotation.y = Utility.change_angle_bounded(rotation.y,current_angle,delta_turn)
	return angle_diff < Movement_Angle

func _get_path_dir(delta) -> Vector2:
	if _path != null:
		var pos = Vector2(global_position.x,global_position.z)
		var tar = _path[_path_ind]
		var dir = pos.direction_to(tar)
		if tar.distance_squared_to(pos) < delta * Speed:
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
		var dir = _get_path_dir(delta)
		if dir.is_equal_approx(Vector2.ZERO) and velocity.y == 0:
			_prev_data = null
			return
		if _is_facing_correctly(delta,dir):
			velocity.x = dir.x * Speed
			velocity.z = dir.y * Speed
		else:
			velocity.x = 0
			velocity.z = 0
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
		var rot = _model.rotation
		rot.y = lerp(_prev_data[1],rotation.y,fract)
		UpdateModel(
			_prev_data[0].lerp(global_position,fract),
			rot
		)
