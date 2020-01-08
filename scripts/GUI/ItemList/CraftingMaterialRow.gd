extends "res://scripts/GUI/ItemList/DefaultRow.gd"

export(Theme) var full_selection = null
export(Theme) var partial_selection = null
export(Theme) var normal_theme = preload("res://data/theme/default_ui_text.tres")

onready var _toggle = get_node("Toggle")

# data {"max":5, "name_id":"Missile', "selected":2, "disabled":true}
func set_row_data(data):
	_metadata = data
	if _metadata.group != null:
		_toggle.group = _metadata.group
	
	select(0)
	
		
#func get_row_data():
	#_metadata["selected"] = self.pressed
#	return _metadata

func _ready():
	_toggle.connect("pressed", self, "pressed_callback")
	
func pressed_callback():
	if _toggle.pressed == false:
		select(0)
	elif _metadata.max == 1:
		select(1)
	else:
		#select(2) # temp while I test outside "main"
		_toggle.pressed = false
		BehaviorEvents.emit_signal("OnPushGUI", "HowManyDiag", {
			"callback_object":self, 
			"callback_method":"select", 
			"min_value":1, 
			"max_value":_metadata.max})

func select(num):
	if num == 0:
		if "display_name_id" in _metadata:
			get_node("HBoxContainer/Name").text = _metadata.display_name_id
		else:
			get_node("HBoxContainer/Name").text = Globals.mytr(_metadata.name_id)
		get_node("HBoxContainer/Wrapper/Count").text = str(_metadata.max)+"x"
		self.theme = normal_theme
		_metadata["selected"] = 0
		if "disabled" in _metadata and _metadata.disabled == true:
			get_node("HBoxContainer/Wrapper/Count").visible = false
			get_node("HBoxContainer/Name").add_color_override("font_color", Color(1,0,0,1))
			_toggle.visible = false
	elif num == _metadata.max:
		_toggle.pressed = true
		if "display_name_id" in _metadata:
			get_node("HBoxContainer/Name").text = _metadata.display_name_id
		else:
			get_node("HBoxContainer/Name").text = Globals.mytr(_metadata.name_id)
		get_node("HBoxContainer/Wrapper/Count").text = "✓"
		self.theme = full_selection
		_metadata["selected"] = _metadata.max
	else:
		_toggle.pressed = true
		if "display_name_id" in _metadata:
			get_node("HBoxContainer/Name").text = _metadata.display_name_id
		else:
			get_node("HBoxContainer/Name").text = Globals.mytr(_metadata.name_id)
		get_node("HBoxContainer/Wrapper/Count").text = str(num) + "/" + str(_metadata.max)
		self.theme = partial_selection
		_metadata["selected"] = num
	_metadata.origin.bubble_selection_changed()
		