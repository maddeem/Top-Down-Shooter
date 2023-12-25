extends Control
var interact_queue = []
var error_display_time := 0.0
var error_text : String:
	set(value):
		error_text = value
		$Label.text = value
		$AudioStreamPlayer.play()
		error_display_time = value.length() * 0.15

func _physics_process(delta):
	error_display_time = max(0.0,error_display_time - delta)
	$Label.visible = error_display_time != 0.0

func check_interact_queue():
	if interact_queue.size() > 0:
		var hotkey = InputMap.action_get_events("Interact")[0].as_text().replace(" (Physical)","")
		$Interact.visible = true
		var first = interact_queue.front()
		if first is Item:
			$Interact.text = "["+hotkey+"] to pickup: " + first.object_name
	else:
		$Interact.visible = false

func add_interact_object(which : Node):
	interact_queue.append(which)
	check_interact_queue()

func remove_interact_object(which : Node):
	interact_queue.erase(which)
	check_interact_queue()
