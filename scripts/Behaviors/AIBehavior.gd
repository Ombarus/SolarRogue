extends Node

export(NodePath) var levelLoaderNode
var levelLoaderRef

func _ready():
	levelLoaderRef = get_node(levelLoaderNode)
	BehaviorEvents.connect("OnObjTurn", self, "OnObjTurn_Callback")
	BehaviorEvents.connect("OnDamageTaken", self, "OnDamageTaken_Callback")
	
func OnDamageTaken_Callback(target, shooter):
	if target.get_attrib("ai") == null:
		return
		
	if target.get_attrib("ai.run_if_attacked") != null:
		target.set_attrib("ai.pathfinding", "run_away")
		target.set_attrib("ai.run_from", shooter.modified_attributes.unique_id)
		target.set_attrib("ai.unseen_for", 0)
		target.set_attrib("wandering", false)
	
func OnObjTurn_Callback(obj):
	if obj.get_attrib("ai") == null:
		return
	
	obj.modified_attributes["ap"] = false
	
	var pathfinding = obj.get_attrib("ai.pathfinding")
		
	var is_aggressive = obj.get_attrib("ai.aggressive")
	
	
	if pathfinding == "simple":
		DoSimplePathFinding(obj)
	elif pathfinding == "run_away":
		DoRunAwayPathFinding(obj)
	else:
		# For now, just do nothing for one AP
		BehaviorEvents.emit_signal("OnUseAP", obj, 1.0)
		
	if obj.modified_attributes["ap"] == false:
		print("**** AI DID NOT DO ANY ACTION. AI SHOULD AT LEAST WAIT FOR 1 TURN ALWAYS ! *****")
		BehaviorEvents.emit_signal("OnUseAP", obj, 1.0)

func FindRandomTile():
	var x = int(randf() * levelLoaderRef.levelSize.x)
	var y = int(randf() * levelLoaderRef.levelSize.y)
	return Vector2(x,y)

func DoSimplePathFinding(obj):
	if obj.get_attrib("wandering") == null:
		obj.modified_attributes["wandering"] = true
	
	var tile_pos = levelLoaderRef.World_to_Tile(obj.position)

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
	var scanner_json = obj.get_attrib("mounts.scanner")
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
	
	
	

