tool
extends Control

export(bool) var editor_trigger_signal = true setget set_signal
export(bool) var dialog_ok = false setget set_dialog_ok
export(bool) var dialog_cancel = false setget set_dialog_cancel
export(bool) var disabled = false setget set_disabled
export(String) var bottom_title = "" setget set_reverse_title
export(int) var title_height = 1 setget set_title_height
export(String) var title = "" setget set_title
export(String, "═", "─", "━", " ") var border_style = "=" setget set_style
export(int) var LineHeightOverride = 20 setget set_line_height

signal OnOkPressed()
signal OnCancelPressed()
signal OnUpdateLayout()

var _window_size
var _font_size
var string_dict = string_double

#var btn_margin_bottom
#var btn_margin_top
#var btn_offset = 0

const string_double = {
	"top_left": "╔",
	"side": "║",
	"bottom_left": "╚",
	"header_left": "╟",
	"repeat_empty": " ",
	"repeat_line": "═",
	"repeat_header": "─",
	"top_right": "╗",
	"bottom_right": "╝",
	"header_right": "╢"
}

const string_simple = {
	"top_left": "┌",
	"side": "│",
	"bottom_left": "└",
	"header_left": "├",
	"repeat_empty": " ",
	"repeat_line": "─",
	"repeat_header": "─",
	"top_right": "┐",
	"bottom_right": "┘",
	"header_right": "┤"
}

const string_simple_thick = {
	"top_left": "┏",
	"side": "┃",
	"bottom_left": "┗",
	"header_left": "┠",
	"repeat_empty": " ",
	"repeat_line": "━",
	"repeat_header": "─",
	"top_right": "┓",
	"bottom_right": "┛",
	"header_right": "┨"
}

const string_empty = {
	"top_left": " ",
	"side": " ",
	"bottom_left": " ",
	"header_left": " ",
	"repeat_empty": " ",
	"repeat_line": " ",
	"repeat_header": " ",
	"top_right": " ",
	"bottom_right": " ",
	"header_right": " "
}

func GetFrameSize():
	var repeat_width = int(floor((_window_size.x) / _font_size.x))
	var repeat_height = int(floor((_window_size.y / _font_size.y)))
	var frame_size := Vector2(repeat_width*_font_size.x, repeat_height*_font_size.y)
	var res := Vector2(frame_size.x - (_font_size.x / 1.7), frame_size.y - (_font_size.y))
	return res
	
func GetFrameOffset():
	return get_node("bg").rect_position

func set_line_height(newval):
	LineHeightOverride = newval
	self.emit_signal("OnUpdateLayout")

func get_height_line():
	return int(floor((_window_size.y / _font_size.y)))

func set_title_height(val):
	title_height = val
	self.emit_signal("OnUpdateLayout")

func set_dialog_ok(val):
	dialog_ok = val
	self.emit_signal("OnUpdateLayout")
	
func set_dialog_cancel(val):
	dialog_cancel = val
	self.emit_signal("OnUpdateLayout")

func set_style(style):
	border_style = style
	if border_style == "═":
		string_dict = string_double
	elif border_style == " ":
		string_dict = string_empty
	elif border_style == "─":
		string_dict = string_simple
	elif border_style == "━":
		string_dict = string_simple_thick
	self.emit_signal("OnUpdateLayout")
	
func set_disabled(newval):
	var ok_btn = get_node("bg/contour/Control/Ok")
	var cancel_btn = get_node("bg/contour/Control/Cancel")
	ok_btn.disabled = newval
	cancel_btn.disabled = newval
	disabled = newval
	
func set_reverse_title(newval):
	bottom_title = newval
	self.emit_signal("OnUpdateLayout")

func _ready():
	init()
	self.emit_signal("OnUpdateLayout")
	
func init():
	if has_node("width_test"):
		var font = get_node("width_test").get_font("font")
		if font == null:
			return
			
#		btn_margin_bottom = get_node("bg/contour/Ok").margin_bottom + btn_offset
#		btn_margin_top = get_node("bg/contour/Ok").margin_top + btn_offset
#		btn_offset = 0
#		print("offset ", btn_offset, ", btn_margin top,bottom = (", btn_margin_top, ", ", btn_margin_bottom, ")")
		
		var test_string = string_dict.side
		_font_size = font.get_string_size(test_string)
		if LineHeightOverride > 0:
			_font_size.y = LineHeightOverride
		_window_size = self.get_rect().size
		if self.is_connected("OnUpdateLayout", self, "update"):
			self.disconnect("OnUpdateLayout", self, "update")
		self.connect("OnUpdateLayout", self, "update")
		if self.is_connected("resized", self, "on_size_changed"):
			self.disconnect("resized", self, "on_size_changed")
		self.connect("resized", self, "on_size_changed")
		set_style(border_style)
	
	
func set_title(val):
	title = val
	self.emit_signal("OnUpdateLayout")
	
func update():
	if _font_size == null || not has_node("bg/contour/Control/Ok"):
		return

	var ok_btn = get_node("bg/contour/Control/Ok")
	var cancel_btn = get_node("bg/contour/Control/Cancel")
	
	if ok_btn:
		ok_btn.visible = dialog_ok
	if cancel_btn:
		cancel_btn.visible = dialog_cancel
		
	var top_string = string_dict.top_left
	var side_string = string_dict.side
	var bottom_string = string_dict.bottom_left
	var header_string = string_dict.header_left
	var repeat_empty = string_dict.repeat_empty
	var repeat_line = string_dict.repeat_line
	var repeat_header = string_dict.repeat_header
	
	var title_width := 0
	var title_space_needed := 0
	if bottom_title != null and bottom_title.length() > 0:
		var f = get_node("bg/contour/Title2").get_font("font")
		title_width = f.get_string_size(bottom_title).x
		title_space_needed = int(ceil(title_width / _font_size.x))
		#title_width = title.length() * _font_size.x
	
	var repeat_width = int(floor((_window_size.x) / _font_size.x))
	var remainder_width = (_window_size.x / _font_size.x) - repeat_width
	remainder_width = remainder_width * _font_size.x
	#get_node("bg").margin_right = -remainder_width - (_font_size.x / 2.0) # remove half font-size to have the bg be half inside the border
	get_node("bg/contour").margin_right = remainder_width + (_font_size.x / 2.0)
	var repeat_height = int(floor((_window_size.y / _font_size.y)))
	var remainder_height = (_window_size.y / _font_size.y) - repeat_height
	remainder_height = remainder_height * _font_size.y
	#get_node("bg").margin_bottom = -remainder_height# - (_font_size.y / 2.0)
	var frame_size := Vector2(repeat_width*_font_size.x, repeat_height*_font_size.y)
	get_node("bg").rect_size.x = frame_size.x - (_font_size.x / 1.7) # remove half font-size to have the bg be half inside the border
	get_node("bg").rect_size.y = frame_size.y - (_font_size.y)
	get_node("bg/contour").margin_bottom = remainder_height + (_font_size.y / 1.2)
	
	ok_btn.margin_top = -remainder_height
	ok_btn.margin_bottom = -remainder_height
	cancel_btn.margin_top = -remainder_height
	cancel_btn.margin_bottom = -remainder_height
	
#	get_node("bg/contour/Ok").margin_bottom = btn_margin_bottom - remainder_height
#	get_node("bg/contour/Ok").margin_top = btn_margin_top - remainder_height
#	get_node("bg/contour/Cancel").margin_bottom = btn_margin_bottom - remainder_height
#	get_node("bg/contour/Cancel").margin_top = btn_margin_top - remainder_height
#	print("btn_offset = ", remainder_height)
#	btn_offset = remainder_height

	#if get_parent() != null:
	#	var format = "%s : _window_size (%d, %d), _font_size (%d, %d), repeat_width (%d, %d)"
	#	format = format % [get_parent().name, _window_size.x, _window_size.y, _font_size.x, _font_size.y, repeat_width, repeat_height]
	#	print(format)
	
	for i in range(0,repeat_width - 2):
		top_string += repeat_line
		side_string += repeat_empty
		
		var start_ok_x = ok_btn.rect_position.x - _font_size.x
		var end_ok_x = ok_btn.rect_position.x + ok_btn.rect_size.x
		var start_cancel_x = cancel_btn.rect_position.x - (2*_font_size.x)
		var end_cancel_x = cancel_btn.rect_position.x + cancel_btn.rect_size.x
		# i+1 because we've already done the 1 char corner
		var cur_x = (i+1) * _font_size.x + get_node("bg/contour").rect_position.x + get_node("bg/contour").margin_left
		if (cur_x < start_ok_x || cur_x > end_ok_x || not dialog_ok) && (cur_x < start_cancel_x || cur_x > end_cancel_x || not dialog_cancel):
			bottom_string += repeat_line
		else:
			bottom_string += repeat_empty
		
		header_string += repeat_header
		
	top_string += string_dict.top_right
	side_string += string_dict.side
	bottom_string += string_dict.bottom_right 
	header_string += string_dict.header_right
	
	########## MAKING THE BOTTOM TITLE ##################
	var inverse_title_string := ""
	if bottom_title != null and bottom_title.length() > 0:
		inverse_title_string += string_dict.header_left
		for i in range(title_space_needed):
			inverse_title_string += string_dict.repeat_header
		inverse_title_string += string_dict.top_left
		for i in range(repeat_width - 3 - title_space_needed):
			inverse_title_string += string_dict.repeat_line
		inverse_title_string += string_dict.bottom_right + "\n"
		inverse_title_string += string_dict.side
		for i in range(title_space_needed):
			inverse_title_string += string_dict.repeat_empty
		inverse_title_string += string_dict.side + "\n"
		inverse_title_string += string_dict.bottom_left
		for i in range(title_space_needed):
			inverse_title_string += string_dict.repeat_line
		inverse_title_string += string_dict.bottom_right
			
	
	#####################################################
	
	var header_height = 2
	var final_window_string = top_string + "\n"
	if !title.empty():
		for i in range(title_height):
			final_window_string += side_string + "\n"
		final_window_string += header_string + "\n"
		header_height = 3 + title_height
	
	for i in range(0, repeat_height-header_height):
		final_window_string += side_string + "\n"
	
	if bottom_title != null and bottom_title.length() > 0:
		final_window_string += inverse_title_string
	else:
		final_window_string += bottom_string
	
	#get_node("bg/contour").text = final_window_string
	get_node("bg/contour/Title").text = title
	get_node("bg/contour/Title2").text = bottom_title


func on_size_changed():
	_window_size = self.get_rect().size
	self.emit_signal("OnUpdateLayout")


func set_signal(newval):
	editor_trigger_signal = false
	if Engine.is_editor_hint():
		init()


func _on_Ok_pressed():
	emit_signal("OnOkPressed")
	
	
func _on_Cancel_pressed():
	emit_signal("OnCancelPressed")
	
func RegisterShortcut():
	if dialog_ok == true:
		BehaviorEvents.emit_signal("OnAddShortcut", "o", self, "_on_Ok_pressed")
	if dialog_cancel == true:
		BehaviorEvents.emit_signal("OnAddShortcut", 16777217, self, "_on_Cancel_pressed")
