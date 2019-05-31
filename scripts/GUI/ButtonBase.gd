tool
extends Control
class_name ButtonBase

export var Text = "" setget set_text
export(String) var ShortcutKey = ""
export(int) var ShortcutEnum = 0
export(bool) var AlwaysOnShortcut = true
#export(ShortCut) var Action = null setget set_action
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
		

func _ready():
	get_node("base").connect("OnUpdateLayout", self, "OnUpdateLayout_Callback")
	set_text(Text)
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
	get_node("ClickSFX").play()
	emit_signal("pressed")

func RegisterShortcut():
	if ShortcutKey != "":
		BehaviorEvents.emit_signal("OnAddShortcut", ShortcutKey, self, "_on_btn_pressed")
	if ShortcutEnum != 0:
		BehaviorEvents.emit_signal("OnAddShortcut", ShortcutEnum, self, "_on_btn_pressed")

func _on_Button_visibility_changed():
	if AlwaysOnShortcut == false:
		if ShortcutKey != "":
			BehaviorEvents.emit_signal("OnEnableShortcut", ShortcutKey, self, "_on_btn_pressed", self.is_visible_in_tree())
		if ShortcutEnum != 0:
			BehaviorEvents.emit_signal("OnEnableShortcut", ShortcutEnum, self, "_on_btn_pressed", self.is_visible_in_tree())


func _on_btn_mouse_entered():
	get_node("HoverSFX").play()
