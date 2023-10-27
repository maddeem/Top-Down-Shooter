class_name Weapon extends Node3D
@export_enum("hand right", "hand left") var Attachment : String
@export_enum("walk weapon") var Walk_Animation : String
@export_enum("stand weapon") var Stand_Animation : String
static var Types = {
	"GaussRifle" = preload("res://Editables/Weapons/GaussRifle.tscn")
}

static func create(type : PackedScene) -> Weapon:
	return type.instantiate()

