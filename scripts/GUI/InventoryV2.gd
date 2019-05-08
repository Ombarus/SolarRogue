extends "res://scripts/GUI/GUILayoutBase.gd"

onready var _mounts_list : MyItemList = get_node("HBoxContainer/Mounts/MyItemList")
onready var _cargo_list : MyItemList = get_node("HBoxContainer/Cargo/MyItemList")
var _obj : Attributes = null

func _ready():
	get_node("HBoxContainer/Mounts").connect("OnOkPressed", self, "Ok_Callback")
	get_node("HBoxContainer/Cargo").connect("OnCancelPressed", self, "Cancel_Callback")
	#get_node(_drop_btn).connect("pressed", self, "OnDropPressed_Callback")
	#get_node(_use_btn).connect("pressed", self, "OnUsePressed_Callback")
	
	#var a = [{"name_id":"Weapons", "equipped":false, "header":true}, {"icon": { "texture":"data/textures/space-sprite.png", "region":[0,128,128,128] }, "name_id":"Laser Turret MK2", "equipped":false, "header":false}, {"name_id":"Empty", "equipped":false, "header":false}]
	
	#_mounts_list.Content = a
	#_cargo_list.Content = []
	
	
func Ok_Callback():
	BehaviorEvents.emit_signal("OnPopGUI")
	
	# reset content or we might end up with dangling references
	_mounts_list.Content = []
	_cargo_list.Content = []
	
	
func Cancel_Callback():
	BehaviorEvents.emit_signal("OnPopGUI")
	
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
			mount_content.push_back({"key":key, "index":index, "name_id":item.name_id, "equipped":false, "header":false, "icon":item.icon})
			index += 1
	_mounts_list.Content = mount_content
	
	var cargo_content := []
	var cargo_item_by_category := {}
	#TODO: order by something consistent
	for row in cargo:
		var data = Globals.LevelLoaderRef.LoadJSON(row.src)
		var cat = data.equipment.slot
		if cat == "cargo" or cat == null or cat == "":
			cat = "Others"
		if not cat in cargo_item_by_category:
			cargo_item_by_category[cat] = []
		var counting = ""
		if row.count > 1:
			counting = str(row.count) + "x "
		cargo_item_by_category[cat].push_back({"key":row.src, "count":row.count, "name_id": counting + data.name_id, "equipped":false, "header":false, "icon":data.icon})
		
	for key in cargo_item_by_category:
		cargo_content.push_back({"name_id":key, "equipped":false, "header":true})
		cargo_content += cargo_item_by_category[key]
	_cargo_list.Content = cargo_content
		
		
	#for item in cargo_content:
	#	mount_content.push_back({"name_id":key, "equipped":false, "header":true})
	#	var items : Array = Globals.LevelLoaderRef.LoadJSONArray(mounts[key])
	#	for item in items:
	#		mount_content.push_back({"name_id":item.name_id, "equipped":false, "header":false, "icon":item.icon})
	