extends Node

# Declare member variables here. Examples:
# var a = 2
# var b = "text"

# Called when the node enters the scene tree for the first time.
func _ready():
	BehaviorEvents.connect("OnLevelLoaded", self, "OnLevelLoaded_Callback")
	BehaviorEvents.connect("OnMovementValidated", self, "OnPositionUpdated_Callback")
	BehaviorEvents.connect("OnCameraZoomed", self, "OnCameraZoomed_Callback")
	BehaviorEvents.connect("OnDamageTaken", self, "OnDamageTaken_Callback")
	BehaviorEvents.connect("OnEnergyChanged", self, "OnEnergyChanged_Callback")
	BehaviorEvents.connect("OnCrafting", self, "OnCrafting_Callback")
	
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
	
func OnPositionUpdated_Callback(obj, dir):
	if obj.get_attrib("type") == "player":
		var sfx_root = obj.find_node("MoveSFX", true, false)
		if sfx_root != null:
			var playid = MersenneTwister.rand(sfx_root.get_child_count())
			if not sfx_root.get_children()[playid].playing:
				sfx_root.get_children()[playid].play()
				
func OnCameraZoomed_Callback(current_zoom):
	var p = Globals.get_first_player()
	var sfx_root = p.find_node("BG", true, false)
	if sfx_root != null:
		if current_zoom.x >= 1.0:
			for child in sfx_root.get_children():
				child.stop()
		else:
			var playid = MersenneTwister.rand(sfx_root.get_child_count())
			if not sfx_root.get_children()[playid].playing:
				sfx_root.get_children()[playid].play()
				
func OnDamageTaken_Callback(target, shooter):
	var is_player = target.get_attrib("type") == "player"
	if not is_player:
		return
	
	var max_hull = target.get_attrib("destroyable.hull")
	var cur_hull = target.get_attrib("destroyable.current_hull", max_hull)
	if cur_hull < max_hull / 4.0 and cur_hull > 0:
		get_node("LowHullAlert").play()
		
func OnEnergyChanged_Callback(obj):
	var is_player = obj.get_attrib("type") == "player"
	if not is_player:
		return
	
	var cur_energy = obj.get_attrib("converter.stored_energy")
	if cur_energy < 1000: # stolen from statusbar
		get_node("LowEnergyAlert").play()

func OnCrafting_Callback(crafter, result):
	var is_player = crafter.get_attrib("type") == "player"
	if not is_player:
		return
	
	if result == Globals.CRAFT_RESULT.success:
		get_node("Crafted").play()