extends Node

export(NodePath) var levelLoaderNode
var levelLoaderRef

func _ready():
	levelLoaderRef = get_node(levelLoaderNode)
	BehaviorEvents.connect("OnMovement", self, "OnMovement_callback")
	
func OnMovement_callback(obj, dir):
	if obj.get_attrib("moving") == null:
		return
	var new_pos = obj.position + levelLoaderRef.Tile_to_World(dir)
	if new_pos.x < 0 || \
		new_pos.y < 0 || \
		new_pos.x >= levelLoaderRef.Tile_to_World(levelLoaderRef.levelSize.x) || \
		new_pos.y >= levelLoaderRef.Tile_to_World(levelLoaderRef.levelSize.y):
		return
	#TODO: Collision Detection
	
	obj.init_cargo()
	var cargo_capacity = obj.get_attrib("cargo.capacity")
	var cargo_used = obj.get_attrib("cargo.volume_used")
	if cargo_used != null and cargo_capacity != null and cargo_used > cargo_capacity and obj.get_attrib("type") == "player":
		BehaviorEvents.emit_signal("OnLogLine", "We have too much cargo, choose what to leave behind before we go")
		obj.set_attrib("moving.moved", false)
		return
	
	var move_speed = obj.get_attrib("moving.speed")
	var energy_cost = obj.get_attrib("moving.energy_cost")
	if energy_cost == null:
		energy_cost = 0
	var is_wandering = obj.get_attrib("wandering")
	if is_wandering != null && is_wandering == true:
		move_speed = obj.get_attrib("moving.wander_speed")
	if not (dir.x == 0 || dir.y == 0):
		# moving diagonal, multiply by 1.4
		move_speed *= 1.41421356237
		energy_cost *= 1.41421356237
	var special_multiplier = obj.get_attrib("moving.special_multiplier")
	if special_multiplier == null:
		special_multiplier = 1.0
	BehaviorEvents.emit_signal("OnUseAP", obj, move_speed * special_multiplier)
	BehaviorEvents.emit_signal("OnUseEnergy", obj, energy_cost)
	
	var newPos = obj.position + levelLoaderRef.Tile_to_World(dir)
	levelLoaderRef.UpdatePosition(obj, newPos)
	
	var has_movement_anim : bool = obj.find_node("MovementAnimations", true, false) != null
	if not has_movement_anim:
		var angle = Vector2(0.0, 0.0).angle_to_point(dir) - deg2rad(90.0)
		obj.rotation = angle
	
	obj.set_attrib("moving.moved", true)

#func _process(delta):
#	# Called every frame. Delta is time since last frame.
#	# Update game logic here.
#	pass
