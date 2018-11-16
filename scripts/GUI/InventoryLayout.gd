extends "res://scripts/GUI/GUILayoutBase.gd"

# class member variables go here, for example:
# var a = 2
# var b = "textvar"

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
	
func Cancel_Callback():
	BehaviorEvents.emit_signal("OnPopGUI")
	
func Init(init_param):
	var cargo = init_param.base_attributes.cargo.content
	var mounts = init_param.base_attributes.mounts
	if init_param.modified_attributes.has("cargo"):
		cargo = init_param.modified_attributes.cargo.content
	if init_param.modified_attributes.has("mounts"):
		mounts = init_param.modified_attributes.mounts
	
	var mount_obj = []
	for key in mounts:
		var data = Globals.LevelLoaderRef.LoadJSON(mounts[key])
		var name = key + " : " + data.name_id
		mount_obj.push_back({"name_id":name, "count":1})
	get_node("base/vbox/Mounts").content = mount_obj
	
	var current_load = 0
	if init_param.modified_attributes.has("cargo"):
		current_load = init_param.modified_attributes.cargo.capacity
	var capacity = "(" + str(current_load) + " of " + str(init_param.base_attributes.cargo.capacity) + " m³)"
	get_node("base/vbox/CargoLabel").bbcode_text = "Cargo " + capacity + " :"
	
	var cargo_obj = []
	for item in cargo:
		var data = Globals.LevelLoaderRef.LoadJSON(item.src)
		var counting = ""
		if item.count > 1:
			counting = str(item.count) + "x "
		cargo_obj.push_back({"name_id": counting + data.name_id, "count":item.count})
	get_node("base/vbox/Cargo").content = cargo_obj
	
	#get_node("base").content = result_string

#func _process(delta):
#	# Called every frame. Delta is time since last frame.
#	# Update game logic here.
#	pass
