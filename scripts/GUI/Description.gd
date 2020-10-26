extends "res://scripts/GUI/GUILayoutBase.gd"

var _obj : Attributes = null
var _json : Dictionary = {}
var _modified_attributes : Dictionary = {} # only for json
var _owner : Attributes = null

func _ready():
	get_node("base").connect("OnOkPressed", self, "Ok_Callback")
	get_node("base").connect("OnCancelPressed", self, "Ok_Callback")
	
	
func Ok_Callback():
	BehaviorEvents.emit_signal("OnPopGUI")
	get_node("base").disabled = true
		
	
func Init(init_param):
	get_node("base").disabled = false
	var scanner_level : int = init_param["scanner_level"]
	
	_obj = null # this is the object floating in space
	_owner = null # this is the object that's holding the _json in his inventory
	_json = {}
	_modified_attributes = {}
	if "obj" in init_param and init_param.obj != null:
		_obj = init_param["obj"]
	if "json" in init_param and init_param.json != null:
		_json = init_param["json"]
	if "modified_attributes" in init_param and init_param.modified_attributes != null:
		_modified_attributes = init_param["modified_attributes"]
	if "owner" in init_param and init_param.owner != null:
		_owner = init_param["owner"]
	
	var is_artifact = get_custom("artifact", false)
	if is_artifact:
		get_node("base").title = "[color=yellow]" + get_display_name_id() + "[/color]"
	else:
		get_node("base").title = get_display_name_id()
	
	var base_desc : String = get_custom("description.text", "")
	if base_desc != "":
		get_node("base/VBoxContainer/BaseDesc").text = Globals.mytr(base_desc)
	else:
		get_node("base/VBoxContainer/BaseDesc").text = Globals.mytr("No information available")
		get_node("base/VBoxContainer/MyItemList").Content = []
		return
		
	# need to make a copy or we end up overwriting the base attributes
	var cat_dict : Dictionary = str2var(var2str(get_custom("description", {})))
	
	var variation_src = _modified_attributes.get("selected_variation")
	if variation_src != null and not variation_src.empty():
		var variation_data : Dictionary = Globals.LevelLoaderRef.LoadJSON(variation_src)
		var extra_desc = str2var(var2str(variation_data.get("description", {})))
		for key in extra_desc.keys():
			cat_dict[key] = extra_desc[key]
		
	
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
			var formatdict := {}
			var is_valid := true
			for i in range(names.size()):
				var path_effect : Dictionary = split_effect(names[i])
				var mult := 1.0
				var bonus := 0.0
				for effect in path_effect["multipliers"]:
					mult *= Globals.EffectRef.GetMultiplierValue(_owner, get_name_id(), _modified_attributes, effect)
				for effect in path_effect["additions"]:
					bonus += Globals.EffectRef.GetBonusValue(_owner, get_name_id(), _modified_attributes, effect)
				var val = get_custom(path_effect["path"])
				if val == null and defaults.size() > 0:
					val = get_custom(defaults[min(i, defaults.size())])
				if val == null:
					is_valid = false
					
				if is_valid == false:
					continue
					
				var base_val = val
				if abs(mult - 1.0) > 0.0001:
					val *= mult
				if abs(bonus) > 0.00001:
					val += bonus
					
				var positive_good : bool = row.get("positive_good", true)
				var per_mult = 1.0
				if row.get("display_percent", false) == true:
					per_mult = 100.0
				var final_val = val
				if typeof(val) in [TYPE_INT, TYPE_REAL]:
					final_val = val*per_mult
				if (base_val > val and positive_good == false) or (base_val < val and positive_good == true):
					val = "[color=lime]" + str(final_val) + "[/color]"
				elif base_val != val:
					val = "[color=red]" + str(final_val) + "[/color]"
				else:
					val = str(final_val)
				formatdict[names[i]] = val
			
			if formatdict.size() > 0:
				if not "translate_value" in row or row.translate_value == true:
					row.value = Globals.mytr2(row.value, formatdict)
				else:
					row.value = row.value.format(formatdict)
			elif not "translate_value" in row or row.translate_value == true:
				row.value = Globals.mytr(row.value)
			
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
	
func split_effect(txt : String) -> Dictionary:
	var multipliers := []
	var additions := []
	var path := ""
	
	var accum := ""
	var cur_char := ""
	for c in txt:
		if c == '*' or c == '+':
			if cur_char == '*' and accum.length() > 0:
				multipliers.push_back(accum)
			elif cur_char == '+' and accum.length() > 0:
				additions.push_back(accum)
			elif accum.length() > 0:
				path = accum
			accum = ""
			cur_char = c
		else:
			accum += c
			
	if accum.length() > 0:
		if cur_char == '*' and accum.length() > 0:
			multipliers.push_back(accum)
		elif cur_char == '+' and accum.length() > 0:
			additions.push_back(accum)
		elif accum.length() > 0:
			path = accum
			
	return {"path":path, "multipliers":multipliers, "additions":additions}
	
func get_custom(path, default=null):
	if _obj != null:
		return _obj.get_attrib(path, default)
	else:
		return Globals.get_data(_json, path, default)
		
func get_name_id():
	if _obj != null:
		return _obj.get_attrib("name_id")
	else:
		return Globals.get_data(_json, "name_id", "")
		
func get_display_name_id():
	if _obj != null:
		return Globals.EffectRef.get_object_display_name(_obj)
	else:
		return Globals.EffectRef.get_display_name(_json, _modified_attributes)
