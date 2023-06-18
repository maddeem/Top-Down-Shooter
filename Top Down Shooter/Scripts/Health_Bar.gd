extends Sprite3D
@onready var viewport : SubViewport = $SubViewport
@onready var bar : TextureProgressBar = $SubViewport/TextureProgressBar

func SetPercent(new_value : float):
	bar.value = new_value
	viewport.render_target_clear_mode = SubViewport.CLEAR_MODE_ONCE
	viewport.render_target_update_mode = SubViewport.UPDATE_ONCE

func _ready():
	texture = viewport.get_texture()
	SetPercent(1.0)
