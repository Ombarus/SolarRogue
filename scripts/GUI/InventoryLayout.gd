extends "res://scripts/GUI/GUILayoutBase.gd"

signal drop_pressed(dropped_mounts, dropped_cargo)
signal use_pressed(key)

export(NodePath) var _drop_btn
export(NodePath) var _use_btn
export(NodePath) var _mounts_node
export(NodePath) var _cargo_node
export(NodePath) var _cargo_label

var _obj = null


func _ready():
	get_node("base").connect("OnOkPressed", self, "Ok_Callback")
	get_node("base").connect("OnCancelPressed", self, "Cancel_Callback")
	get_node(_drop_btn).connect("pressed", self, "OnDropPressed_Callback")
	get_node(_use_btn).connect("pressed", self, "OnUsePressed_Callback")
	
func Ok_Callback():
	BehaviorEvents.emit_signal("OnPopGUI")
	
	# reset content or we might end up with dangling references
	get_node(_mounts_node).content = []
	get_node(_cargo_node).content = []
	
	
func Cancel_Callback():
	BehaviorEvents.emit_signal("OnPopGUI")
	
	# reset content or we might end up with dangling references
	get_node(_mounts_node).content = []
	get_node(_cargo_node).content = []
	
func Init(init_param):
	_obj = init_param["object"]
	
	_obj.init_cargo()
	_obj.init_mounts()
	
	var cargo = _obj.modified_attributes.cargo.content
	var mounts = _obj.modified_attributes.mounts
	
	var mount_obj = []
	for key in mounts:
		var count = 0
		for item in mounts[key]:
			var name = key + " " + str(count+1) + " : Free"
			if not item.empty():
				var data = Globals.LevelLoaderRef.LoadJSON(item)
				name = key + " " + str(count+1) + " : " + data.name_id
			mount_obj.push_back({"name_id":name, "count":1, "key":key, "index":count})
			count += 1
	get_node(_mounts_node).content = mount_obj
	
	var current_load = _obj.get_attrib("cargo.volume_used")
	var cargo_space = _obj.get_attrib("cargo.capacity")
	if current_load == null:
		current_load = 0
	
	var color = ""
	var end_color = ""
	if current_load > cargo_space:
		color="[color=red]"
		end_color="[/color]"
	elif current_load > cargo_space * 0.9:
		color="[color=yellow]"
		end_color="[/color]"	
	
	var capacity = "(" + str(current_load) + " of " + str(cargo_space) + " m³)"
	get_node(_cargo_label).bbcode_text = color + "Cargo " + capacity + " :" + end_color
	
	var cargo_obj = []
	for item in cargo:
		var data = Globals.LevelLoaderRef.LoadJSON(item.src)
		var counting = ""
		if item.count > 1:
			counting = str(item.count) + "x "
		cargo_obj.push_back({"name_id": counting + data.name_id, "count":item.count, "key":item})
	get_node(_cargo_node).content = cargo_obj
	

func OnUsePressed_Callback():
	var selected_mounts = []
	#TODO: allow using stuff from mounts (might be a special ability of a mount)
	#for data in get_node(_mounts_node).content:
	#	if data.checked == true:
	#		dropped_mounts.push_back({"key":data.key, "index":data.index})
	
	#TODO: disable use button if selected object doesn't have "consumable" attribute
	#TODO: disable use button if more than one item selected
	var selected_cargo = []
	for item in get_node(_cargo_node).content:
		if item.checked == true:
			var data = Globals.LevelLoaderRef.LoadJSON(item.key.src)
			if "consumable" in data:
				selected_cargo.push_back(item.key.src)
	
	if selected_cargo.size() > 0:
		emit_signal("use_pressed", selected_cargo[0])
	else:
		BehaviorEvents.emit_signal("OnLogLine", "No selected item can be used like that")
	
func OnDropPressed_Callback():
	var dropped_mounts = []
	for data in get_node(_mounts_node).content:
		if data.checked == true:
			dropped_mounts.push_back({"key":data.key, "index":data.index})
			
	var dropped_cargo = []
	for data in get_node(_cargo_node).content:
		if data.checked == true:
			dropped_cargo.push_back(data.key)
			
	emit_signal("drop_pressed", dropped_mounts, dropped_cargo)
	
	# Update inventory lists
	Init({"object":_obj})