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
@export var Cliff_Scale := 4.0
@export var cliff_data = {}
@export var chunks = {}
var multimesh = preload("res://addons/CliffEditor/multimesh.tres")
var mesh = preload("res://addons/CliffEditor/CliffModel.obj")
var _offset

func _get_new_multimesh(inst_count : Vector2i, pos : Vector3) -> MultiMeshInstance3D:
	var total = (inst_count.x * inst_count.y)
	var new := MultiMeshInstance3D.new()
	var multi := MultiMesh.new()
	new.multimesh = multi
	multi.transform_format = MultiMesh.TRANSFORM_3D
	multi.mesh = mesh
	add_child(new)
	new.position = pos
	multi.instance_count = total
	multi.visible_instance_count = total
	for x in inst_count.x:
		for y in inst_count.y:
			var inst = x + y * inst_count.y
			var b = Basis(Vector3(0.5,0,0),Vector3(0,1,0),Vector3(0,0,0.5)) * Cliff_Scale
			var t : Transform3D = Transform3D(b,pos + Vector3(x,0,y) * Cliff_Scale * 2)
			multi.set_instance_transform(inst,t)
			
	return new

func create_cliff(pos):
	var chunk_pos = floor(pos/2/Chunk_Size) * Chunk_Size
	chunk_pos = Vector2i(chunk_pos.x,chunk_pos.z) + _offset
	print(chunk_pos)

	if chunks.has(chunk_pos):
		chunks[chunk_pos].position.y += 10
		await get_tree().create_timer(1).timeout
		chunks[chunk_pos].position.y -= 10

func _create_chunks():
	for chunk in chunks:
		chunks[chunk].queue_free()
	chunks = {}
	var chunk_map : Vector2i = Cliff_Size / Chunk_Size
	var chunk = Vector2i(Chunk_Size,Chunk_Size) / Cliff_Scale
	_offset = (Cliff_Size - Vector2i(Cliff_Scale,Cliff_Scale))/2
	for x in chunk_map.x:
		for y in chunk_map.y:
			var pos = Vector2i(x,y) * Chunk_Size - _offset
			print(pos)
			chunks[pos] = _get_new_multimesh(chunk,Vector3(pos.x,0,pos.y))
	_offset = Vector2i(Cliff_Scale,Cliff_Scale)/2


func _ready():
	_create_chunks()


