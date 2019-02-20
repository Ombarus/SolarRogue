extends "res://scripts/GUI/GUILayoutBase.gd"

var _callback_obj = null
var _callback_method = ""

onready var _craft_list = get_node("base/HBoxContainer/CraftingList")
onready var _requirement_list = get_node("base/HBoxContainer/VBoxContainer/Requirements")
var _converter_data = null
var _current_crafting_selected = null

func _ready():
	get_node("base").connect("OnOkPressed", self, "Ok_Callback")
	get_node("base").connect("OnCancelPressed", self, "Cancel_Callback")
	
	#var obj = []
	#for i in range(5):
	#	var name = "A B C D E F G HIJKLMN OPQRST UVWXYZ SOMETHING SOMETHING Item #" + str(i)
	#	obj.push_back({"name_id":name, "count":3})
	
	#get_node("base/vbox/Cargo").content = obj
	#get_node("base/vbox/Mounts").content = obj
	
func Ok_Callback():
	BehaviorEvents.emit_signal("OnPopGUI")
	if _callback_obj == null:
		return
			
	var input_list = []
	for data in get_node("base/HBoxContainer/VBoxContainer/Inventory").content:
		if data.checked == true:
			input_list.push_back(data.key)
	
	var recipe_data = null
	for r in _converter_data.converter.recipes:
		if r.name == _current_crafting_selected:
			recipe_data = r
			break
	_callback_obj.call(_callback_method, recipe_data, input_list)
	
	
func Cancel_Callback():
	BehaviorEvents.emit_signal("OnPopGUI")

	
func Init(init_param):
	var obj = init_param["object"]
	_callback_obj = init_param["callback_object"]
	_callback_method = init_param["callback_method"]
	
	var converter_file = obj.get_attrib("mounts.converter")[0]
	_converter_data = Globals.LevelLoaderRef.LoadJSON(converter_file)
	
	_craft_list.clear()
	for recipe_data in _converter_data.converter.recipes:
		var tex = null
		var region = null
		if "icon_texture" in recipe_data:
			tex = load("res://" + recipe_data.icon_texture)
			if "icon_region" in recipe_data:
				var region_data = recipe_data.icon_region
				region = Rect2(region_data[0], region_data[1], region_data[2], region_data[3])
		_craft_list.add_item(recipe_data.name, tex)
		if region != null:
			_craft_list.set_item_icon_region(_craft_list.get_item_count()-1, region)
		
		
	var cargo = obj.get_attrib("cargo.content")
	var cargo_obj = []
	for item in cargo:
		var data = Globals.LevelLoaderRef.LoadJSON(item.src)
		var counting = ""
		if item.count > 1:
			counting = str(item.count) + "x "
		cargo_obj.push_back({"name_id": counting + data.name_id, "count":item.count, "key":item})
	var cur_energy = obj.get_attrib("converter.stored_energy")
	cargo_obj.push_back({"name_id": str(cur_energy) + " Energy", "count":cur_energy, "key":"energy"})
	get_node("base/HBoxContainer/VBoxContainer/Inventory").content = cargo_obj
	

func _on_CraftingList_item_selected(index):
	_current_crafting_selected = _craft_list.get_item_text(index)
	var recipe_data = null
	for r in _converter_data.converter.recipes:
		if r.name == _current_crafting_selected:
			recipe_data = r
			break
		
	_requirement_list.clear()
	_requirement_list.add_item("Requirements...")
	for r in recipe_data.requirements:
		if "type" in r:
			_requirement_list.add_item("Type: " + r.type + ", amount : " + str(r.amount))
		if "src" in r:
			var d = Globals.LevelLoaderRef.LoadJSON(r.src)
			_requirement_list.add_item("Item: " + d.name_id + ", amount : " + str(r.amount))
	_requirement_list.add_item("-------------------------")
	_requirement_list.add_item("Produces :")
	if recipe_data.produce == "energy":
		_requirement_list.add_item(str(recipe_data.amount) + " Energy")
	else:
		var produce_data = Globals.LevelLoaderRef.LoadJSON(recipe_data.produce)
		var line_str = ""
		if recipe_data.amount == 1:
			line_str += "a "
		else:
			line_str += str(recipe_data.amount) + " "
		line_str += produce_data.name_id
		_requirement_list.add_item(line_str)
	
	
