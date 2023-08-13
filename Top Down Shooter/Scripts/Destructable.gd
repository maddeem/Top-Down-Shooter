extends Widget
class_name Destructable

func _ready():
	super._ready()
	remove_on_decay = false
	$VisiblityObserver.Owner_Bit_Value = Globals.LocalPlayerBit
	_update_visibility()
