extends "res://scripts/GUI/ItemList/DefaultRow.gd"

onready var _title = get_node("HBoxContainer/CrewTitle")
onready var _name = get_node("HBoxContainer/CrewName")
onready var _status = get_node("HBoxContainer/CrewStatus")
onready var _log = get_node("HBoxContainer/CrewLog")

func set_row_data(data):
	_metadata = data
	_metadata["self"] = self
	
	# Have to wait for the OnReady
	if _name == null:
		return

	_title.text = data["title"]
	_name.text = data["name"]
	_status.text = data["status"]
	_log.text = data["log"]
	
	var style := StyleBoxFlat.new()
	style.bg_color = Color(data["color"][0],data["color"][1],data["color"][2])
	get_node("BG").set('custom_styles/panel', style)

func _ready():
	if _metadata != null:
		set_row_data(_metadata)
