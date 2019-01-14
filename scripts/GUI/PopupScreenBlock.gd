extends Control


func _unhandled_input(event):
	if self.visible == true and event.is_action_released("touch"):
		get_parent().Pressed_Close_Callback()
		get_tree().set_input_as_handled()

func _ready():
	# Called when the node is added to the scene for the first time.
	# Initialization here
	pass
