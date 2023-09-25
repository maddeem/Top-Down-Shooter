extends Node
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
		_double_size = value * 2
		occluder_image_map = Image.create(_double_size.x,_double_size.y,false,Image.FORMAT_RGBA8)
		occluder_image_map.fill(Color(0,0,0,0))
		_previous_iteration.size = Dimensions + Vector2i(1,1)
		_local_previous.size = _previous_iteration.size
		_viewport.size = Dimensions + Vector2i(1,1)
		_local_viewport.size = _viewport.size
		_clamp_max = _double_size + Vector2i(1,1)
		RenderingServer.global_shader_parameter_set("FogDimensions", _double_size)
		RenderingServer.global_shader_parameter_set("InverseFogDimensions",Vector2(1.0,1.0)/Vector2(_double_size))
		_occluder_map = []
		for x in _double_size.x:
			var row = []
			for y in _double_size.y:
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
			RenderingServer.global_shader_parameter_set("FogUnexploredColor", which_color)
			_initial_image = Image.create(1,1,false,Image.FORMAT_RGBA8)
			_initial_image.fill(which_color)
			_initial_image = ImageTexture.create_from_image(_initial_image)
			_reset_fog()

## The color for actively revealed fog (usually completely transparent)
@export var Fog_Revealed_Color := Color(0,0,0,0):
	set(value):
		Fog_Revealed_Color = value
		if _material:
			RenderingServer.global_shader_parameter_set("FogRevealColor", Fog_Revealed_Color)

## The color for fog that isn't currently visible, but has been visited in the past.
@export var Fog_Explored_Color := Color(0,0,0,0.5):
	set(value):
		Fog_Explored_Color = value
		if _material:
			if FogEnabled:
				if Fog_Resets:
					RenderingServer.global_shader_parameter_set("FogExploredColor", Fog_Color)
				else:
					RenderingServer.global_shader_parameter_set("FogExploredColor", Fog_Explored_Color)
			else:
				RenderingServer.global_shader_parameter_set("FogExploredColor", Fog_Revealed_Color)

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
@export var Fog_Resets = false:
	set(value):
		Fog_Resets = value
		Fog_Explored_Color = Fog_Explored_Color

@export_enum("none","low","medium","high") var Fog_Graphical_Smoothing := 3

#LOCALS
@onready var _timer := $Timer
@onready var _viewport : SubViewport = $SubViewport
@onready var _previous_iteration : Control = $SubViewport/PreviousIteration
@onready var _local_viewport : SubViewport = $LocalFog
@onready var _local_previous = $LocalFog/LocalPreviousIteration
@onready var _material : ShaderMaterial = _previous_iteration.material
@onready var _local_material : ShaderMaterial = _local_previous.material

# Eventually we want to replace this with a color map so we can have different types of occluders.
# Right now vision passes through occluders until the occluder ends, so it allows the occluder
# source to be visible. But it would be nice to have occluders that completely stop all vision
# We can implement this by sampling different colors. 
# Right now:
# Black = Weak Occlusion
var occluder_image_map : Image = Image.new()
var _occluder_map
var _double_size : Vector2i
var _clamp_max : Vector2i
var _initial_image
var _frame_delay = 2
var _resetting = false
var _last_fog_image : Image
var _observer_data = {}

#METHODS
func _ready() -> void:
	if not Paused:
		_timer.start()
	Dimensions = Dimensions
	Fog_Explored_Color = Fog_Explored_Color
	Fog_Color = Fog_Color
	Fog_Revealed_Color = Fog_Revealed_Color
	Update_Period = Update_Period
	Globals.FogOfWar = self
	
func Position_To_Pixel(pos : Vector3) -> Vector2i:
	return Vector2i(Vector2(pos.x,pos.z).floor()) + Dimensions

func IsPointVisibleToBitId(BitId : int, pos : Vector3) -> bool:
	if not _last_fog_image:
		return false
	var adjust_pos = Position_To_Pixel(pos)/2
	var color = _last_fog_image.get_pixelv(adjust_pos)
	return Utility.convert_color_to_bit(color) & BitId != 0

func _check_observers():
	for point in _observer_data:
		var color = Utility.convert_color_to_bit(_last_fog_image.get_pixelv(point))
		for observer in _observer_data[point]:
			if is_instance_valid(observer):
				observer.is_visible = color & Globals.LocalVisionBit != 0
			else:
				_observer_data[point].erase(observer)
				if _observer_data[point].size() == 0:
					_observer_data.erase(point)

func _update_fog() -> void:
	_viewport.render_target_clear_mode = SubViewport.CLEAR_MODE_ONCE
	_viewport.render_target_update_mode = SubViewport.UPDATE_ONCE
	_local_viewport.render_target_clear_mode = SubViewport.CLEAR_MODE_ONCE
	_local_viewport.render_target_update_mode = SubViewport.UPDATE_ONCE
	_previous_iteration.material = _material
	_local_previous.material = _local_material
	var update_pixels = {}
	var tex
	var tree = get_tree()
	for observer in tree.get_nodes_in_group("UpdateObservers"):
		var converted_pos = Position_To_Pixel(observer._last_position)/2
		if observer.Previous_Grid_Position != null:
			_observer_data[observer.Previous_Grid_Position].erase(observer)
			if _observer_data[observer.Previous_Grid_Position].size() == 0:
				_observer_data.erase(observer.Previous_Grid_Position)
		if _observer_data.has(converted_pos):
			_observer_data[converted_pos].append(observer)
		else:
			_observer_data[converted_pos] = [observer]
		observer.Previous_Grid_Position = converted_pos
		observer.remove_from_group("UpdateObservers")

	#OCCLUDER LOGIC
	for occluder in tree.get_nodes_in_group("UpdateOccluders"):
		#Occluders only update when moved, then they are removed from the group
		occluder.remove_from_group("UpdateOccluders")
		#Then we check to see if they have any previously modified points on our occluder map
		for point in occluder.Last_Points_Modified:
			if occluder.Previous_Occlusion_Height >= _occluder_map[point.x][point.y]:
				_occluder_map[point.x][point.y] = 0
				update_pixels[point] = Color(0,0,0,0)
		if not occluder.disabled:
			var offset : Vector2i = occluder.Last_Position + Dimensions
			occluder.Last_Points_Modified = []
			for point in occluder.Occlusion_Points:
				#Clamp the values so they do not exceed our array
				point = (point + offset).clamp(Vector2i.ZERO,_clamp_max)
				#Add the new point to our modified memory, so we can remove
				#modified points if the occluder is removed or moves
				occluder.Last_Points_Modified.append(point)
				#Update the occluder map
				if occluder.Occlusion_Height >= _occluder_map[point.x][point.y]:
					occluder.Previous_Occlusion_Height = occluder.Occlusion_Height
					_occluder_map[point.x][point.y] = occluder.Occlusion_Height
					update_pixels[point] = occluder.Adjusted_Occlusion_Height

			#Add this pixel to a dictionary via the vect2, which prevents duplicate entries
	#Update our bitmap with whatever pixels we need to change
	if update_pixels.size() > 0:
		for point in update_pixels:
			occluder_image_map.set_pixelv(point,update_pixels[point])
		tex = ImageTexture.create_from_image(occluder_image_map)
		RenderingServer.global_shader_parameter_set("OcclusionMap", tex)
	
	#VISIBLITY MODIFIER LOGIC
	#Capture modifier location and radius data and pack it into an array
	var mods : PackedVector3Array = []
	var mods2 = []
	for modifier in get_tree().get_nodes_in_group("VisibilityModifiers"):
		var pos = Position_To_Pixel(modifier.global_position)
		mods.append(Vector3i(pos.x,pos.y,modifier.Radius))
		mods2.append(Vector4(modifier.Adjusted_Vision_Height,modifier.Owner_Bit_Value,modifier.global_rotation.y,modifier.FOV))
	#Update our shaders with the packed data
	_material.set_shader_parameter("visibility_modifiers",mods)
	_material.set_shader_parameter("visiblity_data",mods2)
	_material.set_shader_parameter("count",mods.size())
	#Get 
	if not _resetting:
		_last_fog_image = _viewport.get_texture().get_image()
		_check_observers()
		RenderingServer.global_shader_parameter_set("FogData", 
			ImageTexture.create_from_image(_last_fog_image)
		)
		RenderingServer.global_shader_parameter_set("FogDataLocal", 
			ImageTexture.create_from_image(_local_viewport.get_texture().get_image())
		)
			
	_frame_delay = 2

func _reset_fog() -> void:
	_resetting = true
	var img = Image.create(1,1,false,Image.FORMAT_RGBA8)
	img.fill(Color(0,0,0,0))
	RenderingServer.global_shader_parameter_set("FogData", ImageTexture.create_from_image(img))
	RenderingServer.global_shader_parameter_set("FogDataLocal", _initial_image)
	_previous_iteration.material = _material
	_frame_delay = 2
	_update_fog()

func _process(_delta) -> void:
	#It takes two frames for viewports to update, so we decrement it until we are ready
	# to turn off the shader or reset it
	_frame_delay -= 1
	if _frame_delay == 0:
		_previous_iteration.material = null
		_local_previous.material = null
		if _resetting:
			var tex = ImageTexture.create_from_image(_viewport.get_texture().get_image())
			RenderingServer.global_shader_parameter_set("FogData", tex)
			_resetting = false
