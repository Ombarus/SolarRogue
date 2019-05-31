extends "res://scripts/GUI/GUILayoutBase.gd"

onready var _vol_master: HSlider = get_node("base/VBoxContainer/MasterVolume/MasterSlider")
onready var _vol_sfx: HSlider = get_node("base/VBoxContainer/SFXVolume/SFXSlider")
onready var _vol_music: HSlider = get_node("base/VBoxContainer/MusicVolume/MusicSlider")

func _ready():
	get_node("base").connect("OnOkPressed", self, "Ok_Callback")
	_vol_master.connect("value_changed", self, "value_changed_Callback", [AudioServer.get_bus_index("Master"), "master_volume"])
	_vol_sfx.connect("value_changed", self, "value_changed_Callback", [AudioServer.get_bus_index("Sfx"), "sfx_volume"])
	_vol_music.connect("value_changed", self, "value_changed_Callback", [AudioServer.get_bus_index("Music"), "music_volume"])
	
	
func Ok_Callback():
	BehaviorEvents.emit_signal("OnPopGUI")
		
	
func Init(init_param):
	var fs : bool = PermSave.get_attrib("settings.full_screen", false)
	get_node("base/VBoxContainer/FullScreen/CheckButton").pressed = fs
	
	var vol : float = PermSave.get_attrib("settings.master_volume", 8.0)
	_vol_master.value = vol
	vol = PermSave.get_attrib("settings.sfx_volume", 8.0)
	_vol_sfx.value = vol
	vol = PermSave.get_attrib("settings.music_volume", 12.0)
	_vol_music.value = vol
	

func _on_CheckButton_toggled(button_pressed):
	OS.set_window_fullscreen(button_pressed)
	PermSave.set_attrib("settings.full_screen", button_pressed)


func value_changed_Callback(value, bus, save_name):
	PermSave.set_attrib("settings." + save_name, value)
	AudioServer.set_bus_volume_db(bus, -value + 1)
	if value >= 80:
		#TODO: should show an icon when sound is totaly muted
		AudioServer.set_bus_mute(bus, true)
	else:
		AudioServer.set_bus_mute(bus, false)
