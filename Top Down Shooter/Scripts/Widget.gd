extends CharacterBody3D
class_name Widget
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
var remove_on_decay = true
var dead := false
var current_animation
var current_animation_play_start
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
@export var Visible_In_Fog = true:
	set(value):
		Visible_In_Fog = value
		if _health_bar:
			_update_visibility()
var _visible = false
var _health_bar_displaying = false
@onready var _prev_trans = [global_position,rotation.y]:
	set(value):
		_prev_trans = value
		_move_fract = 0
@onready var _target_trans = [global_position,rotation.y]
var _target_pos

func _update_visibility():
	if Visible_In_Fog:
		_model.visible = revealed_once
	else:
		_model.visible = _visible
	if _visible:
		_target_trans = [global_position,rotation.y]
		_prev_trans = [global_position,rotation.y]
		UpdateModel(_target_trans)
	_health_bar.visible = _health_bar_displaying and _model.visible
	_selection_circle.visible = _model.visible

func _play_anim(anim_name : StringName, queued : bool = false):
	current_animation = anim_name
	current_animation_play_start = Globals.TimeElapsed
	if can_animate:
		if queued:
			Animation_Player.queue(anim_name)
		else:
			Animation_Player.play(anim_name)

func _ready():
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

func ReceiveDamage(source : Widget, amount : float) -> void:
	if dead:
		return
	health -= amount
	_update_heath_bar(health/max_health)
	if health <= 0:
		dead = true
		_play_anim("death")
		EventHandler.TriggerEvent("widget_dying",{"dying_widget" = self,"killing_widget" = source})
		await get_tree().create_timer(death_time).timeout
		_play_anim("decay")
		await get_tree().create_timer(decay_time).timeout
		if remove_on_decay:
			queue_free()
	else:
		_play_anim("damaged")
		_play_anim("stand",true)
		EventHandler.TriggerEvent("widget_damaged",{"damaged_widget" = self,"source_widget" = source, "amount" = amount})

func SetHealth(amount: float):
	health = amount
	if health <= 0 and not dead:
		dead = true
		EventHandler.TriggerEvent("widget_dying",{"dying_widget" = self,"killing_widget" = null})
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

@rpc("unreliable_ordered","call_remote","any_peer")
func _get_transform(buf : PackedByteArray):
	var pos = Vector3(buf.decode_half(0),buf.decode_half(2),buf.decode_half(4))
	var rot = buf.decode_half(6)
	_prev_trans = [_model.global_position,_model.rotation.y]
	_target_trans = [pos,rot]
	_target_pos = _target_trans

var _send_trans = false
func _notification(what: int) -> void:
	if multiplayer and not multiplayer.is_server():
		return
	if what == NOTIFICATION_TRANSFORM_CHANGED:
		_send_trans = true

func move_instantly(pos : Vector3):
	global_position = pos
	_prev_trans = [pos,rotation.y]
	_target_trans = _prev_trans
	UpdateModel(_target_trans)

func _physics_process(_delta):
	if _target_pos:
		global_position = _target_pos[0]
		rotation.y = _target_pos[1]
		_target_pos = null
	if _send_trans:
		_send_trans = false
		_prev_trans = [_model.global_position,_model.rotation.y]
		_target_trans = [global_position,rotation.y]
		var buf = PackedByteArray()
		buf.resize(8)
		buf.encode_half(0,global_position.x)
		buf.encode_half(2,global_position.y)
		buf.encode_half(4,global_position.z)
		buf.encode_half(6,rotation.y)
		_get_transform.rpc(buf)

var _move_fract := 0.0
func _process(_delta):
	if _move_fract == 1.0:
		return
	_move_fract = min(_move_fract + Globals.TicksPerSecond * _delta,1.0)
	UpdateModel([
		_prev_trans[0].lerp(_target_trans[0],_move_fract),
		lerp_angle(_prev_trans[1],_target_trans[1],_move_fract),
	])
