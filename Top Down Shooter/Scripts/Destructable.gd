class_name Destructable extends Widget

func _ready():
	super._ready()
	_update_visibility()
	
func _death():
	$PathingBlocker.disabled = true
	$CollisionShape3D.disabled = true
	$Model.cast_shadow = false
	super()
