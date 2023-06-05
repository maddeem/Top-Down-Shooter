extends Node

func frame_safe_lerp(current,target,time,frame_delta):
	var K = 1.0 - pow(time,frame_delta)
	#I saw this and thought it might be useful, so far idc about it
	return lerp(current,target,K)

func convert_bit_to_color(value : int):
	var new = Vector3(0,0,0);
	new.x = ( (value >> 16) & 0xFF) / 255.0;
	new.y = ( (value >> 8) & 0xFF) / 255.0;
	new.z = (value & 0xFF) / 255.0;
	return new;

func convert_color_to_bit(color):
	var new = Vector3i(0,0,0)
	new.x = round(color[0] * 255)
	new.y = round(color[1] * 255)
	new.z= round(color[2] * 255)
	return (new.x << 16) | (new.y << 8) | new.z


