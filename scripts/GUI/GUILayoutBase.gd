extends Control

func _ready():
	BehaviorEvents.emit_signal("OnGUILoaded", self.name, self)
	self.set_process_input(false)
	self.set_process_unhandled_input(false)
	self.mouse_filter = Control.MOUSE_FILTER_IGNORE

# overridable function for loading dialog content
func Init(init_param):
	pass