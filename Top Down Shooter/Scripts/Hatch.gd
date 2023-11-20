extends Doorway
func set_locked(value):
	super(value)
	if not get_parent():
		return
	var col
	if locked:
		col = Color(1,0,0)
	else:
		col = Color(0,1,0)
	$Model/cliff_hatch/MeshR/Screen.get_surface_override_material(0).emission = col
	$Model/cliff_hatch/MeshL/Screen_001.get_surface_override_material(0).emission = col
