class_name Invisibility extends Area3D
const INVISIBLE := 1
const BURROWED := 2
const VENTS := 4
const TOTAL_BITS = [INVISIBLE,BURROWED]
@export_flags("Invisible","Burrowed","Vents") var detection : int:
	set(value):
		detection = value
		for which in _inside:
			check_detected(which)
@export var player_owner : int
var _inside = []
static var detect_action = {}
static var undetect_action = {}
static var gain_action = {}
static var remove_action = {}
var _player_owner : Player
var _initialized = false

func _owner_changed():
	var p = get_parent()
	player_owner = p.player_owner
	_player_owner = p._player_owner

func _ready():
	await PlayerLib.initialized
	_initialized = true
	var p = get_parent()
	if p is Widget:
		_owner_changed()
		p.connect("owner_changed",_owner_changed)
	elif PlayerLib.PlayerByIndex.has(player_owner):
		_player_owner = PlayerLib.PlayerByIndex[player_owner]
	detection = detection

static func _static_init():
	detect_action[INVISIBLE] = func(detected : Widget):
		detected.set_override_mat(Preload.MATERIAL_INVISIBLE_RELVEAD)
		detected.set_overlay_mat(null)
	undetect_action[INVISIBLE] = func(detected : Widget):
		detected.set_override_mat(Preload.MATERIAL_INVISIBLE)
		detected.set_overlay_mat(null)
	gain_action[INVISIBLE] = undetect_action[INVISIBLE]
	remove_action[INVISIBLE] = func(detected : Widget):
		detected.set_override_mat(null)
		detected.set_overlay_mat(null)

func _inc_widget_detection_amount(which : Widget, amount : int):
	if not which.detected.has(player_owner):
		which.detected[player_owner] = 0
	which.detected[player_owner] += amount

var detection_state = {}
func check_detected(which : Widget):
	if not _initialized:
		return
	var detect = detection & which.invisible_status == which.invisible_status
	var state = _inside.has(which) and detect
	if state:
		if not detection_state.has(which):
			detection_state[which] = true
			_inc_widget_detection_amount(which,1)
	else:
		if detection_state.has(which):
			detection_state.erase(which)
			_inc_widget_detection_amount(which,-1)
	var which_dict : Dictionary
	if which.detected[player_owner] > 0 and Globals.LocalPlayer.is_player_visible(_player_owner) or Globals.LocalPlayer.is_player_visible(which._player_owner):
		which_dict = detect_action
	else:
		which_dict = undetect_action
	for bit in TOTAL_BITS:
		if which.invisible_status & bit == bit:
			which_dict[bit].call(which)
	which.locally_invisible = which.invisible_to_player(Globals.LocalPlayer)

func _on_body_entered(body):
	_inside.append(body)
	check_detected(body)
	body.connect("invsibility_changed",check_detected)


func _on_body_exited(body):
	_inside.erase(body)
	check_detected(body)
	detection_state.erase(body)
	body.disconnect("invsibility_changed",check_detected)

static func gain(which : int, source: Widget):
	if source._player_owner.is_player_visible(Globals.LocalPlayer):
		detect_action[which].call(source)
	else:
		gain_action[which].call(source)

static func lose(which : int, source: Widget):
	remove_action[which].call(source)

