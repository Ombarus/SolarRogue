tool
extends Control

export(bool) var editor_trigger_signal = true setget set_signal

export(bool) var dialog_ok = false setget set_dialog_ok
export(bool) var dialog_cancel = false setget set_dialog_cancel
export(String) var title = "" setget set_title
export(Array) var content = [] setget set_content
export(String, "═", "─", "━", " ") var border_style = "=" setget set_style

signal OnOkPressed()
signal OnCancelPressed()

var _base = null

func set_signal(newval):
	editor_trigger_signal = false
	if Engine.is_editor_hint():
		init()
		if _base:
			_base.init()

func set_dialog_ok(val):
	dialog_ok = val
	if _base:
		_base.dialog_ok = dialog_ok
		
func set_dialog_cancel(val):
	dialog_cancel = val
	if _base:
		_base.dialog_cancel = dialog_cancel
		
func set_title(val):
	title = val
	if _base:
		_base.title = title
	
func set_content(val):
	content = val
	if not has_node("base/Content"):
		return
	var content_node = get_node("base/Content")
	content_node.clear()
	if content:
		for i in content:
			content_node.add_item(str(i))
		
func set_style(val):
	border_style = val
	if _base:
		_base.border_style = border_style

func init():
	if not has_node("base"):
		return
		
	_base = get_node("base")
	if _base.is_connected("OnUpdateLayout", self, "update"):
		_base.disconnect("OnUpdateLayout", self, "update")
	_base.connect("OnUpdateLayout", self, "update")
	_base.title = title
	_base.dialog_ok = dialog_ok
	_base.dialog_cancel = dialog_cancel
	_base.border_style = border_style
	
	if _base.is_connected("OnOkPressed", self, "ForwardOk"):
		_base.disconnect("OnOkPressed", self, "ForwardOk")
	_base.connect("OnOkPressed", self, "ForwardOk")
		
	if _base.is_connected("OnCancelPressed", self, "ForwardCancel"):
		_base.disconnect("OnCancelPressed", self, "ForwardCancel")
	_base.connect("OnCancelPressed", self, "ForwardCancel")

func _ready():
	init()
	
func update():
	var content_node = get_node("base/Content")
	if _base.title.empty():
		content_node.margin_top = 18
	else:
		content_node.margin_top = 54
	
	set_content(content)

func ForwardOk():
	emit_signal("OnOkPressed")
func ForwardCancel():
	emit_signal("OnCancelPressed")
