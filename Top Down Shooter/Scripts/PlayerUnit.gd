class_name PlayerUnit extends Widget
@export var SPEED = 5
@export var JUMP_VELOCITY = 6
@export var direction := Vector2.ZERO
@export var jumping : bool
@onready var camera = $"Shakable Camera"
@export var friction := 25
@export var acceleration_smoothing := 20
@export var turn_speed = 2.0
@export_node_path("Skeleton3D") var skeleton_path
@onready var skeleton : Skeleton3D = get_node(skeleton_path)
@export var bone_chest_name = "Chest"
@export var bone_pelvis_name = "Pelvis"
@export var pelvis_rotation_offset := 0.0
@onready var bone_chest : int = skeleton.find_bone(bone_chest_name)
@onready var bone_legs : int = skeleton.find_bone(bone_pelvis_name)
var rotation_speed = 5.0
var angle_to_mouse := 0.0
var is_owner = false
var _camera_offset = Vector3(0,2,0.7)
var move_dir := 0.0
var current_weapon : Weapon
var is_moving := false
var falling := false
var weapon_prepping := 0.0
var attack_animating := false
var can_move := true
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

func set_player_owner(value):
	super(value)
	if get_parent():
		is_owner = PlayerLib.PlayerByIndex[value].id == multiplayer.get_unique_id()
		camera._camera.current = is_owner
		$VisibilityModifier.Owner = value
		$Model/Nametag.text = _player_owner.name
		_player_owner.main_unit = self
func _ready():
	super._ready()

func _unhandled_input(event):
	if not is_owner:
		return
	var either = false
	if event.is_action("Move_Down") or event.is_action("Move_Left") or event.is_action("Move_Right") or event.is_action("Move_Up"):
		direction = Input.get_vector("Move_Left","Move_Right","Move_Up","Move_Down")
	if event.is_action("Jump") and Input.is_action_just_pressed("Jump") and is_on_floor():
		velocity.y = JUMP_VELOCITY
	if event.is_action("Aim"):
		either = true
		NetworkFactory.anyone_call(instance_id, "set", ["aiming",event.is_action_pressed("Aim")])
	if event.is_action("Attack"):
		either = true
		NetworkFactory.anyone_call(instance_id, "set", ["fire_pressed",event.is_action_pressed("Attack")])
	if either and not is_instance_valid(GlobalUI.current_ability):
		GlobalUI.cursor.show_reticle = Input.is_action_pressed("Attack") or Input.is_action_pressed("Aim")

func set_next_transform(_sender : int, pos : Vector3, rot : float):
	if not is_owner:
		global_position = pos
		rotation.y = rot
		if multiplayer.is_server():
			NetworkFactory.queue_movement(self)

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
	var anim_chest := ""
	var blend : float
	if dead:
		return
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
		if not current_weapon.Can_Aim or not $ChestAnimator.has_animation(anim_chest):
			match anim:
				"stand":
					anim_chest = current_weapon.Stand_Animation
				"walk":
					anim_chest = current_weapon.Walk_Animation
	else:
		anim_chest = anim
	if falling:
		anim_chest = "falling"
		blend = 0.75
	if attack_animating:
		anim_chest = ""
	if $ChestAnimator.current_animation != anim_chest and anim_chest != "":
		$ChestAnimator.play(anim_chest,blend)

func resolve_reticle():
	if not is_owner:
		return
	if is_instance_valid(current_weapon):
		var size = current_weapon.Reticle_Size
		if aiming and current_weapon.Can_Aim:
			size -= current_weapon.Reticle_Aim_Bonus
		if is_moving:
			size += current_weapon.Reticle_Move_Penalty
		GlobalUI.cursor.new_scale = size

func resolve_attack():
	if is_instance_valid(current_weapon) and current_weapon.cooldown == 0.0 and current_weapon.fire_pressed:
		var ray2 = Utility.raycast_from_mouse(self,2000,15,GlobalUI.cursor.resolve_position()).position
		var angle2 = atan2(global_position.x - ray2.x, global_position.z - ray2.z ) + PI
		var diff = abs(Utility.angle_difference(rotation.y,angle2))
		if diff > 0.1:
			angle2 = rotation.y
		if not multiplayer.is_server():
			current_weapon.cooldown = current_weapon.Attack_Speed
		NetworkFactory.peer_call(current_weapon.instance_id,"fire",angle2,true,true)

func _physics_process(delta):
	var adj_speed = SPEED
	falling = not is_on_floor()
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
		elif aiming and current_weapon.Can_Aim:
			adj_speed *= current_weapon.Aim_Speed_Reduction
	$LegAnimator.speed_scale = adj_speed/SPEED
	is_moving = prev[0].distance_to(next[0]) >= adj_speed * delta * 0.5
	if is_owner:
		resolve_attack()
		if send_movement:
			send_movement = false
			NetworkFactory.queue_movement(self)
	if is_moving:
		move_dir = atan2(prev[0].x-next[0].x,prev[0].z-next[0].z)
	else:
		move_dir = rotation.y + PI
	resolve_reticle()
	resolve_animations()
	prev = next
	next = [global_position,rotation.y]
	var vel = Vector2(velocity.x,velocity.z)
	if falling:
		velocity.y -= Globals.Gravity * delta
		vel = vel.lerp(direction * adj_speed, 1 - exp(-delta * acceleration_smoothing * 0.25))
	else:
		vel = vel.lerp(direction * adj_speed, 1 - exp(-delta * acceleration_smoothing))
	if can_move:
		velocity.x = vel.x
		velocity.z = vel.y
		if is_owner:
			rotation.y = Utility.change_angle_bounded(rotation.y,angle_to_mouse,rotation_speed * delta)
	else:
		velocity.x = 0.0
		velocity.z = 0.0
	move_and_slide()

func resolve_chest_rotation():
	var a = Vector3(0,rotation.y,0)
	skeleton.set_bone_pose_rotation(bone_chest,Quaternion.from_euler(a))

func _process(delta):
	super._process(delta)
	if can_move:
		var a = skeleton.get_bone_pose_rotation(bone_legs).get_euler()
		a.y -= pelvis_rotation_offset
		if abs(Utility.angle_difference(move_dir,rotation.y + PI)) > DI:
			a.y = Utility.change_angle_bounded(a.y,move_dir - PI,rotation_speed * delta)
		else:
			a.y = Utility.change_angle_bounded(a.y,move_dir,rotation_speed * delta)
		a.y += pelvis_rotation_offset
		skeleton.set_bone_pose_rotation(bone_legs,Quaternion.from_euler(a))
		resolve_chest_rotation()
	_model.global_rotation.y = 0
	if is_owner:
		camera.global_position = lerp(camera.global_position,next[0],0.1)+_camera_offset
		var mouse_cast = Utility.raycast_from_mouse(self,2000,15)
		if mouse_cast.has("position"):
			var mouse_pos = mouse_cast.position
			angle_to_mouse = atan2(global_position.x-mouse_pos.x, global_position.z-mouse_pos.z) + PI

func weapon_fired():
	pass
	
func weapon_about_to_fire():
	pass

func add_weapon(which : PackedScene):
	if is_instance_valid(current_weapon):
		var it : Item = load(current_weapon.item_path).instantiate()
		Globals.World.add_child(it)
		it.move_instantly(global_position)
		$Inventory.attempt_pickup(it.instance_id,false)
		current_weapon.queue_free()
	current_weapon = Weapon.create(which)
	current_weapon.player_source = self
	var hand = skeleton.find_child(current_weapon.Attachment)
	var offset = hand.find_child("offset")
	if is_instance_valid(offset):
		offset.add_child(current_weapon)
	else:
		hand.add_child(current_weapon)
	current_weapon.connect("fired",weapon_fired)
	current_weapon.connect("about_to_fire",weapon_about_to_fire)
	apply_mats(current_weapon)

func play_walk_sound():
	if is_on_floor():
		$Footstep.pitch_scale = randf_range(0.9,1.1)
		$Footstep.play()

func set_locally_invisible(value):
	super(value)
	$Model/Nametag.visible = not value

func _death():
	$VisibilityModifier.enabled = false
	can_move = false
	_player_owner.dead = true
	super()
