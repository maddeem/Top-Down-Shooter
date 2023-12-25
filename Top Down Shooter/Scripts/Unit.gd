class_name Unit extends Widget
var Attack : UnitAttack
@export var Base_Movement_Speed := 2.5
@export var Speed := 5.0
@export var Turn_Speed := 3.0
@export var Movement_Angle = PI*.25
@onready var vision_modifier = $VisibilityModifier
@export var blend_time := 0.2
var _bit_owner
var _path : Array
var _path_ind : int
var push := Vector3.ZERO
var push_list := []
var push_strength = 128.0
var path_target : Vector3
var attacking := false
var walking := false
var cur_anim : String
var prev_anim : String

func set_player_owner(value):
	super(value)
	if get_parent():
		_bit_owner = Utility.get_bit(value)
		vision_modifier.Owner = player_owner

func set_path(p : PackedVector2Array):
	_path_ind = 0
	_path = p
	var size = _path.size()
	if size > 0:
		_path.pop_front()
		size -= 1
	if size == 0:
		_path = []
		return
	
func set_path_target(target : Vector3):
	if not multiplayer.is_server():
		return
	path_target = target
	Globals.NavigationRegion.unit_threaded_path(self,Vector2(position.x,position.z),Vector2(target.x,target.z))

func stop_moving():
	_path = []

func _ready():
	super()
	add_to_group("Units")
	Attack = $UnitAttack

func face_angle(delta,dir : Vector2) -> float:
	var current_angle = atan2(dir.x,dir.y)
	var angle_diff = abs(Utility.angle_difference(rotation.y,current_angle))
	var delta_turn = Turn_Speed * delta
	if angle_diff <= delta_turn:
		rotation.y = current_angle
	else:
		rotation.y = Utility.change_angle_bounded(rotation.y,current_angle,delta_turn)
	return angle_diff

func _is_facing_correctly(delta, dir : Vector2):
	return face_angle(delta,dir) < Movement_Angle

func _get_path_dir(delta) -> Vector2:
	if _path.size() > 0:
		var pos = Vector2(global_position.x,global_position.z)
		var tar = _path[_path_ind]
		var dir = pos.direction_to(tar)
		if tar.distance_squared_to(pos) < delta * Speed:
			_path_ind += 1
			if _path_ind == _path.size():
				_path = []
		return dir
	else:
		return Vector2.ZERO

func _push_away(delta):
	if not dead:
		var push_size = push_list.size()
		var new_push := Vector3.ZERO
		if push_size > 0:
			for body in push_list:
				var d = body.global_position.direction_to(global_position)
				new_push += Vector3(d.x,0,d.z)
			new_push = (new_push / push_size) * push_strength * delta
		push += new_push
	velocity.x = push.x
	velocity.z = push.z
	push *= 0.25

func _play_anim(anim_name : StringName, queued : bool = false, custom_blend: float = -1, custom_speed: float = 1.0):
	prev_anim = cur_anim
	cur_anim = super(anim_name,queued,custom_blend,custom_speed)
	if cur_anim != "" and prev_anim != "":
		Animation_Player.set_blend_time(prev_anim,cur_anim,blend_time)

func resolve_animation():
	if not attacking and not dead:
		if walking:
			if cur_anim != "walk":
				cur_anim = "walk"
				_play_anim(cur_anim,false,-1,Speed/Base_Movement_Speed)
		elif cur_anim != "stand":
			cur_anim = "stand"
			_play_anim(cur_anim)
		
var _last_pos : Vector3
func _physics_process(delta):
	if cur_anim != "" and prev_anim != "":
		Animation_Player.set_blend_time(prev_anim,cur_anim,max(0,Animation_Player.get_blend_time(prev_anim,cur_anim)-delta))
	if multiplayer.is_server():
		if not is_on_floor():
			velocity.y -= Globals.Gravity * delta
		_push_away(delta)
		var dir = _get_path_dir(delta)
		if dir != Vector2.ZERO and not attacking and _is_facing_correctly(delta,dir):
			velocity.x += dir.x * Speed
			velocity.z += dir.y * Speed
	if not velocity.is_equal_approx(Vector3.ZERO):
		move_and_slide()
	walking = global_position != _last_pos
	_last_pos = global_position
	super(delta)
	resolve_animation()

func _on_area_3d_body_entered(body):
	if body is Widget and body != self:
		push_list.append(body)

func _on_area_3d_body_exited(body):
	push_list.erase(body)

func _on_visiblity_observer_visibility_update(state):
	super._on_visiblity_observer_visibility_update(state)
	_visible = _visible or Globals.LocalPlayerBit == _bit_owner

func _death():
	$VisibilityModifier.enabled = false
	$Area3D.collision_layer = 0
	stop_moving()
	collision_layer = 0
	super()

func _on_mouse_entered():
	super()

func _on_mouse_exited():
	super()
