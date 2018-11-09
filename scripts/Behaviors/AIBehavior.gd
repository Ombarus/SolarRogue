extends Node

export(NodePath) var levelLoaderNode
var levelLoaderRef

func _ready():
	levelLoaderRef = get_node(levelLoaderNode)
	BehaviorEvents.connect("OnObjTurn", self, "OnObjTurn_Callback")
	
func OnObjTurn_Callback(obj):
	if not obj.base_attributes.has("ai"):
		return
	
	var ai_data = obj.base_attributes.ai
	
	if ai_data.pathfinding == "simple":
		DoSimplePathFinding(obj)
	else:
		# For now, just do nothing for one AP
		BehaviorEvents.emit_signal("OnUseAP", obj, 1.0)

func FindRandomTile():
	var x = int(randf() * levelLoaderRef.levelSize.x)
	var y = int(randf() * levelLoaderRef.levelSize.y)
	return Vector2(x,y)

func DoSimplePathFinding(obj):
	if not obj.modified_attributes.has("wandering"):
		obj.modified_attributes["wandering"] = true
	
	var tile_pos = levelLoaderRef.World_to_Tile(obj.position)
	if not obj.modified_attributes.has("ai"):
		obj.modified_attributes["ai"] = {}
	if not obj.modified_attributes.ai.has("objective") || obj.modified_attributes.ai.objective == tile_pos:
		obj.modified_attributes.ai["objective"] =  FindRandomTile()
	
	var target = obj.modified_attributes.ai.objective
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
		
		

