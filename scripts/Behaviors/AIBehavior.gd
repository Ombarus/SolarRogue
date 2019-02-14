extends Node

export(NodePath) var targetting
var _targetting

func _ready():
	_targetting = get_node(targetting)
	BehaviorEvents.connect("OnObjTurn", self, "OnObjTurn_Callback")
	BehaviorEvents.connect("OnDamageTaken", self, "OnDamageTaken_Callback")
	BehaviorEvents.connect("OnScannerUpdated", self, "OnScannerUpdated_Callback")
	
	
func OnScannerUpdated_Callback(obj):
	if obj.get_attrib("ai") == null or obj.get_attrib("ai.aggressive") == false:
		return
		
	var level_id = Globals.LevelLoaderRef.GetLevelID()
	var new_objs = obj.get_attrib("scanner_result.new_in_range." + level_id)
	#var new_out_objs = obj.get_attrib("scanner_result.new_out_of_range." + level_id)
	
	var player = null
	var in_range = false
	for id in new_objs:
		var o = Globals.LevelLoaderRef.GetObjectById(id)
		if o.get_attrib("type") == "player":
			in_range = true
			player = id
			break
	
	if in_range == true:
		obj.set_attrib("ai.pathfinding", "attack")
		obj.set_attrib("ai.target", player)
		obj.set_attrib("wandering", false)
	

	
func OnDamageTaken_Callback(target, shooter):
	if target.get_attrib("ai") == null:
		return
	
	var run_if_attacked = target.get_attrib("ai.run_if_attacked")
	if run_if_attacked != null and run_if_attacked == true:
		target.set_attrib("ai.pathfinding", "run_away")
		target.set_attrib("ai.run_from", shooter.modified_attributes.unique_id)
		target.set_attrib("ai.unseen_for", 0)
		target.set_attrib("wandering", false)
	
func OnObjTurn_Callback(obj):
	if obj.get_attrib("ai") == null:
		return
	
	obj.set_attrib("ap.ai_acted", false)
	#obj.modified_attributes["ap"] = false
	
	var pathfinding = obj.get_attrib("ai.pathfinding")
		
	var is_aggressive = obj.get_attrib("ai.aggressive")
	
	
	if pathfinding == "simple":
		DoSimplePathFinding(obj)
	elif pathfinding == "run_away":
		DoRunAwayPathFinding(obj)
	elif pathfinding == "attack":
		DoAttackPathFinding(obj)
	else:
		# For now, just do nothing for one AP
		BehaviorEvents.emit_signal("OnUseAP", obj, 1.0)
		
	if obj.get_attrib("ap.ai_acted") == false:
		print("**** AI DID NOT DO ANY ACTION. AI SHOULD AT LEAST WAIT FOR 1 TURN ALWAYS ! *****")
		BehaviorEvents.emit_signal("OnUseAP", obj, 1.0)

func FindRandomTile():
	var x = MersenneTwister.rand(Globals.LevelLoaderRef.levelSize.x)
	var y = MersenneTwister.rand(Globals.LevelLoaderRef.levelSize.y)
	return Vector2(x,y)

func DoAttackPathFinding(obj):
	var player = Globals.LevelLoaderRef.GetObjectById(obj.get_attrib("ai.target"))
	var player_tile = Globals.LevelLoaderRef.World_to_Tile(player.position)
	var obj_tile = Globals.LevelLoaderRef.World_to_Tile(obj.position)
	var weapons = obj.get_attrib("mounts.weapon")
	var weapons_data = Globals.LevelLoaderRef.LoadJSONArray(weapons)
	#if weapons_data != null and weapons_data.size() > 0
	
	var minimal_move = null
	var shot = false
	BehaviorEvents.emit_signal("OnBeginParallelAction", obj)
	for data in weapons_data:
		var best_move = _targetting.ClosestFiringSolution(obj_tile, player_tile, data)
		if best_move.length() == 0:
			BehaviorEvents.emit_signal("OnDealDamage", player, obj, data)
			shot = true
		if minimal_move == null or minimal_move.length() > best_move.length():
			minimal_move = best_move
	BehaviorEvents.emit_signal("OnEndParallelAction", obj)

	if shot == false:
		var move_by = Vector2(0, 0)
		move_by.x = clamp(minimal_move.x, -1, 1)
		move_by.y = clamp(minimal_move.y, -1, 1)
		BehaviorEvents.emit_signal("OnMovement", obj, move_by)

func DoSimplePathFinding(obj):
	if obj.get_attrib("wandering") == null:
		obj.modified_attributes["wandering"] = true
	
	var tile_pos = Globals.LevelLoaderRef.World_to_Tile(obj.position)

	var cur_objective = obj.get_attrib("ai.objective")
	if cur_objective == null || cur_objective == tile_pos:
		obj.set_attrib("ai.objective", FindRandomTile())
	
	var target = obj.get_attrib("ai.objective")
	var move_by = Vector2(0,0)
	if target.x > tile_pos.x:
		move_by.x += 1
	elif target.x < tile_pos.x:
		move_by.x -= 1
	if target.y > tile_pos.y:
		move_by.y += 1
	elif target.y < tile_pos.y:
		move_by.y -= 1
		
	if move_by.length_squared() > 0:
		BehaviorEvents.emit_signal("OnMovement", obj, move_by)

func DoRunAwayPathFinding(obj):
	var my_pos = obj.position
	var scary_pos = Globals.LevelLoaderRef.objById[obj.modified_attributes.ai.run_from].position
	my_pos = Globals.LevelLoaderRef.World_to_Tile(my_pos)
	scary_pos = Globals.LevelLoaderRef.World_to_Tile(scary_pos)
	var scanner_range = 0
	var scanner = obj.get_attrib("mounts.scanner")
	var scanner_json = null
	if scanner != null:
		scanner_json = scanner[0]
	if scanner_json != null and scanner_json != "":
		var scanner_data = Globals.LevelLoaderRef.LoadJSON(scanner_json)
		scanner_range = scanner_data.scanning.radius
	var distance = my_pos - scary_pos
	if distance.length_squared() >= scanner_range * scanner_range:
		obj.set_attrib("ai.unseen_for", obj.get_attrib("ai.unseen_for") + 1)
	
	if obj.get_attrib("ai.unseen_for") > obj.get_attrib("ai.stop_running_after"):
		#TODO: Maybe wrap this in a method too ?
		obj.modified_attributes.ai.erase("pathfinding")
		obj.modified_attributes.ai.erase("run_from")
		obj.modified_attributes.ai.erase("unseen_for")
		obj.modified_attributes.erase("wandering")
		BehaviorEvents.emit_signal("OnUseAP", obj, 1.0)
		return
		
		
	if distance.length_squared() <= 0:
		BehaviorEvents.emit_signal("OnMovement", obj, Vector2(1, 0))
		return
	
	if abs(distance.x) > abs(distance.y):
		distance = distance / abs(distance.x)
		distance.x += 0.1
	else:
		distance = distance / abs(distance.y)
		distance.y += 0.1
	
	var dir = Vector2(int(round(distance.x)), int(round(distance.y)))
	BehaviorEvents.emit_signal("OnMovement", obj, dir)
	
	
	

