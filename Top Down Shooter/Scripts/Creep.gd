extends Node
var _update_queued = false
var creep_data : PackedVector3Array = []:
	set(value):
		creep_data = value
		_update_queued = true
var creep_cache = {}

func update_spawner(which : CreepSpawner):
	creep_data[creep_cache[which]] = which.get_data()

func remove_spawner(which : CreepSpawner):
	creep_data.remove_at(creep_cache[which])
	creep_cache.erase(which)

func add_spawner(which : CreepSpawner):
	creep_cache[which] = creep_data.size()
	creep_data.append(which.get_data())
	which.connect("updated",update_spawner.bind(which))
	which.connect("tree_exiting",remove_spawner.bind(which))

func _process(_delta):
	if _update_queued and Globals.HeightTerrainMaterial:
		Globals.HeightTerrainMaterial.set_shader_parameter("CreepData",creep_data)
		Globals.HeightTerrainMaterial.set_shader_parameter("CreepCount",creep_data.size())
		_update_queued = false
