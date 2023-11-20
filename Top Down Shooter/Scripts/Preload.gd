extends Node
var WeaponTypes = {
	"GaussRifle" = preload("res://Editables/Weapons/GaussRifle.tscn")
}
var Units = {
	"Marine" = load("res://Scenes/Widgets/PlayerUnit.tscn")
}
@export var materials: Array[Material]


func _ready():
	_load_materials()
	

func _load_materials():
	var sprites = []
	for material in materials:
		var sprite = Sprite2D.new()
		sprite.texture = PlaceholderTexture2D.new()
		sprite.material = material
		add_child(sprite)
		sprites.append(sprite)
	
		# Remove the sprites after being rendered
	await get_tree().create_timer(0.2).timeout
	for sprite in sprites:
		sprite.queue_free()
