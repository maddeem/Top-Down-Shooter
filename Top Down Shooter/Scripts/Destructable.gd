extends Widget
class_name Destructable

func _ready():
	super._ready()
	remove_on_decay = false
	_update_visibility()
