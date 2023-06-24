extends Node

func frame_safe_lerp(current,target,time,frame_delta):
	var K = 1.0 - pow(time,frame_delta)
	#I saw this and thought it might be useful, so far idc about it
	return lerp(current,target,K)

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

func GetTerrainHeight(terrain, pos : Vector2):
	var data = terrain.get_data()
	var offset
	if Cache.exists("terrain_offset",terrain):
		offset = Cache.read_from("terrain_offset",terrain)
	else:
		var img : Image = data.get_image(data.CHANNEL_HEIGHT)
		offset = Vector2(img.get_width(),img.get_height())/2 - Vector2(0.5,0.5)
		Cache.write_to("terrain_offset",terrain,offset)
	pos = (pos + offset).round()
	return data.get_height_at(pos.x, pos.y)
