extends "res://scripts/GUI/ItemList/DefaultRow.gd"

export(Theme) var normal_theme = preload("res://data/theme/default_ui_text.tres")

onready var _toggle = get_node("Toggle")

# data {"name_id":"Missile', "icon": {"texture":<path>, "region":[x,y,w,h]}, "chance":0.15}
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
		
	get_node("HBoxContainer/Name").text = Globals.mytr(data.name_id)
	get_node("HBoxContainer/Chance").text = "%.0f%%" % [data.chance * 100.0]
		
	
func get_row_data():
	_metadata["selected"] = _toggle.pressed
	return _metadata

func _ready():
	_toggle.connect("pressed", self, "pressed_callback")
	if _metadata != null:
		set_row_data(_metadata)
	
func pressed_callback():
	_metadata.origin.bubble_selection_changed()
	
