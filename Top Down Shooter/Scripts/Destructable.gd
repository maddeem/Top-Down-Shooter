extends Widget
class_name Destructable

func _ready():
	remove_on_decay = false
	$VisiblityObserver.Owner_Bit_Value = Globals.LocalPlayerBit
	_update_visibility()
	while true:
		await get_tree().create_timer(1).timeout
		ReceiveDamage(self,1)
