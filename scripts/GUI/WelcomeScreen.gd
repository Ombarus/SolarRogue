extends "res://scripts/GUI/GUILayoutBase.gd"

export(NodePath) var DefaultLang = "base/en"

func _ready():
	get_node("base").connect("OnOkPressed", self, "Ok_Callback")
	
	
func Ok_Callback():
	Globals.TutorialRef.emit_signal("StartTuto")
	BehaviorEvents.emit_signal("OnPopGUI")
	get_node("base").disabled = true
		
	
func Init(init_param):
	get_node("base").disabled = false
	var player_name = init_param["player_name"]
	get_node("base").title = Globals.mytr("Welcome %s...", [player_name])
	
	var locale := TranslationServer.get_locale()
	locale = locale.split("_")[0]
	var contents : Array = get_tree().get_nodes_in_group("welcome_lang")
	var found := false
	for content in contents:
		if locale == content.name:
			found = true
			content.visible = true
		else:
			content.visible = false
			
	if found == false:
		get_node(DefaultLang).visible = true
	
