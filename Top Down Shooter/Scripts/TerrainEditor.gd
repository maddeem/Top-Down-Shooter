extends Node3D
@export var Map_Size := Vector2i(256,256):
	set(value):
		Map_Size = value
@onready var Cliff_Editor = $Cliff
@onready var Terrain_Editor = $HTerrain
