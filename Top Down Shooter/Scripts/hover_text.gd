extends CenterContainer
var border_color : Color:
	set(value):
		border_color = value
		if not get_parent():
			return
		$"Hover Text".self_modulate = border_color
var text : String:
	set(value):
		text = value
		if not get_parent():
			return
		$"Hover Text/Title".text = text
