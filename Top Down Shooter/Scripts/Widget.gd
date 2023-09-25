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
@export var attack_priority : float = 1.0
var facing_angle : float
var revealed_once = false
@export var remove_on_decay := true
var dead := false
var current_animation
var current_animation_play_start
var instance_id : int
@export var player_owner := 30: set = set_player_owner
var _player_owner : Player
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
@onready var update_last = [global_position,rotation.y]

func set_player_owner(value):
	player_owner = value
	if get_parent():
		_player_owner = PlayerLib.PlayerByIndex[value]

func _update_visibility():
	if Visible_Once_Revealed or always_visible_in_fog:
		_model.visible = revealed_once or always_visible_in_fog
	else:
		_model.visible = _visible
	if _visible:
		UpdateModel([global_position,rotation.y])
	_health_bar.visible = _health_bar_displaying and _model.visible
	#_selection_circle.visible = _model.visible

func _play_anim(anim_name : StringName, queued : bool = false, custom_blend: float = -1):
	current_animation = anim_name
	current_animation_play_start = Globals.TimeElapsed
	if can_animate:
		if queued:
			Animation_Player.queue(anim_name)
		else:
			if Animation_Player.is_playing():
				Animation_Player.advance(100)
			Animation_Player.play(anim_name,custom_blend)

func visible_to_player(p:Player) -> bool:
	return Globals.FogOfWar.IsPointVisibleToBitId(p._player_visibility, global_position)

func _ready():
	player_owner = player_owner
	instance_id = WidgetFactory.get_new_id(self)
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
	Animation_Player.advance(min(Animation_Player.current_animation_length,Globals.TimeElapsed - current_animation_play_start))

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
	Animation_Player.clear_queue()
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

func UpdateModel(trans : Array, forced := false):
	if _visible or forced:
		_model.global_position = trans[0]
		_selection_circle.global_position = trans[0]
		_model.rotation.y = trans[1]

func _on_visiblity_observer_visibility_update(state):
	_visible = state
	can_animate = _visible
	if self is PlayerUnit:
		print(state)
	if _visible:
		revealed_once = true
		reset_current_animation()
	_update_visibility()

func set_next_transform(sender : int, pos : Vector3, rot : float):
	if multiplayer.get_unique_id() != sender:
		global_position = pos
		rotation.y = rot

func _apply_update_scale(value : Variant):
	var snap = Globals.NETWORK_UPDATE_SCALE
	if value is Vector3:
		snap = Vector3(snap,snap,snap)
	return snapped(value,snap)

var send_movement = false
func _notification(what: int) -> void:
	if multiplayer and not multiplayer.is_server():
		return
	if what == NOTIFICATION_TRANSFORM_CHANGED:
		var pos = _apply_update_scale(global_position)
		var rot = _apply_update_scale(rotation.y)
		if pos != update_last[0] or rot != update_last[1]:
			update_last[0] = pos
			update_last[1] = rot
			send_movement = true

func move_instantly(pos : Vector3):
	global_position = pos
	prev = [pos,rotation.y]
	next = prev
	UpdateModel(prev,true)

@onready var prev = [global_position,rotation.y]
@onready var next = prev
func _physics_process(_delta):
	prev = next
	next = [global_position,rotation.y]
	if send_movement and multiplayer.is_server():
		send_movement = false
		WidgetFactory.queue_movement(self)


func _process(_delta):

	var d = min(1.0,Engine.get_physics_interpolation_fraction())
	UpdateModel([
		prev[0].lerp(next[0],d),
		lerp_angle(prev[1],next[1],d),
	])
