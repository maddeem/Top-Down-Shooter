extends Weapon

func fire_effect():
	$WeaponTip/Sprite3D.modulate = lerp(Color.WHITE,Color(1,.8,.8),randf())
	var s = randf_range(0.9,1.1)
	$WeaponTip/Sprite3D.scale = Vector3(s,s,s)
