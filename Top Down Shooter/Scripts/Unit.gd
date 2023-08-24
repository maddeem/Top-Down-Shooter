class_name Unit extends Widget
@export var Speed := 5.0
@export var Turn_Speed := 3.0
@export var Movement_Angle = PI*.25
@export var player_owner := 0:
	set(value):
		player_owner = value
		if vision_observer:
			_bit_owner = Utility.get_bit(value)
			vision_observer.Owner = player_owner
			vision_modifier.Owner = player_owner
@onready var vision_observer = $VisiblityObserver
@onready var vision_modifier = $VisibilityModifier
var _bit_owner
var _path
var _path_ind : int
var _prev_data
var push := Vector3.ZERO
var push_list := []
var push_strength = 4

func set_path(p : PackedVector2Array):
	_path_ind = 0
	_path = p
	var size = _path.size()
	if size == 0:
		_path = null
		return
	_path.remove_at(0)
	if size == 1:
		_path = null

func set_path_target(target : Vector2):
	Globals.NavigationRegion.unit_threaded_path(self,Vector2(position.x,position.z),target)

func _ready():
	super._ready()
	player_owner = player_owner
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

func _push_away():
	var push_size = push_list.size()
	if push_size > 0:
		for body in push_list:
			var d = body.global_position.direction_to(global_position)
			push += Vector3(d.x,0,d.z)
		push = (push / push_size) * push_strength
	velocity.x = push.x
	velocity.z = push.z

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
		_push_away()
		if dir != Vector2.ZERO and _is_facing_correctly(delta,dir):
			velocity.x += dir.x * Speed
			velocity.z += dir.y * Speed
		if velocity.is_equal_approx(Vector3.ZERO):
			_prev_data = null
			return
		move_and_slide()
		push = Vector3.ZERO
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

func _on_area_3d_body_entered(body):
	if body is Widget:
		push_list.append(body)


func _on_area_3d_body_exited(body):
	push_list.erase(body)

func _on_visiblity_observer_visibility_update(state):
	super._on_visiblity_observer_visibility_update(state)
	_visible = _visible or Globals.LocalPlayerBit == _bit_owner
