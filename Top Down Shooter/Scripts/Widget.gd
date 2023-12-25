class_name Widget extends CharacterBody3D
@export var object_name : String:
	get:
		if not object_name:
			return name
		else:
			return object_name
@export var max_health : int = 10:
	set(value):
		max_health = max(1,value)
@export var health : float = 10.0
@onready var Animation_Player : AnimationPlayer = $AnimationPlayer
@onready var _model = $Model
@onready var _health_bar = $"Health Bar"
@onready var _health_bar_offset : float = _health_bar.position.y
@onready var selection_circle : Decal = $"Selection Circle"
@export var interact_size : float = 1.0
@export var attack_priority : float = 1.0
var facing_angle : float
var revealed_once = false
@export var remove_on_decay := true
var dead := false
var current_animation
var current_animation_play_start
var instance_id : int
@export var player_owner : int = 30: set = set_player_owner
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
@export_flags("Item","Mechanical","Organic","Unit") var Target_As : int
@export var collision_y_range := 0.0
var _visible = false
@onready var model_offset : Vector3 = _model.position
@onready var update_last = [global_position,rotation.y]
var _mesh_instances = []
signal dies
signal owner_changed
func set_player_owner(value):
	var changed = player_owner != value
	player_owner = value
	if get_parent() and PlayerLib.PlayerByIndex.has(value):
		_player_owner = PlayerLib.PlayerByIndex[value]
		for mesh in _mesh_instances:
			for i in mesh.get_surface_override_material_count():
				var mat = mesh.get_surface_override_material(i)
				if mat is ShaderMaterial:
					mat.set_shader_parameter("mesh_player_owner",value)
	if changed:
		emit_signal("owner_changed")

func _update_visibility():
	if get_parent() == null:
		return
	var vis = _visible or (Visible_Once_Revealed and revealed_once) or always_visible_in_fog or (always_visible_to_owner and _player_owner == Globals.LocalPlayer)
	_model.visible = vis
	if vis:
		UpdateModel([global_position,rotation.y])
	_health_bar.visible = _visible and not dead

func get_anim(anim_name : String) -> String:
	if not Animation_Player.has_animation(anim_name):
		if Animation_Player.has_animation(anim_name+"1"):
			if Animation_Player.has_animation(anim_name+"2"):
				return anim_name + str(randi_range(1,2))
			else:
				return anim_name+"1"
	else:
		return anim_name
	return ""

func _play_anim(anim_name : StringName, queued : bool = false, custom_blend: float = -1, custom_speed: float = 1.0) -> String:
	current_animation = anim_name
	anim_name = get_anim(anim_name)
	current_animation_play_start = Globals.TimeElapsed
	if can_animate:
		if queued:
			Animation_Player.queue(anim_name)
		else:
			Animation_Player.play(anim_name,custom_blend,custom_speed)
	return anim_name

func invisible_to_player(p:Player) ->bool:
	if p.is_player_visible(_player_owner):
		return false
	if invisible_status > 0:
		if detected.has(p.index):
			return detected[p.index] == 0
		else:
			return true
	else:
		return false

func visible_to_player(p:Player) -> bool:
	return Globals.FogOfWar.IsPointVisibleToBitId(p._player_visibility, global_position) and not invisible_to_player(p)

func init_owner():
	player_owner = player_owner

func _ready():
	player_owner = player_owner
	PlayerLib.initialized.connect(init_owner)
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
	instance_id = NetworkFactory.get_new_id(self)
	set_notify_transform(true)
	_model.top_level = true
	_play_anim("stand")
	_health_bar.top_level = true
	_model.visible = false

func reset_current_animation():
	if current_animation == null:
		return
	Animation_Player.stop()
	Animation_Player.play(current_animation)
	Animation_Player.advance(min(Animation_Player.current_animation_length,Globals.TimeElapsed - current_animation_play_start))

func _update_heath_bar(percent):
	_health_bar.display_time = 5.0
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
	dmg_tween.tween_method(set_meshes_override,Vector4(1,1,1,1),Vector4.ZERO,0.1).set_trans(Tween.TRANS_CUBIC)
	health -= amount
	_update_heath_bar(health/max_health)
	if health <= 0:
		NetworkFactory.server_call(instance_id,"_death")

func _death():
	_health_bar.display_time = -1.0
	dead = true
	Animation_Player.clear_queue()
	emit_signal("dies")
	var anim = get_anim("death")
	if anim != "":
		_play_anim(anim)
		var length = Animation_Player.get_animation(anim).length
		await get_tree().create_timer(length).timeout
	anim = get_anim("decay")
	if anim != "":
		_play_anim(anim)
		var length = Animation_Player.get_animation(anim).length
		await get_tree().create_timer(length).timeout
	if remove_on_decay:
		queue_free()

func SetHealth(amount: float):
	health = amount
	_update_heath_bar(health/max_health)
	if health <= 0 and not dead:
		NetworkFactory.server_call(instance_id,"_death")

func UpdateModel(trans : Array, forced := false):
	if _model.visible or forced:
		_model.global_position = trans[0] + basis * model_offset
		selection_circle.global_position = _model.global_position
		_health_bar.global_position = _model.global_position
		_health_bar.global_position.y += _health_bar_offset
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
		NetworkFactory.queue_movement(self)

func _process(_delta):
	var d = min(1.0,Engine.get_physics_interpolation_fraction())
	UpdateModel([
		prev[0].lerp(next[0],d),
		lerp_angle(prev[1],next[1],d),
	])

func get_hover_color() -> Color:
	if _player_owner == null:
		return Colors.hover_color_neutral
	else:
		if Globals.LocalPlayer.is_player_ally(_player_owner):
			if _player_owner == Globals.LocalPlayer:
				return Colors.hover_color_ally
			else:
				return Colors.hover_color_neutral
		else:
			return Colors.hover_color_enemy

func _on_mouse_entered():
	GlobalUI.hover_target = self
	if not self is Item and not locally_invisible:
		_health_bar.display_time = INF


func _on_mouse_exited():
	if GlobalUI.hover_target == self:
		GlobalUI.hover_target = null
		_health_bar.display_time = -1.0

func apply_mats(which : Node):
	Utility.apply_override_material(which,_override_mat,_overlay_mat)

var _override_mat : Material
var _overlay_mat : Material
func set_override_mat(mat : Material):
	_override_mat = mat
	Utility.apply_override_material(_model,_override_mat,_overlay_mat)

func set_overlay_mat(mat : Material):
	_overlay_mat = mat
	Utility.apply_override_material(_model,_override_mat,_overlay_mat)

signal invsibility_changed
var invisible_status : int = 0
var detected = {}
var locally_invisible = false: set = set_locally_invisible

func set_locally_invisible(value):
	locally_invisible = value
	if locally_invisible:
		$"Health Bar".display_time = -1.0
func update_invisible_status(which : int, add : bool):
	if add:
		Invisibility.gain(which,self)
		invisible_status |= which
	else:
		Invisibility.lose(which,self)
		invisible_status &= ~which
	emit_signal("invsibility_changed",self)
	locally_invisible = invisible_to_player(Globals.LocalPlayer)
