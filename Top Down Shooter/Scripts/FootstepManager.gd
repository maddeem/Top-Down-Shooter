class_name FootstepManager extends Node3D
@export var sounds : Array[String] = []
@export var play_random_sound := true
@export var pitch_range := 0.1
@export var distance := 30
@export var base_pitch := 1.0
var last_sound_position = 0
var sound_players : Array[AudioStreamPlayer3D] = []

func _ready():
	var i = 0
	$AudioStreamPlayer3D.max_distance = distance
	for sound_path in sounds:
		if i == 0:
			$AudioStreamPlayer3D.stream = load(sound_path)
			sound_players.append($AudioStreamPlayer3D)
		else:
			var new = $AudioStreamPlayer3D.duplicate()
			add_child(new)
			new.stream = load(sound_path)
			sound_players.append(new)
		i += 1
func play_step():
	var player : AudioStreamPlayer3D
	if play_random_sound:
		player = sound_players[randi_range(0,sound_players.size()-1)]
	else:
		player = sound_players[last_sound_position]
		last_sound_position += 1
		if last_sound_position >= sound_players.size():
			last_sound_position = 0
	player.pitch_scale = base_pitch + randf_range(-pitch_range,pitch_range)
	player.play()
