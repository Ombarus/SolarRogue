tool
extends Control

export var Text = "" setget set_text
export(ShortCut) var Action = null setget set_action
export(bool) var Disabled = false setget set_disabled
signal pressed

func set_disabled(newval):
	get_node("btn").disabled = newval
	Disabled = newval

func get_height_line():
	return get_node("base").get_height_line()

func set_text(newval):
	Text = newval
	if has_node("btn"):
		get_node("btn").text = Text

func set_action(newval):
	Action = newval
	if has_node("btn"):
		get_node("btn").shortcut = Action
		

func _ready():
	get_node("base").connect("OnUpdateLayout", self, "OnUpdateLayout_Callback")
	set_text(Text)
	set_action(Action)
	OnUpdateLayout_Callback()

#func _process(delta):
#	# Called every frame. Delta is time since last frame.
#	# Update game logic here.
#	pass

func OnUpdateLayout_Callback():
	var frame_size : Vector2 = get_node("base").GetFrameSize()
	var frame_offset : Vector2 = get_node("base").GetFrameOffset()
	var btn : Button = get_node("btn")
	btn.rect_size = frame_size
	btn.rect_position = frame_offset

func _on_btn_pressed():
	emit_signal("pressed")
