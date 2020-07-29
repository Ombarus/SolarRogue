extends Node



func _ready():
	BehaviorEvents.connect("OnEquipMount", self, "OnEquipMount_Callback")
	BehaviorEvents.connect("OnMountRemoved", self, "OnMountRemoved_Callback")
	BehaviorEvents.connect("OnObjectLoaded", self, "OnObjectLoaded_Callback")
	

func OnEquipMount_Callback(obj, slot, index, src, variation_src):
	pass
	
func OnMountRemoved_Callback(obj, slot, src):
	# need index & variation
	pass

func OnObjectLoaded_Callback(obj):
	var selected_variation = obj.get_attrib("selected_variation")
	if selected_variation != null:
		return
		
	var variations = obj.get_attrib("variations", [])
	if variations.size() <= 0:
		return
		
	selected_variation = MersenneTwister.rand_weight(variations, "src", "chance")
	
	obj.set_attrib("selected_variation", selected_variation)
