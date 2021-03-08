extends "res://scripts/GUI/ItemList/DefaultRow.gd"

export(Theme) var full_selection = null
export(Theme) var partial_selection = null
export(Theme) var normal_theme = preload("res://data/theme/default_ui_text.tres")

onready var _toggle = get_node("Toggle")

# data {"name_id":"Missile', "icon": {"texture":<path>, "region":[x,y,w,h]}}
func set_row_data(data):
	_metadata = data
	if _toggle == null:
		return
		
	if _metadata.group != null:
		_toggle.group = _metadata.group
		
	var icon_path : String = Globals.get_data(data, "icon.texture", "")
	if icon_path != "":
		icon_path = Globals.clean_path(icon_path)
		var icon_region : Array = Globals.get_data(data, "icon.region", [])
		var t := AtlasTexture.new()
		t.atlas = load(icon_path)
		if icon_region.size() > 0:
			t.region = Rect2(icon_region[0], icon_region[1], icon_region[2], icon_region[3])
		get_node("HBoxContainer/Wrapper/TextureRect").texture = t
	else:
		get_node("HBoxContainer/Wrapper/TextureRect").texture = null
		
	get_node("HBoxContainer/Direction").text = Globals.mytr(data["direction"])
	select(0, true)
		
	
func get_row_data():
	#_metadata["selected"] = _toggle.pressed
	return _metadata

func _ready():
	_toggle.connect("pressed", self, "pressed_callback")
	if _metadata != null:
		set_row_data(_metadata)
	
func pressed_callback():
	if _toggle.pressed == false:
		select(0)
	elif _metadata["count"] == 1:
		select(1)
	else:
		#select(2) # temp while I test outside "main"
		_toggle.pressed = false
		BehaviorEvents.emit_signal("OnPushGUI", "HowManyDiag", {
			"callback_object":self, 
			"callback_method":"select", 
			"min_value":1, 
			"max_value":_metadata["count"]})
			
func UpdateContent(data):
	_metadata = data
	var num : int = 0
	if "selected" in _metadata:
		num = _metadata["selected"]
	select(num, true)
	
func select(num, skip_event=false):
	if num == 0:
		if _metadata["count"] > 1:
			get_node("HBoxContainer/Name").text = str(_metadata["count"]) + "x " + Globals.mytr(_metadata.name_id)
		else:
			get_node("HBoxContainer/Name").text = Globals.mytr(_metadata.name_id)
		self.theme = normal_theme
		_toggle.pressed = false
		_metadata["selected"] = 0
	elif num == _metadata["count"]:
		_toggle.pressed = true
		get_node("HBoxContainer/Name").text = "✓ " + Globals.mytr(_metadata.name_id)
		self.theme = full_selection
		_metadata["selected"] = _metadata["count"]
	else:
		_toggle.pressed = true
		get_node("HBoxContainer/Name").text = str(num) + "/" + str(_metadata["count"]) + "x " + Globals.mytr(_metadata.name_id)
		self.theme = partial_selection
		_metadata["selected"] = num
		
	if skip_event == false:
		_metadata.origin.bubble_selection_changed()
	
