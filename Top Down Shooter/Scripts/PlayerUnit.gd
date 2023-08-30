class_name PlayerUnit extends Widget
@export var SPEED = 5
@export var JUMP_VELOCITY = 8
@export var direction : Vector2
@export var jumping : bool
@onready var camera = $"Shakable Camera"
@export var friction := 25
@export var acceleration = 10
@export var turn_speed = 1.0
var player_owner : Player:
	set(value):
		player_owner = value
		is_owner = player_owner.id == multiplayer.get_unique_id()
		camera._camera.current = is_owner
var is_owner = false
var _camera_offset = Vector3(0,2,0.7)

func _ready():
	super._ready()

@rpc("call_local","reliable","any_peer")
func sync_input(dir,jump):
	direction = dir
	if jump and is_on_floor():
		velocity.y = JUMP_VELOCITY

func _input(_event):
	if not is_owner:
		return
	var dir = Input.get_vector("Move_Left","Move_Right","Move_Up","Move_Down")
	var jump_press = Input.is_action_just_pressed("Jump")
	if dir != direction or jump_press:
		direction = dir
		rpc("sync_input",dir,jump_press)

func _physics_process(delta):
	super._physics_process(delta)
	if not is_on_floor():
		velocity.y -= Globals.Gravity * delta
	var vel = Vector2(velocity.x,velocity.z)
	if direction.length() > 0:
		vel = vel.lerp(direction * SPEED, acceleration * delta)
	else:
		vel = vel.lerp(Vector2.ZERO,friction * delta)
	velocity.x = vel.x
	velocity.z = vel.y
	if velocity.is_equal_approx(Vector3.ZERO):
		return
	move_and_slide()

func _process(delta):
	super._process(delta)
	if is_owner:
		camera.position = lerp(camera.position,position,0.1)+_camera_offset
