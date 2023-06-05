@tool
extends Node
@export var _cache = {}

func read_from(dir : Variant, key : Variant) -> Variant:
	return _cache.get(dir.get(key))

func write_to(dir : Variant, key : Variant, value : Variant) -> void:
	if _cache.has(dir):
		_cache[dir][key] = value
	else:
		_cache[dir] = {key : value}

func exists(dir : Variant, key : Variant) -> bool:
	if _cache.has(dir):
		return _cache.has(key)
	return false
