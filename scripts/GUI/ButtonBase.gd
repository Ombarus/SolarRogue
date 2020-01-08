tool
extends Control
class_name ButtonBase

export var Text = "" setget set_text
export(String) var ShortcutKey = ""
export(int) var ShortcutEnum = 0
export(bool) var AlwaysOnShortcut = true
#export(ShortCut) var Action = null setget set_action
export(bool) var Disabled = false setget set_disabled
export(StyleBox) var HighlightStyle
export(bool) var IsHUD = false
signal pressed
signal down
signal up

var _prev_style : StyleBox = null

func set_disabled(newval):
	get_node("btn").disabled = newval
	Disabled = newval

func get_height_line():
	return get_node("base").get_height_line()

func set_text(newval):
	Text = newval
	var trans_text = Text
	if not Engine.editor_hint and newval != "":
		trans_text = Globals.mytr(newval)
	if has_node("btn"):
		get_node("btn").text = trans_text
		
func OnLocaleChanged_Callback():
	set_text(Text)

func _ready():
	BehaviorEvents.connect("OnHighlightUIElement", self, "Hightlight_Callback")
	BehaviorEvents.connect("OnResetHighlight", self, "ResetHightlight_Callback")
	BehaviorEvents.connect("OnHUDVisiblityChanged", self, "OnHUDVisiblityChanged_Callback")
	BehaviorEvents.connect("OnLocaleChanged", self, "OnLocaleChanged_Callback")
	get_node("base").connect("OnUpdateLayout", self, "OnUpdateLayout_Callback")
	#set_text(Text)
	OnUpdateLayout_Callback()
	if IsHUD == true and Engine.is_editor_hint() == false:
		self.visible = not PermSave.get_attrib("settings.hide_hud")

func OnHUDVisiblityChanged_Callback():
	if IsHUD and Engine.is_editor_hint() == false:
		self.visible = not PermSave.get_attrib("settings.hide_hud")

func ResetHightlight_Callback():
	get_node("AnimationPlayer").stop(true)
	if _prev_style != null:
		get_node("btn").set('custom_styles/normal', _prev_style)

func Hightlight_Callback(id):
	if name == id:
		get_node("AnimationPlayer").play("highlight")
		_prev_style = get_node("btn").get("custom_styles/normal")
		get_node("btn").set('custom_styles/normal', HighlightStyle)
		
func OnUpdateLayout_Callback():
	var frame_size : Vector2 = get_node("base").GetFrameSize()
	var frame_offset : Vector2 = get_node("base").GetFrameOffset()
	var btn : Button = get_node("btn")
	btn.rect_size = frame_size
	btn.rect_position = frame_offset

func _on_btn_pressed():
	if get_node("btn").get("custom_styles/normal") == HighlightStyle:
		BehaviorEvents.emit_signal("OnResetHighlight")
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


func _on_btn_button_down():
	emit_signal("down")


func _on_btn_button_up():
	emit_signal("up")
