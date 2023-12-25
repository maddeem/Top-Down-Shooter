class_name Player extends Node
var id := 0
var bit_id := 0
var index := 0
var dead := false
var _player_visibility := 0:
	set(value):
		_player_visibility = value
		if multiplayer.get_unique_id() == id:
			Globals.LocalVisionBit = _player_visibility
			RenderingServer.global_shader_parameter_set("FogPlayerBit", value)
var _player_alliance := 0
var controller := PlayerLib.COMPUTER
var main_unit : PlayerUnit

func _ready():
	set_player_visible(self,true)
	set_player_ally(self,true)

func set_player_visible(p : Player, state : bool) -> void:
	if state:
		_player_visibility |= p.bit_id
	else:
		_player_visibility &= ~p.bit_id

func set_player_ally(p: Player, state : bool) -> void:
	if state:
		_player_alliance |= p.bit_id
	else:
		_player_alliance &= ~p.bit_id

func is_player_visible(p : Player) -> bool:
	return _player_visibility & p.bit_id == p.bit_id

func is_player_ally(p : Player) -> bool:
	return p != null and _player_alliance & p.bit_id == p.bit_id

func set_alliance_both(p : Player, ally : bool, vis_state : bool) -> void:
	set_player_visible(p,vis_state)
	set_player_ally(p,ally)
	p.set_player_visible(self,vis_state)
	p.set_player_ally(self,ally)
