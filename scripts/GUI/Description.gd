extends "res://scripts/GUI/GUILayoutBase.gd"

var _obj : Attributes = null
var _json : Dictionary = {}


func _ready():
	get_node("base").connect("OnOkPressed", self, "Ok_Callback")
	get_node("base").connect("OnCancelPressed", self, "Ok_Callback")
	
	
func Ok_Callback():
	BehaviorEvents.emit_signal("OnPopGUI")
		
	
func Init(init_param):
	var scanner_level : int = init_param["scanner_level"]
	
	if "obj" in init_param and init_param.obj != null:
		_obj = init_param["obj"]
	if "json" in init_param and init_param.json != null:
		_json = init_param["json"]
	
	get_node("base").title = get_custom("name_id")
	
	var base_desc : String = get_custom("description.text")
	if base_desc != null:
		get_node("base/VBoxContainer/BaseDesc").text = base_desc
	else:
		get_node("base/VBoxContainer/BaseDesc").text = "No information available"
		get_node("base/VBoxContainer/MyItemList").Content = []
		return
		
	# need to make a copy or we end up overwriting the base attributes
	var cat_dict : Dictionary = str2var(var2str(get_custom("description")))
	var final_list := []
	for key in cat_dict:
		if key == "text" or scanner_level < cat_dict[key].min_level:
			continue
		
		# we know the last category was empty if we're about to add a header and the previous row is also a header
		# remove it
		if final_list.size() > 0 and "header" in final_list[-1] and final_list[-1].header == true:
			final_list.pop_back()
		final_list.push_back({"name":key, "header":true})
		for row in cat_dict[key].fields:
			var names : Array = get_names(row.value)
			var defaults := []
			if "default" in row:
				defaults = get_names(row.default)
			var i := 0
			var formatdict := {}
			var is_valid := true
			for i in range(names.size()):
				var val = get_custom(names[i])
				if val == null and defaults.size() > 0:
					val = get_custom(defaults[min(i, defaults.size())])
				if val == null:
					is_valid = false
				formatdict[names[i]] = val
			
			if formatdict.size() > 0:
				row.value = row.value.format(formatdict)
			
			if is_valid == true:
				final_list.push_back(row)
		
		# remove last header if empty
		if "header" in final_list[-1] and final_list[-1].header == true:
			final_list.pop_back()
			
	get_node("base/VBoxContainer/MyItemList").Content = final_list
	
func get_names(txt) -> Array:
	if not "{" in txt:
		return []
	
	var res := []
	var lpad := 0
	var start : int
	var end : int
	var id : String
	while lpad >= 0:
		start = txt.find("{", lpad)
		end = txt.find("}", lpad+1)
		if start >= 0 and end >= 0:
			id = txt.substr(start+1, end-start-1)
			res.push_back(id)
		lpad = end
		
	return res
	
func get_custom(path):
	if _obj != null:
		return _obj.get_attrib(path)
	else:
		return Globals.get_data(_json, path)