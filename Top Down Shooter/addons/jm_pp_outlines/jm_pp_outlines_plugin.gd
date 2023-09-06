@tool
extends EditorPlugin

func _enter_tree():
	add_custom_type("PPOutlinesCamera", "Camera", preload("res://addons/jm_pp_outlines/jm_pp_outlines_camera.gd"), preload("res://addons/jm_pp_outlines/graphics/pp_outlines_camera_icon.png"))
	pass


func _exit_tree():
	pass
