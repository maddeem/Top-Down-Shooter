class_name Widget extends CharacterBody3D
@export var max_health : int = 10:
	set(value):
		max_health = max(1,value)
@export var health : float = 10.0
@export var death_time : float = 1.0
@export var decay_time : float = 10.0
@onready var Animation_Player = $AnimationPlayer
@onready var _model = $Model
@onready var _health_bar = $"Health Bar"
@onready var _selection_circle = $"Selection Circle"
@export var interact_size : float = 1.0
var facing_angle : float
var revealed_once = false
@export var remove_on_decay := true
var dead := false
var current_animation
var current_animation_play_start
var instance_id : int
var object_id : int:
	get:
		return Cache.read_from("WidgetID",scene_file_path)
var can_animate = true:
	set(value):
		can_animate = value
		if Animation_Player:
			if not can_animate:
				Animation_Player.clear_queue()
				Animation_Player.stop(true)
@export var Visible_Once_Revealed = true:
	set(value):
		Visible_Once_Revealed = value
		if _health_bar:
			_update_visibility()
@export var always_visible_in_fog := false:
	set(value):
		always_visible_in_fog = value
		if _health_bar:
			_update_visibility()
var _visible = false
var _health_bar_displaying = false
@onready var _prev_trans = [global_position,rotation.y]
@onready var _target_trans = [global_position,rotation.y]

var buffer = []
var buffer_last_sent = 0
@onready var update_last = [global_position,rotation.y]

func _update_visibility():
	if Visible_Once_Revealed or always_visible_in_fog:
		_model.visible = revealed_once or always_visible_in_fog
	else:
		_model.visible = _visible
	if _visible:
		buffer = []
		UpdateModel([global_position,rotation.y])
	_health_bar.visible = _health_bar_displaying and _model.visible
	#_selection_circle.visible = _model.visible

func _play_anim(anim_name : StringName, queued : bool = false):
	current_animation = anim_name
	current_animation_play_start = Globals.TimeElapsed
	if can_animate:
		if queued:
			Animation_Player.queue(anim_name)
		else:
			if Animation_Player.is_playing():
				Animation_Player.advance(100)
			Animation_Player.play(anim_name)

func _ready():
	instance_id = WidgetFactory.get_new_id(self)
	set_deferred("name",str(instance_id))
	tree_exiting.connect(func():
		WidgetFactory.recycle_id(self)
		)
	set_notify_transform(true)
	_model.top_level = true
	_play_anim("stand")

func reset_current_animation():
	if current_animation == null:
		return
	Animation_Player.stop()
	Animation_Player.play(current_animation)
	Animation_Player.advance(Globals.TimeElapsed - current_animation_play_start)

func _update_heath_bar(percent):
	_health_bar_displaying = percent > 0.0 and not dead
	_health_bar.visible = _health_bar_displaying and _visible
	_health_bar.SetPercent(percent)

func server_call(whichFunc : Callable):
	if multiplayer.is_server():
		whichFunc.rpc()

func ReceiveDamage(_source : int, amount : float) -> void:
	if dead:
		return
	health -= amount
	_update_heath_bar(health/max_health)
	if health <= 0:
		WidgetFactory.server_call(instance_id,"_death")
	else:
		_play_anim("damaged")
		_play_anim("stand",true)

func _death():
	dead = true
	_play_anim("death")
	await get_tree().create_timer(death_time).timeout
	_play_anim("decay")
	await get_tree().create_timer(decay_time).timeout
	if remove_on_decay:
		queue_free()

func SetHealth(amount: float):
	health = amount
	if health <= 0 and not dead:
		WidgetFactory.server_call(instance_id,"_death")
	_update_heath_bar(health/max_health)

func UpdateModel(trans : Array):
	if _visible:
		_model.global_position = trans[0]
		_selection_circle.global_position = trans[0]
		_model.rotation.y = trans[1]
#	var normal = Utility.GetTerrainNormal(
#		Globals.HeightTerrain,
#		Vector2(global_position.x,global_position.z),
#		)

func _on_visiblity_observer_visibility_update(state):
	_visible = state
	can_animate = _visible
	if _visible:
		revealed_once = true
		reset_current_animation()
	_update_visibility()

func _get_transform(buf : PackedByteArray):
	var pos = Vector3(buf.decode_half(0),buf.decode_half(2),buf.decode_half(4))
	var rot = buf.decode_half(6)
	global_position = pos
	rotation.y = rot
	new_buffer(pos,rot)

func _apply_update_scale(value : Variant):
	return round(value / Globals.NETWORK_UPDATE_SCALE) * Globals.NETWORK_UPDATE_SCALE

func _notification(what: int) -> void:
	if multiplayer and not multiplayer.is_server():
		return
	if what == NOTIFICATION_TRANSFORM_CHANGED:
		var pos = _apply_update_scale(global_position)
		var rot = _apply_update_scale(rotation.y)
		if pos != update_last[0] or rot != update_last[1]:
			update_last[0] = pos
			update_last[1] = rot
			buffer_last_sent = Globals.BUFFER_SIZE

func move_instantly(pos : Vector3):
	global_position = pos
	_prev_trans = [pos,rotation.y]
	_target_trans = _prev_trans
	UpdateModel(_target_trans)

func new_buffer(pos : Vector3, rot : float):
	buffer.append({
		next_pos = pos,
		next_rot = rot,
	})
	

func pop_buffer():
	var next = buffer.pop_front()
	if buffer.size() > Globals.BUFFER_SIZE + 4:
		next = buffer.pop_front()
	_prev_trans = [_model.global_position,_model.rotation.y]
	_target_trans = [next.next_pos,next.next_rot]
	_move_fract = 0.0

func pack_data() -> PackedByteArray:
	var buf = PackedByteArray()
	buf.resize(8)
	buf.encode_half(0,global_position.x)
	buf.encode_half(2,global_position.y)
	buf.encode_half(4,global_position.z)
	buf.encode_half(6,rotation.y)
	return buf

func _physics_process(_delta):
	if buffer_last_sent > 0 and multiplayer.is_server():
		buffer_last_sent -= 1
		new_buffer(global_position,rotation.y)
		WidgetFactory.server_call(instance_id,"_get_transform",pack_data(),false,false)

var _move_fract := 0.0
func _process(_delta):
	if _move_fract == 1.0:
		if buffer.size() >= Globals.BUFFER_SIZE:
			pop_buffer()
		else:
			return
	_move_fract = min(_move_fract + Globals.TicksPerSecond * _delta,1.0)
	UpdateModel([
		_prev_trans[0].lerp(_target_trans[0],_move_fract),
		lerp_angle(_prev_trans[1],_target_trans[1],_move_fract),
	])
