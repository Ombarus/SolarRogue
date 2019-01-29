extends "res://scripts/GUI/GUILayoutBase.gd"

var _callback_obj = null
var _callback_method = ""

var _lobj = null
var _robj = null

const L_BASE_PATH = "base/HBoxContainer/LShip"
const R_BASE_PATH = "base/HBoxContainer/RShip"

func _ready():
	get_node("base").connect("OnOkPressed", self, "Ok_Callback")
	get_node("base").connect("OnCancelPressed", self, "Cancel_Callback")
	
	get_node(L_BASE_PATH + "/Mounts").connect("OnChoiceDragAndDrop", self, "OnChoiceDragAndDrop_Callback")
	get_node(R_BASE_PATH + "/Mounts").connect("OnChoiceDragAndDrop", self, "OnChoiceDragAndDrop_Callback")
	
	get_node(L_BASE_PATH + "/Cargo").connect("OnChoiceDragAndDrop", self, "OnChoiceDragAndDrop_Callback")
	get_node(R_BASE_PATH + "/Cargo").connect("OnChoiceDragAndDrop", self, "OnChoiceDragAndDrop_Callback")
	
	#get_node(L_BASE_PATH + "/Mounts/List/Row/Choice").connect("toggled", self, ")
	
	#var debug_mounts = []
	#for i in range(5):
	#	debug_mounts.push_back({"mount_key":"small weapon module", "src_key":"data/json/items/weapons/missile_launcher_mk1.json"})
		
	#var debug_cargo = []
	#for i in range(5):
	#	debug_cargo.push_back({"amount":i, "src_key":"data/json/items/weapons/missile.json"})
	
	#get_node(L_BASE_PATH + "/Cargo").content = debug_cargo
	#get_node(L_BASE_PATH + "/Mounts").content = debug_mounts
	
func Ok_Callback():
	BehaviorEvents.emit_signal("OnPopGUI")
	if _callback_obj == null:
		return
	
	var rnode = get_node(R_BASE_PATH)
	var lnode = get_node(L_BASE_PATH)
	
	var l_new_mounts = []
	var r_new_mounts = []
	for data in lnode.get_node("Mounts").content:
		l_new_mounts.push_back({"mount_key":data.mount_key, "src_key":data.src_key})
	for data in rnode.get_node("Mounts").content:
		r_new_mounts.push_back({"mount_key":data.mount_key, "src_key":data.src_key})
			
	var l_new_cargo = []
	var r_new_cargo = []
	for data in lnode.get_node("Cargo").content:
		l_new_cargo.push_back({"src_key":data.src_key, "amount":data.amount})
	for data in rnode.get_node("Cargo").content:
		r_new_cargo.push_back({"src_key":data.src_key, "amount":data.amount})

	_callback_obj.call(_callback_method, _lobj, l_new_mounts, l_new_cargo, _robj, r_new_mounts, r_new_cargo)
	
	# reset content or we might end up with dangling references
	get_node(L_BASE_PATH + "/Mounts").content = []
	get_node(L_BASE_PATH + "/Cargo").content = []
	get_node(R_BASE_PATH + "/Mounts").content = []
	get_node(R_BASE_PATH + "/Cargo").content = []
	
	
func Cancel_Callback():
	BehaviorEvents.emit_signal("OnPopGUI")
	
	# reset content or we might end up with dangling references
	get_node(L_BASE_PATH + "/Mounts").content = []
	get_node(L_BASE_PATH + "/Cargo").content = []
	get_node(R_BASE_PATH + "/Mounts").content = []
	get_node(R_BASE_PATH + "/Cargo").content = []
	
func Init(init_param):
	var obj1 = init_param["object1"]
	var obj2 = init_param["object2"]
	_callback_obj = init_param["callback_object"]
	_callback_method = init_param["callback_method"]
	
	_lobj = obj1
	_robj = obj2
	
	obj1.init_cargo()
	obj1.init_mounts()
	obj2.init_cargo()
	obj2.init_mounts()
	
	var cargo1 = obj1.get_attrib("cargo.content")
	var mounts1 = obj1.get_attrib("mounts")
	var cargo2 = obj2.get_attrib("cargo.content")
	var mounts2 = obj2.get_attrib("mounts")
	
	var mount_obj = []
	for key in mounts1:
		mount_obj.push_back({"mount_key":key, "src_key":mounts1[key]})
	get_node(L_BASE_PATH + "/Mounts").content = mount_obj
	
	mount_obj = []
	for key in mounts2:
		mount_obj.push_back({"mount_key":key, "src_key":mounts2[key]})
	get_node(R_BASE_PATH + "/Mounts").content = mount_obj
	
	var current_load = obj1.get_attrib("cargo.volume_used")
	if current_load == null:
		current_load = 0
	var capacity = "(" + str(current_load) + " of " + str(obj1.get_attrib("cargo.capacity")) + " m³)"
	get_node(L_BASE_PATH + "/CargoLabel").bbcode_text = "Cargo " + capacity + " :"
	
	current_load = obj2.get_attrib("cargo.volume_used")
	if current_load == null:
		current_load = 0
	capacity = "(" + str(current_load) + " of " + str(obj2.get_attrib("cargo.capacity")) + " m³)"
	get_node(R_BASE_PATH + "/CargoLabel").bbcode_text = "Cargo " + capacity + " :"
	
	var cargo_obj = []
	for item in cargo1:
		cargo_obj.push_back({"amount":item.count, "src_key":item.src})
	get_node(L_BASE_PATH + "/Cargo").content = cargo_obj
	
	cargo_obj = []
	for item in cargo2:
		cargo_obj.push_back({"amount":item.count, "src_key":item.src})
	get_node(R_BASE_PATH + "/Cargo").content = cargo_obj
	
	get_node("base/RShipName").bbcode_text = obj2.get_attrib("name_id")
	get_node("base").title = obj1.get_attrib("name_id")
	
	get_node(L_BASE_PATH + "/Mounts").connect("OnChoiceSelectionChanged", self, "LMountsChanged_Callback")

func OnChoiceDragAndDrop_Callback(container_src, container_dst, content_index_src):
	var new_src = []
	var new_dst = []
	var old_src = container_src.get_content()
	var old_dst = container_dst.get_content()
	var src_data = old_src[content_index_src]
	var is_src_mount = "mount_key" in old_src[0]
	var is_dst_mount = "mount_key" in old_dst[0]
	var dst_data_copy = null
	var src_json = Globals.LevelLoaderRef.LoadJSON(src_data.src_key)
	var is_stackable = "stackable" in src_json.equipment and src_json.equipment.stackable == true
	
	# Remake set array for the ship that receives the item
	for item in old_dst:
		if is_dst_mount == true:
			new_dst.push_back({"mount_key":item.mount_key, "src_key":item.src_key})
		else:
			new_dst.push_back({"src_key":item.src_key, "amount":item.amount})
	
	# Update the drag destination to add whatever was received
	if is_dst_mount == true:
		var lookup_mount = ""
		if is_src_mount:
			lookup_mount = src_data.mount_key
		else:
			lookup_mount = src_json.equipment.slot
		# This could probably done in a single loop (create the new_dst while modifying it at the same time)
		# But my brain refuses to fathom all the possible conditions
		# (mount to mount, mount to cargo, cargo to mount, selected to not selected, etc.)
		# fuck performance, anyway, recreating all the nodes after the drag & drop is definitly more expensive
		for item in new_dst:
			if item.mount_key == lookup_mount:
				dst_data_copy = item.src_key
				item.src_key = src_data.src_key
				break
	else:
		var found = false
		if is_stackable == true:
			for item in new_dst:
				if item.src_key == src_data.src_key:
					item.amount += 1
					found = true
					break
		if found == false:
			new_dst.push_back({"src_key":src_data.src_key, "amount":1})
	
	# Remake the drag source that will lose an item	
	for item in old_src:
		if is_src_mount == true:
			new_src.push_back({"mount_key":item.mount_key, "src_key":item.src_key})
		else:
			new_src.push_back({"src_key":item.src_key, "amount":item.amount})
	
	# Update the array to remove whatever we sent to destination	
	if is_src_mount == true:
		for item in new_src:
			if item.mount_key == src_data.mount_key:
				if dst_data_copy == null:
					item.src_key = ""
				else:
					item.src_key = dst_data_copy
	else:
		var index_to_remove = -1
		for i in range(new_src.size()):
			if new_src[i].src_key == src_data.src_key and new_src[i].amount > 1 and is_dst_mount == true:
				new_src[i].amount -= 1
				break
			elif new_src[i].src_key == src_data.src_key:
				index_to_remove = i
				break
		if index_to_remove >= 0:
			new_src.remove(index_to_remove)
	
			
	container_dst.content = new_dst
	container_src.content = new_src
	
func _on_TakeAll_pressed():
	var rnode = get_node(R_BASE_PATH)
	var lnode = get_node(L_BASE_PATH)
	
	_transfer_all(rnode, lnode)


func _on_PutAll_pressed():
	var rnode = get_node(R_BASE_PATH)
	var lnode = get_node(L_BASE_PATH)
	
	_transfer_all(lnode, rnode)
	
func _transfer_all(from, to):
	var cargo_content = to.get_node("Cargo").content
	
	var take_mounts = []
	for data in from.get_node("Mounts").content:
		if data.src_key == null or data.src_key.empty() == true:
			take_mounts.push_back({"mount_key":data.mount_key, "src_key":""})
			continue
		var jsondata = Globals.LevelLoaderRef.LoadJSON(data.src_key)
		var added = false
		for cargo_data in cargo_content:
			if cargo_data.src_key in data.src_key:
				var cargojsondata = Globals.LevelLoaderRef.LoadJSON(cargo_data.key)
				if "stackable" in cargojsondata.equipment and cargojsondata.equipment.stackable == true:
					cargo_data.amount += 1
					added = true
					break
		if added == false:
			cargo_content.push_back({"src_key":data.src_key, "amount":1})
		take_mounts.push_back({"mount_key":data.mount_key, "src_key":""})
	from.get_node("Mounts").content = take_mounts
	
	var take_cargo = []
	for data in from.get_node("Cargo").content:
		var jsondata = Globals.LevelLoaderRef.LoadJSON(data.src_key)
		var added = false
		#TODO: Check cargo space
		for cargo_data in cargo_content:
			if cargo_data.src_key in data.src_key:
				var cargojsondata = Globals.LevelLoaderRef.LoadJSON(cargo_data.src_key)
				if "stackable" in cargojsondata.equipment and cargojsondata.equipment.stackable == true:
					cargo_data.amount += data.amount
					added = true
					break
		if added == false:
			cargo_content.push_back({"src_key":data.src_key, "amount":data.amount})
	from.get_node("Cargo").content = take_cargo
	to.get_node("Cargo").content = cargo_content