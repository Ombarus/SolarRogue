extends Node2D

export(NodePath) var BorderContainer : NodePath = "Border"

onready var _root := get_node(BorderContainer)
onready var _defaults := get_node("Defaults")

func _ready():
	BehaviorEvents.connect("OnStartLoadLevel", self, "OnStartLoadLevel_Callback")
	get_node("Defaults").visible = false


func OnStartLoadLevel_Callback():
	Clear()
	var defaults := _defaults.get_children()
	# Apparently I don't do validation when converting Tile Coord to World coord. Works for me
	# but it might break if I ever add validation so keep it in mind.
	for y in [-1, Globals.LevelLoaderRef.levelSize.y]:
		for x in range(Globals.LevelLoaderRef.levelSize.x):
			var coord := Vector2(x,y)
			Spawn(coord, defaults)
			
	for x in [-1, Globals.LevelLoaderRef.levelSize.x]:
		for y in range(Globals.LevelLoaderRef.levelSize.y):
			var coord := Vector2(x,y)
			Spawn(coord, defaults)

func Spawn(coord, defaults):
	var pos = Globals.LevelLoaderRef.Tile_to_World(coord)
	var roll : float = MersenneTwister.rand(100)
	var to_spawn : BorderData = null
	var freq_sum := 0.0
	for child in defaults:
		freq_sum += child.frequency * 100.0
		if roll <= freq_sum:
			to_spawn = child
			break
	if to_spawn != null:
		var n := to_spawn.duplicate()
		var offset = Vector2(MersenneTwister.rand(n.max_offset.x*2)-n.max_offset.x, MersenneTwister.rand(n.max_offset.y*2)-n.max_offset.y)
		n.position = pos + offset
		_root.call_deferred("add_child", n)
	
func Clear():
	for child in _root.get_children():
		_root.remove_child(child)
		child.queue_free()
