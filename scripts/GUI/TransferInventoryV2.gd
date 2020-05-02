extends "res://scripts/GUI/GUILayoutBase.gd"

signal drop_pressed(dropped_mounts, dropped_cargo)
signal use_pressed(key)

onready var _my_ship_list : MyItemList = get_node("HBoxContainer/MyShip/MyItemList")
onready var _other_ship_list : MyItemList = get_node("HBoxContainer/OtherShip/MyItemList")
var _obj : Attributes = null

var _transfer_btn : ButtonBase = null
var _take_all_btn : ButtonBase = null
var _transfer_all_btn : ButtonBase = null
var _desc_btn : ButtonBase = null

var _normal_btns : Control = null
var _question_btns : Control = null

var _transfered_cargo : Dictionary = {}
var _transfered_ship : Attributes = null
var _transfered_to : Attributes = null

var _callback_obj : Node = null
var _callback_method : String = ""

var _lobj : Attributes = null
var _robj : Attributes = null

func _ready():
	_normal_btns = get_node("HBoxContainer/Control/Normal")
	_question_btns = get_node("HBoxContainer/Control/Control")
	_transfer_btn = get_node("HBoxContainer/Control/Normal/Transfer")
	_transfer_btn.connect("pressed", self, "Transfer_Callback")
	_take_all_btn = get_node("HBoxContainer/Control/Normal/TakeAll")
	_take_all_btn.connect("pressed", self, "TakeAll_Callback")
	_transfer_all_btn = get_node("HBoxContainer/Control/Normal/TransferAll")
	_transfer_all_btn.connect("pressed", self, "TransferAll_Callback")
	_desc_btn = get_node("HBoxContainer/Control/Normal/Desc")
	_desc_btn.connect("pressed", self, "Desc_Callback")
	
	get_node("HBoxContainer/Control/Control/Cancel").connect("pressed", self, "Cancel_Callback")
	get_node("HBoxContainer/Control/Normal/Close").connect("pressed", self, "Ok_Callback")
	_my_ship_list.connect("OnSelectionChanged", self, "OnSelectionChanged_Callback")
	_my_ship_list.connect("OnDragDropCompleted", self, "OnDragDropCompleted_Callback")
	_other_ship_list.connect("OnSelectionChanged", self, "OnSelectionChanged_Callback")
	_other_ship_list.connect("OnDragDropCompleted", self, "OnDragDropCompleted_Callback")

func HowManyDiag_Callback(num):
	_transfered_cargo.count = num
	BehaviorEvents.emit_signal("OnRemoveItem", _transfered_ship, _transfered_cargo.src, _transfered_cargo.count)
	for i in range(_transfered_cargo.count):
		BehaviorEvents.emit_signal("OnAddItem", _transfered_to, _transfered_cargo.src)
	
	BehaviorEvents.emit_signal("OnMoveCargo", _transfered_ship, _transfered_to)
	# Update inventory lists
	ReInit()


func Cancel_Callback():
	ReInit()
	
func Ok_Callback():
	BehaviorEvents.emit_signal("OnPopGUI")
	get_node("HBoxContainer/Control/Normal/Close").Disabled = true
	
	# reset content or we might end up with dangling references
	_my_ship_list.Content = []
	_other_ship_list.Content = []
	
	
func Desc_Callback():
	var selected_item = null
	var selected_ship = null
	var to_ship = null
	var from_list = null
	var to_list = null
	
	var left = _my_ship_list.Content
	
	var scanner_level := 0
	var scanner_data = Globals.LevelLoaderRef.LoadJSONArray(_lobj.get_attrib("mounts.scanner"))
	if scanner_data != null and scanner_data.size() > 0:
		scanner_level = Globals.get_data(scanner_data[0], "scanning.level")
	
	var right = _other_ship_list.Content
	
	for item in left:
		if item.selected == true:
			selected_item = item
			selected_ship = _lobj
			to_ship = _robj
			from_list = _my_ship_list
			to_list = _other_ship_list
			get_node("HBoxContainer/OtherShip").title = "Transfer Where ?"
			#get_node("HBoxContainer/MyShip").title = _lobj.get_attrib("name_id")
			break
	
	if selected_item == null:
		for item in right:
			if item.selected == true and "src" in item and item.src != "":
				selected_item = item
				selected_ship = _robj
				to_ship = _lobj
				from_list = _other_ship_list
				to_list = _my_ship_list
				get_node("HBoxContainer/MyShip").title = "Transfer Where ?"
				break
	
	if selected_item == null:
		return
	
	var data = null
	if "src" in selected_item and selected_item.src != null and selected_item.src != "":
		data = Globals.LevelLoaderRef.LoadJSON(selected_item.src)
	
	BehaviorEvents.emit_signal("OnPushGUI", "Description", {"json":data, "scanner_level":scanner_level})
	
func Transfer_Callback():
	var selected_item = null
	var selected_ship = null
	var to_ship = null
	var from_list = null
	var to_list = null
	
	var left = _my_ship_list.Content
	var right = _other_ship_list.Content
	
	for item in left:
		if item.selected == true:
			selected_item = item
			selected_ship = _lobj
			to_ship = _robj
			from_list = _my_ship_list
			to_list = _other_ship_list
			get_node("HBoxContainer/OtherShip").title = Globals.mytr("Transfer Where ?")
			#get_node("HBoxContainer/MyShip").title = _lobj.get_attrib("name_id")
			break
	
	if selected_item == null:
		for item in right:
			if item.selected == true and "src" in item and item.src != "":
				selected_item = item
				selected_ship = _robj
				to_ship = _lobj
				from_list = _other_ship_list
				to_list = _my_ship_list
				get_node("HBoxContainer/MyShip").title = Globals.mytr("Transfer Where ?")
				break
	
	if selected_item == null:
		return
	
	####### If mountable item, ask the player were he wants to send it (mount point or cargo) ########
	var data = Globals.LevelLoaderRef.LoadJSON(selected_item.src)
	var slot = Globals.get_data(data, "equipment.slot")
	if slot != null and slot != "":
		var question_content : Array = []
		for item in to_list.Content:
			if "key" in item and item.key == slot:
				question_content.push_back(item)
		if question_content.size() > 0:
			question_content.push_back({"src":"", "name_id":"Cargo Contents", "equipped":false, "header":true})
			question_content.push_back({"src":"", "name_id":"Empty", "equipped":false, "header":false})
			var other_content = [selected_item]
			from_list.Content = other_content
			to_list.Content = question_content
			_normal_btns.visible = false
			_question_btns.visible = true
			return # ABORT !
	
	if "key" in selected_item and "idx" in selected_item:
		BehaviorEvents.emit_signal("OnRemoveMount", selected_ship, selected_item.key, selected_item.idx)
	
	if "count" in selected_item and selected_item.count > 1:
		_transfered_cargo = selected_item
		_transfered_ship = selected_ship
		_transfered_to = to_ship
		BehaviorEvents.emit_signal("OnPushGUI", "HowManyDiag", {
				"callback_object":self, 
				"callback_method":"HowManyDiag_Callback", 
				"min_value":1, 
				"max_value":selected_item.count})
	else:
		BehaviorEvents.emit_signal("OnMoveCargo", selected_ship, to_ship)
		BehaviorEvents.emit_signal("OnRemoveItem", selected_ship, selected_item.src)
		BehaviorEvents.emit_signal("OnAddItem", to_ship, selected_item.src)
		ReInit()
	

func TakeAll_Callback():
	TransferAll(_robj, _lobj, _other_ship_list, _my_ship_list)
	
	
func TransferAll_Callback():
	TransferAll(_lobj, _robj, _my_ship_list, _other_ship_list)
	

func TransferAll(from, to, from_list, to_list):
	var from_content = from_list.Content
	var to_content = to_list.Content
	
	BehaviorEvents.emit_signal("OnBeginParallelAction", from)
	BehaviorEvents.emit_signal("OnBeginParallelAction", to)
	
	var no_mount := true
	
	for item in from_content:
		if item.header == true or item.src == "":
			continue
		var added = false
		if "key" in item and "idx" in item:
			BehaviorEvents.emit_signal("OnRemoveMount", from, item.key, item.idx)
			var index = 0
			for to_item in to_content:
				if "src" in to_item and "key" in to_item and (to_item.src == null or to_item.src == "") and to_item.key == item.key:
					BehaviorEvents.emit_signal("OnEquipMount", to, to_item.key, to_item.idx, item.src)
					to_item.src = item.src # to signal the rest of the loop that this slot is now occupied before the actual refresh in reinit()
					added = true
					no_mount = false
					break
				index += 1
		var num = 1
		if "count" in item:
			num = item.count
		BehaviorEvents.emit_signal("OnRemoveItem", from, item.src, num)
		if added == false:
			for i in range(num):
				BehaviorEvents.emit_signal("OnAddItem", to, item.src)
		
	if no_mount: # just for sound
		BehaviorEvents.emit_signal("OnMoveCargo", from, to)
	BehaviorEvents.emit_signal("OnEndParallelAction", from)
	BehaviorEvents.emit_signal("OnEndParallelAction", to)
	
	ReInit()
	
func Init(init_param):
	var obj1 = init_param["object1"]
	var obj2 = init_param["object2"]
	
	_callback_obj = init_param["callback_object"]
	_callback_method = init_param["callback_method"]
	
	_lobj = obj1
	_robj = obj2
	
	ReInit()
	
func ReInit():
	get_node("HBoxContainer/Control/Normal/Close").Disabled = false
	_lobj.init_cargo()
	_lobj.init_mounts()
	_robj.init_cargo()
	_robj.init_mounts()
	
	get_node("HBoxContainer/OtherShip").title = Globals.mytr(_robj.get_attrib("name_id"))
	get_node("HBoxContainer/MyShip").title = Globals.mytr(_lobj.get_attrib("player_name", _lobj.get_attrib("name_id")))
	
	var cargo1 = _lobj.get_attrib("cargo.content")
	var mounts1 = _lobj.get_attrib("mounts")
	var cargo2 = _robj.get_attrib("cargo.content")
	var mounts2 = _robj.get_attrib("mounts")
	
	_normal_btns.visible = true
	_question_btns.visible = false
	
	GenerateContent(_my_ship_list, mounts1, cargo1)
	GenerateContent(_other_ship_list, mounts2, cargo2)
	
	var current_load = _lobj.get_attrib("cargo.volume_used")
	var cargo_space = _lobj.get_attrib("cargo.capacity")
	
	var cargo_color = "lime"
	var cargo_str = ""
	if current_load > cargo_space:
		cargo_color="red"
	elif current_load > cargo_space * 0.9:
		cargo_color="yellow"
		
	get_node("HBoxContainer/MyShip/CargoLabel").bbcode_text = "[right]([color=%s]%.f / %.f[/color])[/right]" % [cargo_color, current_load, cargo_space]
	
	current_load = _robj.get_attrib("cargo.volume_used")
	cargo_space = _robj.get_attrib("cargo.capacity")
	
	cargo_color = "lime"
	cargo_str = ""
	if current_load > cargo_space:
		cargo_color="red"
	elif current_load > cargo_space * 0.9:
		cargo_color="yellow"
		
	get_node("HBoxContainer/OtherShip/CargoLabel").bbcode_text = "[right]([color=%s]%.f / %.f[/color])[/right]" % [cargo_color, current_load, cargo_space]
	
	# Init all the buttons to Enable/Disabled state
	OnSelectionChanged_Callback()
	
func sort_categories(var a, var b):
	return a > b
	
func GenerateContent(list_node, mounts, cargo):
	var mount_content := []
	var keys = mounts.keys()
	keys.sort_custom(self, "sort_categories")
	for key in keys:
		mount_content.push_back({"key":key, "name_id":key, "equipped":false, "header":true})
		var items : Array = mounts[key]
		var index = 0
		for src in items:
			if src != null and src != "":
				var item = Globals.LevelLoaderRef.LoadJSON(src)
				mount_content.push_back({"src":mounts[key][index], "key":key, "idx":index, "name_id":item.name_id, "equipped":false, "header":false, "icon":item.icon})
			else:
				mount_content.push_back({"src":"", "key":key, "idx":index, "name_id":"Empty", "equipped":false, "header":false})
			index += 1
		
	mount_content.push_back({"src":"", "name_id":"Cargo Contents", "equipped":false, "header":true})	
	for row in cargo:
		var data = Globals.LevelLoaderRef.LoadJSON(row.src)
		var counting = ""
		if row.count > 1:
			counting = str(row.count) + "x "
		if typeof(data.icon) == TYPE_ARRAY:
			data.icon = data.icon[0]
		mount_content.push_back({"src":row.src, "count":row.count, "display_name_id": counting + Globals.mytr(data.name_id), "name_id": counting + Globals.mytr(data.name_id), "equipped":false, "header":false, "icon":data.icon})

	list_node.Content = mount_content

func OnSelectionChanged_Callback():
	if _normal_btns.visible == true:
		UpdateNormalVisibility()
	else:
		DoMounting()

func DoMounting():
	var from_item = null
	var to_list = null
	var to_item = null
	var from_ship = null
	var to_ship = null
	
	var left = _my_ship_list.Content
	var right = _other_ship_list.Content
	
	for item in left:
		if item.selected == true:
			to_item = item
			to_list = _my_ship_list
			from_item = _other_ship_list.Content[0]
			from_ship = _robj
			to_ship = _lobj
			break
			
	for item in right:
		if item.selected == true:
			to_item = item
			to_list = _other_ship_list
			from_item = _my_ship_list.Content[0]
			from_ship = _lobj
			to_ship = _robj
			break
	
	# Selection is borked
	if from_item.header == true:
		ReInit()
		return
		
	BehaviorEvents.emit_signal("OnBeginParallelAction", from_ship)
	BehaviorEvents.emit_signal("OnBeginParallelAction", to_ship)
	
	if to_item != null:
		var added = false
		if "key" in from_item and "idx" in from_item:
			if "key" in to_item and to_item.src != "":
				BehaviorEvents.emit_signal("OnEquipMount", from_ship, to_item.key, to_item.idx, to_item.src)
				added = true
			else:
				BehaviorEvents.emit_signal("OnRemoveMount", from_ship, from_item.key, from_item.idx)
		BehaviorEvents.emit_signal("OnRemoveItem", from_ship, from_item.src)
		if "key" in to_item:
			if to_item.src != "":
				BehaviorEvents.emit_signal("OnRemoveMount", to_ship, to_item.key, to_item.idx)
				BehaviorEvents.emit_signal("OnRemoveItem", to_ship, to_item.src)
				if added == false:
					BehaviorEvents.emit_signal("OnAddItem", from_ship, to_item.src)
			BehaviorEvents.emit_signal("OnEquipMount", to_ship, to_item.key, to_item.idx, from_item.src)
		else:
			BehaviorEvents.emit_signal("OnMoveCargo", from_item, to_ship)
			BehaviorEvents.emit_signal("OnAddItem", to_ship, from_item.src)
			
	ReInit()
	BehaviorEvents.emit_signal("OnEndParallelAction", from_ship)
	BehaviorEvents.emit_signal("OnEndParallelAction", to_ship)

func UpdateNormalVisibility():
	var selected_left = null
	var selected_right = null
	
	var left = _my_ship_list.Content
	var right = _other_ship_list.Content
	
	for item in left:
		if item.selected == true and "src" in item and item.src != "":
			selected_left = item
			break
			
	for item in right:
		if item.selected == true and "src" in item and item.src != "":
			selected_right = item
			break
			
	if selected_left != null:
		_transfer_btn.Text = "Transfer >"
		_disable_button(_transfer_btn, false)
	elif selected_right != null:
		_transfer_btn.Text = "< Transfer"
		_disable_button(_transfer_btn, false)
	else:
		_transfer_btn.Text = "Transfer"
		_disable_button(_transfer_btn, true)
	
	_disable_button(_desc_btn, selected_left == null and selected_right == null)
		
############### DRAG & DROP ###################

func OnDragDropCompleted_Callback(origin_data, destination_data):
	var origin_ship : Attributes = null
	var dest_ship : Attributes = null
	if origin_data.origin == get_node("HBoxContainer/OtherShip/MyItemList"):
		origin_ship = _robj
	if origin_data.origin == get_node("HBoxContainer/MyShip/MyItemList"):
		origin_ship = _lobj
	if destination_data.origin == get_node("HBoxContainer/OtherShip/MyItemList"):
		dest_ship = _robj
	if destination_data.origin == get_node("HBoxContainer/MyShip/MyItemList"):
		dest_ship = _lobj
		
	var dest_is_mount := false
	if "key" in destination_data and "idx" in destination_data:
		dest_is_mount = true
	var origin_is_mount := false
	if "key" in origin_data and "idx" in origin_data:
		origin_is_mount = true
		
	BehaviorEvents.emit_signal("OnBeginParallelAction", origin_ship)
	BehaviorEvents.emit_signal("OnBeginParallelAction", dest_ship)
	
	# Cargo to Cargo
	if dest_is_mount == false and origin_is_mount == false and origin_ship != dest_ship:
		if origin_data.count > 1:
			_transfered_cargo = origin_data
			_transfered_ship = origin_ship
			_transfered_to = dest_ship
			BehaviorEvents.emit_signal("OnPushGUI", "HowManyDiag", {
					"callback_object":self, 
					"callback_method":"HowManyDiag_Callback", 
					"min_value":1, 
					"max_value":origin_data.count})
		else:
			BehaviorEvents.emit_signal("OnMoveCargo", origin_ship, dest_ship)
			BehaviorEvents.emit_signal("OnRemoveItem", origin_ship, origin_data.src)
			BehaviorEvents.emit_signal("OnAddItem", dest_ship, origin_data.src)
	# Cargo to Mount
	elif dest_is_mount == true and origin_is_mount == false:
		BehaviorEvents.emit_signal("OnRemoveItem", origin_ship, origin_data.src)
		if destination_data.src != "": # Swap
			BehaviorEvents.emit_signal("OnRemoveMount", dest_ship, destination_data.key, destination_data.idx)
			BehaviorEvents.emit_signal("OnRemoveItem", dest_ship, destination_data.src)
			BehaviorEvents.emit_signal("OnAddItem", origin_ship, destination_data.src)
		BehaviorEvents.emit_signal("OnAddItem", dest_ship, origin_data.src)
		BehaviorEvents.emit_signal("OnEquipMount", dest_ship, destination_data.key, destination_data.idx, origin_data.src)
	# Mount to Cargo
	elif dest_is_mount == false and origin_is_mount == true:
		BehaviorEvents.emit_signal("OnRemoveMount", origin_ship, origin_data.key, origin_data.idx)
		BehaviorEvents.emit_signal("OnRemoveItem", origin_ship, origin_data.src)
		BehaviorEvents.emit_signal("OnAddItem", dest_ship, origin_data.src)
	# Mount to Mount
	elif dest_is_mount == true and origin_is_mount == true:
		if destination_data.src != "":
			BehaviorEvents.emit_signal("OnRemoveMount", dest_ship, destination_data.key, destination_data.idx)
			BehaviorEvents.emit_signal("OnRemoveItem", dest_ship, destination_data.src)
		if origin_data.src != "":
			BehaviorEvents.emit_signal("OnRemoveMount", origin_ship, origin_data.key, origin_data.idx)
			BehaviorEvents.emit_signal("OnRemoveItem", origin_ship, origin_data.src)
		if destination_data.src != "":
			BehaviorEvents.emit_signal("OnAddItem", origin_ship, destination_data.src)
			BehaviorEvents.emit_signal("OnEquipMount", origin_ship, origin_data.key, origin_data.idx, destination_data.src)
		if origin_data.src != "":
			BehaviorEvents.emit_signal("OnAddItem", dest_ship, origin_data.src)
			BehaviorEvents.emit_signal("OnEquipMount", dest_ship, destination_data.key, destination_data.idx, origin_data.src)
	
	ReInit()

	BehaviorEvents.emit_signal("OnEndParallelAction", origin_ship)
	BehaviorEvents.emit_signal("OnEndParallelAction", dest_ship)
	
	

func _disable_button(btn : ButtonBase, is_disabled : bool):
	#btn.Disabled = is_disabled
	btn.visible = !is_disabled
	
