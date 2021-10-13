extends "res://scripts/GUI/GUILayoutBase.gd"

var _callback_obj : Node = null
var _callback_method : String = ""
var _random_index : int = 0
var _cur_offset : int = 0

onready var _selector = get_node("base/Control/Selector")

var random_names : Array = [
	"Voyager", "Endeavour", "Atlantis", "Sputnik", "Falcon", "Challenger", "Curosity", 
	"Jules Verne", "Pioneer 11", "Shenzhou", "Hayabusa", "Pathfinder", "Rosetta", 
	"Chernobyl", "Bebop", "Excelsior", "Icarus I", "Icarus II", "Serenity", "Yamato", 
	"Amaterasu", "Ark", "Battlestar", "Hyperion", "Liberator", "Normandy SR-X", "Prometheus",
	"Red Dwarf", "SDF-1", "NCC-1701-j", "Orion III", "Daedalus", "Explorer", "SSTO-TAV-37B",
	"Intrepid", "Odyssey", "Pleiades", "X-71", "Armageddon", "Aries Ib", "F-302", "Mars I",
	"Nightflyer", "Orbit Jet", "USSC Discovery", "USS Cygnus", "Thunderbirds", "Amaterasu",
	"Basroil", "C-57D", "Conquistador", "Derelict", "Event Horizon", "Jupiter 2", "Nautilus",
	"Nemesis", "Star Destroyer", "Sleeper Service", "Death glider", "Destiny", "TARDIS"]

func _ready():
	get_node("base").connect("OnOkPressed", self, "Ok_Callback")
	get_node("base").connect("OnCancelPressed", self, "Cancel_Callback")
	
	var diff_options : OptionButton = get_node("base/Control/Difficulty")
	diff_options.add_item("Normal", 0)
	diff_options.add_item("Hard", 1)
	diff_options.add_item("Harder", 2)
	diff_options.add_item("Hardest", 3)
	diff_options.add_item("Not Happening...", 4)

func Ok_Callback():
	if OS.get_virtual_keyboard_height() > 0 or _selector.text == "":
		OS.hide_virtual_keyboard()
		return
		
	BehaviorEvents.emit_signal("OnPopGUI")
	get_node("base").disabled = true
	var diff_options : OptionButton = get_node("base/Control/Difficulty")
	var selected_diff = diff_options.get_selected_id()
	PermSave.set_attrib("settings.difficulty", selected_diff)
	
	if _callback_obj == null:
		return
		
	var val = _selector.text
	_callback_obj.call(_callback_method, val)
	
func Cancel_Callback():
	BehaviorEvents.emit_signal("OnPopGUI")
	get_node("base").disabled = true
	
func Init(init_param):
	get_node("base").disabled = false
	_callback_obj = init_param["callback_object"]
	_callback_method = init_param["callback_method"]
	
	random_names.shuffle()
	_random_index = 0
	
	var def_name = PermSave.get_attrib("settings.default_name")
	if def_name == null:
		def_name = random_names[0]
		_random_index += 1
		
	_selector.text = def_name
	
	var diff_options : OptionButton = get_node("base/Control/Difficulty")
	var default_diff : int = PermSave.get_attrib("settings.difficulty")
	diff_options.select(default_diff)

	
func _on_Randomize_pressed():
	var name : String = random_names[_random_index]
	_random_index += 1
	_random_index = _random_index % random_names.size()
	_selector.text = name
	
func _process(delta):
	var cur_height := OS.get_virtual_keyboard_height()
	if cur_height > 0 and _cur_offset == 0:
		_cur_offset = get_node("base").rect_position.y
		get_node("base").rect_position.y = 0
	elif cur_height <= 0 and _cur_offset != 0:
		get_node("base").rect_position.y = _cur_offset
		_cur_offset = 0
		
