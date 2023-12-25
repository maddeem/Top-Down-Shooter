extends Node
var hover_text = preload("res://Scenes/hover_text.tscn").instantiate()
var cursor = preload("res://Scenes/Reticle.tscn").instantiate()
var error_interface = preload("res://Scenes/error_interface.tscn").instantiate()
var default_mouse = preload("res://Assets/Textures/UI/Cursor.png")
var target_mouse = preload("res://Assets/Textures/UI/CursorTarget.png")
var holding_item = false
var desciption_object = preload("res://Scenes/titledescription.tscn").instantiate()
var chat : Control
var hover_target : Node3D:
	set(value):
		if is_instance_valid(hover_target) and hover_target != value:
			hover_target.selection_circle.visible = false
		hover_target = value
		update_hover()
var _hover_status : = false
var current_ability : Ability:
	set(value):
		current_ability = value
		if current_ability != null:
			cursor.center_mouse = true
			set_mouse_texture(target_mouse)
		else:
			cursor.center_mouse = false
			set_mouse_texture(default_mouse)

func update_hover():
	var next_status = not (is_instance_valid(hover_target) and hover_target._visible and not hover_target.locally_invisible) or cursor.show_reticle
	if _hover_status == next_status:
		return
	_hover_status = next_status
	if _hover_status:
		hover_text.visible = false
		cursor.modulate = Color.WHITE
		if is_instance_valid(hover_target):
			hover_target.selection_circle.visible = false
	else:
		hover_text.visible = true
		if hover_target is Widget:
			var color = hover_target.get_hover_color()
			hover_text.border_color = color
			cursor.modulate = color
			hover_target.selection_circle.visible = true
			hover_target.selection_circle.modulate = color
		hover_text.text = hover_target.object_name

func set_mouse_texture(tex : Texture2D):
	if tex == null:
		tex = default_mouse
	cursor.texture = tex

func _ready():
	add_child(hover_text)
	add_child(cursor)
	add_child(desciption_object)
	add_child(error_interface)
	hover_text.visible = false

func display_error(error: String):
	error_interface.error_text = error

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta):
	update_hover()
	if not _hover_status:
		var cam = get_viewport().get_camera_3d()
		if hover_target is Widget:
			hover_text.position = cam.unproject_position(hover_target._model.global_position + Vector3(0,hover_target.collision_y_range,0)) - Vector2(0,30)
		else:
			hover_text.position = cam.unproject_position(hover_target.global_position)
