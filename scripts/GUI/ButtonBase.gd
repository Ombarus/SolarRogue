tool
extends Control

export var Text = "" setget set_text
export(ShortCut) var Action = null setget set_action
signal pressed

func set_text(newval):
	Text = newval
	if has_node("btn"):
		get_node("btn").text = Text

func set_action(newval):
	Action = newval
	if has_node("btn"):
		get_node("btn").shortcut = Action
		

func _ready():
	set_text(Text)
	set_action(Action)

#func _process(delta):
#	# Called every frame. Delta is time since last frame.
#	# Update game logic here.
#	pass


func _on_btn_pressed():
	emit_signal("pressed")
