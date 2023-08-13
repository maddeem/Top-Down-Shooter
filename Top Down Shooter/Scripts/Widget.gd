extends CharacterBody3D
class_name Widget
@export var max_health : int = 10:
	set(value):
		max_health = max(1,value)
@export var health : float = 10.0
@export var death_time : float = 1.0
@export var decay_time : float = 10.0
@onready var Animation_Player = $AnimationPlayer
@onready var _model = $Model
@onready var _health_bar = $"Health Bar"
var revealed_once = false
var remove_on_decay = true
var dead := false
var current_animation
var current_animation_play_start
@onready var last_visible_location = global_position
@onready var last_visible_rotation = rotation
var can_animate = true:
	set(value):
		can_animate = value
		if Animation_Player:
			if not can_animate:
				Animation_Player.clear_queue()
				Animation_Player.stop(true)
@export var Visible_In_Fog = true:
	set(value):
		Visible_In_Fog = value
		if _health_bar:
			_update_visibility()
var _visible = false
var _health_bar_displaying = false

func _update_visibility():
	if Visible_In_Fog:
		_model.visible = revealed_once
	else:
		_model.visible = _visible
	if _visible:
		_model.global_position = last_visible_location
		_model.rotation = last_visible_rotation
	_health_bar.visible = _health_bar_displaying and _model.visible

func _play_anim(anim_name : StringName, queued : bool = false):
	current_animation = anim_name
	current_animation_play_start = Globals.TimeElapsed
	if can_animate:
		if queued:
			Animation_Player.queue(anim_name)
		else:
			Animation_Player.play(anim_name)

func _ready():
	_model.top_level = true
	_play_anim("stand")

func reset_current_animation():
	if current_animation == null:
		return
	Animation_Player.stop()
	Animation_Player.play(current_animation)
	Animation_Player.advance(Globals.TimeElapsed - current_animation_play_start)

func _update_heath_bar(percent):
	_health_bar_displaying = percent > 0.0 and not dead
	_health_bar.visible = _health_bar_displaying and _visible
	_health_bar.SetPercent(percent)

func ReceiveDamage(source : Widget, amount : float) -> void:
	if dead:
		return
	health -= amount
	_update_heath_bar(health/max_health)
	if health <= 0:
		dead = true
		_play_anim("death")
		EventHandler.TriggerEvent("widget_dying",{"dying_widget" = self,"killing_widget" = source})
		await get_tree().create_timer(death_time).timeout
		_play_anim("decay")
		await get_tree().create_timer(decay_time).timeout
		if remove_on_decay:
			queue_free()
	else:
		_play_anim("damaged")
		_play_anim("stand",true)
		EventHandler.TriggerEvent("widget_damaged",{"damaged_widget" = self,"source_widget" = source, "amount" = amount})

func SetHealth(amount: float):
	health = amount
	if health <= 0 and not dead:
		dead = true
		EventHandler.TriggerEvent("widget_dying",{"dying_widget" = self,"killing_widget" = null})
	_update_heath_bar(health/max_health)

func UpdateModel(pos : Vector3, rot : Vector3):
	if _visible:
		_model.global_position = pos
		_model.rotation = rot
		last_visible_location = pos
		last_visible_rotation = rot
	

func _on_visiblity_observer_visibility_update(state):
	_visible = state
	can_animate = _visible
	if _visible:
		revealed_once = true
		reset_current_animation()
	_update_visibility()
