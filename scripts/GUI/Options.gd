extends "res://scripts/GUI/GUILayoutBase.gd"

onready var _base = get_node("base")

# Called when the node enters the scene tree for the first time.
func _ready():
	_base.connect("OnOkPressed", self, "Ok_Callback")
	_base.connect("OnCancelPressed", self, "Ok_Callback")
	
		
func Init(init_param):
	_base.disabled = false
	

func Ok_Callback():
	BehaviorEvents.emit_signal("OnPopGUI")
	_base.disabled = true

func _on_Save_pressed():
	Globals.LevelLoaderRef.SaveState(Globals.LevelLoaderRef.GetCurrentLevelData())
	BehaviorEvents.emit_signal("OnLogLine", "Game saved")


func _on_Suicide_pressed():
	BehaviorEvents.emit_signal("OnPushGUI", "ValidateDiag", {"callback_object":self, "callback_method":"On_Suicide_Confirmed_Callback", "custom_text":"CONFIRM delete save"})


func _on_SaveAndQuit_pressed():
	Globals.LevelLoaderRef.SaveStateAndQuit(Globals.LevelLoaderRef.GetCurrentLevelData())

func On_Suicide_Confirmed_Callback():
	BehaviorEvents.emit_signal("OnPopGUI")
	BehaviorEvents.emit_signal("OnPlayerDeath")

func _on_Settings_pressed():
	BehaviorEvents.emit_signal("OnPushGUI", "Settings", {})


func _on_Help_pressed():
	BehaviorEvents.emit_signal("OnPushGUI", "Tutorial", {})
