extends "res://scripts/GUI/GUILayoutBase.gd"

onready var _counter : Label = get_node("Label")

func _ready():
	self.visible = PermSave.get_attrib("settings.display_fps")

func _process(delta):
	var cur_fps : float = Engine.get_frames_per_second()
	_counter.text = "FPS : %.f" % cur_fps
