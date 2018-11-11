tool
extends Control

export var Text = "" setget set_text
export(int) var Action = "" setget set_action
signal pressed

func set_text(newval):
	Text = newval
	if get_node("btn") != null:
		get_node("btn").text = Text

func set_action(newval):
	Action = newval
	if get_node("btn") != null:
		get_node("btn").shortcut.shortcut.scancode = Action
		

func _ready():
	set_text(Text)

#func _process(delta):
#	# Called every frame. Delta is time since last frame.
#	# Update game logic here.
#	pass


func _on_btn_pressed():
	emit_signal("pressed")
