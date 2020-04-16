extends "res://scripts/GUI/GUILayoutBase.gd"

func _ready():
	get_node("base").connect("OnOkPressed", self, "Ok_Callback")
	get_node("base").connect("OnCancelPressed", self, "Cancel_Callback")
	
	# DEBUG TEST
	var data = [
		{"color":Color(0.58,0.58,0.0), "title":"CMO", "name":"Eric 'doc' Brown", "status":"MIA", "log":"Deserter, ran for the human colony on Homeworld 3."},
		{"color":Color(0.1,0.1,0.1), "title":"XO", "name":"Uptight mcShortypants", "status":"Active", "log":"Doing a good job"},
		{"color":Color(0.1,0.1,0.1), "title":"Helms", "name":"Stradivarius Rex", "status":"Active", "log":"Doing a good job"},
		{"color":Color(0.1,0.1,0.1), "title":"Cook", "name":"Xileen", "status":"VIP", "log":"Food is getting hard to come by. We need someone with knowledge of the indegenous life in this area."},
		{"color":Color(0.4,0.0,0.0), "title":"CSO", "name":"Leonard Grayson", "status":"KIA", "log":"Recommendation : Post-humorous medal of valor for putting his life on the line for the crew."},
		{"color":Color(0.0,0.4,0.0), "title":"CE", "name":"Jerg Hive Mind", "status":"Medal", "log":"Recommendation : Medal of Valor for successfully escaping a Jerg Mothership alive!"},
		{"color":Color(0.0,0.4,0.0), "title":"CWO", "name":"Hideo Ishii", "status":"Medal", "log":"Exceptional shooting skill"}
	]
	get_node("base/Content/Control/MyItemList").Content = data

func Ok_Callback():
	BehaviorEvents.emit_signal("OnPopGUI")
	get_node("base").disabled = true
	
	
func Cancel_Callback():
	BehaviorEvents.emit_signal("OnPopGUI")
	get_node("base").disabled = true
	
func Init(init_param):
	get_node("base").disabled = false
	
	get_node("base/Content/Control/MyItemList").Content = str2var(var2str(init_param["crew"]))
