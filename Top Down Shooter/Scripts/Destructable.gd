extends Widget
class_name Destructable
@onready var _health_bar = $"Health Bar"
@onready var _model = $Model
@export var Visible_In_Fog = true:
	set(value):
		Visible_In_Fog = value
		if _health_bar:
			_update_visibility()
var _visible = false
var _health_bar_displaying = false

func _update_visibility():
	if Visible_In_Fog:
		_model.visible = true
	else:
		_model.visible = _visible
	_health_bar.visible = _health_bar_displaying and _visible

func _ready():
	remove_on_decay = false
	$VisiblityObserver.Owner_Bit_Value = Globals.LocalPlayerBit
	_update_visibility()
	while true:
		await get_tree().create_timer(1).timeout
		ReceiveDamage(self,1)

func _update_heath_bar(percent):
	_health_bar_displaying = percent < 1.0 and not dead
	_health_bar.visible = _health_bar_displaying and _visible
	_health_bar.SetPercent(percent)

func ReceiveDamage(source : Widget, amount: float):
	super.ReceiveDamage(source,amount)
	_update_heath_bar(health/max_health)

func SetHealth(amount : float):
	super.SetHealth(amount)
	_update_heath_bar(health/max_health)

func _on_visiblity_observer_visibility_update(state):
	_visible = state
	can_animate = _visible
	if _visible:
		reset_current_animation()
	_update_visibility()
