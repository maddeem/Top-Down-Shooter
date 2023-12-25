class_name Ability extends Node
enum{
	NO_TARGET,
	WIDGET,
	POINT,
	POINT_OR_WIDGET
}
var item : Item
var instance_id : int
var cur_cooldown := 0.0
var cur_caster : Widget
@export var cooldown := 1.0
@export_enum("No Target","Widget","Point","Point or Widget") var cast_type : int
@export_flags("Item","Mechanical","Organic","Unit") var targets_allowed : int
const TARGET_ITEM = 1
const TARGET_MECHANICAL = 2
const TARGET_ORGANIC = 4
const TARGET_UNIT = 8
@export_flags("Enemies","Allies") var target_type_required : int
const TARGET_ENEMY = 1
const TARGET_ALLY = 2
const ERROR_TEXT = {
	-2: "an ally",
	-1: "an enemy",
	1: "an item",
	2: "mechanical",
	4: "organic",
	8: "a unit",
}
signal ability_cast

func _ready():
	instance_id = NetworkFactory.get_new_id(self)

func is_target_valid(target : Widget, show_error = false) -> bool:
	var errors = Utility.find_missing_bits(targets_allowed,target.Target_As)
	var error_count = errors.size()
	var is_ally = target._player_owner.is_player_ally(cur_caster._player_owner)
	if target_type_required & TARGET_ENEMY == TARGET_ENEMY and is_ally:
		errors.append(-1)
		error_count += 1
	if target_type_required & TARGET_ALLY == TARGET_ALLY and not is_ally:
		errors.append(-2)
		error_count += 1
	if show_error and error_count > 0:
		var i = 0
		var s = "Must target something that is"
		for error in errors:
			i += 1
			if i > 1:
				if i == error_count:
					s += " and "
				else:
					s += ", "
			else:
				s += " "
			s += ERROR_TEXT[error]
			if i == error_count:
				s += "."
		GlobalUI.display_error(s)
	return error_count == 0

func start_cast(caster : Widget):
	if cur_cooldown > 0.0:
		GlobalUI.display_error("This ability is on a cooldown.")
		return
	cur_caster = caster
	if cast_type == NO_TARGET:
		if is_target_valid(caster,true):
			var args : PackedInt32Array = [caster.instance_id,caster.instance_id]
			if multiplayer.is_server():
				check_cast(args)
			else:
				NetworkFactory.peer_call(instance_id,"check_cast",args)
	else:
		GlobalUI.current_ability = self

func check_cast(args : Array):
	if cur_cooldown <= 0.0:
		NetworkFactory.server_call(instance_id,"cast_ability",args)

func cast_ability(caster_id : int, target : Variant):
	cur_cooldown = cooldown
	var caster : Widget = NetworkFactory.Instance2Node(caster_id)
	if target is int:
		target = NetworkFactory.Instance2Node(target)
	if is_instance_valid(item) and item.max_stacks > 1:
		item.current_stacks -= 1
	cast_action(caster,target)
	emit_signal("ability_cast")
	if item.remove_on_use:
		item.queue_free()

func cast_action(caster : Widget, target : Variant):
	pass

func _input(event):
	if event.is_action("Aim") and event.is_action_pressed("Aim") and GlobalUI.current_ability:
		GlobalUI.current_ability = null
		get_viewport().set_input_as_handled()
	if event.is_action("Attack") and event.is_action_pressed("Attack") and GlobalUI.current_ability == self:
		var args : PackedInt32Array
		get_viewport().set_input_as_handled()
		match cast_type:
			WIDGET:
				if is_instance_valid(GlobalUI.hover_target):
					if is_target_valid(GlobalUI.hover_target,true):
						GlobalUI.current_ability = null
						args = [cur_caster.instance_id,GlobalUI.hover_target.instance_id]
				else:
					GlobalUI.display_error("You must select a target.")
			POINT:
				var ray = Utility.raycast_from_mouse(cur_caster, 1000, 1)
				if ray.has("position"):
					GlobalUI.current_ability = null
					args = [cur_caster.instance_id,ray.position]
			POINT_OR_WIDGET:
				if is_instance_valid(GlobalUI.hover_target) and is_target_valid(GlobalUI.hover_target,true):
					GlobalUI.current_ability = null
					args = [cur_caster.instance_id,GlobalUI.hover_target.instance_id]
				else:
					var ray = Utility.raycast_from_mouse(cur_caster, 1000, 1)
					if ray.has("position"):
						GlobalUI.current_ability = null
						args = [cur_caster.instance_id,ray.position]
		if args:
			if multiplayer.is_server():
				check_cast(args)
			else:
				NetworkFactory.peer_call(instance_id,"check_cast",args)

func _physics_process(delta):
	var prev = cur_cooldown
	cur_cooldown = cur_cooldown - delta
	if prev != cur_cooldown and is_instance_valid(item) and is_instance_valid(item.slot):
		item.slot.material.set_shader_parameter("percent",cur_cooldown/cooldown)
