@tool
extends Node3D
class_name Cliff
@export var Cliff_Size = Vector2i(256,256):
	set(value):
		Cliff_Size = value
		_create_chunks()
@export var Chunk_Size := 32:
	set(value):
		Chunk_Size = value
		_create_chunks()
var chunks = {}
var multimesh = preload("res://addons/CliffEditor/multimesh.tscn")

func _get_new_multimesh(inst_count : int, pos : Vector3) -> MultiMeshInstance3D:
	var new : MultiMeshInstance3D = multimesh.instantiate()
	var mesh : MultiMesh = new.multimesh
	add_child(new)
	new.position = pos
	mesh.instance_count = inst_count
	mesh.visible_instance_count = inst_count
	return new

func _create_chunks():
	for chunk in chunks:
		chunks[chunk].queue_free()
	chunks = {}
	var chunk_map = Cliff_Size / Chunk_Size
	var inst_count = chunk_map.x * chunk_map.y
	for x in chunk_map.x:
		for y in chunk_map.y:
			var pos = Vector2i(x,y) * Chunk_Size - (Cliff_Size / 2) + Vector2i(Chunk_Size,Chunk_Size) / 2
			chunks[pos] = _get_new_multimesh(inst_count,Vector3(pos.x,0,pos.y))


func _ready():
	_create_chunks()


