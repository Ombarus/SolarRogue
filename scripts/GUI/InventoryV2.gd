extends "res://scripts/GUI/GUILayoutBase.gd"

onready var _mounts_list : MyItemList = get_node("HBoxContainer/Mounts/MyItemList")
onready var _cargo_list : MyItemList = get_node("HBoxContainer/Cargo/MyItemList")
var _obj : Attributes = null

var _swap_btn : ButtonBase = null
var _drop_btn : ButtonBase = null
var _use_btn : ButtonBase = null

func _ready():
	get_node("HBoxContainer/Mounts").connect("OnOkPressed", self, "Close_Callback")
	get_node("HBoxContainer/Cargo").connect("OnCancelPressed", self, "Close_Callback")
	_swap_btn = get_node("HBoxContainer/Control/Swap")
	_swap_btn.connect("pressed", self, "Swap_Callback")
	_drop_btn = get_node("HBoxContainer/Control/Drop")
	_drop_btn.connect("pressed", self, "Drop_Callback")
	_use_btn = get_node("HBoxContainer/Control/Use")
	_use_btn.connect("pressed", self, "Use_Callback")
	get_node("HBoxContainer/Control/Close").connect("pressed", self, "Close_Callback")
	_mounts_list.connect("OnSelectionChanged", self, "OnSelectionChanged_Callback")
	_cargo_list.connect("OnSelectionChanged", self, "OnSelectionChanged_Callback")

func Swap_Callback():
	pass
	
func Drop_Callback():
	pass
	
func Use_Callback():
	pass
	
func Close_Callback():
	BehaviorEvents.emit_signal("OnPopGUI")
	
	var c = _cargo_list.Content
	
	# reset content or we might end up with dangling references
	_mounts_list.Content = []
	_cargo_list.Content = []
	
	
func Init(init_param):
	_obj = init_param["object"]
	
	_obj.init_cargo()
	_obj.init_mounts()
	
	var cargo : Array = _obj.modified_attributes.cargo.content
	var mounts : Dictionary = _obj.modified_attributes.mounts
	
	var mount_content := []
	#TODO: order by something consistent
	for key in mounts:
		mount_content.push_back({"name_id":key, "equipped":false, "header":true})
		var items : Array = Globals.LevelLoaderRef.LoadJSONArray(mounts[key])
		var index = 0
		for item in items:
			mount_content.push_back({"src":mounts[key][index], "key":key, "index":index, "name_id":item.name_id, "equipped":false, "header":false, "icon":item.icon})
			index += 1
	_mounts_list.Content = mount_content
	
	var cargo_content := []
	var cargo_item_by_category := {}
	#TODO: order by something consistent
	for row in cargo:
		var data = Globals.LevelLoaderRef.LoadJSON(row.src)
		var cat : String = data.equipment.slot
		if cat == "cargo" or cat == null or cat == "":
			cat = "Others"
		if not cat in cargo_item_by_category:
			cargo_item_by_category[cat] = []
		var counting = ""
		if row.count > 1:
			counting = str(row.count) + "x "
		cargo_item_by_category[cat].push_back({"src":row.src, "count":row.count, "name_id": counting + data.name_id, "equipped":false, "header":false, "icon":data.icon})
		
	for key in cargo_item_by_category:
		cargo_content.push_back({"name_id":key, "equipped":false, "header":true})
		cargo_content += cargo_item_by_category[key]
	_cargo_list.Content = cargo_content

func OnSelectionChanged_Callback():
	var selected_cargo = null
	var selected_mount = null
	
	var cargo = _cargo_list.Content
	var mounts = _mounts_list.Content
	
	for item in cargo:
		if item.selected == true:
			selected_cargo = item
			break
			
	for item in mounts:
		if item.selected == true:
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
		_use_btn.Disabled = false
	else:
		_use_btn.Disabled = true
	
	###### Setup the Drop button if something is selected ######	
	if selected_cargo != null or selected_mount != null:
		_drop_btn.Disabled = false
	else:
		_drop_btn.Disabled = true
	
	###### Setup the swap/install/remove button ######
	_swap_btn.Disabled = true
	var cargo_slot = null
	if cargo_data != null:
		cargo_slot = Globals.get_data(cargo_data, "equipment.slot")
	var mount_slot = null
	if mount_data != null:
		mount_slot = Globals.get_data(mount_data, "equipment.slot")
		
	if cargo_data != null and mount_data != null:
		if cargo_slot != null and cargo_slot == mount_slot:
			_swap_btn.Text = "<> Swap"
			_swap_btn.Disabled = false
			
	if cargo_slot != null and mount_data == null:
		var mounted : Array = _obj.get_attrib("mounts." + cargo_slot)
		var has_free := false
		if mounted != null:
			for m in mounted:
				if m == null or m == "":
					has_free = true
					break
		if has_free:
			_swap_btn.Text = "< Mount"
			_swap_btn.Disabled = false
			
	if _swap_btn.Disabled == true and mount_slot != null:
		_swap_btn.Text = "> Remove"
		_swap_btn.Disabled = false
	