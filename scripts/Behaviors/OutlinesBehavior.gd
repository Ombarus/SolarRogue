extends Node

func _ready():
	#BehaviorEvents.connect("OnObjectLoaded", self, "OnObjectLoaded_Callback")
	BehaviorEvents.connect("OnStatusChanged", self, "OnStatusChanged_Callback")
	BehaviorEvents.connect("OnTransferPlayer", self, "OnTransferPlayer_Callback")
	
func OnTransferPlayer_Callback(old_player, new_player):
	# make sure all other behaviors had time to update Attributes data
	call_deferred("UpdateColor", new_player)
	call_deferred("UpdateColor", old_player)
	

# Doing it in "OnObjectLoaded" conflicts with SpriteBehavior so we don't have the outline yet. 
# So wait for SpriteBehavior to send a "OnStatusChange" instead	
#func OnObjectLoaded_Callback(obj):
#	if obj.is_inside_tree() == false:
#		obj.connect("tree_entered", self, "UpdateColor", [obj])
#	else:
#		UpdateColor(obj)
		
	
func OnStatusChanged_Callback(obj):
	UpdateColor(obj)
	
	
func UpdateColor(obj : Attributes):
	var outline : Sprite = obj.find_node("outline", true, false)
	if outline == null:
		return
	
	var ai_target : Attributes = Globals.LevelLoaderRef.GetObjectById(obj.get_attrib("ai.target"))
	if obj.get_attrib("type") == "player":
		outline.modulate = Color(1.0, 1.0, 1.0, 0.0)
	elif obj.get_attrib("boardable") == true:
		outline.modulate = Color(1.0, 1.0, 1.0, 1.0)
	elif obj.get_attrib("ai.aggressive", false) == true and ai_target != null and ai_target.get_attrib("type") == "player" :
		outline.modulate = Color(1.0, 0.0, 0.0, 1.0)
	else:
		outline.modulate = Color(0.0, 0.0, 1.0, 1.0)
	#TODO: If we ever have allies, make them green