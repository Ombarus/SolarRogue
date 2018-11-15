extends "res://scripts/GUI/GUILayoutBase.gd"

# class member variables go here, for example:
# var a = 2
# var b = "textvar"

func _ready():
	get_node("base").connect("OnOkPressed", self, "Ok_Callback")
	get_node("base").connect("OnCancelPressed", self, "Cancel_Callback")
	
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
	
	var result_string = ""
	result_string = "[b]Mounts :[/b]\n"
	for key in mounts:
		var data = Globals.LevelLoaderRef.LoadJSON(mounts[key])
		result_string += key + " : " + data.name_id + "\n"
	
	var current_load = 0
	if init_param.modified_attributes.has("cargo"):
		current_load = init_param.modified_attributes.cargo.capacity
	var capacity = "(" + str(current_load) + " of " + str(init_param.base_attributes.cargo.capacity) + " m³)"
	result_string += "\n[b]Cargo " + capacity + " :[/b]\n"
	for item in cargo:
		var data = Globals.LevelLoaderRef.LoadJSON(item.src)
		var counting = ""
		if item.count > 1:
			counting = str(item.count) + "x "
		result_string += counting + data.name_id + "\n"
		
	get_node("base").content = result_string

#func _process(delta):
#	# Called every frame. Delta is time since last frame.
#	# Update game logic here.
#	pass
