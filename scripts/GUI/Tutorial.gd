extends "res://scripts/GUI/GUILayoutBase.gd"

export(NodePath) var DefaultLang = "base/en"

onready var _base = get_node("base")
onready var _default_lang = get_node(DefaultLang)

func _ready():
	_base.connect("OnOkPressed", self, "Ok_Callback")
	
	
func Ok_Callback():
	BehaviorEvents.emit_signal("OnPopGUI")
	_base.disabled = true
		
	
func Init(init_param):
	_base.disabled = false
	
	var locale := TranslationServer.get_locale()
	locale = locale.split("_")[0]
	var contents : Array = get_tree().get_nodes_in_group("Tuto_Lang")
	var found := false
	for content in contents:
		if locale == content.name:
			found = true
			content.visible = true
		else:
			content.visible = false
			
	if found == false:
		_default_lang.visible = true

	
	
