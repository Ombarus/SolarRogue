extends Control

export(NodePath) var AP_behavior_path = ""

onready var _label : RichTextLabel = get_node("RichTextLabel")
onready var _behavior : APBehavior = get_node(AP_behavior_path)

# Called when the node enters the scene tree for the first time.
func _ready():
	pass # Replace with function body.


#var action_list = []
#var star_date_turn = 0
#var star_date_minor = 0
#var star_date_major = 0
#var _disable = false
#var _waiting_on_anim = false
#var _need_sort = true

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	if _behavior == null or self.visible == false or Globals.get_first_player() == null:
		return
		
	var to_display : String = ""
#	to_display += "========= states ========\n"
#	to_display += "Disabled : %s\n" % _behavior._disable
#	to_display += "Waiting on Anim : %s\n" % _behavior._waiting_on_anim
#	to_display += "Need Sort : %s\n" % _behavior._need_sort
#
#	to_display += "\n====== effects list ======\n"
#	for effect in Globals.get_first_player().get_attrib("applied_effects", []):
#		var src = effect["src"]
#		to_display += "-> " + src.substr(src.find_last("/"), -1) + ", "
#		if effect.has("from_inventory"):
#			to_display += "(inv), "
#
#		for key in effect.keys():
#			if key != "src" and key != "from_inventory":
#				to_display += key + ", "
#		to_display += "\n"
	
	to_display += "\n====== action list ======\n"
	for obj in _behavior.action_list:
		var color_on := ""
		var color_off := ""
		if obj.get_attrib("type") == "player":
			color_on += "[color=red]"
			color_off += "[/color]"
		to_display += "%s%0.2f - %s%s\n" % [color_on, obj.get_attrib("action_point"), obj.name, color_off]
	
	_label.bbcode_text = to_display
