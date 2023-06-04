@tool
extends Node
@export var _cache = {}

func read_from(key : Variant) -> Variant:
	return _cache.get(key)

func write_to(key : Variant, value : Variant) -> void:
	_cache[key] = value

func exists(key : Variant) -> bool:
	return _cache.has(key)
