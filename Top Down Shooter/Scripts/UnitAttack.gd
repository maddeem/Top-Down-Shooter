class_name UnitAttack extends Node
@export var attack_range := 10.0:
	set(value):
		attack_range = value
		if not get_parent():
			return
		shapecast.target_position.z = attack_range
@export var launch_angle := PI * 0.1
@export var launch_delay := 0.5
@export var attack_speed = 1.0
@export var damage := 0.5
@export var max_hits := 5
@export var can_hit_allies := false
@export var attack_radius := 0.5:
	set(value):
		attack_radius = value
		if not get_parent():
			return
		shapecast.shape.radius = attack_radius
@export var stop_when_in_range : bool = true
@export_enum("Melee","Missile","Raycast") var attack_type: int
@export_enum("Metal", "Flesh", "Wood", "Rock", "Glass") var Impact_Type : int
@export_flags_3d_physics var Targets = 0:
	set(value):
		Targets = value
		if not get_parent():
			return
		shapecast.collision_mask = Targets
@onready var unit : Unit = get_parent()
@onready var shapecast = ShapeCast3D.new()
var cooldown := 0.0
enum{Melee,Missile,Raycast}
var attack_in_range : bool = false:
	set(value):
		attack_in_range = value
		if attack_in_range:
			if stop_when_in_range:
				unit.stop_moving()
var attack_in_angle : bool = false


func _ready():
	shapecast.shape = SphereShape3D.new()
	shapecast.max_results = 1
	unit.call_deferred("add_child",shapecast)
	shapecast.enabled = false
	shapecast.collision_mask = Targets
	attack_radius = attack_radius
	attack_range = attack_range

func is_in_range(source_pos : Vector3, target : Widget) -> bool:
	var my_range = attack_range * attack_range
	var target_offset = target.selection_circle.size.x
	target_offset *= target_offset
	return my_range >= source_pos.distance_squared_to(target.global_position) - target_offset

func is_in_launch_angle(delta : float, target_node : Widget) -> bool:
	var dir = Vector2(unit.global_position.x,unit.global_position.z).direction_to(Vector2(target_node.global_position.x,target_node.global_position.z))
	var diff = unit.face_angle(delta,dir)
	return diff <= launch_angle

func can_hit_target(target : PhysicsBody3D) -> bool:
	if target is Widget:
		if can_hit_allies:
			return true
		else:
			return not target._player_owner.is_player_ally(unit._player_owner)
	return false

func melee_attack(target : Widget):
	shapecast.enabled = true
	shapecast.target_position.y = target.global_position.y
	shapecast.add_exception(unit)
	shapecast.force_shapecast_update()
	var i = max_hits
	while i != 0 and shapecast.is_colliding():
		var collider = shapecast.get_collider(0)
		shapecast.add_exception(collider)
		if can_hit_target(collider):
			i -= 1
			ArmoredObject.resolve_impact(Impact_Type,collider.Armor_Type,target.global_position + Vector3(0,randf_range(0,target.collision_y_range),0),Vector3(0,unit.rotation.y+PI,0))
			if multiplayer.is_server():
				NetworkFactory.server_call(collider.instance_id, "ReceiveDamage", [unit.instance_id,damage])
		shapecast.force_shapecast_update()
	shapecast.enabled = false
	shapecast.clear_exceptions()

@rpc("authority","call_local","reliable")
func launch_attack(target_id : int):
	var target : Widget = NetworkFactory.Instance2Node(target_id)
	unit.attacking = true
	var which_attack = unit.get_anim("attack")
	var anim : Animation = unit.Animation_Player.get_animation(which_attack)
	var speed = anim.length / attack_speed
	unit._play_anim(which_attack,false,-1,speed)
	await get_tree().create_timer(launch_delay).timeout
	if not unit.dead:
		match attack_type:
			Melee:
				melee_attack(target)
	await get_tree().create_timer(attack_speed - launch_delay).timeout
	unit.attacking = false

func attack(target : Widget):
	if cooldown == 0.0:
		cooldown = attack_speed
		rpc("launch_attack",target.instance_id)

func _physics_process(delta):
	cooldown = max(0.0,cooldown-delta)
