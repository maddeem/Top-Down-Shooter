extends Node3D
class_name Widget
@export var max_health : int = 10:
	set(value):
		max_health = max(1,value)
@export var health : float = 10.0
@export var death_time : float = 1.0
@export var decay_time : float = 10.0
@onready var Animation_Player = $AnimationPlayer
var remove_on_decay = true
var dead := false
var current_animation
var current_animation_play_start
var can_animate = true:
	set(value):
		can_animate = value
		if Animation_Player:
			if not can_animate:
				Animation_Player.clear_queue()
				Animation_Player.stop(true)

func _play_anim(anim_name : StringName, queued : bool = false):
	current_animation = anim_name
	current_animation_play_start = Globals.TimeElapsed
	if can_animate:
		if queued:
			Animation_Player.queue(anim_name)
		else:
			Animation_Player.play(anim_name)

func reset_current_animation():
	if current_animation == null:
		return
	Animation_Player.stop()
	Animation_Player.play(current_animation)
	Animation_Player.advance(Globals.TimeElapsed - current_animation_play_start)


func ReceiveDamage(source : Widget, amount : float) -> void:
	if dead:
		return
	health -= amount
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
