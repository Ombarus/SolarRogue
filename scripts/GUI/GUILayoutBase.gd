extends Control

func _ready():
	BehaviorEvents.emit_signal("OnGUILoaded", self.name, self)
	self.set_process_input(false)
	self.set_process_unhandled_input(false)
	self.mouse_filter = Control.MOUSE_FILTER_IGNORE

func _input(ev):
	pass
	#print("blehbleh")

func _input_event(ev):
	print("bleh")
	
func _gui_input(event):
	print("_gui_input of HUD")