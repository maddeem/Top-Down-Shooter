extends Node

func frame_safe_lerp(current,target,time,frame_delta):
	var K = 1.0 - pow(time,frame_delta)
	#I saw this and thought it might be useful, so far idc about it
	return lerp(current,target,K)
