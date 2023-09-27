class_name PlayerUnit extends Widget
@export var SPEED = 5
@export var JUMP_VELOCITY = 6
@export var direction := Vector2.ZERO
@export var jumping : bool
@onready var camera = $"Shakable Camera"
@export var friction := 25
@export var acceleration_smoothing := 20
@export var turn_speed = 1.0
@onready var skeleton : Skeleton3D = $Model/spacemarine/Armature/Skeleton3D
@onready var bone_chest : int = skeleton.find_bone("Chest")
@onready var bone_legs : int = skeleton.find_bone("Pelvis")
var rotation_speed = 5.0
var mouse_position := Vector3.ZERO
var angle_to_mouse := 0.0
var is_owner = false
var _camera_offset = Vector3(0,2,0.7)
var move_dir := 0.0
const DI = PI/2

func set_player_owner(value):
	super(value)
	if get_parent():
		is_owner = PlayerLib.PlayerByIndex[value].id == multiplayer.get_unique_id()
		camera._camera.current = is_owner
		$VisibilityModifier.Owner = value
func _ready():
	super._ready()

func _input(event):
	if not is_owner:
		return
	direction = Input.get_vector("Move_Left","Move_Right","Move_Up","Move_Down")
	if Input.is_action_just_pressed("Jump") and is_on_floor():
		velocity.y = JUMP_VELOCITY
	if event is InputEventMouseMotion:
		var cast = Utility.raycast_from_mouse(self,1000,1)
		if cast.has("position"):
			mouse_position = cast.position
			angle_to_mouse = atan2(global_position.x-mouse_position.x, global_position.z-mouse_position.z)

func set_next_transform(_sender : int, pos : Vector3, rot : float):
	if not is_owner:
		global_position = pos
		rotation.y = rot
		print("nice")
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

func _physics_process(delta):
	if is_owner and send_movement:
		send_movement = false
		WidgetFactory.queue_movement(self)
	if prev[0].distance_to(next[0]) >= SPEED * delta * 0.5:
		move_dir = atan2(prev[0].x-next[0].x,prev[0].z-next[0].z)
		if is_on_floor():
			if $LegAnimator.current_animation != "walk":
				$LegAnimator.play("walk",0.15)
		else:
			if $LegAnimator.current_animation != "stand":
				$LegAnimator.play("stand",1.0)
	else:
		if $LegAnimator.current_animation != "stand":
			$LegAnimator.play("stand",0.15)
		move_dir = rotation.y + PI
	prev = next
	next = [global_position,rotation.y]
	var vel = Vector2(velocity.x,velocity.z)
	if is_on_floor():
		vel = vel.lerp(direction * SPEED, 1 - exp(-delta * acceleration_smoothing))
	else:
		vel = vel.lerp(direction * SPEED, 1 - exp(-delta * acceleration_smoothing * 0.1))
		velocity.y -= Globals.Gravity * delta
	velocity.x = vel.x
	velocity.z = vel.y
	if is_owner:
		rotation.y = Utility.change_angle_bounded(rotation.y,angle_to_mouse + PI,rotation_speed * delta)
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
	skeleton.set_bone_pose_rotation(bone_chest,Quaternion(Vector3.UP,rotation.y))
	_model.global_rotation.y = 0
	if is_owner:
		camera.global_position = lerp(camera.global_position,_model.global_position,0.1)+_camera_offset
