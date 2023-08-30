extends Node

func IsPointInCone(vec1 : Vector2, vec2 : Vector2, dir : float, fov : float) -> bool:
	#fov is the halved opening angle of the cone
	return cos(atan2(vec2.y-vec1.y,vec2.x-vec1.x)-dir) > cos(fov)

func angle_difference(from, to):
	return fposmod(to-from + PI, TAU) - PI

func change_angle_bounded(from, to, amount):
	return from + clampf(wrapf(to - from, -PI, PI),-amount,amount)

func frame_safe_lerp(current,target,time,frame_delta):
	var K = 1.0 - pow(time,frame_delta)
	#I saw this and thought it might be useful, so far idc about it
	return lerp(current,target,K)

func get_bit(val : int) -> int:
	if Cache.exists("bit",val):
		return Cache.read_from("bit",val)
	else:
		var bit = pow(2,val)
		Cache.write_to("bit",val,bit)
		return bit

func convert_bit_to_color(value : int):
	if Cache.exists("bit_color",value):
		return Cache.read_from("bit_color",value)
	var new = Vector3(0,0,0);
	new.x = ( (value >> 16) & 0xFF) / 255.0;
	new.y = ( (value >> 8) & 0xFF) / 255.0;
	new.z = (value & 0xFF) / 255.0;
	Cache.write_to("bit_color",value,new)
	return new;

func convert_color_to_bit(color):
	if Cache.exists("bit_color",color):
		return Cache.read_from("bit_color",color)
	var new = Vector3i(0,0,0)
	new.x = round(color[0] * 255)
	new.y = round(color[1] * 255)
	new.z= round(color[2] * 255)
	var val = (new.x << 16) | (new.y << 8) | new.z
	Cache.write_to("bit_color",color,val)
	return val

func get_interpolated_normal(x : float, y : float, data):
	var x1 = int(x)
	var y1 = int(y)
	var heightT = data.get_height_at(x1, y1+1)
	var heightL = data.get_height_at(x1-1, y1)
	var heightR = data.get_height_at(x1+1, y1)
	var heightB = data.get_height_at(x1, y1-1)
	var dx = heightR-heightL;
	var dy = heightB-heightT;
	return Vector3(dx*2,-4,dy*2).normalized()

func get_interpolated_height(x : float, y : float, data) -> float:
	var x1 = int(x)
	var y1 = int(y)
	var x2 = x1 + 1
	var y2 = y1 + 1
	var height1 = data.get_height_at(x1, y1)
	var height2 = data.get_height_at(x2, y1)
	var height3 = data.get_height_at(x2, y2)
	var height4 = data.get_height_at(x1, y2)
	var dx = x - x1
	var dy = y - y1
	var fractional_height1 = height1 + (height2 - height1) * dx
	var fractional_height2 = height4 + (height3 - height4) * dx
	return fractional_height1 + (fractional_height2 - fractional_height1) * dy

func get_terrain_offset(terrain,data):
	var offset
	if Cache.exists("terrain_offset",terrain):
		offset = Cache.read_from("terrain_offset",terrain)
	else:
		var img : Image = data.get_image(data.CHANNEL_HEIGHT)
		offset = Vector2(img.get_width(),img.get_height())/2 - Vector2(0.5,0.5)
		Cache.write_to("terrain_offset",terrain,offset)
	return offset

func GetTerrainHeight(terrain, pos : Vector2):
	var data = terrain.get_data()
	pos = pos + get_terrain_offset(terrain,data)
	return get_interpolated_height(pos.x,pos.y,data)

func GetTerrainNormal(terrain, pos : Vector2):
	var data = terrain.get_data()
	pos = pos + get_terrain_offset(terrain,data)
	return get_interpolated_normal(pos.x,pos.y,data)

func raycast_from_mouse(source : Node3D, ray_length: float, collision_mask : int):
	var viewport  = get_viewport()
	var camera = viewport.get_camera_3d()
	var space_state = source.get_world_3d().direct_space_state
	var pos = viewport.get_mouse_position()
	var ray_start = camera.project_ray_origin(pos)
	var ray_end = ray_start + camera.project_ray_normal(pos) * ray_length
	var param := PhysicsRayQueryParameters3D.create(ray_start, ray_end, collision_mask)
	return space_state.intersect_ray(param)

func dir_contents(path : String) -> PackedStringArray:
	var dir_list = [path]
	var list : PackedStringArray = []
	var cur_path
	while dir_list.size() > 0:
		cur_path = dir_list.pop_back()
		var dir = DirAccess.open(cur_path)
		if dir:
			dir.list_dir_begin()
			var file_name = dir.get_next()
			while file_name != "":
				if dir.current_is_dir():
					dir_list.append(cur_path + "/" + file_name)
				else:
					list.append(cur_path + "/" + file_name)
				file_name = dir.get_next()
	return list
