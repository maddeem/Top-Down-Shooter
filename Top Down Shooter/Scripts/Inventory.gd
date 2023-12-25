class_name Inventory extends Node3D
const SLOT_PATH = preload("res://Scenes/Inventory/ItemSlot.tscn")
var slot_items : Array[ItemSlot] = []
var items_in_range : Array[Item] = []
var hovered : ItemSlot
var instance_id : int
@export var can_use_items := true:
	set(value):
		can_use_items = value
		if get_parent():
			for slot in slot_items:
				slot.disabled = not (slot.real_item.useable and can_use_items)
var held : ItemSlot:
	set(value):
		held = value
		if is_instance_valid(held):
			GlobalUI.set_mouse_texture(held.icon)
		else:
			GlobalUI.set_mouse_texture(null)
@onready var parent = get_parent()
@export var inventory_size := 6:
	set(value):
		inventory_size = max(value,0)
		if parent:
			while inventory_size < slot_items.size():
				NetworkFactory.anyone_call(instance_id,"drop_item",slot_items.pop_back().real_item.instance_id)
@export var columns := 6:
	set(value):
		columns = value
		if parent:
			$Inventory/GridContainer.columns = columns
var current_global_cooldowns = {}

func global_cooldown(item : Item):
	for slot in slot_items:
		var it = slot.real_item
		if it.ability.get_script() == item.ability.get_script():
			it.ability.cur_cooldown = item.ability.cur_cooldown
	current_global_cooldowns[item.scene_file_path] = Globals.TimeElapsed + item.ability.cur_cooldown

func _ready():
	instance_id = NetworkFactory.get_new_id(self)
	can_use_items = can_use_items

func drop_item(item_id : int):
	var item : Item = NetworkFactory.Instance2Node(item_id)
	if not is_instance_valid(item) or not item is Item:
		return
	var slotItem : ItemSlot = item.slot
	item.move_instantly(parent.global_position + Vector3(item.rng.randf_range(-0.5,0.5),0,item.rng.randf_range(-0.5,0.5)))
	item.hidden = false
	item.slot = null
	slotItem.queue_free()
	slot_items.erase(slotItem)
	if is_instance_valid(item.ability):
		item.ability.cur_cooldown = 0.0

func attempt_pickup(item_id : int, display_error := true):
	var item : Item = NetworkFactory.Instance2Node(item_id)
	if not is_instance_valid(item) or not item is Item or item.hidden:
		return
	if item.max_stacks > 1:
		var stacks_remaining = item.current_stacks
		for slot in slot_items:
			var cur : Item = slot.real_item
			if cur.scene_file_path== item.scene_file_path:
				var stacks_to_fill = cur.max_stacks - cur.current_stacks
				var r = min(stacks_to_fill,stacks_remaining)
				cur.current_stacks += r
				stacks_remaining -= r
				if stacks_remaining == 0:
					item.queue_free()
					return
		item.current_stacks = stacks_remaining
	if is_instance_valid(item):
		if slot_items.size() >= inventory_size and display_error:
			GlobalUI.display_error("Your inventory is full.")
			return
		item.hidden = true
		var new : ItemSlot = SLOT_PATH.instantiate()
		new.real_item = item
		new.inventory = self
		item.slot = new
		slot_items.append(new)
		$Inventory/GridContainer.add_child(new)
		if current_global_cooldowns.has(item.scene_file_path):
			var t = current_global_cooldowns[item.scene_file_path]
			if t < Globals.TimeElapsed:
				current_global_cooldowns.erase(item.scene_file_path)
			else:
				item.ability.cur_cooldown = t - Globals.TimeElapsed

func _physics_process(_delta):
	visible = parent is PlayerUnit and parent._player_owner == Globals.LocalPlayer
	$Inventory.visible = visible
	$Area3D.monitoring = visible
		
func _input(event):
	var is_owner = parent._player_owner.id == multiplayer.get_unique_id()
	if event.is_action("Interact") and event.is_action_pressed("Interact") and is_owner:
		if items_in_range.size() > 0:
			NetworkFactory.anyone_call(instance_id,"attempt_pickup",items_in_range.back().instance_id)

func _on_area_3d_body_entered(body):
	if body is Item:
		items_in_range.append(body)
		GlobalUI.error_interface.add_interact_object(body)

func _on_area_3d_body_exited(body):
	items_in_range.erase(body)
	GlobalUI.error_interface.remove_interact_object(body)


func _on_grid_container_child_exiting_tree(node):
	if node is ItemSlot:
		slot_items.erase(node)

