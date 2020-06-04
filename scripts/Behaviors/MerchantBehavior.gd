extends Node


func _ready():
	BehaviorEvents.connect("OnObjectLoaded", self, "OnObjectLoaded_Callback")
	BehaviorEvents.connect("OnObjectDestroyed", self, "OnObjectDestroyed_Callback")
	BehaviorEvents.connect("OnStatusChanged", self, "OnStatusChanged_Callback")

func OnStatusChanged_Callback(obj):
	if obj.get_attrib("ai.aggressive", false) == false:
		return
		
	var ports : Array = obj.get_attrib("merchant.port_ref", [])
	if ports.empty() == true:
		return
		
	for port in ports:
		var port_obj : Attributes = Globals.LevelLoaderRef.GetObjectById(port)
		BehaviorEvents.emit_signal("OnRequestObjectUnload", port_obj)
	obj.set_attrib("merchant.port_ref", [])

func OnObjectDestroyed_Callback(target):
	var ports : Array = target.get_attrib("merchant.port_ref", [])
	if ports.empty() == true:
		return
		
	for port in ports:
		var obj : Attributes = Globals.LevelLoaderRef.GetObjectById(port)
		BehaviorEvents.emit_signal("OnRequestObjectUnload", obj)
	target.set_attrib("merchant.port_ref", [])
	

func OnObjectLoaded_Callback(obj):
	var merchant_data : Dictionary = obj.get_attrib("merchant", {})
	if merchant_data.empty() == true or not "trade_ports" in merchant_data:
		return
		
	# loading a save, the objects will be loaded from the save
	var port_ids = obj.get_attrib("merchant.port_ref", [])
	if port_ids.empty() == false:
		return
		
	var cur_tile : Vector2 = Globals.LevelLoaderRef.World_to_Tile(obj.position)
	var host_id = obj.get_attrib("unique_id")
	for port in merchant_data["trade_ports"]:
		var port_tile := Vector2(cur_tile.x + port[0], cur_tile.y + port[1])
		var n = Globals.LevelLoaderRef.RequestObject("data/json/props/trade_port.json", port_tile, {"host":host_id})
		port_ids.push_back(n.get_attrib("unique_id"))

	obj.set_attrib("merchant.port_ref", port_ids)
	
	CreateInventory(obj)
	
func sort_by_chance(a, b):
	if a.chance > b.chance:
		return true
	return false
	
func CreateInventory(obj):
	obj.init_cargo()
	obj.init_mounts()
	
	var inv_size = obj.get_attrib("merchant.inventory_size")
	var pondered_inv = obj.get_attrib("merchant.pondered_inventory_content")
	pondered_inv.sort_custom(self, "sort_by_chance")
	
	#var modified_merchant_data = {}
	var actual_inv_size = MersenneTwister.rand(inv_size[1]-inv_size[0]) + inv_size[0]
	var max_pond_inv = 0
	for item in pondered_inv:
		max_pond_inv += item.chance
	
	var actual_inv = []
	for i in range(actual_inv_size):
		var target = MersenneTwister.rand(max_pond_inv)
		var selected_item = null
		var sum = 0
		for item in pondered_inv:
			if sum + item.chance > target:
				var actual_count = 1
				if item.has("count"):
					var min_count : int = item["count"][0]
					var max_count : int = item["count"][1]
					actual_count = MersenneTwister.rand(max_count-min_count) + min_count
				selected_item = {"src":item.src, "count":actual_count}
				pondered_inv.erase(item)
				max_pond_inv -= item.chance
				break
			sum += item.chance
		actual_inv.push_back(selected_item)
		
	#modified_merchant_data["inventory"] = actual_inv
	#modified_merchant_data["actual_inventory_size"] = actual_inv_size
	
	obj.set_attrib("cargo.content", actual_inv)
	
