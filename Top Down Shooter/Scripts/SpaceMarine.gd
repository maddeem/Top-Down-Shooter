extends PlayerUnit

func weapon_fired():
	$Recoil.play("recoil")

func resolve_chest_rotation():
	var a = Vector3(0,rotation.y,0)
	if is_instance_valid(current_weapon):
		a += current_weapon.recoil_angle
	if aiming:
		a.x += PI*0.125
	skeleton.set_bone_pose_rotation(bone_chest,Quaternion.from_euler(a))
func _death():
	GlobalUI.chat.display_message("[color=8000FF]A crew member has died![/color]","CrewDeath")
	super()

func toggle_invis(state : bool):
	update_invisible_status(Invisibility.INVISIBLE,state)
	
var invis = false
func _input(event):
	if Input.is_action_just_pressed("Jump") and _player_owner == Globals.LocalPlayer:
		invis = not invis
		NetworkFactory.anyone_call(instance_id,"toggle_invis",invis)
