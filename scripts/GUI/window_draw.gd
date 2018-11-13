tool
extends Control

export(bool) var editor_trigger_signal = true setget set_signal
export(bool) var dialog_ok = false setget set_dialog_ok
export(bool) var dialog_cancel = false setget set_dialog_cancel
export(String) var title = "" setget set_title
export(String) var content = "" setget set_content
export(String, "═", "─", "━", " ") var border_style = "=" setget set_style

var _window_size
var _font_size
var string_dict = string_double

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

func set_dialog_ok(val):
	dialog_ok = val
	update()
	
func set_dialog_cancel(val):
	dialog_cancel = val
	update()

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
	update()

func _ready():
	init()
	update()
	
func init():
	if _font_size == null && has_node("width_test"):
		var font = get_node("width_test").get_font("font")
		if font == null:
			return
		_font_size = font.get_string_size("a")
		_window_size = self.get_rect().size
		if self.is_connected("resized", self, "on_size_changed"):
			self.disconnect("resized", self, "on_size_changed")
		self.connect("resized", self, "on_size_changed")
		set_style(border_style)
	
	
func set_title(val):
	title = val
	update()
	
func set_content(val):
	content = val
	update()
	
func update():
	if _font_size == null || not has_node("bg/contour/Ok"):
		return

	var ok_btn = get_node("bg/contour/Ok")
	var cancel_btn = get_node("bg/contour/Cancel")
	
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
	
	var repeat_width = int(floor((_window_size.x - (_font_size.x/2.0)) / _font_size.x))
	var repeat_height = int(floor((_window_size.y - (_font_size.y/2.0)) / _font_size.y))
	
	for i in range(0,repeat_width - 2):
		top_string += repeat_line
		side_string += repeat_empty
		
		var start_ok_x = ok_btn.rect_position.x - _font_size.x
		var end_ok_x = ok_btn.rect_position.x + ok_btn.rect_size.x
		var start_cancel_x = cancel_btn.rect_position.x - _font_size.x
		var end_cancel_x = cancel_btn.rect_position.x + cancel_btn.rect_size.x
		var cur_x = i * _font_size.x + self.rect_position.x
		if (cur_x < start_ok_x || cur_x > end_ok_x || not dialog_ok) && (cur_x < start_cancel_x || cur_x > end_cancel_x || not dialog_cancel):
			bottom_string += repeat_line
		else:
			bottom_string += repeat_empty
		
		header_string += repeat_header
		
	top_string += string_dict.top_right
	side_string += string_dict.side
	bottom_string += string_dict.bottom_right
	header_string += string_dict.header_right
	
	var header_height = 2
	var final_window_string = top_string + "\n"
	if !title.empty():
		final_window_string += side_string + "\n"
		final_window_string += header_string + "\n"
		header_height = 4
	
	for i in range(0, repeat_height-header_height):
		final_window_string += side_string + "\n"
	
	final_window_string += bottom_string
	
	get_node("bg/contour").bbcode_text = final_window_string
	
	get_node("bg/contour/Title").bbcode_text = title
	var content_node = get_node("bg/contour/Content")
	if title.empty():
		content_node.margin_top = 18
	else:
		content_node.margin_top = 54
	content_node.bbcode_text = content

func on_size_changed():
	_window_size = self.get_rect().size
	update()


func set_signal(newval):
	editor_trigger_signal = false
	if Engine.is_editor_hint():
		init()
	
#func _process(delta):
#	# Called every frame. Delta is time since last frame.
#	# Update game logic here.
#	pass

