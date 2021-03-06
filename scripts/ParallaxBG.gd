extends Sprite

# How much to offset background from one end of the map to the other
export(float) var parallax = 0.0
export(NodePath) var camera = ""
onready var _camera : Camera2D = get_node(camera)

func _ready():
	BehaviorEvents.connect("OnMovement", self, "OnMovement_Callback")
	BehaviorEvents.connect("OnLevelLoaded", self, "OnLevelLoaded_Callback")
	BehaviorEvents.connect("OnTransferPlayer", self, "OnTransferPlayer_Callback")
	
	OnLevelLoaded_Callback()
	

func OnMovement_Callback(obj, dir):
	#if obj.get_attrib("type") == "player":
	#	_update_parallax(obj)
	pass
		
func OnLevelLoaded_Callback():
	var player := Globals.get_first_player()
	if player == null:
		return
	_update_parallax(Globals.LevelLoaderRef.objByType["player"][0])
	
func OnTransferPlayer_Callback(old_player, new_player):
	_update_parallax(new_player)

func _update_parallax(obj):
	if _camera == null:
		return
	var bounds = Globals.LevelLoaderRef.levelSize
	var tile_size = Globals.LevelLoaderRef.tileSize
	var grid_span = bounds * tile_size
	
	var default_pos = grid_span / 2.0
	var player_pos = _camera.global_position#obj.position
	#if obj.get_child_count() > 0:
	#	player_pos = obj.get_child(0).global_position
	var offset_from_center = player_pos - default_pos
	var offset_per_pix = Vector2(parallax, parallax) / default_pos
	var cur_offset = offset_per_pix * offset_from_center
	self.position = default_pos + cur_offset
	if has_node("Occlusion"):
		get_node("Occlusion").position = Vector2(-cur_offset.x - 64, -cur_offset.y-64)
	
func _process(delta):
	if "player" in Globals.LevelLoaderRef.objByType and Globals.LevelLoaderRef.objByType["player"].size() > 0:
		_update_parallax(Globals.LevelLoaderRef.objByType["player"][0])
