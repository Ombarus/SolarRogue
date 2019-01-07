extends "res://scripts/GUI/GUILayoutBase.gd"

var _callback_obj = null
var _callback_method = ""

func _ready():
	get_node("base").connect("OnOkPressed", self, "Ok_Callback")
	
	#var obj = []
	#for i in range(5):
	#	var name = "A B C D E F G HIJKLMN OPQRST UVWXYZ SOMETHING SOMETHING Item #" + str(i)
	#	obj.push_back({"name_id":name, "count":3})
	
	#get_node("base/vbox/Cargo").content = obj
	#get_node("base/vbox/Mounts").content = obj
	
func Ok_Callback():
	BehaviorEvents.emit_signal("OnPopGUI")
	_callback_obj.call(_callback_method)
	#BehaviorEvents.emit_signal("OnPlayerDeath")
	
	
func Init(init_param):
	var text = init_param["text"]
	_callback_obj = init_param["callback_object"]
	_callback_method = init_param["callback_method"]
	get_node("base/Content").bbcode_text = text
	

#func _process(delta):
#	# Called every frame. Delta is time since last frame.
#	# Update game logic here.
#	pass
