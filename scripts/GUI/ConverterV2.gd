extends "res://scripts/GUI/GUILayoutBase.gd"

export(NodePath) var CraftingBehavior : NodePath

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
onready var _desc_btn : BaseButton = get_node("HBoxContainer/Control/VBoxContainer/IconContainer/DescBtn")

onready var _behavior = get_node(CraftingBehavior)

var _converter_data = null
var _current_crafting_selected = null

var _orig_data = null
var _dst_data = null

var _current_data = {"count":0, "ap":0, "energy":0}

func _ready():
	get_node("HBoxContainer/Control/VBoxContainer/Close").connect("pressed", self, "Close_Callback")
	_desc_btn.connect("pressed", self, "DescBtn_Callback")
	_craft_button.connect("pressed", self, "CraftButtonPressed_Callback")
	_material_list.connect("OnSelectionChanged", self, "OnMaterialChanged_Callback")
	_recipe_list.connect("OnSelectionChanged", self, "OnRecipeChanged_Callback")
	
	BehaviorEvents.connect("OnDamageTaken", self, "OnDamageTaken_Callback")
	BehaviorEvents.connect("OnEnergyChanged", self, "OnEnergyChanged")
	
	
func DescBtn_Callback():
	var scanner_level := 0
	var scanner_data = Globals.LevelLoaderRef.LoadJSONArray(_obj.get_attrib("mounts.scanner"))
	if scanner_data != null and scanner_data.size() > 0:
		scanner_level = Globals.get_data(scanner_data[0], "scanning.level")
		
	var produce_data = Globals.LevelLoaderRef.LoadJSON(_current_crafting_selected.produce)
	# TODO: Handle effects in converter
	BehaviorEvents.emit_signal("OnPushGUI", "Description", {"json":produce_data, "owner":_obj, "modified_attributes": {}, "scanner_level":scanner_level})
	
	
func OnDamageTaken_Callback(target, shooter, damage_type):
	if _obj != null:
		UpdateShipInfo()
	
func OnEnergyChanged(obj):
	if _obj != null:
		UpdateShipInfo()

func CraftButtonPressed_Callback():
	if _callback_obj == null:
		return
		
	var using_content = _material_list.Content	
	using_content.push_back("energy")
	_callback_obj.call(_callback_method, _current_crafting_selected, using_content)
	
	var last_selected :int = _current_crafting_selected.index
	
	ReInit()
	# ReInit now add child on the next frame for layout reason. So give it
	# a chance to populate before we re-select the previous recipe
	_recipe_list.call_deferred("select", last_selected)


func Close_Callback():
	BehaviorEvents.emit_signal("OnPopGUI")
	get_node("HBoxContainer/Control/VBoxContainer/Close").Disabled = true
	
	_recipe_list.Content = []
	_material_list.Content = []
	_obj = null


func OnFocusGained():
	get_node("HBoxContainer/Control/VBoxContainer/Close").Disabled = false
	UpdateCraftButton()
	
func OnFocusLost():
	get_node("HBoxContainer/Control/VBoxContainer/Close").Disabled = true
	_craft_button.Disabled = true


func Init(init_param):
	get_node("HBoxContainer/Control/VBoxContainer/Close").Disabled = false
	_obj = init_param["object"]
	_callback_obj = init_param["callback_object"]
	_callback_method = init_param["callback_method"]
	
	var converter_file = _obj.get_attrib("mounts.converter")[0]
	_converter_data = Globals.LevelLoaderRef.LoadJSON(converter_file)
	
	get_node("HBoxContainer/Recipes").title = _converter_data.name_id
	
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
				if typeof(produce_data.icon) == TYPE_ARRAY:
					d["icon"] = produce_data.icon[0]
				else:
					d["icon"] = produce_data.icon
		recipe_content.push_back(d)

	_recipe_list.Content = recipe_content
	_material_list.Content = []
	
	_recipe_icon.visible = false
	_desc_btn.visible = false
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
	
	_desc_btn.visible = ".json" in _current_crafting_selected.produce
	
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
	var input_data = []
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
			if recipe_data.produce == "spare_parts" and "disassembling" in data:
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
					input_data.push_back({"name_id":d.name_id, "max":item.count, "src":item.src, "selected":item.count})
					added_to_data[cargo_index] = true
			cargo_index += 1
	var using_content = _material_list.Content	
	using_content.push_back("energy")
			
			
	input_data.push_back("energy")
	var missing = []
	var loaded_input_data = _behavior.LoadInput(using_content)
	var can_produce = _behavior.TestRequirements(recipe_data, loaded_input_data, _obj.get_attrib("converter.stored_energy"), missing)
	
	for require in missing:
		var missing_count : String = ""
		if "amount" in require and require["amount"] > 1:
			missing_count = " " + str(require["amount"])
		if "type" in require and (require.type == "energy" or require.type == "disassembling"):
			pass # for now this will be handled by the updateCraftButton()
		elif "type" in require:
			list_data.push_front({"display_name_id":Globals.mytr("Missing%s %s", [missing_count, Globals.mytr(require.type)]), "name_id": Globals.mytr("Missing%s %s", [missing_count, Globals.mytr(require.type)]), "disabled":true, "max":require.amount})
		elif "src" in require:
			var d = Globals.LevelLoaderRef.LoadJSON(require.src)
			list_data.push_front({"display_name_id":Globals.mytr("Missing%s %s", [missing_count, Globals.mytr(d.name_id)]), "name_id":Globals.mytr("Missing%s %s", [missing_count, Globals.mytr(d.name_id)]), "disabled":true, "max":require.amount})
	
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
	if _current_crafting_selected.produce == "energy":
		recipe_name_str = Globals.mytr("Recycle %d Item(s)", [_current_data["count"]])
	elif _current_crafting_selected.produce == "spare_parts":
		recipe_name_str = Globals.mytr("%d Item(s) for %d Spare Part(s)", [_current_data["count"], _current_data["spare_parts"]])
	else:
		recipe_name_str = Globals.mytr("Craft %d %s", [_current_data["count"], Globals.mytr(_current_crafting_selected.name)])
		
	_recipe_name.bbcode_text = "[color=%s]%s[/color]" % [recipe_color_str, recipe_name_str]
	
	####### Energy Label #######
	var energy_label_str : String = "Energy Cost...."
	if _current_crafting_selected.produce == "energy":
		energy_label_str = "Energy Gain...."
	get_node("HBoxContainer/Control/VBoxContainer/RecipeInfoContainer/HBoxContainer2/EnergyLabel").bbcode_text = Globals.mytr(energy_label_str)
	
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
				in_cargo += item.count
	if _current_crafting_selected.produce == "spare_parts":
		var cargo = _obj.get_attrib("cargo.content")
		for item in cargo:
			if "spare_parts.json" in Globals.clean_path(item.src):
				in_cargo += item.count
				
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
		ship_name = Globals.mytr("The %s's Status", [p_name])
		
	var max_hull = _obj.get_attrib("destroyable.hull")
	var cur_hull = _obj.get_attrib("destroyable.current_hull", max_hull)
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
		shield_str += "[color=yellow]%s[/color]" % Globals.mytr("Missing")
		if ship_color != "red":
			ship_color = "yellow"
	elif cur_shield != null and cur_shield < 1:
		shield_str += "[color=red]%s[/color]" % Globals.mytr("Down!")
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
		
	if _current_crafting_selected.produce == "spare_parts":
		special_disassemble_update(_current_crafting_selected)
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
	
	using_content.push_back("energy")
	var missing = []
	var loaded_input_data = _behavior.LoadInput(using_content)
	var can_produce = _behavior.TestRequirements(_current_crafting_selected, loaded_input_data, _obj.get_attrib("converter.stored_energy"), missing)
	
	var list_data = _material_list.Content
	var index := 0
	for l_data in list_data:
		if missing.size() > index and missing[index].has("type") and missing[index].type == "energy":
			index += 1
		if "disabled" in l_data and l_data.disabled == true:
			var name_id := ""
			var display_name_id := ""
			if missing.size() > index:
				var missing_data = missing[index]
				var missing_count : String = ""
				if missing_data["amount"] > 1:
					missing_count = " " + str(missing_data["amount"])
				if "type" in missing_data and (missing_data.type == "energy" or missing_data.type == "disassembling"):
					pass # for now this will be handled by the updateCraftButton()
				elif "type" in missing_data:
					name_id = Globals.mytr("Missing%s %s", [missing_count, Globals.mytr(missing_data.type)])
					display_name_id = Globals.mytr("Missing%s %s", [missing_count, Globals.mytr(missing_data.type)])
				elif "src" in missing_data:
					var d = Globals.LevelLoaderRef.LoadJSON(missing_data.src)
					name_id = Globals.mytr("Missing%s %s", [missing_count, Globals.mytr(d.name_id)])
					display_name_id = Globals.mytr("Missing%s %s", [missing_count, Globals.mytr(d.name_id)])
			l_data.name_id = name_id
			l_data.display_name_id = display_name_id
			index += 1
	_material_list.UpdateContent(list_data)
	

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


func special_disassemble_update(recipe_data):
	var using_content = _material_list.Content
	var total_items = 0
	var total_energy = 0
	var total_spare_parts = 0
	for item in using_content:
		if "disabled" in item and item.disabled == true:
			continue
		var d = Globals.LevelLoaderRef.LoadJSON(item.src)
		total_items += item.selected
		total_energy += (d.disassembling.energy_cost * item.selected)
		total_spare_parts += d.disassembling.count * item.selected

	_current_data["count"] = total_items
	_current_data["ap"] = total_items * recipe_data.ap_cost
	_current_data["energy"] = total_energy - _get_idle_turn_energy_cost(_current_data["ap"])
	_current_data["spare_parts"] = total_spare_parts
		
	UpdateCraftInfo()

	
func _get_idle_turn_energy_cost(num_turn):
	var base_ap_energy_cost = _obj.get_attrib("converter.base_ap_energy_cost")
	if base_ap_energy_cost != null and base_ap_energy_cost > 0:
		return base_ap_energy_cost*num_turn
	else:
		return 0

func UpdateCraftButton():
	# We died while crafting and crashed because _obj had been destroyed
	if not is_instance_valid(_obj) or _obj.get_attrib("destroyable.destroyed", false) == true:
		return
	
	if _current_data["count"] > 0 and (_current_crafting_selected.produce == "energy" or _obj.get_attrib("converter.stored_energy") > _current_data["energy"]):
		_craft_button.Disabled = false
	else:
		if _current_crafting_selected != null and _current_crafting_selected.produce != "energy" and _obj.get_attrib("converter.stored_energy") <= _current_data["energy"]:
			_craft_button.Text = "Not Enough Energy!"
		else:
			_craft_button.Text = "[c]raft"
		_craft_button.Disabled = true
	
