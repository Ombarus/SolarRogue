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
	if _behavior == null and self.visible == true:
		return
		
	var to_display : String = ""
	to_display += "========= states ========\n"
	to_display += "Disabled : %s\n" % _behavior._disable
	to_display += "Waiting on Anim : %s\n" % _behavior._waiting_on_anim
	to_display += "Need Sort : %s\n" % _behavior._need_sort
	
	to_display += "\n====== action list ======\n"
	for obj in _behavior.action_list:
		var color_on := ""
		var color_off := ""
		if obj.get_attrib("type") == "player":
			color_on += "[color=red]"
			color_off += "[/color]"
		to_display += "%s%0.2f - %s%s\n" % [color_on, obj.get_attrib("action_point"), obj.name, color_off]
	
	_label.bbcode_text = to_display