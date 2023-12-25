extends PlayerUnit

func _ready():
	super()
	add_weapon(Preload.WEAPON_INFECTED)

func weapon_about_to_fire():
	var anim :Animation = $ChestAnimator.get_animation("attack")
	$ChestAnimator.play("attack",-1,anim.length/current_weapon.Attack_Speed)
	attack_animating = true
	await get_tree().create_timer(current_weapon.Attack_Speed).timeout
	attack_animating = false
