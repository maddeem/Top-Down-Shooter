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
@export_category("Sounds")
@export var fire_sounds : Array[String]
@export var pitch_variance := 0.1
@export_flags_3d_physics var Targets = 0
@export_category("Misc")
@export_node_path("Node3D") var weapon_tip_path
@export_enum("hand right", "hand left") var Attachment : String
@export_enum("walk weapon") var Walk_Animation : String
@export_enum("stand weapon") var Stand_Animation : String
var player_source = null
var weapon_tip : Node3D
var cooldown := 0.0
var fire_pressed = false
var sound_players = []
var base_fire_pitch := 0.0
signal fired

func _ready():
	weapon_tip = get_node(weapon_tip_path)
	sound_players.append($AudioStreamPlayer3D)
	$AudioStreamPlayer3D.stream = load(fire_sounds[0])
	base_fire_pitch = $AudioStreamPlayer3D.pitch_scale
	for i in fire_sounds.size():
		if i+1 != fire_sounds.size():
			var new = $AudioStreamPlayer3D.duplicate()
			add_child(new)
			new.stream = load(fire_sounds[i+1])
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
	sound.pitch_scale = base_fire_pitch + randf_range(-pitch_variance,pitch_variance)
	sound.play()
	cooldown = Attack_Speed
	$AnimationPlayer.play("fire")
	$ScreenShakeCauser.cause_shake(0.5,true, false)
	emit_signal("fired")
	var target = source + Vector3(Attack_Range * sin(angle),0,Attack_Range * cos(angle))
	var ray = project_ray(source,target)
	if Uses_Tracer:
		if ray.has("position"):
			target = ray.position
		var tracer : MeshInstance3D = TRACER_PATH.instantiate()
		tracer.set("instance_shader_parameters/color",Vector4(1,1,0,0.4))
		tracer.set("instance_shader_parameters/time",0.0)
		var tween : Tween = get_tree().create_tween()
		tween.tween_property(tracer,"instance_shader_parameters/time",1.0,0.2).set_trans(Tween.TRANS_BOUNCE)
		tween.tween_property(tracer,"instance_shader_parameters/color",Vector4(1,1,0,0),0.2).set_trans(Tween.TRANS_BOUNCE)
		tween.tween_callback(tracer.queue_free)
		Globals.World.add_child(tracer)
		var dist = source.distance_to(target)
		tracer.mesh.height = dist
		tracer.global_position = source + Vector3(dist * sin(angle) * 0.5,0,dist * cos(angle) * 0.5)
		tracer.rotation.y = angle + PI
	if ray.has("collider"):
		var collider = ray.collider
		if collider is Widget:
			WidgetFactory.server_call(collider.instance_id, "ReceiveDamage", [player_source.instance_id,Damage])
	fire_effect()

@rpc("reliable","call_local","any_peer")
func fire(angle : float):
	rpc("confirm_fire",weapon_tip.global_position,angle)

func _physics_process(delta):
	cooldown = max(cooldown - delta,0.0)
