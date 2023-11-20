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
@export var player_owner : int: set = set_player_owner
var _player_owner : Player
var object_id : int:
	get:
		return Cache.read_from("WidgetID",scene_file_path)
var can_animate = true:
	set(value):
		can_animate = value
		if Animation_Player:
			if can_animate:
				Animation_Player.speed_scale = 1.0
			else:
				Animation_Player.speed_scale = 0.0
@export var Visible_Once_Revealed = true:
	set(value):
		Visible_Once_Revealed = value
		_update_visibility()
@export var always_visible_in_fog := false:
	set(value):
		always_visible_in_fog = value
		_update_visibility()
@export var always_visible_to_owner := false:
	set(value):
		always_visible_to_owner = value
		_update_visibility()
@export_enum("Metal", "Flesh", "Wood", "Rock", "Glass") var Armor_Type : int
@export var collision_y_range := 0.0
var _visible = false
var _health_bar_displaying = false
@onready var model_offset : Vector3 = _model.position
@onready var update_last = [global_position,rotation.y]
var _mesh_instances = []

func set_player_owner(value):
	player_owner = value
	if get_parent() and PlayerLib.PlayerByIndex.has(value):
		_player_owner = PlayerLib.PlayerByIndex[value]
		for mesh in _mesh_instances:
			for i in mesh.get_surface_override_material_count():
				var mat = mesh.get_surface_override_material(i)
				if mat is ShaderMaterial:
					mat.set_shader_parameter("mesh_player_owner",value)

func _update_visibility():
	if get_parent() == null:
		return
	_visible = _visible or (Visible_Once_Revealed and revealed_once) or always_visible_in_fog or (always_visible_to_owner and _player_owner != null and _player_owner == Globals.LocalPlayer)
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
	if Cache.exists("mesh_instances",scene_file_path):
		for path in Cache.read_from("mesh_instances",scene_file_path):
			var child = get_node(path)
			_mesh_instances.append(child)
	else:
		var cache_list = []
		var chr = []
		var n = get_children()
		while n.size() > 0:
			chr = n
			n = []
			for child in chr:
				n += child.get_children()
				if child is MeshInstance3D:
					child.set_instance_shader_parameter("color_override",Vector4(-1,-1,-1,0))
					if child.get_instance_shader_parameter("color_override"):
						cache_list.append(get_path_to(child))
						_mesh_instances.append(child)
		Cache.write_to("mesh_instances",scene_file_path,cache_list)
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

func set_meshes_override(color : Vector4):
	for mesh in _mesh_instances:
		mesh.set("instance_shader_parameters/color_override",color)

var dmg_tween : Tween
func ReceiveDamage(_source : int, amount : float) -> void:
	if dead:
		return
	if dmg_tween:
		dmg_tween.kill()
	dmg_tween = create_tween()
	dmg_tween.tween_method(set_meshes_override,Vector4(1,1,1,1),Vector4.ZERO,0.3).set_trans(Tween.TRANS_CUBIC)
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
		_model.global_position = trans[0] + basis * model_offset
		_selection_circle.global_position = trans[0]
		_model.rotation.y = trans[1]

func _on_visiblity_observer_visibility_update(state):
	_visible = state
	can_animate = _visible
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


func _on_visibility_changed():
	pass # Replace with function body.
