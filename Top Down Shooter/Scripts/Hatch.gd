extends Destructable


# Called when the node enters the scene tree for the first time.
func _ready():
	super._ready()
	
func _process(delta):
	super._process(delta)
	if randf() > 0.99:
		WidgetFactory.server_call(instance_id,"ReceiveDamage",[instance_id,1])

func _death():
	super._death()
	$VisionBlocker.disabled = true
	$PathingBlocker.disabled = true
	$CollisionShape3D.disabled = true
