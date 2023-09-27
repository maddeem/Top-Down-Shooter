class_name AggroSystem extends Area3D
@export var aggro_range := 5.0:
	set(value):
		aggro_range = value
		if get_parent():
			$CollisionShape3D.shape.radius = aggro_range
var inside : Array[Widget] = []

func _ready():
	aggro_range = aggro_range

func get_target() -> Widget:
	var player_owner = get_parent()._player_owner
	var closest_dist = INF
	var closest_widget = null
	for widget in inside:
		if not is_instance_valid(widget):
			inside.erase(widget)
			continue
		if not widget.dead and not widget._player_owner.is_player_ally(player_owner) and widget.visible_to_player(player_owner):
			var dist = widget.global_position.distance_squared_to(global_position) / widget.attack_priority
			if dist < closest_dist:
				closest_dist = dist
				closest_widget = widget
	return closest_widget

func _on_body_entered(body):
	if body != get_parent() and body is Widget:
		inside.append(body)


func _on_body_exited(body):
	inside.erase(body)
