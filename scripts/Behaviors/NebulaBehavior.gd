extends Node

var nebulas := []

func _ready():
	BehaviorEvents.connect("OnObjTurn", self, "OnObjTurn_Callback")
	BehaviorEvents.connect("OnObjectLoaded", self, "OnObjectLoaded_Callback")
	
	
func OnObjTurn_Callback(obj):
	pass

func OnObjectLoaded_Callback(obj : Attributes):
	if obj.get_attrib("nebula") == null:
		return
		
	var range_min : int = obj.get_attrib("nebula.min_range")
	var range_max : int = obj.get_attrib("nebula.max_range")
	var real_range = obj.get_attrib("nebula.real_range")
	var nebula_seed = obj.get_attrib("nebula.seed")
	
	if real_range == null:
		real_range = MersenneTwister.rand(range_max - range_min) + range_min
		obj.set_attrib("nebula.real_range", real_range)
		
	if nebula_seed == null:
		nebula_seed = MersenneTwister.rand(100000)
		obj.set_attrib("nebula.seed", nebula_seed)

	
	# give a chance to add sprite to scene tree
	call_deferred("defered_init", obj)
	
func defered_init(obj):
	var real_range : int = obj.get_attrib("nebula.real_range")
	var nebula_seed : int = obj.get_attrib("nebula.seed")
		
	obj.get_child(0).Init(nebula_seed, real_range)
