extends "res://scripts/GUI/GUILayoutBase.gd"

signal drop_pressed(dropped_mounts, dropped_cargo)
signal use_pressed(key)

onready var _my_ship_list : MyItemList = get_node("HBoxContainer/MyShip/MyItemList")
onready var _other_ship_list : MyItemList = get_node("HBoxContainer/OtherShip/MyItemList")
var _obj : Attributes = null

var _transfer_btn : ButtonBase = null
var _take_all_btn : ButtonBase = null
var _transfer_all_btn : ButtonBase = null

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
	# Update inventory lists
	ReInit()


func Cancel_Callback():
	ReInit()
	
func Ok_Callback():
	BehaviorEvents.emit_signal("OnPopGUI")
	
	# reset content or we might end up with dangling references
	_my_ship_list.Content = []
	_other_ship_list.Content = []
	
	
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
					added = true
					break
				index += 1
		var num = 1
		if "count" in item:
			num = item.count
		BehaviorEvents.emit_signal("OnRemoveItem", from, item.src, num)
		if added == false:
			for i in range(num):
				BehaviorEvents.emit_signal("OnAddItem", to, item.src)
		
			
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
	_lobj.init_cargo()
	_lobj.init_mounts()
	_robj.init_cargo()
	_robj.init_mounts()
	
	get_node("HBoxContainer/OtherShip").title = _robj.get_attrib("name_id")
	get_node("HBoxContainer/MyShip").title = _lobj.get_attrib("name_id")
	
	var cargo1 = _lobj.get_attrib("cargo.content")
	var mounts1 = _lobj.get_attrib("mounts")
	var cargo2 = _robj.get_attrib("cargo.content")
	var mounts2 = _robj.get_attrib("mounts")
	
	_normal_btns.visible = true
	_question_btns.visible = false
	
	GenerateContent(_my_ship_list, mounts1, cargo1)
	GenerateContent(_other_ship_list, mounts2, cargo2)
	
	# Init all the buttons to Enable/Disabled state
	OnSelectionChanged_Callback()
	
func GenerateContent(list_node, mounts, cargo):
	var mount_content := []
	#TODO: order by something consistent
	for key in mounts:
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
		mount_content.push_back({"src":row.src, "count":row.count, "name_id": counting + data.name_id, "equipped":false, "header":false, "icon":data.icon})

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
		if item.selected == true:
			selected_left = item
			break
			
	for item in right:
		if item.selected == true and "src" in item and item.src != "":
			selected_right = item
			break
			
	if selected_left != null:
		_transfer_btn.Text = "Transfer >"
		_transfer_btn.Disabled = false
	elif selected_right != null:
		_transfer_btn.Text = "< Transfer"
		_transfer_btn.Disabled = false
	else:
		_transfer_btn.Text = "Transfer"
		_transfer_btn.Disabled = true
		
############### DRAG & DROP ###################

func OnDragDropCompleted_Callback(origin_data, destination_data):
	pass
	