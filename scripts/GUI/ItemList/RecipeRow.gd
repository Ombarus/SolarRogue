extends "res://scripts/GUI/ItemList/DefaultRow.gd"

onready var _toggle : Button = get_node("Toggle")

# data : {"name":<recipe_name>, "icon": {"texture":<path>, "region":[x,y,w,h]}, requirements, produce, ap_cost, etc... (see converter recipe.json)}
func set_row_data(data):
	_metadata = data
	# OnReady is called after the row is added to the scene
	# but now for layout to flow properly we have to use call_defered
	# to add to scene so OnReady might not have been called yet
	if _toggle == null:
		return
	if _metadata.group != null:
		_toggle.group = _metadata.group
		
	var display_name = Globals.mytr(data.name)
	if "selected_variation" in data and not data.selected_variation.empty():
		var variation_data = Globals.LevelLoaderRef.LoadJSON(data.selected_variation)
		if not variation_data["prefix"].empty(): # "normal" effects might have an empty prefix
			display_name = Globals.mytr(variation_data["prefix"], display_name)
		
	get_node("HBoxContainer/Name").text = display_name
		
	var icon_path : String = Globals.get_data(data, "icon.texture", "")
	if icon_path != "":
		icon_path = Globals.clean_path(icon_path)
		var icon_region : Array = Globals.get_data(data, "icon.region", [])
		var t := AtlasTexture.new()
		t.atlas = load(icon_path)
		if icon_region.size() > 0:
			t.region = Rect2(icon_region[0], icon_region[1], icon_region[2], icon_region[3])
		get_node("HBoxContainer/Icon").texture = t
	else:
		get_node("HBoxContainer/Icon").texture = null
		
	if "selected" in data:
		_toggle.pressed = data.selected
		pressed_callback()
		
	if _metadata.origin.is_connected("OnSelectionChanged", self, "OnSelectionChanged_Callback"):
		_metadata.origin.disconnect("OnSelectionChanged", self, "OnSelectionChanged_Callback")
	_metadata.origin.connect("OnSelectionChanged", self, "OnSelectionChanged_Callback")

func get_row_data():
	_metadata["selected"] = _toggle.pressed
	# Since I'm going to display it in the center of the converter window. It's just more efficient to use the same
	# copy.
	_metadata["texture_cache"] = get_node("HBoxContainer/Icon").texture
	return _metadata

func _ready():
	_toggle.connect("pressed", self, "pressed_callback")
	if _metadata != null:
		set_row_data(_metadata)
	
func pressed_callback():
	get_node("HBoxContainer/Name").add_color_override("font_color", Color(0,0,0))
	_metadata.origin.bubble_selection_changed()

func OnSelectionChanged_Callback():
	if _toggle.pressed == false:
		get_node("HBoxContainer/Name").add_color_override("font_color", Color(1,1,1))
