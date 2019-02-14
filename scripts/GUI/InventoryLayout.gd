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
	for data in get_node("base/vbox/Mounts").content:
		if data.checked == true:
			dropped_mounts.push_back({"key":data.key, "index":data.index})
			
	var dropped_cargo = []
	for data in get_node("base/vbox/Cargo").content:
		if data.checked == true:
			dropped_cargo.push_back(data.key)
	_callback_obj.call(_callback_method, dropped_mounts, dropped_cargo)
	
	# reset content or we might end up with dangling references
	get_node("base/vbox/Mounts").content = []
	get_node("base/vbox/Cargo").content = []
	
	
func Cancel_Callback():
	BehaviorEvents.emit_signal("OnPopGUI")
	
	# reset content or we might end up with dangling references
	get_node("base/vbox/Mounts").content = []
	get_node("base/vbox/Cargo").content = []
	
func Init(init_param):
	var obj = init_param["object"]
	_callback_obj = init_param["callback_object"]
	_callback_method = init_param["callback_method"]
	
	obj.init_cargo()
	obj.init_mounts()
	
	var cargo = obj.modified_attributes.cargo.content
	var mounts = obj.modified_attributes.mounts
	
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
	get_node("base/vbox/Mounts").content = mount_obj
	
	var current_load = obj.get_attrib("cargo.volume_used")
	var cargo_space = obj.get_attrib("cargo.capacity")
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
	get_node("base/vbox/CargoLabel").bbcode_text = color + "Cargo " + capacity + " :" + end_color
	
	var cargo_obj = []
	for item in cargo:
		var data = Globals.LevelLoaderRef.LoadJSON(item.src)
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
