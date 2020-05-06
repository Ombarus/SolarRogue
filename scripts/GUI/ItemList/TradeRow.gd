extends "res://scripts/GUI/ItemList/DefaultRow.gd"

export(Theme) var normal_theme = preload("res://data/theme/default_ui_text.tres")
export(Theme) var header_theme = preload("res://data/theme/header_ui_text.tres")

export(Theme) var full_selection = null
export(Theme) var partial_selection = null

onready var _toggle = get_node("BtnWrap/Toggle")
var _locked = false

#func _ready():
#	_toggle.connect("pressed", self, "_on_Toggle_toggled")
	#var data = {"icon": { "texture":"data/textures/space-sprite.png", "region":[256,128,128,128] }, "name_id":"Matter-to-Energy Converter MK2", "equipped":false, "header":true}
	#set_row_data(data)

# data = {"icon": { "texture":<path>, "region":[x,y,w,h] }, "name_id":<name>, "equipped":false, "header":false}
func set_row_data(data):
	_metadata = data
	_metadata["self"] = self
	_metadata["selected"] = false
	if data.group != null:
		get_node("BtnWrap/Toggle").group = data.group
		
	if not "max" in _metadata:
		_metadata["max"] = 1
		
	var icon_path : String = Globals.get_data(data, "icon.texture", "")
	if icon_path != null and icon_path != "":
		icon_path = Globals.clean_path(icon_path)
		var icon_region : Array = Globals.get_data(data, "icon.region", [])
		var t := AtlasTexture.new()
		t.atlas = load(icon_path)
		if icon_region.size() > 0:
			t.region = Rect2(icon_region[0], icon_region[1], icon_region[2], icon_region[3])
		get_node("BtnWrap/HBoxContainer/Icon").texture = t
	else:
		get_node("BtnWrap/HBoxContainer/Icon").texture = null
		
	if "header" in data and data.header == true:
		self.theme = header_theme
		get_node("BtnWrap/Toggle").visible = false
		get_node("BtnWrap/HBoxContainer/Icon").visible = false
		if _metadata.has("display_name_id") == true:
			get_node("BtnWrap/HBoxContainer/Wrap/Name").text = _metadata["display_name_id"]
		else:
			get_node("BtnWrap/HBoxContainer/Wrap/Name").text = Globals.mytr(_metadata["name_id"])
		#get_node("Equipped").visible = false
	else:
		self.theme = normal_theme
		get_node("BtnWrap/HBoxContainer/Icon").visible = true
		select(0, true)
	
	if _metadata.origin.is_connected("OnSelectionChanged", self, "OnSelectionChanged_Callback"):
		_metadata.origin.disconnect("OnSelectionChanged", self, "OnSelectionChanged_Callback")
	

func UpdateSelection():
	if _toggle.pressed == false and (not "header" in _metadata or not _metadata.header == true):
		get_node("BtnWrap/HBoxContainer/Wrap/Name").add_color_override("default_color", Color(1,1,1))

func _on_Toggle_toggled(button_pressed):
	#if _locked == true:
	#	return
	# drag and dropping a selected node would crash because we duplicate the node for creating
	# the drag preview and it'll trigger a bunch of selection refresh on fake data
	# only way I could think of stopping it is to check if _metadata is null
	if _metadata == null:
		return
	#get_node("BtnWrap/HBoxContainer/Wrap/Name").add_color_override("default_color", Color(0,0,0))
	if button_pressed == false or (button_pressed == true and _metadata["count"] > 0):
		_toggle.pressed = false
		select(0)
	elif _metadata.max == 1:
		select(1)
	else:
		#_toggle.pressed = false
		BehaviorEvents.emit_signal("OnPushGUI", "HowManyDiag", {
			"callback_object":self, 
			"callback_method":"select", 
			"min_value":1, 
			"max_value":_metadata.max})

func select(num, skip_event=false):
	_locked = true
	if num == 0:
		var counting_str = ""
		if _metadata.max > 1:
			counting_str = str(_metadata.max)+"x "
		if _metadata.has("display_name_id") == true:
			get_node("BtnWrap/HBoxContainer/Wrap/Name").text = counting_str + _metadata["display_name_id"]
		else:
			get_node("BtnWrap/HBoxContainer/Wrap/Name").text = counting_str + Globals.mytr(_metadata["name_id"])
		self.theme = normal_theme
		_metadata["count"] = 0
		if "disabled" in _metadata and _metadata.disabled == true:
			get_node("HBoxContainer/Wrapper/Count").visible = false
			get_node("BtnWrap/HBoxContainer/Wrap/Name").add_color_override("font_color", Color(1,0,0,1))
			_toggle.visible = false
	elif num == _metadata.max:
		var counting_str = ""
		if _metadata.max > 1:
			counting_str = "✓ "
		#_toggle.pressed = true
		if "display_name_id" in _metadata:
			get_node("BtnWrap/HBoxContainer/Wrap/Name").text = counting_str + _metadata.display_name_id
		else:
			get_node("BtnWrap/HBoxContainer/Wrap/Name").text = counting_str + Globals.mytr(_metadata.name_id)
		self.theme = full_selection
		_metadata["count"] = _metadata.max
	else:
		#_toggle.pressed = true
		var counting_str = str(num) + "/" + str(_metadata.max) + " "
		if "display_name_id" in _metadata:
			get_node("BtnWrap/HBoxContainer/Wrap/Name").text = counting_str + _metadata.display_name_id
		else:
			get_node("BtnWrap/HBoxContainer/Wrap/Name").text = counting_str + Globals.mytr(_metadata.name_id)
		self.theme = partial_selection
		_metadata["count"] = num
		
	_locked = false
	if skip_event == false:
		var group : ButtonGroup = get_node("BtnWrap/Toggle").group
		if group != null:
			for btn in group.get_buttons():
				btn.UpdateSelection()
		_metadata.origin.bubble_selection_changed()

################ DRAG & DROP OVERRIDE #########################

func get_drag_data(position):
	return null


func get_row_data():
	_metadata["selected"] = _toggle.pressed
	_metadata["texture_cache"] = get_node("BtnWrap/HBoxContainer/Icon").texture
	return _metadata
	
func can_drop_data(position, data):
	return false
