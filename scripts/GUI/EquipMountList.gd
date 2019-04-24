extends "res://scripts/GUI/GUILayoutBase.gd"

var _callback_obj = null
var _callback_method = ""
var _ref_obj = null

onready var _mounts = get_node("base/vbox/MountsV2")

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
	var selected_mount = null
	var selected_index = null
	for data in _mounts.Content:
		if data.selected == true:
			selected_mount = data.key
			selected_index = data._index
			break
	
	BehaviorEvents.emit_signal("OnPopGUI")
	BehaviorEvents.emit_signal("OnPushGUI", "EquipItemList", {"object":_ref_obj, "selected_mount":selected_mount, "selected_index":selected_index, "callback_object":_callback_obj, "callback_method":_callback_method})

	# reset content or we might end up with dangling references
	_mounts.Content = []
	
	
func Cancel_Callback():
	BehaviorEvents.emit_signal("OnPopGUI")
	
	# reset content or we might end up with dangling references
	_mounts.Content = []
	
func Init(init_param):
	var obj = init_param["object"]
	_ref_obj = obj
	_callback_obj = init_param["callback_object"]
	_callback_method = init_param["callback_method"]
	
	obj.init_cargo()
	obj.init_mounts()
	
	var mounts = obj.modified_attributes.mounts
	
	var mount_obj = []
	for key in mounts:
		var count = 0
		for item in mounts[key]:
			var name = key + " " + str(count + 1) + " : Free"
			if not item.empty():
				var data = Globals.LevelLoaderRef.LoadJSON(item)
				name = key + " " + str(count + 1) + " : " + data.name_id
			mount_obj.push_back({"name_id":name, "count":1, "key":key, "_index":count})
			count += 1
	_mounts.Content = mount_obj
	

#func _process(delta):
#	# Called every frame. Delta is time since last frame.
#	# Update game logic here.
#	pass
