class_name PlayerUnit extends Widget
@export var SPEED = 5
@export var JUMP_VELOCITY = 6
@export var direction := Vector2.ZERO
@export var jumping : bool
@onready var camera = $"Shakable Camera"
@export var friction := 25
@export var acceleration_smoothing := 20
@export var turn_speed = 2.0
@onready var skeleton : Skeleton3D = $Model/spacemarine/Armature/Skeleton3D
@onready var bone_chest : int = skeleton.find_bone("Chest")
@onready var bone_legs : int = skeleton.find_bone("Pelvis")
var rotation_speed = 5.0
var angle_to_mouse := 0.0
var is_owner = false
var _camera_offset = Vector3(0,2,0.7)
var move_dir := 0.0
var current_weapon : Weapon
var is_moving := false
var falling := false
var weapon_prepping := 0.0
var fire_pressed := false:
	set(value):
		fire_pressed = value
		resolve_animations()
var aiming := false:
	set(value):
		aiming = value
		if aiming and is_instance_valid(current_weapon):
			$VisibilityModifier.FOV = current_weapon.Aim_FOV
		else:
			$VisibilityModifier.FOV = PI
		resolve_animations()
const DI = PI/2

@rpc("any_peer","reliable","call_local")
func set_prop(property : String, value : Variant):
	rpc("set_prop_final",property, value)

@rpc("authority","reliable","call_local")
func set_prop_final(property:String, value : Variant):
	set(property,value)

func set_player_owner(value):
	super(value)
	if get_parent():
		is_owner = PlayerLib.PlayerByIndex[value].id == multiplayer.get_unique_id()
		camera._camera.current = is_owner
		$VisibilityModifier.Owner = value
func _ready():
	super._ready()
	add_weapon("GaussRifle")

func _input(event):
	if not is_owner:
		return
	direction = Input.get_vector("Move_Left","Move_Right","Move_Up","Move_Down")
	if Input.is_action_just_pressed("Jump") and is_on_floor():
		velocity.y = JUMP_VELOCITY
	var r_click = event.is_action_pressed("Mouse_Right")
	if event.is_action("Mouse_Right") and r_click != aiming:
		WidgetFactory.anyone_call(instance_id, "set", ["aiming",r_click])
	var firing = event.is_action_pressed("Mouse_Left")
	if firing != fire_pressed and event.is_action("Mouse_Left"):
		WidgetFactory.anyone_call(instance_id, "set", ["fire_pressed",firing])

func set_next_transform(_sender : int, pos : Vector3, rot : float):
	if not is_owner:
		global_position = pos
		rotation.y = rot
		if multiplayer.is_server():
			WidgetFactory.queue_movement(self)

func _notification(what: int) -> void:
	if not is_owner:
		return
	if what == NOTIFICATION_TRANSFORM_CHANGED:
		var pos = _apply_update_scale(global_position)
		var rot = _apply_update_scale(rotation.y)
		if pos != update_last[0] or rot != update_last[1]:
			update_last[0] = pos
			update_last[1] = rot
			send_movement = true

func resolve_animations():
	var anim : String
	var anim_chest : String
	var blend : float
	if is_moving:
		if is_on_floor():
			anim = "walk"
			blend = 0.15
		else:
			anim = "stand"
			blend = 1.0
	else:
		anim = "stand"
		blend = 0.15
	if $LegAnimator.current_animation != anim:
		$LegAnimator.play(anim,blend)
	if is_instance_valid(current_weapon):
		if aiming:
			anim_chest = "aim"
		elif fire_pressed:
			anim_chest = "hip_aim"
		else:
			match anim:
				"stand":
					anim_chest = current_weapon.Stand_Animation
				"walk":
					anim_chest = current_weapon.Walk_Animation
	if falling:
		anim_chest = "falling"
		blend = 0.75
	if $ChestAnimator.current_animation != anim_chest and anim_chest != null:
		$ChestAnimator.play(anim_chest,blend)

func resolve_reticle():
	if not is_owner:
		return
	var size = current_weapon.Reticle_Size
	if aiming:
		size -= current_weapon.Reticle_Aim_Bonus
	if is_moving:
		size += current_weapon.Reticle_Move_Penalty
	Globals.Reticle.new_scale = size

func resolve_attack():
	if is_instance_valid(current_weapon) and current_weapon.cooldown == 0.0 and current_weapon.fire_pressed:
		var ray2 = Utility.raycast_from_mouse(self,2000,15,Globals.Reticle.resolve_position()).position
		var angle2 = atan2(global_position.x - ray2.x, global_position.z - ray2.z ) + PI
		var diff = abs(Utility.angle_difference(rotation.y,angle2))
		if diff > 0.1:
			angle2 = rotation.y
		current_weapon.rpc_id(1,"fire",angle2)

func _physics_process(delta):
	var adj_speed = SPEED
	if is_instance_valid(current_weapon):
		if aiming or fire_pressed:
			weapon_prepping += delta
			current_weapon.fire_pressed = fire_pressed and weapon_prepping >= current_weapon.Prep_Time
		else:
			weapon_prepping = 0.0
			if not fire_pressed:
				current_weapon.fire_pressed = false
		if falling:
			weapon_prepping = 0.0
			current_weapon.fire_pressed = false
		elif aiming:
			adj_speed *= current_weapon.Aim_Speed_Reduction
	$LegAnimator.speed_scale = adj_speed/SPEED
	is_moving = prev[0].distance_to(next[0]) >= adj_speed * delta * 0.5
	if is_owner:
		resolve_attack()
		if send_movement:
			send_movement = false
			WidgetFactory.queue_movement(self)
	if is_moving:
		move_dir = atan2(prev[0].x-next[0].x,prev[0].z-next[0].z)
	else:
		move_dir = rotation.y + PI
	resolve_reticle()
	resolve_animations()
	prev = next
	next = [global_position,rotation.y]
	var vel = Vector2(velocity.x,velocity.z)
	if is_on_floor():
		vel = vel.lerp(direction * adj_speed, 1 - exp(-delta * acceleration_smoothing))
		falling = false
	else:
		vel = vel.lerp(direction * adj_speed, 1 - exp(-delta * acceleration_smoothing * 0.25))
		velocity.y -= Globals.Gravity * delta
		falling = true
	velocity.x = vel.x
	velocity.z = vel.y
	if is_owner:
		rotation.y = Utility.change_angle_bounded(rotation.y,angle_to_mouse,rotation_speed * delta)
	if velocity.is_equal_approx(Vector3.ZERO):
		return
	move_and_slide()

func _process(delta):
	super._process(delta)
	var a = skeleton.get_bone_pose_rotation(bone_legs).get_euler()
	if abs(Utility.angle_difference(move_dir,rotation.y + PI)) > DI:
		a.y = Utility.change_angle_bounded(a.y,move_dir - PI,rotation_speed * delta)
	else:
		a.y = Utility.change_angle_bounded(a.y,move_dir,rotation_speed * delta)
	skeleton.set_bone_pose_rotation(bone_legs,Quaternion.from_euler(a))
	var q
	a = rotation.y
	if is_instance_valid(current_weapon):
		a += current_weapon.recoil_angle
	if aiming:
		q = Quaternion.from_euler(Vector3(PI*0.125,a,0))
	else:
		q = Quaternion.from_euler(Vector3(0,a,0))
	skeleton.set_bone_pose_rotation(bone_chest,q)
	_model.global_rotation.y = 0
	if is_owner:
		camera.global_position = lerp(camera.global_position,next[0],0.1)+_camera_offset
		var mouse_pos = Utility.raycast_from_mouse(self,2000,15).position
		angle_to_mouse = atan2(global_position.x-mouse_pos.x, global_position.z-mouse_pos.z) + PI

func weapon_fired():
	$Recoil.play("recoil")

func add_weapon(which : String):
	assert(Preload.WeaponTypes.has(which),"Weapon invalid!")
	if is_instance_valid(current_weapon):
		current_weapon.queue_free()
	current_weapon = Weapon.create(Preload.WeaponTypes[which])
	current_weapon.player_source = self
	current_weapon.connect("fired",weapon_fired)
	match current_weapon.Attachment:
		"hand right":
			$Model/spacemarine/Armature/Skeleton3D/Hand_Right/Offset.add_child(current_weapon)

func play_walk_sound():
	if is_on_floor():
		$Footstep.pitch_scale = randf_range(0.9,1.1)
		$Footstep.play()
