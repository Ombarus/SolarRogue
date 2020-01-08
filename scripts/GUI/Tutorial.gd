extends "res://scripts/GUI/GUILayoutBase.gd"

export(NodePath) var DefaultLang = "base/en"

func _ready():
	get_node("base").connect("OnOkPressed", self, "Ok_Callback")
	
	
func Ok_Callback():
	BehaviorEvents.emit_signal("OnPopGUI")
	get_node("base").disabled = true
		
	
func Init(init_param):
	get_node("base").disabled = false
	
	var locale := TranslationServer.get_locale()
	var contents : Array = get_tree().get_nodes_in_group("Tuto_Lang")
	var found := false
	for content in contents:
		if locale == content.name:
			found = true
			content.visible = true
		else:
			content.visible = false
			
	if found == false:
		get_node(DefaultLang).visible = true

	
	
