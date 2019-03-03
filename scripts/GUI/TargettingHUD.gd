extends "res://scripts/GUI/GUILayoutBase.gd"

signal skip_pressed()
signal cancel_pressed()

func _ready():
	pass
	
func Init(init_param):
	pass
	
func _on_Skip_pressed():
	emit_signal("skip_pressed")


func _on_Cancel_pressed():
	emit_signal("cancel_pressed")
