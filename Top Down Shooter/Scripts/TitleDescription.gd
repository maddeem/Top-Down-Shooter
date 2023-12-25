extends PanelContainer
var title : String:
	set(value):
		title = value
		if get_parent():
			$VBoxContainer/RichTextLabel.text = "[center]"+title
			size = Vector2.ZERO
var description : String:
	set(value):
		description = value
		if get_parent():
			$VBoxContainer/RichTextLabel2.text = description
			size = Vector2.ZERO

func _ready():
	visible = false

