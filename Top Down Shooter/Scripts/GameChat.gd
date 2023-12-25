extends Control
const MESSAGE_SCENE = preload("res://Scenes/default_chat_message.tscn") 

func _ready():
	GlobalUI.chat = self

func time_to_string() -> String:
	var minutes = floor(Globals.TimeElapsed/60)
	return str(minutes).pad_zeros(2) +":"+str(floor(Globals.TimeElapsed-minutes*60)).pad_zeros(2)

@rpc("authority","reliable","call_local",2)
func _recieve_chat(sender: int, msg : String):
	var p : Player = PlayerLib.PlayerById[sender]
	var txt = ""
	var display = true
	var sound = ""
	if p.dead:
		if not Globals.LocalPlayer.dead:
			display = false
		txt = "[DEAD] [color="+Colors.player_colors[p.index].to_html()+"]"+p.name+"[/color]: "+msg
	else:
		sound = "ChatChirp"
		txt = time_to_string()+" [color="+Colors.player_colors[p.index].to_html()+"]"+p.name+"[/color]: "+msg
	if display:
		display_message(txt,sound)

func display_message(msg : String, snd : String = ""):
	var new : RichTextLabel = MESSAGE_SCENE.instantiate()
	new.text = msg
	$Container/VBoxContainer.add_child(new)
	if snd != "":
		var nd = find_child(snd)
		if is_instance_valid(nd) and nd is AudioStreamPlayer:
			nd.play()

@rpc("any_peer","reliable","call_local",2)
func _get_chat(msg : String):
	_recieve_chat.rpc(multiplayer.get_remote_sender_id(),msg.strip_escapes())

func _unhandled_input(_event):
	if Input.is_action_just_pressed("Open_Chat") :
		get_viewport().set_input_as_handled()
		$ChatWindow.visible = not $ChatWindow.visible
		if $ChatWindow.visible:
			$ChatWindow/LineEdit.grab_focus()
	if Input.is_action_just_pressed("Open_Menu") and $ChatWindow.visible:
		get_viewport().set_input_as_handled()
		$ChatWindow/LineEdit.text = ""
		$ChatWindow.visible = false

func _on_line_edit_text_submitted(new_text):
	$ChatWindow.visible = false
	$ChatWindow/LineEdit.text = ""
	_get_chat.rpc_id(1,new_text.strip_escapes())

func _on_line_edit_gui_input(event):
	if event is InputEventKey and not event.is_pressed():
		get_viewport().set_input_as_handled()
