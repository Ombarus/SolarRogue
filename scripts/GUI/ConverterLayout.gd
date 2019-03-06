extends "res://scripts/GUI/GUILayoutBase.gd"

var _callback_obj = null
var _callback_method = ""
var _obj = null

onready var _craft_list = get_node("base/HBoxContainer/CraftingList")
onready var _requirement_list = get_node("base/HBoxContainer/VBoxContainer/Requirements")
onready var _need_list = get_node("base/HBoxContainer/VBoxContainer/HBoxContainer/Need")
onready var _using_list = get_node("base/HBoxContainer/VBoxContainer/HBoxContainer/Using")
onready var _craft_result_info = get_node("base/HBoxContainer/VBoxContainer/CraftResultInfo")
onready var _craft_button = get_node("base/HBoxContainer/VBoxContainer/Craft")

var _converter_data = null
var _current_crafting_selected = null

var _orig_data = null
var _dst_data = null

var _current_how_many = 0

func _ready():
	get_node("base").connect("OnOkPressed", self, "Ok_Callback")
	get_node("base").connect("OnCancelPressed", self, "Cancel_Callback")
	
	_need_list.connect("OnDragDropCompleted", self, "OnDropCrafting_Callback")
	_using_list.connect("OnDragDropCompleted", self, "OnDropCrafting_Callback")
	_craft_button.connect("pressed", self, "CraftButtonPressed_Callback")
	
	#var obj = []
	#for i in range(5):
	#	var name = "A B C D E F G HIJKLMN OPQRST UVWXYZ SOMETHING SOMETHING Item #" + str(i)
	#	obj.push_back({"name_id":name, "count":3})
	
	#get_node("base/vbox/Cargo").content = obj
	#get_node("base/vbox/Mounts").content = obj
	
func CraftButtonPressed_Callback():
	if _callback_obj == null:
		return
		
	var input_list = []
	var using_content = _using_list.Content	
	var recipe_data = null
	for r in _converter_data.converter.recipes:
		if r.name == _current_crafting_selected:
			recipe_data = r
			break
	using_content.push_back("energy")
	_callback_obj.call(_callback_method, recipe_data, using_content)
	
	_on_CraftingList_item_selected(_craft_list.get_selected_items()[0])
	
	
func Ok_Callback():
	BehaviorEvents.emit_signal("OnPopGUI")
	
	_using_list.Content = []
	_need_list.Content = []
		
	
func Cancel_Callback():
	BehaviorEvents.emit_signal("OnPopGUI")

	_using_list.Content = []
	_need_list.Content = []
	
func Init(init_param):
	_obj = init_param["object"]
	_callback_obj = init_param["callback_object"]
	_callback_method = init_param["callback_method"]
	
	var converter_file = _obj.get_attrib("mounts.converter")[0]
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
		
		
	var cargo = _obj.get_attrib("cargo.content")
	var list_data = []
	var added_to_data = {}
	for r in recipe_data.requirements:
		if "type" in r and r.type == "energy":
			continue
		var has_item_to_use = false
		var cargo_index = 0
		for item in cargo:
			var data = Globals.LevelLoaderRef.LoadJSON(item.src)
			var add_item = false
			if recipe_data.produce == "energy" and "recyclable" in data:
				add_item = true
			if "type" in r and r.type == data.type:
				add_item = true
			if "src" in r and Globals.clean_path(r.src) == Globals.clean_path(item.src):
				add_item = true
			if add_item == true:
				has_item_to_use = true
				if not cargo_index in added_to_data:
					list_data.push_back({"src":item.src, "count":item.count})
					added_to_data[cargo_index] = true
			cargo_index += 1
		if has_item_to_use == false:
			if "type" in r:
				list_data.push_back({"color":"red", "type":r.type, "missing":true})
			else:
				list_data.push_back({"color":"red", "src":r.src, "count":r.amount, "missing":true})
	_need_list.Content = list_data
	_using_list.Content = []
	
	UpdateCraftButton()
	
	
func OnDropCrafting_Callback(orig_data, dst_data):
	_orig_data = orig_data
	_dst_data = dst_data
	if orig_data.count > 1:
		BehaviorEvents.emit_signal("OnPushGUI", "HowManyDiag", {
			"callback_object":self, 
			"callback_method":"HowManyDiag_Callback", 
			"min_value":1, 
			"max_value":orig_data.count})
	else:
		HowManyDiag_Callback(1)
		
		
func HowManyDiag_Callback(num):
	var content_orig = _orig_data.origin.Content
	var content_dst = _dst_data.origin.Content
	if num == _orig_data.count:
		content_orig.remove(_orig_data.index)
	else:
		_orig_data.count -= num
	var found = false
	for item in content_dst:
		if Globals.clean_path(item.src) == Globals.clean_path(_orig_data.src):
			var data = Globals.LevelLoaderRef.LoadJSON(item.src)
			if data.equipment.stackable == true:
				item.count += num
				found = true
				break
	if found == false:
		var new_data = _orig_data.duplicate()
		new_data.count = num
		content_dst.push_back(new_data)
	_orig_data.origin.Content = content_orig
	_dst_data.origin.Content = content_dst
	
	UpdateCraftButton()
	
func UpdateCraftButton():
	_current_crafting_selected = _craft_list.get_item_text(_craft_list.get_selected_items()[0])
	var recipe_data = null
	for r in _converter_data.converter.recipes:
		if r.name == _current_crafting_selected:
			recipe_data = r
			break
	
	# a bit hackish but the "recycle" recipe is special so better to do it in a separate function	
	if recipe_data.produce == "energy":
		special_recycle_update(recipe_data)
		return
			
	var requirement_count = {}
	var energy_cost = 0
	for r in recipe_data.requirements:
		if "type" in r:
			if r.type == "energy":
				energy_cost = r.amount
			else:
				requirement_count[r.type] = {"using":0, "need":r.amount}
		if "src" in r:
			requirement_count[r.src] = {"using":0, "need":r.amount}
			
	var using_content = _using_list.Content
	# Note, if you have a src AND a type requirement. If an item fits both this will not work... please don't do that !
	# Yeah... I'll probably do it one day, that's why I'm putting a comment here
	for item in using_content:
		var d = Globals.LevelLoaderRef.LoadJSON(item.src)
		for r in requirement_count:
			if d.type == r:
				requirement_count[r].using += item.count
			if "src" in item and Globals.clean_path(item.src) == Globals.clean_path(r):
				requirement_count[r].using += item.count
	
	_current_how_many = -1
	# Special case where were we only need energy so default to making just 1
	if requirement_count.size() == 0:
		_current_how_many = 1
	for r in requirement_count:
		var can_craft = int(requirement_count[r].using / requirement_count[r].need)
		if _current_how_many > can_craft or _current_how_many < 0:
			_current_how_many = can_craft
			
	var recipe_name = recipe_data.name
	var t_color = "[color=lime]"
	if _current_how_many == 0:
		t_color = "[color=red]"
	if _current_how_many > 0:
		energy_cost *= _current_how_many
	_current_how_many *= recipe_data.amount
	_craft_result_info.bbcode_text = t_color + str(_current_how_many) + " " + recipe_name + " for " + str(energy_cost) + " energy[/color]"
	#TODO: might be nice to have a "disabled" look for my custom buttons
	if _current_how_many > 0:
		_craft_button.visible = true
	else:
		_craft_button.visible = false

func special_recycle_update(recipe_data):
	var using_content = _using_list.Content
	var total_items = 0
	var total_energy = 0
	for item in using_content:
		var d = Globals.LevelLoaderRef.LoadJSON(item.src)
		total_items += item.count
		total_energy += (d.recyclable.energy * item.count)
		
	var color = "[color=lime]"
	if total_items <= 0:
		color = "[color=red]"
	_craft_result_info.bbcode_text = color + "Recycle " + str(total_items) + " items and gain " + str(total_energy) + " energy[/color]"
	
	if total_items > 0:
		_craft_button.visible = true
	else:
		_craft_button.visible = false
	
	