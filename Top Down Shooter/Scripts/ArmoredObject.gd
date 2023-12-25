class_name ArmoredObject extends Node
@export var collision_y_range := 0.0
enum{
	Metal, Flesh, Wood, Rock, Glass
}

static var resolve_array = []
static var sounds = {}
static var particles = {
	"Sparks" = preload("res://Scenes/Particles/MetalSparks.tscn"),
	"Glass" = preload("res://Scenes/Particles/Glass.tscn")
}
@export_enum("Metal", "Flesh", "Wood", "Rock", "Glass") var Armor_Type : int

static func _static_init():
	sounds[Flesh] = [
	preload("res://Assets/Sounds/FleshImpact1.mp3"),
	preload("res://Assets/Sounds/FleshImpact2.mp3"),
	preload("res://Assets/Sounds/FleshImpact3.mp3"),
	preload("res://Assets/Sounds/FleshImpact4.mp3")]
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

static func play_impact_sound(impact_type:int, pos : Vector3):
	var player = AudioStreamPlayer3D.new()
	player.attenuation_filter_cutoff_hz = 20500
	player.pitch_scale = randf_range(0.9,1.1)
	Globals.add_child(player)
	player.position = pos
	var which = sounds[impact_type]
	player.stream = which[randi_range(0,which.size()-1)]
	player.play()
	await player.finished
	player.queue_free()

static func resolve_impact(source_type : int, origin_type : int, target : Vector3, rotation : Vector3) -> void:
	var which = resolve_array[source_type][origin_type]
	if which is Callable:
		which.call(target,rotation)
	if sounds.has(source_type):
		ArmoredObject.play_impact_sound(source_type,target)
