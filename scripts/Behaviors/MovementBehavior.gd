extends Node

export(NodePath) var levelLoaderNode
var levelLoaderRef

func _ready():
	levelLoaderRef = get_node(levelLoaderNode)
	BehaviorEvents.connect("OnMovement", self, "OnMovement_callback")
	
func OnMovement_callback(obj, dir):
	if not obj.base_attributes.has("moving"):
		return
	var new_pos = obj.position + levelLoaderRef.Tile_to_World(dir)
	if new_pos.x < 0 || \
		new_pos.y < 0 || \
		new_pos.x >= levelLoaderRef.Tile_to_World(levelLoaderRef.levelSize.x) || \
		new_pos.y >= levelLoaderRef.Tile_to_World(levelLoaderRef.levelSize.y):
		return
	#TODO: Collision Detection
	
	BehaviorEvents.emit_signal("OnUseAP", obj, obj.base_attributes["moving"]["speed"])
	
	obj.position += levelLoaderRef.Tile_to_World(dir)
	var angle = Vector2(0.0, 0.0).angle_to_point(dir) - deg2rad(90.0)
	obj.rotation = angle

#func _process(delta):
#	# Called every frame. Delta is time since last frame.
#	# Update game logic here.
#	pass
