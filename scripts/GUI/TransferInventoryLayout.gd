extends "res://scripts/GUI/GUILayoutBase.gd"

var _callback_obj = null
var _callback_method = ""

func _ready():
	get_node("base").connect("OnOkPressed", self, "Ok_Callback")
	get_node("base").connect("OnCancelPressed", self, "Cancel_Callback")
	
	#var obj = []
	#for i in range(5):
	#	var name = "A B C D E F G HIJKLMN OPQRST UVWXYZ SOMETHING SOMETHING Item #" + str(i)
	#	obj.push_back({"name_id":name, "count":3})
	
	#get_node("base/vbox/Cargo").content = obj
	#get_node("base/vbox/Mounts").content = obj
	
func Ok_Callback():
	BehaviorEvents.emit_signal("OnPopGUI")
	if _callback_obj == null:
		return
	
	var dropped_mounts = []
	#for data in get_node("base/vbox/Mounts").content:
	#	if data.checked == true:
	#		dropped_mounts.push_back(data.key)
			
	var dropped_cargo = []
	#for data in get_node("base/vbox/Cargo").content:
	#	if data.checked == true:
	#		dropped_cargo.push_back(data.key)
	_callback_obj.call(_callback_method, dropped_mounts, dropped_cargo)
	
	# reset content or we might end up with dangling references
	get_node("base/HBoxContainer/LShip/Mounts").content = []
	get_node("base/HBoxContainer/LShip/Cargo").content = []
	get_node("base/HBoxContainer/RShip/Mounts").content = []
	get_node("base/HBoxContainer/RShip/Cargo").content = []
	
	
func Cancel_Callback():
	BehaviorEvents.emit_signal("OnPopGUI")
	
	# reset content or we might end up with dangling references
	get_node("base/HBoxContainer/LShip/Mounts").content = []
	get_node("base/HBoxContainer/LShip/Cargo").content = []
	get_node("base/HBoxContainer/RShip/Mounts").content = []
	get_node("base/HBoxContainer/RShip/Cargo").content = []
	
func Init(init_param):
	var obj1 = init_param["object1"]
	var obj2 = init_param["object2"]
	_callback_obj = init_param["callback_object"]
	_callback_method = init_param["callback_method"]
	
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
	get_node("base/HBoxContainer/LShip/Mounts").content = mount_obj
	
	mount_obj = []
	for key in mounts2:
		mount_obj.push_back({"mount_key":key, "src_key":mounts2[key]})
	get_node("base/HBoxContainer/RShip/Mounts").content = mount_obj
	
	var current_load = obj1.get_attrib("cargo.volume_used")
	if current_load == null:
		current_load = 0
	var capacity = "(" + str(current_load) + " of " + str(obj1.get_attrib("cargo.capacity")) + " m³)"
	get_node("base/HBoxContainer/LShip/CargoLabel").bbcode_text = "Cargo " + capacity + " :"
	
	current_load = obj2.get_attrib("cargo.volume_used")
	if current_load == null:
		current_load = 0
	capacity = "(" + str(current_load) + " of " + str(obj2.get_attrib("cargo.capacity")) + " m³)"
	get_node("base/HBoxContainer/RShip/CargoLabel").bbcode_text = "Cargo " + capacity + " :"
	
	var cargo_obj = []
	for item in cargo1:
		cargo_obj.push_back({"amount":item.count, "src_key":item.src})
	get_node("base/HBoxContainer/LShip/Cargo").content = cargo_obj
	
	cargo_obj = []
	for item in cargo2:
		cargo_obj.push_back({"amount":item.count, "src_key":item.src})
	get_node("base/HBoxContainer/RShip/Cargo").content = cargo_obj
	
	get_node("base/RShipName").bbcode_text = obj2.get_attrib("name_id")
	get_node("base").title = obj1.get_attrib("name_id")
	

func _on_TakeAll_pressed():
	var rnode = get_node("base/HBoxContainer/RShip")
	var lnode = get_node("base/HBoxContainer/LShip")
	
	_transfer_all(rnode, lnode)


func _on_PutAll_pressed():
	var rnode = get_node("base/HBoxContainer/RShip")
	var lnode = get_node("base/HBoxContainer/LShip")
	
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