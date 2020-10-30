extends "res://scripts/GUI/GUILayoutBase.gd"

signal drop_pressed(dropped_mounts, dropped_cargo)
signal use_pressed(key, attrib)

onready var _mounts_list : MyItemList = get_node("HBoxContainer/Mounts/MyItemList")
onready var _cargo_list : MyItemList = get_node("HBoxContainer/Cargo/MyItemList")
var _obj : Attributes = null

var _remove_btn : ButtonBase = null
var _swap_btn : ButtonBase = null
var _drop_btn : ButtonBase = null
var _use_btn : ButtonBase = null
var _desc_btn : ButtonBase = null

var _normal_btns : Control = null
var _mounting_btns : Control = null

var _dropped_cargo := []

func _ready():
	get_node("HBoxContainer/Mounts").connect("OnOkPressed", self, "Close_Callback")
	get_node("HBoxContainer/Cargo").connect("OnCancelPressed", self, "Close_Callback")
	
	_normal_btns = get_node("HBoxContainer/Control/Normal")
	_mounting_btns = get_node("HBoxContainer/Control/Mounting")
	_mounting_btns.get_node("Cancel").connect("pressed", self, "OnCancelMounting_Callback")
	
	_remove_btn = get_node("HBoxContainer/Control/Normal/Remove")
	_remove_btn.connect("pressed", self, "Remove_Callback")
	_swap_btn = get_node("HBoxContainer/Control/Normal/Swap")
	_swap_btn.connect("pressed", self, "Swap_Callback")
	_drop_btn = get_node("HBoxContainer/Control/Normal/Drop")
	_drop_btn.connect("pressed", self, "Drop_Callback")
	_use_btn = get_node("HBoxContainer/Control/Normal/Use")
	_use_btn.connect("pressed", self, "Use_Callback")
	_desc_btn = get_node("HBoxContainer/Control/Normal/Desc")
	_desc_btn.connect("pressed", self, "Desc_Callback")
	
	get_node("HBoxContainer/Control/Normal/Close").connect("pressed", self, "Close_Callback")
	_mounts_list.connect("OnSelectionChanged", self, "OnSelectionChanged_Callback")
	_mounts_list.connect("OnDragDropCompleted", self, "OnDragDropCompleted_Callback")
	_cargo_list.connect("OnSelectionChanged", self, "OnSelectionChanged_Callback")
	_cargo_list.connect("OnDragDropCompleted", self, "OnDragDropCompleted_Callback")
	get_node("HBoxContainer/Control/DropDrag").connect("OnDragDropCompleted", self, "OnDragDropCompleted_Callback")
	
	BehaviorEvents.connect("OnPlayerTurn", self, "OnPlayerTurn_Callback")

func OnPlayerTurn_Callback(obj):
	if self.visible == true and obj == _obj:
		Init({"object":_obj})


func Desc_Callback():
	var scanner_level := 0
	var scanner_data = Globals.LevelLoaderRef.LoadJSONArray(_obj.get_attrib("mounts.scanner"))
	if scanner_data != null and scanner_data.size() > 0:
		scanner_level = Globals.get_data(scanner_data[0], "scanning.level")
	
	var selected = null
	
	var cargo = _cargo_list.Content
	var mounts = _mounts_list.Content
	
	for item in cargo:
		if item.selected == true:
			selected = item
			break
			
	if selected == null:
		for item in mounts:
			if item.selected == true:
				selected = item
				break
		
	var data = null
	if selected != null and "src" in selected and selected.src != null and selected.src != "":
		data = Globals.LevelLoaderRef.LoadJSON(selected.src)
		
	var owner = null
	# Only show ship-wide effects if item is equipped, otherwise show only effect of selected item
	if "key" in selected and "idx" in selected:
		#print("showing global effect for selected mounted item")
		owner = _obj
	
	BehaviorEvents.emit_signal("OnPushGUI", "Description", {"json":data, "owner":owner, "modified_attributes":selected.get("modified_attributes", {}), "scanner_level":scanner_level})

func Remove_Callback():
	var selected_mount = null
	var mounts = _mounts_list.Content
	
	for item in mounts:
		if item.selected == true:
			selected_mount = item
			break
	
	if selected_mount != null and "src" in selected_mount and selected_mount.src != "":
		BehaviorEvents.emit_signal("OnRemoveMount", _obj, selected_mount.key, selected_mount.idx)
		Init({"object":_obj})

func Swap_Callback():
	var selected_cargo = null
	var cargo = _cargo_list.Content
	
	for item in cargo:
		if item.selected == true:
			selected_cargo = item
			break
			
	if selected_cargo == null:
		return
	
	var data = Globals.LevelLoaderRef.LoadJSON(selected_cargo.src)
	var desired_slot = Globals.get_data(data, "equipment.slot")
	if desired_slot == null:
		return
		
	var mount_points = []
	var valid_count : int = 0
	var last_mount = null
	for item in _mounts_list.Content:
		if item.key == desired_slot:
			if item.header == false:
				last_mount = item
				valid_count += 1
			mount_points.push_back(item)
	
	if valid_count > 1:
		get_node("HBoxContainer/Mounts").title = "Mount Where ?"
		_cargo_list.Content = [selected_cargo]
		_mounts_list.Content = mount_points
	
		_normal_btns.visible = false
		_mounting_btns.visible = true
	else:
		BehaviorEvents.emit_signal("OnEquipMount", _obj, last_mount.key, last_mount.idx, selected_cargo.src, selected_cargo.get("modified_attributes", null))
		Init({"object":_obj}) # refresh list
		pass
	
func OnCancelMounting_Callback():
	# reset everything without doing anything special
	Init({"object":_obj})	
	
func Drop_Callback():
	var dropped_mounts = []
	for data in _mounts_list.Content:
		if data.selected == true:
			dropped_mounts.push_back(data)
			
	_dropped_cargo = []
	for data in _cargo_list.Content:
		if data.selected == true:
			_dropped_cargo.push_back(data)
			
	if _dropped_cargo.size() > 0 and _dropped_cargo[0].count > 1:
		BehaviorEvents.emit_signal("OnPushGUI", "HowManyDiag", {
			"callback_object":self, 
			"callback_method":"HowManyDiag_Callback", 
			"min_value":1, 
			"max_value":_dropped_cargo[0].count})
	else:
		emit_signal("drop_pressed", dropped_mounts, _dropped_cargo)
		# Update inventory lists
		Init({"object":_obj})
	
	
func HowManyDiag_Callback(num):
	_dropped_cargo[0].count = num
	emit_signal("drop_pressed", [], _dropped_cargo)
	# Update inventory lists
	Init({"object":_obj})
	
func Use_Callback():
	var selected_mounts = []
	#TODO: allow using stuff from mounts (might be a special ability of a mount)
	#for data in get_node(_mounts_node).content:
	#	if data.checked == true:
	#		dropped_mounts.push_back({"key":data.key, "index":data.index})
	var selected_cargo = []
	var selected_attrib = []
	for item in _cargo_list.Content:
		if item.selected == true:
			var data = Globals.LevelLoaderRef.LoadJSON(item.src)
			if "consumable" in data:
				selected_cargo.push_back(item.src)
				selected_attrib.push_back(item.get("modified_attributes", {}))
	
	if selected_cargo.size() > 0:
		var data = Globals.LevelLoaderRef.LoadJSON(selected_cargo[0])
		emit_signal("use_pressed", selected_cargo[0], selected_attrib[0])
		if Globals.get_data(data, "consumable.close_inventory", true) == true:
			Close_Callback()
		#Init({"object":_obj}) # refresh list
	else:
		BehaviorEvents.emit_signal("OnLogLine", "No selected item can be used like that")
	
func Close_Callback():
	BehaviorEvents.emit_signal("OnPopGUI")
	get_node("HBoxContainer/Mounts").disabled = true
	get_node("HBoxContainer/Cargo").disabled = true
	get_node("HBoxContainer/Control/Normal/Close").Disabled = true
	
	var c = _cargo_list.Content
	
	# reset content or we might end up with dangling references
	_mounts_list.Content = []
	_cargo_list.Content = []
	_obj = null
	

func sort_categories(var a, var b):
	return a > b
	
	
func Init(init_param):
	get_node("HBoxContainer/Mounts").disabled = false
	get_node("HBoxContainer/Cargo").disabled = false
	get_node("HBoxContainer/Control/Normal/Close").Disabled = false
	
	_normal_btns.visible = true
	_mounting_btns.visible = false
	get_node("HBoxContainer/Mounts").title = "Ship's Mounts"
	_obj = init_param["object"]
	
	_obj.init_cargo()
	_obj.init_mounts()
	
	var cargo : Array = _obj.modified_attributes.cargo.content
	var mounts : Dictionary = _obj.modified_attributes.mounts
	var mount_variations : Dictionary = _obj.modified_attributes.mount_attributes
	
	var mount_content := []
	var keys : Array = mounts.keys()
	keys.sort_custom(self, "sort_categories")
	for key in keys:
		mount_content.push_back({"key":key, "name_id":key, "equipped":false, "header":true})
		var items : Array = mounts[key]
		var index = 0
		for src in items:
			if src != null and src != "":
				var item = Globals.LevelLoaderRef.LoadJSON(src)
				var variation = mount_variations[key][index]
				var display_name = Globals.EffectRef.get_display_name(item, variation)
				mount_content.push_back({"src":mounts[key][index], "key":key, "idx":index, "modified_attributes":variation, "display_name_id":display_name, "name_id":item.name_id, "equipped":false, "header":false, "icon":item.icon})
			else:
				mount_content.push_back({"src":"", "key":key, "idx":index, "name_id":"Empty", "equipped":false, "header":false})
			index += 1
	_mounts_list.Content = mount_content
	
	var cargo_content := []
	var cargo_item_by_category := {}
	for row in cargo:
		var data = Globals.LevelLoaderRef.LoadJSON(row.src)
		var cat : String = data.equipment.slot
		if "consumable" in data:
			cat = "consumable"
		if cat == "cargo" or cat == null or cat == "":
			cat = "others"
		if not cat in cargo_item_by_category:
			cargo_item_by_category[cat] = []
		var counting = ""
		if row.count > 1:
			counting = str(row.count) + "x "
		var icon_data = data.icon
		if typeof(data.icon) == TYPE_ARRAY:
			icon_data = data.icon[0]
			
		var display_name = counting
		display_name += Globals.EffectRef.get_display_name(data, row.get("modified_attributes", {}))
		cargo_item_by_category[cat].push_back({"src":row.src, "modified_attributes":row.get("modified_attributes", null), "count":row.count, "display_name_id": display_name, "name_id": display_name, "equipped":false, "header":false, "icon":icon_data})
		
	keys = cargo_item_by_category.keys()
	keys.sort_custom(self, "sort_categories")
	for key in keys:
		cargo_content.push_back({"name_id":key, "equipped":false, "header":true})
		cargo_content += cargo_item_by_category[key]
	_cargo_list.Content = cargo_content
	
	var current_load = _obj.get_attrib("cargo.volume_used")
	var cargo_space = _obj.get_attrib("cargo.capacity")
	
	var cargo_color = "lime"
	var cargo_str = ""
	if current_load > cargo_space:
		cargo_color="red"
	elif current_load > cargo_space * 0.9:
		cargo_color="yellow"
		
	get_node("HBoxContainer/Cargo/CargoLabel").bbcode_text = "[right]([color=%s]%.f / %.f[/color])[/right]" % [cargo_color, current_load, cargo_space]
	
	# Init all the buttons to Enable/Disabled state
	OnSelectionChanged_Callback()

func OnSelectionChanged_Callback():
	if _normal_btns.visible == true:
		UpdateNormalVisibility()
	else:
		DoMounting()

func DoMounting():
	var selected_cargo = null
	var selected_mount = null
	
	var cargo = _cargo_list.Content
	var mounts = _mounts_list.Content
	
	for item in cargo:
		if item.header == false:
			selected_cargo = item
			break
			
	for item in mounts:
		if item.selected == true:
			selected_mount = item
			break
	
	if selected_mount == null:
		Init({"object":_obj}) # refresh list
		return
		
	BehaviorEvents.emit_signal("OnEquipMount", _obj, selected_mount.key, selected_mount.idx, selected_cargo.src, selected_cargo.get("modified_attributes", null))
	Init({"object":_obj}) # refresh list

func UpdateNormalVisibility():
	var selected_cargo = null
	var selected_mount = null
	
	var cargo = _cargo_list.Content
	var mounts = _mounts_list.Content
	
	for item in cargo:
		if item.selected == true:
			selected_cargo = item
			break
			
	for item in mounts:
		if item.selected == true and "src" in item and item.src != "":
			selected_mount = item
			break
			
	var cargo_data = null
	if selected_cargo != null:
		cargo_data = Globals.LevelLoaderRef.LoadJSON(selected_cargo.src)
	var mount_data = null
	if selected_mount != null:
		mount_data = Globals.LevelLoaderRef.LoadJSON(selected_mount.src)
		
	###### Setup the Use button if selected items are "consumable" ######
	if (cargo_data != null and "consumable" in cargo_data) or \
		(mount_data != null and "consumable" in mount_data):
		_disable_button(_use_btn, false)
	else:
		_disable_button(_use_btn, true)
	
	###### Setup the Drop button if something is selected ######	
	if selected_cargo != null or selected_mount != null:
		_disable_button(_drop_btn, false)
	else:
		_disable_button(_drop_btn, true)
	
	
	###### Setup the swap/mount button #######
	_disable_button(_swap_btn, true)
	var cargo_slot = null
	if cargo_data != null:
		cargo_slot = Globals.get_data(cargo_data, "equipment.slot")
		if cargo_slot != null:
			var mounted : Array = _obj.get_attrib("mounts." + cargo_slot, [])
			if mounted.size() > 0:
				_disable_button(_swap_btn, false)
				
				
	###### Setup the remove mount button #######
	if selected_mount != null:
		_disable_button(_remove_btn, false)
	else:
		_disable_button(_remove_btn, true)
		
	###### Can show description button #######
	
	_disable_button(_desc_btn, selected_cargo == null and selected_mount == null)
		
		
############### DRAG & DROP ###################

func OnDragDropCompleted_Callback(origin_data, destination_data):
	# Drop Item on the ground
	if destination_data.origin == get_node("HBoxContainer/Control/DropDrag"):
		var dropped_mounts = []
		if "key" in origin_data and "idx" in origin_data and origin_data.src != "":
			dropped_mounts.push_back(origin_data)
			
		_dropped_cargo = []
		if not "key" in origin_data and not "idx" in origin_data and origin_data.src != "":
			_dropped_cargo.push_back(origin_data)
				
		if _dropped_cargo.size() > 0 and _dropped_cargo[0].count > 1:
			BehaviorEvents.emit_signal("OnPushGUI", "HowManyDiag", {
				"callback_object":self, 
				"callback_method":"HowManyDiag_Callback", 
				"min_value":1, 
				"max_value":_dropped_cargo[0].count})
		else:
			emit_signal("drop_pressed", dropped_mounts, _dropped_cargo)
			# Update inventory lists
			Init({"object":_obj})
	# Drop item in cargo
	elif destination_data.origin == get_node("HBoxContainer/Cargo/MyItemList"):
		var selected_mount = origin_data
				
		if selected_mount != null and "src" in selected_mount and selected_mount.src != "":
			BehaviorEvents.emit_signal("OnRemoveMount", _obj, selected_mount.key, selected_mount.idx)
			Init({"object":_obj})
	# Drop item on Mount point
	else:
		BehaviorEvents.emit_signal("OnEquipMount", _obj, destination_data.key, destination_data.idx, origin_data.src, origin_data.get("modified_attributes", null))
		Init({"object":_obj})
	
func _disable_button(btn : ButtonBase, is_disabled : bool):
	#btn.Disabled = is_disabled
	btn.visible = !is_disabled
