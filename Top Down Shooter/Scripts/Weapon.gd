class_name Weapon extends Node3D
const TRACER_PATH = preload("res://Scenes/tracer_test.tscn")
@export_category("Aiming")
@export var Aim_FOV := PI
@export var Aim_Speed_Reduction := 0.5
@export_category("Reticle")
@export var Reticle_Move_Penalty := 0.5
@export var Reticle_Aim_Bonus = 0.5
@export var Reticle_Size := 2.0
@export_category("Properties")
@export var Damage := 3.5
@export var Attack_Range := 10.0
@export var Attack_Speed := 0.45
@export var Prep_Time := 0.25
@export var Uses_Tracer := true
@export var Bullet_Radius := 0.01
@export_enum("Metal", "Flesh", "Wood", "Rock", "Glass") var Impact_Type : int
@export_category("Sounds")
@export var Fire_Sounds : Array[String]
@export var Pitch_Variance := 0.1
@export_flags_3d_physics var Targets = 0
@export_category("Misc")
@export_enum("hand right", "hand left") var Attachment : String
@export_enum("walk weapon") var Walk_Animation : String
@export_enum("stand weapon") var Stand_Animation : String
@onready var weapon_tip = $WeaponTip
var player_source = null:
	set(value):
		player_source = value
		$WeaponTip/ShapeCast3D.add_exception(value)
var cooldown := 0.0
var fire_pressed = false
var sound_players = []
var base_fire_pitch := 0.0
@onready var base_rotation_y = rotation.y
var recoil_angle := 0.0
signal fired

func _ready():
	$WeaponTip/ShapeCast3D.collision_mask = Targets
	$WeaponTip/ShapeCast3D.shape.radius = Bullet_Radius
	$WeaponTip/ShapeCast3D.enabled = false
	sound_players.append($AudioStreamPlayer3D)
	$AudioStreamPlayer3D.stream = load(Fire_Sounds[0])
	base_fire_pitch = $AudioStreamPlayer3D.pitch_scale
	for i in Fire_Sounds.size():
		if i+1 != Fire_Sounds.size():
			var new = $AudioStreamPlayer3D.duplicate()
			add_child(new)
			new.stream = load(Fire_Sounds[i+1])
			sound_players.append(new)
static func create(type : PackedScene) -> Weapon:
	return type.instantiate()

func fire_effect():
	pass

func project_ray(source : Vector3, target : Vector3):
	var space_state = get_world_3d().direct_space_state
	var param := PhysicsRayQueryParameters3D.create(source, target, Targets)
	return space_state.intersect_ray(param)

@rpc("authority","call_local","reliable")
func confirm_fire(source : Vector3, angle : float):
	var sound :AudioStreamPlayer3D = sound_players[randi_range(0,sound_players.size()-1)]
	sound.pitch_scale = base_fire_pitch + randf_range(-Pitch_Variance,Pitch_Variance)
	sound.play()
	cooldown = Attack_Speed
	$AnimationPlayer.play("fire")
	$ScreenShakeCauser.cause_shake(0.5,true, false)
	var target = source + Vector3(Attack_Range * sin(angle),0,Attack_Range * cos(angle))
	$WeaponTip/ShapeCast3D.global_position = source
	$WeaponTip/ShapeCast3D.target_position = $WeaponTip/ShapeCast3D.to_local(target)
	$WeaponTip/ShapeCast3D.enabled = true
	$WeaponTip/ShapeCast3D.force_shapecast_update()
	recoil_angle = angle - player_source.rotation.y
	if $WeaponTip/ShapeCast3D.is_colliding():
		target = $WeaponTip/ShapeCast3D.get_collision_point(0)
		target.y = $WeaponTip.global_position.y
	var dist = $WeaponTip.global_position.distance_to(target)
	if Uses_Tracer:
		if dist > 3.0:
			var tracer : MeshInstance3D = TRACER_PATH.instantiate()
			tracer.set("instance_shader_parameters/color",Vector4(1,1,0,0.4))
			tracer.set("instance_shader_parameters/time",0.0)
			var tween : Tween = get_tree().create_tween()
			Globals.World.add_child(tracer)
			var ratio = dist/Attack_Range
			tracer.set("instance_shader_parameters/size",0.125 / ratio)
			tween.tween_property(tracer,"instance_shader_parameters/time",1.1,0.2 * ratio)
			tween.tween_callback(tracer.queue_free)
			tracer.mesh.height = dist
			tracer.global_position = $WeaponTip.global_position + Vector3(dist * sin(angle) * 0.5,0,dist * cos(angle) * 0.5)
			tracer.rotation.y = angle + PI
	if $WeaponTip/ShapeCast3D.is_colliding():
		for i in $WeaponTip/ShapeCast3D.get_collision_count():
			var tar = $WeaponTip/ShapeCast3D.get_collider(i)
			if tar.get("Armor_Type") != null:
				ArmoredObject.resolve_impact(Impact_Type,tar.Armor_Type,target,Vector3(0,angle+PI,0))
			if tar is Widget:
				WidgetFactory.server_call(tar.instance_id, "ReceiveDamage", [player_source.instance_id,Damage])
	fire_effect()
	emit_signal("fired")
	$WeaponTip/ShapeCast3D.enabled = false

@rpc("reliable","call_local","any_peer")
func fire(angle : float):
	rpc("confirm_fire",player_source.global_position,angle)

func _physics_process(delta):
	cooldown = max(cooldown - delta,0.0)

func _process(delta):
	recoil_angle = max(0.0,recoil_angle - delta * 0.1)
