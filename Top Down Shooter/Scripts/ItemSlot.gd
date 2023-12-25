class_name ItemSlot extends Button
var real_item : Item
var held = false
var inventory : Inventory
@onready var mat : ShaderMaterial = material
func stacks_changed():
	$MarginContainer/Label.text = str(real_item.current_stacks)

func setup_slot():
	real_item.connect("stacks_changed",stacks_changed)
	stacks_changed()
	icon = real_item.icon
	$MarginContainer/Label.visible = real_item.max_stacks > 1
	disabled = not (real_item.useable and inventory.can_use_items)

static func swap_slots(slot1 : ItemSlot, slot2 : ItemSlot):
	var item1 = slot1.real_item
	var item2 = slot2.real_item
	item1.disconnect("stacks_changed",slot1.stacks_changed)
	item2.disconnect("stacks_changed",slot2.stacks_changed)
	slot2.real_item = item1
	slot1.real_item = item2
	item1.slot = slot2
	item2.slot = slot1
	slot1.setup_slot()
	slot2.setup_slot()

func _ready():
	setup_slot()

func _on_gui_input(event):
	if event is InputEventMouseButton:
		if Input.is_action_just_pressed("Aim"):
			inventory.held = self
		elif Input.is_action_just_released("Aim"):
			if inventory.held == self:
				inventory.held = null
				if not is_instance_valid(inventory.hovered):
					NetworkFactory.anyone_call(inventory.instance_id,"drop_item",real_item.instance_id)
				elif inventory.hovered != self:
					ItemSlot.swap_slots(self,inventory.hovered)

func _on_mouse_entered():
	inventory.hovered = self
	GlobalUI.desciption_object.title = real_item.object_name
	GlobalUI.desciption_object.description = real_item.description
	GlobalUI.desciption_object.visible = true
	GlobalUI.desciption_object.global_position = global_position - Vector2(GlobalUI.desciption_object.size.x*0.5-size.x*0.5,GlobalUI.desciption_object.size.y)

func _on_mouse_exited():
	if inventory.hovered == self:
		inventory.hovered = null
		GlobalUI.desciption_object.visible = false

func _on_pressed():
	if is_instance_valid(real_item.ability):
		inventory.held = null
		real_item.ability.start_cast(inventory.parent)


func _on_tree_exiting():
	if inventory.hovered == self:
		inventory.hovered = null
		GlobalUI.desciption_object.visible = false
