extends MeshInstance3D
## This is the update fequency of the fog of war, lower values result in higher refresh rates.
@export_range(.1,1) var Update_Period := .2:
	set(value):
		Update_Period = value
		if _timer:
			_timer.wait_time = Update_Period

## This will toggle the fog of war updates
@export var Paused := false:
	set(value):
		Paused = value
		if Paused:
			_timer.stop()
		else:
			_timer.start()

## This determines the dimentions of the fog of war. This value is multiplied by 2. So For example:
## 100 x 100 would be like Rect(-100,-100,100,100)
@export var Dimensions := Vector2i(100,100):
	set(value):
		Dimensions = value
		if not _material:
			return
		scale.x = Dimensions.x
		scale.z = Dimensions.y
		_doube_size = value * 2
		_map.create(_doube_size)
		_previous_iteration.size = Dimensions + Vector2i(1,1)
		_viewport.size = Dimensions + Vector2i(1,1)
		_material.set_shader_parameter("dimensions",_doube_size)
		RenderingServer.global_shader_parameter_set("FogDimensions", Vector3(_doube_size.x,0,_doube_size.y))
		_occluder_map = []
		for x in _doube_size.x:
			var row = []
			for y in _doube_size.y:
				row.append(0)
			_occluder_map.append(row)

## The color of the fog of war.
@export var Fog_Color := Color(0,0,0,1):
	set(value):
		Fog_Color = value
		if _material:
			var which_color
			if FogMaskEnabled:
				which_color = Fog_Color
			else:
				if FogEnabled:
					which_color = Fog_Explored_Color
				else:
					which_color = Fog_Revealed_Color
			_material.set_shader_parameter("fog_color",which_color)
			_initial_image = Image.create(10,10,false,Image.FORMAT_RGBA8)
			_initial_image.fill(which_color)
			_initial_image = ImageTexture.create_from_image(_initial_image)
			_reset_fog()

## The color for actively revealed fog (usually completely transparent)
@export var Fog_Revealed_Color := Color(0,0,0,0):
	set(value):
		Fog_Revealed_Color = value
		if _material:
			_material.set_shader_parameter("reveal_color",Fog_Revealed_Color)

## The color for fog that isn't currently visible, but has been visited in the past.
@export var Fog_Explored_Color := Color(0,0,0,0.5):
	set(value):
		Fog_Explored_Color = value
		if _material:
			if FogEnabled:
				_material.set_shader_parameter("explored_color",Fog_Explored_Color)
			else:
				_material.set_shader_parameter("explored_color",Fog_Revealed_Color)

## If set to false, explored terrain will always be visible.
@export var FogEnabled = true:
	set(value):
		FogEnabled = value
		Fog_Explored_Color = Fog_Explored_Color

## If set to false, the fog color will be set to the Fog Explored color
@export var FogMaskEnabled = true:
	set(value):
		FogMaskEnabled = value
		Fog_Color = Fog_Color
		
## If set to true, there terrain will revert back to being unexplored when
## you lose vision of the area
@export var Fog_Resets = false

@export_enum("none","low","medium","high") var Fog_Graphical_Smoothing := 3

#LOCALS
@onready var _timer := $Timer
@onready var _viewport : SubViewport = $SubViewport
@onready var _previous_iteration : Control = $SubViewport/PreviousIteration
@onready var _material : ShaderMaterial = _previous_iteration.material
@onready var _mesh_material : ShaderMaterial = get_surface_override_material(0)
var _map = BitMap.new()
var _occluder_map
var _doube_size : Vector2i
var _initial_image
var _frame_delay = 2
var _resetting = false

#METHODS
func _ready():
	if not Paused:
		_timer.start()
	Dimensions = Dimensions
	Fog_Explored_Color = Fog_Explored_Color
	Fog_Color = Fog_Color
	Fog_Revealed_Color = Fog_Revealed_Color
	Update_Period = Update_Period

func _update_fog():
	_viewport.render_target_clear_mode = SubViewport.CLEAR_MODE_ONCE
	_viewport.render_target_update_mode = SubViewport.UPDATE_ONCE
	_previous_iteration.material = _material
	var update_pixels = {}
	
	#OCCLUDER LOGIC
	for occluder in get_tree().get_nodes_in_group("UpdateOccluders"):
		#Occluders only update when moved, then they are removed from the group
		occluder.remove_from_group("UpdateOccluders")
		#Then we check to see if they have any previously modified points on our occluder map
		for point in occluder.Last_Points_Modified:
			_occluder_map[point.x][point.y] -= 1
			update_pixels[point] = true
		var offset : Vector2i = occluder.Last_Position + Dimensions
		occluder.Last_Points_Modified = []
		for point in occluder.Occlusion_Points:
			#Clamp the values so they do not exceed our array
			point = (point + offset).clamp(Vector2i.ZERO,_doube_size-Vector2i(1,1))
			#Add the new point to our modified memeory, so we can remove
			#modified points if the occluder is removed or moves
			occluder.Last_Points_Modified.append(point)
			#Update the occluder map
			_occluder_map[point.x][point.y] += 1
			#Add this pixel to a dictionary via the vect2, which prevents duplicate entries
			update_pixels[point] = true
	#Update our bitmap with whatever pixels we need to change
	for point in update_pixels:
		_map.set_bit(point.x,point.y,_occluder_map[point.x][point.y]>0)
	#Then we build a texture from our bitmap and pass it to the shader
	var tex = ImageTexture.create_from_image(_map.convert_to_image())
	_material.set_shader_parameter("occlusion_mask",tex)
	
	#VISIBLITY MODIFIER LOGIC
	#Capture modifier location and radius data and pack it into an array
	var mods : PackedVector3Array = []
	for modifier in get_tree().get_nodes_in_group("VisibilityModifiers"):
		var pos = Vector2i(round(modifier.global_position.x),round(modifier.global_position.z)) + Dimensions
		mods.append(Vector3i(pos.x,pos.y,modifier.Radius))
	#Update our shaders with the packed data
	_material.set_shader_parameter("visibility_modifiers",mods)
	_material.set_shader_parameter("count",mods.size())
	#Get 
	if not _resetting:
		tex = ImageTexture.create_from_image(_viewport.get_texture().get_image())
		_mesh_material.set_shader_parameter("albedo_texture", tex)
		if Fog_Resets:
			_material.set_shader_parameter("previous_iteration",_initial_image)
			RenderingServer.global_shader_parameter_set("FogData", _initial_image)
		else:
			_material.set_shader_parameter("previous_iteration",tex)
		RenderingServer.global_shader_parameter_set("FogData", tex)
	_frame_delay = 2

func _reset_fog():
	_resetting = true
	_material.set_shader_parameter("previous_iteration",_initial_image)
	_previous_iteration.material = _material
	_frame_delay = 2
	_update_fog()

func _process(_delta):
	#It takes two frames for viewports to update, so we decrement it until we are ready
	# to turn off the shader or reset it
	_frame_delay -= 1
	if _frame_delay == 0:
		_previous_iteration.material = null
		if _resetting:
			var tex = ImageTexture.create_from_image(_viewport.get_texture().get_image())
			_mesh_material.set_shader_parameter("albedo_texture", tex)
			_resetting = false
