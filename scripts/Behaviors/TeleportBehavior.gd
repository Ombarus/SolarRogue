extends Node

func _ready():
	#BehaviorEvents.connect("OnObjTurn", self, "OnObjTurn_Callback")
	BehaviorEvents.connect("OnConsumeItem", self, "OnConsumeItem_Callback")
	

func _process_teleport(obj, data, item_data):
	if not "last_turn_update" in data:
		data["last_turn_update"] = Globals.total_turn-1.0
		
	if not "first_turn" in data:
		data["first_turn"] = Globals.total_turn-1.0
	
	var last_update = data.last_turn_update
	
	var turn_count = Globals.total_turn - last_update
	var turn_since_beginning = Globals.total_turn - data.first_turn
	if item_data.teleport.duration >= 0 and turn_since_beginning > item_data.teleport.duration:
		turn_count = (Globals.total_turn - data.first_turn) - item_data.teleport.duration
	
	#TODO: Add potential for teleportitis (random teleport each turn for a certain duration)
	var cur_tile : Vector2 = Globals.LevelLoaderRef.World_to_Tile(obj.global_position)
	var new_tile : Vector2 = Globals.LevelLoaderRef.GetRandomEmptyTile()
	var bounds : Vector2 = Globals.LevelLoaderRef.levelSize
	var dist : Vector2 = new_tile - cur_tile
	var margin : Array = Globals.get_data(item_data, "teleport.margin", [0,0])
	if abs(dist.x) < margin[0] and abs(dist.y) < margin[1]:
		var dist_bounds = bounds - new_tile
		# Let's try to remember the logic. If the random *empty* tile I got is not valid because too close
		# I take the direction furthest from a bounds (0 or tilesize) and offset the new_tile by a random number
		# at LEAST what is needed to get the minimum margin distance
		if new_tile.x > dist_bounds.x and new_tile.x > dist_bounds.y and new_tile.x > new_tile.y:
			# far east
			var offset = MersenneTwister.rand(new_tile.x - (margin[0]-dist.x)) + (margin[0]-dist.x)
			new_tile.x -= offset
		if dist_bounds.x > new_tile.x and dist_bounds.x > dist_bounds.y and dist_bounds.x > new_tile.y:
			# far west
			var offset = MersenneTwister.rand(dist_bounds.x - (margin[0]-dist.x)) + (margin[0]-dist.x)
			new_tile.x += offset
		if new_tile.y > dist_bounds.y and new_tile.y > dist_bounds.x and new_tile.y > new_tile.x:
			# far south
			var offset = MersenneTwister.rand(new_tile.y - (margin[1]-dist.y)) + (margin[1]-dist.y)
			new_tile.y -= offset
		if dist_bounds.y > new_tile.y and dist_bounds.y > dist_bounds.x and dist_bounds.y > new_tile.x:
			# far north
			var offset = MersenneTwister.rand(dist_bounds.y - (margin[1]-dist.y)) + (margin[1]-dist.y)
			new_tile.y += offset
			
	BehaviorEvents.emit_signal("OnTeleport", obj, cur_tile, new_tile)
	
	data.last_turn_update = Globals.total_turn
	return data
	
	
func OnConsumeItem_Callback(obj, item_data, key, attrib):
	if not "teleport" in item_data:
		return
		
	BehaviorEvents.emit_signal("OnLogLine", "[color=yellow]You are transported somewhere![/color]")
	
	var teleport_data = obj.get_attrib("consumable.teleport", [])
	
	# Do one update right away, hence the -1.0 to total_turn
	var cur_data = {"data":item_data.src, "last_turn_update": Globals.total_turn-1.0, "first_turn": Globals.total_turn-1.0}
	cur_data = _process_teleport(obj, cur_data, item_data)
	
	# don't need to keep updating if consumable is instant
	if item_data.teleport.duration > 1.0:
		teleport_data.push_back(cur_data)
		obj.set_attrib("consumable.teleport", teleport_data)
		
	BehaviorEvents.emit_signal("OnValidateConsumption", obj, item_data, key, attrib)
	
	
