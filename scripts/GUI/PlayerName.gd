extends "res://scripts/GUI/GUILayoutBase.gd"

var _callback_obj : Node = null
var _callback_method : String = ""
var _random_index : int = 0

onready var _selector = get_node("base/Selector")

var random_names : Array = [
	"Voyager", "Endeavour", "Atlantis", "Sputnik", "Falcon", "Challenger", "Curosity", 
	"Jules Verne", "Pioneer 11", "Shenzhou", "Hayabusa", "Pathfinder", "Rosetta", 
	"Chernobyl", "Bebop", "Excelsior", "Icarus I", "Icarus II", "Serenity", "Yamato", 
	"Amaterasu", "Ark", "Battlestar", "Hyperion", "Liberator", "Normandy SR-X", "Prometheus",
	"Red Dwarf", "SDF-1", "NCC-1701-j"]

func _ready():
	get_node("base").connect("OnOkPressed", self, "Ok_Callback")
	get_node("base").connect("OnCancelPressed", self, "Cancel_Callback")

func Ok_Callback():
	BehaviorEvents.emit_signal("OnPopGUI")
	get_node("base").disabled = true
	
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
	
func _on_Randomize_pressed():
	var name : String = random_names[_random_index]
	_random_index += 1
	_random_index = _random_index % random_names.size()
	_selector.text = name
