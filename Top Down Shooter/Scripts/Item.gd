class_name Item extends Widget
@export var cost := 100
@export var current_stacks := 1:
	set(value):
		current_stacks = value
		emit_signal("stacks_changed")
		if current_stacks <= 0 and max_stacks > 1:
			queue_free()
@export var max_stacks := 3
@export var icon : Texture2D
@export var useable :=  true
@export var remove_on_use := false
@export_multiline var description : String
@export_node_path() var ability_path
@export var share_item_cooldown := false
var ability : Ability
signal stacks_changed
var slot : ItemSlot
var push := Vector3.ZERO
var rng := RandomNumberGenerator.new()
var hidden := false:
	set(value):
		hidden = value
		if get_parent():
			set_physics_process(not hidden)
			set_process(not hidden)
			visible = not hidden
			if hidden:
				collision_layer = 0
			else:
				collision_layer = 16

func ability_cast():
	if share_item_cooldown and is_instance_valid(slot):
		slot.inventory.global_cooldown(self)

func _ready():
	super._ready()
	_model.top_level = false
	hidden = hidden
	rng.seed = instance_id
	if ability_path:
		ability = get_node(ability_path)
		ability.item = self
		ability.connect("ability_cast",ability_cast)

func _physics_process(delta):
	super(delta)
	velocity.y -= Globals.Gravity * delta
	for i  in get_slide_collision_count():
		var col : KinematicCollision3D =get_slide_collision(i)
		if col.get_collider(0) is Item:
			var n = col.get_normal(0)
			push += n
			col.get_collider(0).push -= n
	push *= 0.5
	velocity.x = push.x
	velocity.z = push.z
	move_and_slide()

func _on_visiblity_observer_visibility_update(state):
	super._on_visiblity_observer_visibility_update(state)
	if state:
		$Model/Loot.speed_scale = 1.0
	else:
		$Model/Loot.speed_scale = 0.0


func _on_tree_exiting():
	if is_instance_valid(slot):
		slot.queue_free()
