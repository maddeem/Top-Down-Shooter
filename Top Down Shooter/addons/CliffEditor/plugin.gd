@tool
extends EditorPlugin
var _cliff_ui = preload("res://addons/CliffEditor/CliffEditorUI.tscn")
var _brush_path = preload("res://addons/CliffEditor/Brush.tscn")
var docked_scene
var eds = get_editor_interface().get_selection()
enum BRUSH_TYPE {Elevate, Lower, Flatten}
var _current_brush = BRUSH_TYPE.Elevate
var _current_brush_size := 1
var _editor_viewports = []
var brush
var cur_cliff : Cliff

func _get_mouse_terrain_position() -> Vector3:
	var vp = _editor_viewports[0]
	var m_pos = vp.get_mouse_position()
	var cam = vp.get_camera_3d()
	if not cam:
		return Vector3.ZERO
	var ray_start = cam.project_ray_origin(m_pos)
	var ray_end = ray_start + cam.project_ray_normal(m_pos) * 1000
	var world3d = vp.find_world_3d()
	var space_state = world3d.direct_space_state
	var query = PhysicsRayQueryParameters3D.create(ray_start, ray_end, 1)
	var ray = space_state.intersect_ray(query)
	if not ray.has("position"):
		return Vector3.ZERO
	return ray.position

func _process(delta):
	if is_instance_valid(docked_scene):
		var m_pos = _get_mouse_terrain_position()
		brush.position = m_pos.round()

func _change_brush(brush : int):
	_current_brush = brush

func _change_brush_size(_size : int) -> void:
	_current_brush_size = _size
	brush.update_brush_size(_size)

func _show_cliff_editor(visible : bool, cliff : Cliff) -> void:
	if visible:
		if not is_instance_valid(docked_scene):
			brush = _brush_path.instantiate()
			add_child(brush)
			docked_scene = _cliff_ui.instantiate()
			add_control_to_container(CONTAINER_SPATIAL_EDITOR_MENU,docked_scene)
			docked_scene.connect("brush_updated",_change_brush)
			docked_scene.connect("brush_size_updated",_change_brush_size)
		cur_cliff = cliff
	else:
		if is_instance_valid(docked_scene):
			remove_control_from_container(CONTAINER_SPATIAL_EDITOR_MENU,docked_scene)
			brush.free()
			docked_scene.free()
func _selection_changed():
	var sel = eds.get_selected_nodes()
	if sel.size() > 0:
		_show_cliff_editor(sel[0] is Cliff,sel[0])

func _ready():
	eds.connect("selection_changed",_selection_changed)
	var base_control = get_editor_interface().get_base_control()
	var next = base_control.get_children()
	_editor_viewports = []
	var cur = []
	while true:
		cur = next
		next = []
		if cur.size() == 0:
			break
		for node in cur:
			next += node.get_children()
			var super_parent = node.get_parent().get_parent().get_parent()
			if super_parent.get_class() =="Node3DEditorViewport" and node is Camera3D:
				_editor_viewports.append(node.get_parent())

func _exit_tree():
	_show_cliff_editor(false)
