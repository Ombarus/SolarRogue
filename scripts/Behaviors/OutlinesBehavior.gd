extends Node

func _ready():
	BehaviorEvents.connect("OnObjectLoaded", self, "OnObjectLoaded_Callback")
	BehaviorEvents.connect("OnStatusChanged", self, "OnStatusChanged_Callback")
	
	
func OnObjectLoaded_Callback(obj):
	yield(get_tree(), "idle_frame") # Give a chance to the SpriteBehavior to finish initializing everything
	var outline : Sprite = obj.find_node("outline", true, false)
	if outline == null:
		return
		
	UpdateColor(obj, outline)
		
	
func OnStatusChanged_Callback(obj):
	var outline : Sprite = obj.find_node("outline", true, false)
	if outline == null:
		return
		
	UpdateColor(obj, outline)
	
	
func UpdateColor(obj : Attributes, outline : Sprite):
	var ai_target : Attributes = Globals.LevelLoaderRef.GetObjectById(obj.get_attrib("ai.target"))
	if obj.get_attrib("type") == "player":
		outline.modulate = Color(1.0, 1.0, 1.0, 0.0)
	elif obj.get_attrib("ai.aggressive", false) == true and ai_target != null and ai_target.get_attrib("type") == "player" :
		outline.modulate = Color(1.0, 0.0, 0.0, 1.0)
	else:
		outline.modulate = Color(0.0, 0.0, 1.0, 1.0)
	#TODO: If we ever have allies, make them green