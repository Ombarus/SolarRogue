extends Node

# Declare member variables here. Examples:
# var a = 2
# var b = "text"

# Called when the node enters the scene tree for the first time.
func _ready():
	BehaviorEvents.connect("OnLevelLoaded", self, "OnLevelLoaded_Callback")
	BehaviorEvents.connect("OnPositionUpdated", self, "OnPositionUpdated_Callback")
	
	var vol : float = PermSave.get_attrib("settings.master_volume", 8.0)
	_set_bus_volume("Master", vol)
	vol = PermSave.get_attrib("settings.sfx_volume", 8.0)
	_set_bus_volume("Sfx", vol)
	vol = PermSave.get_attrib("settings.music_volume", 12.0)
	_set_bus_volume("Music", vol)
	
	
func _set_bus_volume(bus_name, vol):
	var bus : int = AudioServer.get_bus_index(bus_name)
	AudioServer.set_bus_volume_db(bus, -vol + 1)
	if vol >= 80:
		AudioServer.set_bus_mute(bus, true)
	else:
		AudioServer.set_bus_mute(bus, false)
	
func OnLevelLoaded_Callback():
	if has_node("BG") == true:
		get_node("BG").play()
	
func OnPositionUpdated_Callback(obj):
	if obj.get_attrib("type") == "player":
		var sfx_root = obj.find_node("MoveSFX", true, false)
		if sfx_root != null:
			var playid = MersenneTwister.rand(sfx_root.get_child_count())
			if not sfx_root.get_children()[playid].playing:
				sfx_root.get_children()[playid].play()