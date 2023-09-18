extends Widget
@export var locked := false:
	set(value):
		locked = value
		if not get_parent():
			return
		var col
		if locked:
			toggle_doorway(false)
			col = Color(1,0,0)
		else:
			toggle_doorway(bodys_in_doorway_count > 0)
			col = Color(0,1,0)
		$Model/cliff_hatch/MeshR/Screen.get_surface_override_material(0).emission = col
		$Model/cliff_hatch/MeshL/Screen_001.get_surface_override_material(0).emission = col
var is_open := false
var can_open := true
var bodys_in_doorway_count = 0

func toggle_doorway(state : bool):
	$PathingBlocker.disabled = not locked
	var next_state = state and not locked
	if is_open == next_state or dead:
		return
	is_open = next_state
	$VisionBlocker.disabled = is_open
	$CollisionShape3D.set_deferred("disabled",is_open)
	var anim = "birth"
	var cur = $AnimationPlayer.current_animation
	if is_open:
		anim = "death"
	var offset 
	if cur:
		offset = $AnimationPlayer.current_animation_length - $AnimationPlayer.current_animation_position
	_play_anim(anim)
	if cur == "birth" or cur == "death":
		$AnimationPlayer.advance(offset)

func _death():
	toggle_doorway(false)
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
