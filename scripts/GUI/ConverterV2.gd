extends "res://scripts/GUI/GUILayoutBase.gd"

var _callback_obj = null
var _callback_method = ""
var _obj = null

onready var _recipe_list : MyItemList = get_node("HBoxContainer/Recipes/MyItemList")
onready var _material_list : MyItemList = get_node("HBoxContainer/Materials/MyItemList")
onready var _craft_button : ButtonBase = get_node("HBoxContainer/Control/VBoxContainer/Craft")

onready var _recipe_icon : TextureRect = get_node("HBoxContainer/Control/VBoxContainer/IconContainer/Icon")
onready var _recipe_name : RichTextLabel = get_node("HBoxContainer/Control/VBoxContainer/RecipeInfoContainer/RecipeName")
onready var _energy_cost : RichTextLabel = get_node("HBoxContainer/Control/VBoxContainer/RecipeInfoContainer/HBoxContainer2/EnergyCost")
onready var _turn_cost : RichTextLabel = get_node("HBoxContainer/Control/VBoxContainer/RecipeInfoContainer/HBoxContainer3/TurnCost")
onready var _energy_ship : RichTextLabel = get_node("HBoxContainer/Control/VBoxContainer/ShipInfoContainer/HBoxContainer4/EnergyShip")
onready var _hull_ship : RichTextLabel = get_node("HBoxContainer/Control/VBoxContainer/ShipInfoContainer/HBoxContainer5/HullShip")
onready var _shield_ship : RichTextLabel = get_node("HBoxContainer/Control/VBoxContainer/ShipInfoContainer/HBoxContainer6/ShieldShip")

var _converter_data = null
var _current_crafting_selected = null

var _orig_data = null
var _dst_data = null

var _current_data = {"count":0, "ap":0, "energy":0}

func _ready():
	get_node("HBoxContainer/Control/VBoxContainer/Close").connect("pressed", self, "Close_Callback")
	_craft_button.connect("pressed", self, "CraftButtonPressed_Callback")
	_material_list.connect("OnSelectionChanged", self, "OnMaterialChanged_Callback")
	_recipe_list.connect("OnSelectionChanged", self, "OnRecipeChanged_Callback")
	
	BehaviorEvents.connect("OnDamageTaken", self, "UpdateShipInfo")
	BehaviorEvents.connect("OnEnergyChanged", self, "UpdateShipInfo")
	
	
	############ TEST ###########
	#get_node("HBoxContainer/Materials/MyItemList").Content = [{"max":2, "name_id":"Missing Missile", "disabled":true}, {"max":4, "name_id":"Missile"}, {"max":1, "name_id":"Hydrogen"},{"max":8, "name_id":"Oxygen"}]
	#get_node("HBoxContainer/Recipes/MyItemList").Content = [{"name_id":"Missile", "icon": { "texture":"data/textures/space-sprite.png", "region":[256,128,128,128] }}]


func CraftButtonPressed_Callback():
	if _callback_obj == null:
		return
		
	var input_list = []
	var using_content = _material_list.Content	
	using_content.push_back("energy")
	_callback_obj.call(_callback_method, _current_crafting_selected, using_content)
	
	var last_selected :int = _current_crafting_selected.index
	#TODO: stay on the same recipe after re-init
	ReInit()
	_recipe_list.select(last_selected)


func Close_Callback():
	BehaviorEvents.emit_signal("OnPopGUI")
	
	_recipe_list.Content = []
	_material_list.Content = []


func OnFocusGained():
	get_node("HBoxContainer/Control/VBoxContainer/Close").Disabled = false
	UpdateCraftButton()
	
func OnFocusLost():
	get_node("HBoxContainer/Control/VBoxContainer/Close").Disabled = true
	_craft_button.Disabled = true


func Init(init_param):
	_obj = init_param["object"]
	_callback_obj = init_param["callback_object"]
	_callback_method = init_param["callback_method"]
	
	var converter_file = _obj.get_attrib("mounts.converter")[0]
	_converter_data = Globals.LevelLoaderRef.LoadJSON(converter_file)
	
	ReInit()
	
func ReInit():
	
	_current_data = {"count":0, "ap":0, "energy":0}
	_current_crafting_selected = null
	
	var recipe_content = []
	for recipe_data in _converter_data.converter.recipes:
		var d = str2var(var2str(recipe_data)) # make a copy because we're changing stuff
		if not "icon" in d and ".json" in recipe_data.produce:
			var produce_data = Globals.LevelLoaderRef.LoadJSON(recipe_data.produce)
			if "icon" in produce_data:
				d["icon"] = produce_data.icon
		recipe_content.push_back(d)

	_recipe_list.Content = recipe_content
	_material_list.Content = []
	
	_recipe_icon.visible = false
	get_node("HBoxContainer/Control/VBoxContainer/RecipeInfoContainer").visible = false
	UpdateShipInfo()
	UpdateCraftButton()
	
	
func OnRecipeChanged_Callback():
	_current_crafting_selected = null
	for item in _recipe_list.Content:
		if item.selected == true:
			_current_crafting_selected = item
			break
	
	if _current_crafting_selected == null:
		ReInit()
		return
	
	if "texture_cache" in _current_crafting_selected:
		_recipe_icon.visible = true
		_recipe_icon.texture = _current_crafting_selected.texture_cache
	
	get_node("HBoxContainer/Control/VBoxContainer/RecipeInfoContainer").visible = true
	_current_data["count"] = 0
	_current_data["energy"] = 0
	_current_data["ap"] = 0
	
	UpdateMaterialsList(_current_crafting_selected)
	OnMaterialChanged_Callback()
	UpdateCraftButton()
	
func UpdateMaterialsList(recipe_data):
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
					var d = Globals.LevelLoaderRef.LoadJSON(item.src)
					list_data.push_back({"name_id":d.name_id, "max":item.count, "src":item.src})
					added_to_data[cargo_index] = true
			cargo_index += 1
		if has_item_to_use == false:
			if "type" in r:
				list_data.push_back({"name_id":"Missing " + r.type, "disabled":true, "max":r.amount})
			else:
				var d = Globals.LevelLoaderRef.LoadJSON(r.src)
				list_data.push_back({"name_id":"Missing " + d.name_id, "max":r.amount, "disabled":true})
	_material_list.Content = list_data
	
	
func UpdateCraftInfo():
	if _current_crafting_selected == null:
		get_node("HBoxContainer/Control/VBoxContainer/RecipeInfoContainer").visible = false
		return
	else:
		get_node("HBoxContainer/Control/VBoxContainer/RecipeInfoContainer").visible = true
		
	####### RECIPE NAME #######
	var recipe_color_str : String = "lime"
	var recipe_name_str : String = ""
	if _current_data["count"] == 0:
		#recipe_name_str = "Cannot Craft " + _current_crafting_selected.name
		recipe_color_str = "red"
	recipe_name_str = "Craft " + str(_current_data["count"]) + " " + _current_crafting_selected.name
	if _current_crafting_selected.produce == "energy":
		recipe_name_str = "Recycle " + str(_current_data["count"]) + " Item(s)"
		
	_recipe_name.bbcode_text = "[color=%s]%s[/color]" % [recipe_color_str, recipe_name_str]
	
	####### Energy Label #######
	var energy_label_str : String = "Energy Cost...."
	if _current_crafting_selected.produce == "energy":
		energy_label_str = "Energy Gain...."
	get_node("HBoxContainer/Control/VBoxContainer/RecipeInfoContainer/HBoxContainer2/EnergyLabel").bbcode_text = energy_label_str
	
	####### Energy Cost #######
	var energy_color = "red"
	if _current_crafting_selected.produce == "energy" and _current_data["count"] > 0:
		energy_color = "lime"
	_energy_cost.bbcode_text = "[color=%s]%d[/color]" % [energy_color, _current_data["energy"]]
	
	####### Turn Cost #######
	_turn_cost.bbcode_text = "[color=%s]%.1f[/color]" % ["red", _current_data["ap"]]
	
	####### In Cargo Count #######
	var in_cargo : int = 0
	if ".json" in _current_crafting_selected.produce:
		var cargo = _obj.get_attrib("cargo.content")
		for item in cargo:
			if Globals.clean_path(item.src) == Globals.clean_path(_current_crafting_selected.produce):
				in_cargo = item.count
				
	var n : Container = get_node("HBoxContainer/Control/VBoxContainer/RecipeInfoContainer/InCargoContainer")
	if in_cargo <= 0:
		n.visible = false
	else:
		n.visible = true
		n.get_node("InCargo").bbcode_text = str(in_cargo)
		
	
	UpdateCraftButton()
	

#TODO: This is a big copy-pasta from StatusBar. Probably should find a way to avoid these duplicated between systems
func UpdateShipInfo():
	var ship_name : String = "The Maveric's Status"
	var ship_color : String = "lime"
	var p_name : String = _obj.get_attrib("player_name")
	if p_name != null:
		ship_name = "The " + p_name + "'s Status"
		
	var cur_hull = _obj.get_attrib("destroyable.hull")
	var max_hull = _obj.base_attributes.destroyable.hull
	var hull_color = "lime"
	if cur_hull < max_hull / 2.0:
		hull_color = "yellow"
		if ship_color != "red":
			ship_color = "yellow"
	if cur_hull < max_hull / 4.0:
		hull_color="red"
		ship_color = "red"
	var cur_energy = _obj.get_attrib("converter.stored_energy")
	var energy_color = "lime"
	if cur_energy < 5001:
		energy_color = "yellow"
		if ship_color != "red":
			ship_color = "yellow"
	if cur_energy < 1001:
		energy_color = "red"
		ship_color = "red"
		
	#var bottom_title_str = ship_name
	var hull_str : String = "[color=" + hull_color + "]"
	#"gray"
	var health_per = cur_hull / max_hull
	var changed_color = false
	for i in range(10):
		var bar_per = float(i) / float(10)
		if bar_per >= health_per and not changed_color:
			hull_str += "[/color][color=gray]"
			changed_color = true
		hull_str += "="
	var energy_str : String = "[color=%s]%.f[/color]" % [energy_color, cur_energy]
	
	var shields = _obj.get_attrib("mounts.shield")
	var missing_shield = true
	if shields != null:
		for shield in shields:
			if not shield.empty():
				missing_shield = false
				break
	var cur_shield = _obj.get_attrib("shield.current_hp")
	var shield_str : String = ""
	if missing_shield:
		shield_str += "[color=yellow]Missing[/color]"
		if ship_color != "red":
			ship_color = "yellow"
	elif cur_shield != null and cur_shield < 1:
		shield_str += "[color=red]Down![/color]"
		ship_color = "red"
	else:
		var max_shield = _obj.get_max_shield()
		shield_str += "[color=aqua]"
		var shield_per = floor(cur_shield) / max_shield
		changed_color = false
		for i in range(10):
			var bar_per = float(i) / float(10)
			if bar_per >= shield_per and not changed_color:
				shield_str += "[/color][color=gray]"
				changed_color = true
			shield_str += "="
		shield_str += "[/color]"
		
	get_node("HBoxContainer/Control/VBoxContainer/ShipInfoContainer/ShipTitle").bbcode_text = "[color=%s]%s[/color]" % [ship_color, ship_name]
	_energy_ship.bbcode_text = energy_str
	_shield_ship.bbcode_text = shield_str
	_hull_ship.bbcode_text = hull_str
	
func OnMaterialChanged_Callback():
	if _current_crafting_selected == null:
		ReInit()
		return
		
	if _current_crafting_selected.produce == "energy":
		special_recycle_update(_current_crafting_selected)
		return
		
	var requirement_count = {}
	var energy_cost = 0
	for r in _current_crafting_selected.requirements:
		if "type" in r:
			if r.type == "energy":
				energy_cost = r.amount
			else:
				requirement_count[r.type] = {"using":0, "need":r.amount}
		if "src" in r:
			requirement_count[r.src] = {"using":0, "need":r.amount}
			
	var using_content = _material_list.Content
	# Note, if you have a src AND a type requirement. If an item fits both this will not work... please don't do that !
	# Yeah... I'll probably do it one day, that's why I'm putting a comment here
	for item in using_content:
		if not "src" in item:
			continue
		var d = Globals.LevelLoaderRef.LoadJSON(item.src)
		for r in requirement_count:
			if d.type == r:
				requirement_count[r].using += item.selected
			if "src" in item and Globals.clean_path(item.src) == Globals.clean_path(r):
				requirement_count[r].using += item.selected
	
	_current_data["count"] = -1
	# Special case where were we only need energy so default to making just 1
	if requirement_count.size() == 0:
		_current_data["count"] = 1
	for r in requirement_count:
		var can_craft = int(requirement_count[r].using / requirement_count[r].need)
		if _current_data["count"] > can_craft or _current_data["count"] < 0:
			_current_data["count"] = can_craft
	if _current_data["count"] > 0:
		energy_cost *= _current_data["count"]
		
	_current_data["ap"] = _current_data["count"] * _current_crafting_selected.ap_cost
	_current_data["energy"] = (energy_cost*_current_data["count"]) + _get_idle_turn_energy_cost(_current_data["ap"])
	_current_data["count"] *= _current_crafting_selected.amount
	
	UpdateCraftInfo()

func special_recycle_update(recipe_data):
	var using_content = _material_list.Content
	var total_items = 0
	var total_energy = 0
	for item in using_content:
		if "disabled" in item and item.disabled == true:
			continue
		var d = Globals.LevelLoaderRef.LoadJSON(item.src)
		total_items += item.selected
		total_energy += (d.recyclable.energy * item.selected)

	_current_data["count"] = total_items
	_current_data["ap"] = total_items * recipe_data.ap_cost
	_current_data["energy"] = total_energy - _get_idle_turn_energy_cost(_current_data["ap"])
		
	UpdateCraftInfo()

	
func _get_idle_turn_energy_cost(num_turn):
	var base_ap_energy_cost = _obj.get_attrib("converter.base_ap_energy_cost")
	if base_ap_energy_cost != null and base_ap_energy_cost > 0:
		return base_ap_energy_cost*num_turn
	else:
		return 0

func UpdateCraftButton():
	if _current_data["count"] > 0:
		_craft_button.Disabled = false
	else:
		_craft_button.Disabled = true
	