class_name PlayerUnit extends Widget
@export var SPEED = 5
@export var JUMP_VELOCITY = 6
@export var direction := Vector2.ZERO
@export var jumping : bool
@onready var camera = $"Shakable Camera"
@export var friction := 25
@export var acceleration_smoothing := 10
@export var turn_speed = 1.0
var is_owner = false
var _camera_offset = Vector3(0,2,0.7)

func set_player_owner(value):
	super(value)
	if get_parent():
		is_owner = PlayerLib.PlayerByIndex[value].id == multiplayer.get_unique_id()
		camera._camera.current = is_owner
		$VisibilityModifier.Owner = value
func _ready():
	super._ready()

func _input(_event):
	if not is_owner:
		return
	direction = Input.get_vector("Move_Left","Move_Right","Move_Up","Move_Down")
	if Input.is_action_just_pressed("Jump") and is_on_floor():
		velocity.y = JUMP_VELOCITY

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

func _physics_process(delta):
	prev = next
	next = [global_position,rotation.y]
	if not is_on_floor():
		velocity.y -= Globals.Gravity * delta
	var vel = Vector2(velocity.x,velocity.z)
	vel = vel.lerp(direction * SPEED, 1 - exp(-delta * acceleration_smoothing))
	velocity.x = vel.x
	velocity.z = vel.y
	if velocity.is_equal_approx(Vector3.ZERO):
		return
	move_and_slide()
	if is_owner and send_movement:
		send_movement = false
		WidgetFactory.queue_movement(self)

func _process(delta):
	super._process(delta)
	if is_owner:
		camera.global_position = lerp(camera.global_position,_model.global_position,0.1)+_camera_offset
