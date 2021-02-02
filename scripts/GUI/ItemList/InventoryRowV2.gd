extends "res://scripts/GUI/ItemList/DefaultRow.gd"

export(Theme) var normal_theme = preload("res://data/theme/default_ui_text.tres")
export(Theme) var header_theme = preload("res://data/theme/header_ui_text.tres")
export(Theme) var disabled_header_theme = preload("res://data/theme/disabled_ui_text.tres")
export(Theme) var disabled_normal_theme = preload("res://data/theme/disabled_normal_ui_text.tres")

#func _ready():
#	var data = {"icon": { "texture":"data/textures/space-sprite.png", "region":[256,128,128,128] }, "name_id":"Matter-to-Energy Converter MK2", "equipped":false, "header":true}
#	set_row_data(data)

# data = {"icon": { "texture":<path>, "region":[x,y,w,h] }, "name_id":<name>, "equipped":false, "header":false}
func set_row_data(data):
	_metadata = data
	_metadata["self"] = self
	_metadata["selected"] = false
	if data.group != null:
		get_node("BtnWrap/Toggle").group = data.group
		
	#get_node("Equipped").visible = data.equipped
	if "display_name_id" in data:
		get_node("BtnWrap/HBoxContainer/Wrap/Name").text = data.display_name_id
	else:
		get_node("BtnWrap/HBoxContainer/Wrap/Name").text = Globals.mytr(data.name_id)
	
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
		if "disabled" in data and data["disabled"] > 0:
			get_node("BtnWrap/HBoxContainer/Wrap/Name").text += Globals.mytr(" (disabled:%d)", [data["disabled"]])
			self.theme = disabled_header_theme
		else:
			self.theme = header_theme
		get_node("BtnWrap/Toggle").visible = false
		get_node("BtnWrap/HBoxContainer/Icon").visible = false
		#get_node("Equipped").visible = false
	else:
		if "disabled" in data and data["disabled"] > 0:
			self.theme = disabled_normal_theme
		else:
			self.theme = normal_theme
		get_node("BtnWrap/HBoxContainer/Icon").visible = true
	
	if _metadata.origin.is_connected("OnSelectionChanged", self, "OnSelectionChanged_Callback"):
		_metadata.origin.disconnect("OnSelectionChanged", self, "OnSelectionChanged_Callback")
	
	#self.minimum_size_changed()
	#self.call_deferred("update")

func UpdateSelection():
	if get_node("BtnWrap/Toggle").pressed == false and (not "header" in _metadata or not _metadata.header == true):
		get_node("BtnWrap/HBoxContainer/Wrap/Name").add_color_override("font_color", Color(1,1,1))

func _on_Toggle_toggled(button_pressed):
	# drag and dropping a selected node would crash because we duplicate the node for creating
	# the drag preview and it'll trigger a bunch of selection refresh on fake data
	# only way I could think of stopping it is to check if _metadata is null
	if _metadata == null:
		return
	get_node("BtnWrap/HBoxContainer/Wrap/Name").add_color_override("font_color", Color(0,0,0))
	var group : ButtonGroup = get_node("BtnWrap/Toggle").group
	if group != null:
		for btn in group.get_buttons():
			btn.UpdateSelection()
	_metadata.origin.bubble_selection_changed()

################ DRAG & DROP OVERRIDE #########################

func get_drag_data(position):
	if not "src" in _metadata or _metadata.src == "":
		return null
		
	return .get_drag_data(position)


func get_row_data():
	_metadata["selected"] = get_node("BtnWrap/Toggle").pressed
	_metadata["texture_cache"] = get_node("BtnWrap/HBoxContainer/Icon").texture
	return _metadata
	
func can_drop_data(position, data):
	if not "dragdrop_id" in data or data.dragdrop_id == "":
		return false
	var res : bool = data.dragdrop_id == _metadata.dragdrop_id and (data["self"].get_parent() != self.get_parent() or data["origin"].CanDropOnSelf == true)
	if res == false:
		return res
		
	# Can't drop mount on self
	var same_list : bool = data["self"].get_parent() == self.get_parent() 
	var both_mount : bool = "key" in data and "key" in _metadata and "idx" in data and "idx" in _metadata
	if same_list and both_mount and data.key == _metadata.key and data.idx == _metadata.idx:
		return false
	
	# When dropping in the "empty" list to drop an item on the floor
	if data.origin.Content.size() == 0:
		return true
		
	# Can always drop a mount anywhere in the cargo list to "remove" a mount
	if "key" in data and "idx" in data and not "key" in _metadata:
		return true
		
	# Cargo on Cargo is valid
	if not "key" in data and not "key" in _metadata:
		return true
	
	# Sanity check, should always have a "src"
	if not "src" in data:
		return false
		
	# Dragging something from the cargo holds to a mount points... check if we can actually  mount this here	
	var json_data = Globals.LevelLoaderRef.LoadJSON(data.src)
	var slot = Globals.get_data(json_data, "equipment.slot")
	
	if slot == null or not "key" in _metadata or slot != _metadata.key:
		return false
	
	return true
