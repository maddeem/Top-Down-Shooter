extends Area3D
@export var follow_target : Node3D
@export var Shake_Reduction_Rate := 0.8
@export var NoiseInstance : FastNoiseLite
@export var Noise_Speed := 50.0
@export var Shake_Input_Radius := 10.0:
	set(value):
		Shake_Input_Radius = value
		_collision_shape.radius = Shake_Input_Radius
@export var Max_Rotate := Vector3(0.174533,0.174533,0.0872665)
@onready var _camera = $CameraController
@onready var current_rotation := _camera.rotation_degrees as Vector3
@onready var _collision_shape : SphereShape3D = $CollisionShape3D.shape
var _shake := 0.0
var _time := 0.0

func add_shake(shake_amount : float) -> void:
	_shake = clamp(_shake + shake_amount,0.0,1.0)

func _get_shake_intensity() -> float:
	return _shake * _shake

func _process(delta):
	_time += delta
	_shake = max(_shake - delta * Shake_Reduction_Rate, 0.0)
	_camera.rotation = current_rotation + Max_Rotate * _get_shake_intensity() * get_noise_from_seed(Vector3(1,2,3))
	if is_instance_valid(follow_target):
		var targetPos = Vector3(follow_target.global_position.x,global_position.y,follow_target.global_position.z)
		global_position = lerp(global_position,targetPos,delta * 5.0)

func get_noise_from_seed(_seed : Vector3i) -> Vector3:
	var new = Vector3i.ZERO
	var speed = _time * Noise_Speed
	NoiseInstance.seed = _seed.x
	new.x = NoiseInstance.get_noise_1d(speed)
	NoiseInstance.seed = _seed.y
	new.y = NoiseInstance.get_noise_1d(speed)
	NoiseInstance.seed = _seed.z
	new.z = NoiseInstance.get_noise_1d(speed)
	return new
