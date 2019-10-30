tool
extends Control
class_name MyWindow

export(bool) var dialog_ok = false setget set_dialog_ok
export(bool) var dialog_cancel = false setget set_dialog_cancel
export(bool) var disabled = false setget set_disabled
export(String) var bottom_title = "" setget set_reverse_title
export(String) var title = "" setget set_title
export(String, "═", "─", "━", " ") var border_style = "═" setget set_style

signal OnUpdateLayout()
signal OnOkPressed()
signal OnCancelPressed()

func GetFrameSize():
	return self.rect_size

func GetFrameOffset():
	return self.rect_position

func set_dialog_ok(newval):
	dialog_ok = newval
	emit_signal("OnUpdateLayout")
	if Engine.is_editor_hint():
		_ready()
	
func set_dialog_cancel(newval):
	dialog_cancel = newval
	emit_signal("OnUpdateLayout")
	
func set_disabled(newval):
	disabled = newval
	emit_signal("OnUpdateLayout")
	
func set_reverse_title(newval):
	bottom_title = newval
	emit_signal("OnUpdateLayout")
	
func set_title(newval):
	title = newval
	emit_signal("OnUpdateLayout")
	
func set_style(newval):
	border_style = newval
	emit_signal("OnUpdateLayout")
	
func _ready():
	if is_connected("OnUpdateLayout", self, "update_visual"):
		disconnect("OnUpdateLayout", self, "update_visual")
	connect("OnUpdateLayout", self, "update_visual")
	
	if is_connected("resized", self, "on_size_changed"):
		disconnect("resized", self, "on_size_changed")
	connect("resized", self, "on_size_changed")
	update_visual()
	
func update_visual():
	if has_node("Layouts") == false:
		return
	var node_to_show = "Layouts/"
	if border_style == "═":
		node_to_show += "Double"
	else:
		node_to_show += "Single"
	
	if title.empty() != true:
		node_to_show += "Title"
	
	var panel = get_node("Panel")
	if bottom_title.empty() != true:
		node_to_show += "Bottom"
		var left = get_node("Layouts/DoubleBottom/Left")
		var right = get_node("Layouts/DoubleBottom/Right")
		var f = get_node("TitleBottom").get_font("font")
		var title_width : float = f.get_string_size(bottom_title).x + 50.0
		var self_width = self.rect_size.x
		left.anchor_right = ANCHOR_BEGIN
		right.anchor_left = ANCHOR_BEGIN
		left.rect_position = Vector2(0.0, 0.0)
		right.rect_position = Vector2(title_width, 0.0)
		left.rect_size = Vector2(title_width, rect_size.y)
		right.rect_size = Vector2(self_width - title_width, rect_size.y)
		panel.visible = false
	else:
		panel.visible = true
		
	
	if dialog_ok == true:
		node_to_show += "Ok"
	if dialog_cancel == true:
		node_to_show += "Cancel"
		
	var dialog_nodes = get_node("Layouts").get_children()
	for n in dialog_nodes:
		n.visible = false
	
	if has_node(node_to_show) == true:
		get_node(node_to_show).visible = true
	get_node("Btn/Ok").visible = dialog_ok
	get_node("Btn/Ok").disabled = disabled
	get_node("Btn/Cancel").visible = dialog_cancel
	get_node("Btn/Cancel").disabled = disabled
	get_node("TitleUp").bbcode_text = title
	get_node("TitleBottom").text = bottom_title
	
func on_size_changed():
	call_deferred("emit_signal", "OnUpdateLayout")

func _on_Ok_pressed():
	get_node("ClickSFX").play()
	emit_signal("OnOkPressed")
	
func _on_Cancel_pressed():
	get_node("ClickSFX").play()
	emit_signal("OnCancelPressed")
	
func RegisterShortcut():
	if dialog_ok == true:
		BehaviorEvents.emit_signal("OnAddShortcut", "o", self, "_on_Ok_pressed")
		BehaviorEvents.emit_signal("OnAddShortcut", 16777221, self, "_on_Ok_pressed") # KEY_RETURN
		BehaviorEvents.emit_signal("OnAddShortcut", 16777222, self, "_on_Ok_pressed") # KEY_KP_RETURN
	if dialog_cancel == true:
		BehaviorEvents.emit_signal("OnAddShortcut", 16777217, self, "_on_Cancel_pressed")


func _on_btn_mouse_entered():
	get_node("HoverSFX").play()
