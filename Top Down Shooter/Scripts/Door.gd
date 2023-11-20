class_name Doorway extends Destructable
@export var locked := false: set = set_locked
var is_open := false
var bodys_in_doorway_count = 0

func doorway_sound(anim : String, offset : float = 0.0):
	match anim:
		"death":
			$AudioStreamPlayer3D.stream = load("res://Assets/Sounds/HatchOpen.mp3")
		"birth":
			$AudioStreamPlayer3D.stream = load("res://Assets/Sounds/HatchClose.mp3")
	$AudioStreamPlayer3D.play(offset)

func set_locked(value):
	locked = value
	if not get_parent():
		return
	if locked:
		toggle_doorway(false)
	else:
		toggle_doorway(bodys_in_doorway_count > 0)

func toggle_doorway(state : bool):
	$PathingBlocker.disabled = not locked
	var next_state = state and not locked or dead
	if is_open == next_state:
		return
	is_open = next_state
	$VisionBlocker.disabled = is_open
	$CollisionShape3D.set_deferred("disabled",is_open)
	var anim = "birth"
	var cur = $AnimationPlayer.current_animation
	if is_open:
		anim = "death"
	var offset = 0.0
	if cur:
		offset = $AnimationPlayer.current_animation_length - $AnimationPlayer.current_animation_position
	_play_anim(anim)
	if cur == "birth" or cur == "death":
		$AnimationPlayer.advance(offset)
	doorway_sound(anim,offset)

func _death():
	toggle_doorway(true)
	super()

func _ready():
	super()
	locked = locked

func is_valid_open_target(body):
	return body is Unit or body is PlayerUnit


func _on_open_area_body_entered(body):
	if is_valid_open_target(body):
		bodys_in_doorway_count += 1
		if bodys_in_doorway_count == 1:
			toggle_doorway(true)

func _on_open_area_body_exited(body):
	if is_valid_open_target(body):
		bodys_in_doorway_count -= 1
		if bodys_in_doorway_count == 0:
			toggle_doorway(false)
