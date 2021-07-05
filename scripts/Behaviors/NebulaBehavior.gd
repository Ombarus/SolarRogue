extends Node

var nebulas := []

func _ready():
	BehaviorEvents.connect("OnPositionUpdated", self, "OnPositionUpdated_Callback")
	BehaviorEvents.connect("OnObjectLoaded", self, "OnObjectLoaded_Callback")
	BehaviorEvents.connect("OnRequestObjectUnload", self, "OnRequestObjectUnload_Callback")
	
	
func OnRequestObjectUnload_Callback(obj):
	if obj in nebulas:
		nebulas.erase(obj)
	
func OnPositionUpdated_Callback(obj : Attributes):
	var tile : Vector2 = Globals.LevelLoaderRef.World_to_Tile(obj.position)
	var now_in_nebula : bool = false
	var prev_nebula_bonus : int = obj.get_attrib("scanner_result.nebula_bonus", 0)
	var cur_bonus : int = obj.get_attrib("scanner_result.range_bonus", 0)
	for nebula in nebulas:
		var nebula_tile_offset : Vector2 = Globals.LevelLoaderRef.World_to_Tile(nebula.position)
		var cell_index = nebula.get_child(0).get_cellv(tile - nebula_tile_offset)
		if cell_index >= 0:
			now_in_nebula = true
			if prev_nebula_bonus == 0:
				var nebula_bonus : int = nebula.get_attrib("nebula.scanner.range_bonus")
				obj.set_attrib("scanner_result.range_bonus", cur_bonus + nebula_bonus)
				obj.set_attrib("scanner_result.nebula_bonus", nebula_bonus)
	
	if now_in_nebula == false and prev_nebula_bonus != 0:
		obj.set_attrib("scanner_result.range_bonus", cur_bonus - prev_nebula_bonus)
		obj.set_attrib("scanner_result.nebula_bonus", 0)
		
		

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
	nebulas.append(obj)
