extends Node2D

# class member variables go here, for example:
# var a = 2
# var b = "textvar"

func _ready():
	pass
#	if Input.get_mouse_mode() == Input.MOUSE_MODE_HIDDEN:
#		self.visible == false
#		self.set_process_input(false)
	
func _input(event):
	if event is InputEventScreenTouch:
		self.visible == false # For some reason this doesn't work here ?!?
		self.set_process_input(false)
		return
		
	if event is InputEventMouseMotion:
		var world_mouse_tile = Globals.LevelLoaderRef.World_to_Tile(get_global_mouse_position())
		var tile_world_center = Globals.LevelLoaderRef.Tile_to_World(world_mouse_tile)
		self.position = tile_world_center

func _process(delta):
	if self.is_processing_input() == false:
		self.visible = false