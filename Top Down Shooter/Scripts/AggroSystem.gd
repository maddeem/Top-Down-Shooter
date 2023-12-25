class_name AggroSystem extends Area3D
@export var aggro_check_period = 0.1
@export var aggro_range := 5.0:
	set(value):
		aggro_range = value
		if get_parent():
			$CollisionShape3D.shape.radius = aggro_range
var _inside : Array[Widget] = []
var _last_check := 0.0
@onready var unit : Unit = get_parent()
var target : Widget:
	set(value):
		var prev = target
		target = value
		if not unit:
			return
		if is_instance_valid(prev):
			prev.dies.disconnect(target_dies)
			prev.invsibility_changed.disconnect(invsibility_changed)
		if is_instance_valid(target):
			target.dies.connect(target_dies)
			target.invsibility_changed.connect(invsibility_changed)
		_last_check = aggro_check_period

func _ready():
	aggro_range = aggro_range

func invsibility_changed(which : Widget):
	if target == which:
		target = null
		get_target()

func target_dies():
	set_deferred("target",null)

func get_target() -> Widget:
	var player_owner = unit._player_owner
	var closest_dist = INF
	var closest_widget : Widget
	for widget in _inside:
		if not is_instance_valid(widget):
			_inside.erase(widget)
			continue
		if not widget.dead and not widget._player_owner.is_player_ally(player_owner) and widget.visible_to_player(player_owner):
			var dist = widget.global_position.distance_squared_to(global_position) / widget.attack_priority
			if dist < closest_dist:
				closest_dist = dist
				closest_widget = widget
	return closest_widget

func _on_body_entered(body):
	if body != get_parent() and body is Widget:
		_inside.append(body)

func _on_body_exited(body):
	_inside.erase(body)

func _physics_process(delta):
	if not multiplayer.is_server() or unit.dead:
		return
	_last_check += delta
	var attack : UnitAttack = unit.Attack
	if _last_check > aggro_check_period:
		_last_check = 0.0
		target = get_target()
		if target == null:
			return
		if is_instance_valid(attack):
			attack.attack_in_range = attack.is_in_range(global_position,target)
			if target.global_position != unit.path_target or not attack.attack_in_range:
				if not attack.attack_in_range or (attack.attack_in_range and not attack.stop_when_in_range):
					unit.set_path_target(target.global_position)
	if is_instance_valid(attack) and attack.attack_in_range:
		attack.attack_in_angle = attack.is_in_launch_angle(delta,target)
		if attack.attack_in_angle:
			attack.attack(target)
