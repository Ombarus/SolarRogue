extends Node2D

# class member variables go here, for example:
# var a = 2
# var b = "textvar"

export var base_attributes = {} # can be kept by reference, no need to serialize
export var modified_attributes = {} # locally modified attribute (like current position). Should be saved !


func init_cargo():
	if modified_attributes.has("cargo") or not base_attributes.has("cargo"):
		return
	
	modified_attributes["cargo"] = {}
	modified_attributes.cargo["content"] = base_attributes.cargo.content
	modified_attributes.cargo["volume_used"] = 0
	for item in modified_attributes.cargo.content:
		var item_data = Globals.LevelLoaderRef.LoadJSON(item.src)
		var vol = item_data.equipment.volume
		modified_attributes.cargo["volume_used"] += vol * item.count

func init_mounts():
	if modified_attributes.has("mounts") or not base_attributes.has("mounts"):
		return
		
	modified_attributes["mounts"] = base_attributes.mounts

func _ready():
	# Called when the node is added to the scene for the first time.
	# Initialization here
	pass

#func _process(delta):
#	# Called every frame. Delta is time since last frame.
#	# Update game logic here.
#	pass
