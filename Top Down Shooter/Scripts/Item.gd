class_name Item extends Widget

func _ready():
	super._ready()
	_model.top_level = false

func _on_visiblity_observer_visibility_update(state):
	super._on_visiblity_observer_visibility_update(state)
	if state:
		$Model/Loot.speed_scale = 1.0
	else:
		$Model/Loot.speed_scale = 0.0
