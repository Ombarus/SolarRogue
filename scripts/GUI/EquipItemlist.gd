extends "res://scripts/GUI/GUILayoutBase.gd"

var _callback_obj = null
var _callback_method = ""
var _mount_to = null
var _mount_index = null

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
	
	var mount_item = null
	for data in get_node("base/vbox/Cargo").content:
		if data.checked == true:
			mount_item = data.key
			
			
	if mount_item != null:
		_callback_obj.call(_callback_method, mount_item.src, _mount_to, _mount_index)
	
	# reset content or we might end up with dangling references
	get_node("base/vbox/Cargo").content = []
	
	
func Cancel_Callback():
	BehaviorEvents.emit_signal("OnPopGUI")
	
	# reset content or we might end up with dangling references
	get_node("base/vbox/Cargo").content = []
	
func Init(init_param):
	var obj = init_param["object"]
	_callback_obj = init_param["callback_object"]
	_callback_method = init_param["callback_method"]
	_mount_to = init_param["selected_mount"]
	_mount_index = init_param["selected_index"]
	
	
	obj.init_cargo()
	obj.init_mounts()
	
	var cargo = obj.modified_attributes.cargo.content
	
	var current_load = obj.get_attrib("cargo.volume_used")
	if current_load == null:
		current_load = 0
	var capacity = "(" + str(current_load) + " of " + str(obj.get_attrib("cargo.capacity")) + " m³)"
	get_node("base/vbox/CargoLabel").bbcode_text = "Cargo " + capacity + " :"
	
	var cargo_obj = []
	#TODO: filter based on selected _mount_to
	for item in cargo:
		var data = Globals.LevelLoaderRef.LoadJSON(item.src)
		if not "equipment" in data or not "slot" in data.equipment or data.equipment.slot != _mount_to:
			continue
		var counting = ""
		if item.count > 1:
			counting = str(item.count) + "x "
		cargo_obj.push_back({"name_id": counting + data.name_id, "count":item.count, "key":item})
	get_node("base/vbox/Cargo").content = cargo_obj
	
	#get_node("base").content = result_string

#func _process(delta):
#	# Called every frame. Delta is time since last frame.
#	# Update game logic here.
#	pass
