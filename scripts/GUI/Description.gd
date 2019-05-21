extends "res://scripts/GUI/GUILayoutBase.gd"

func _ready():
	get_node("base").connect("OnOkPressed", self, "Ok_Callback")
	get_node("base").connect("OnCancelPressed", self, "Ok_Callback")
	
	
func Ok_Callback():
	BehaviorEvents.emit_signal("OnPopGUI")
		
	
func Init(init_param):
	var obj : Attributes = init_param["obj"]
	var scanner_level : int = init_param["scanner_level"]
	var base_desc : String = obj.get_attrib("description.text")
	if base_desc != null:
		get_node("base/VBoxContainer/BaseDesc").text = base_desc
	var cat_dict : Dictionary = obj.get_attrib("description")
	var final_list := []
	for key in cat_dict:
		if key == "text" or scanner_level < cat_dict[key].min_level:
			continue
		
		final_list.push_back({"name":key, "header":true})
		for row in cat_dict[key].fields:
			if "{" in row.value:
				var start : int = row.value.find("{")
				var end : int = row.value.rfind("}")
				var id = row.value.substr(start+1, end-start-1)
				var val = obj.get_attrib(id)
				row.value = row.value.format({id:val})
			final_list.push_back(row)
			
	get_node("base/VBoxContainer/MyItemList").Content = final_list
	
