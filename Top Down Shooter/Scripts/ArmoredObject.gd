class_name ArmoredObject extends Node
@export var collision_y_range := 0.0
enum{
	Metal, Flesh, Wood, Rock, Glass
}
static var resolve_array = []
static var particles = {
	"Sparks" = preload("res://Scenes/Particles/MetalSparks.tscn"),
	"Glass" = preload("res://Scenes/Particles/Glass.tscn")
}
@export_enum("Metal", "Flesh", "Wood", "Rock", "Glass") var Armor_Type : int

static func _static_init():
	var max_size = Glass + 1
	for x in range(max_size):
		resolve_array.append([])
		for y in range(max_size):
			resolve_array[x].append([0])
	resolve_array[Metal][Metal] = func(target : Vector3, rotation : Vector3):
		var new = particles.Sparks.instantiate()
		Globals.add_child(new)
		new.position = target
		new.rotation = rotation
	resolve_array[Metal][Glass] = func(target: Vector3, rotation: Vector3):
		var new = particles.Sparks.instantiate()
		Globals.add_child(new)
		new.position = target
		new.rotation = rotation
		new = particles.Glass.instantiate()
		Globals.add_child(new)
		new.position = target
		new.rotation = rotation

static func resolve_impact(source_type : int, origin_type : int, target : Vector3, rotation : Vector3) -> void:
	var which = resolve_array[source_type][origin_type]
	if which is Callable:
		which.call(target,rotation)
