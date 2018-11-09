tool
extends Control

export(bool) var editor_trigger_signal = true setget set_signal
export(String) var title = "" setget set_title
export(String) var content = "" setget set_content

var _window_size
var _font_size

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
		self.disconnect("resized", self, "on_size_changed")
		self.connect("resized", self, "on_size_changed")
	
	
func set_title(val):
	title = val
	update()
	
func set_content(val):
	content = val
	update()
	
func update():
	if _font_size == null:
		return
		
	var top_string = "╔"
	var side_string = "║"
	var bottom_string = "╚"
	var header_string = "╟"
	var repeat_empty = " "
	var repeat_line = "═"
	var repeat_header = "─"
	
	var repeat_width = int(floor((_window_size.x - (_font_size.x/2.0)) / _font_size.x))
	var repeat_height = int(floor((_window_size.y - (_font_size.y/2.0)) / _font_size.y))
	#print("window_size.y ", _window_size.y, ", font_size.y ", _font_size.y)
	
	for i in range(0,repeat_width - 2):
		top_string += repeat_line
		side_string += repeat_empty
		bottom_string += repeat_line
		header_string += repeat_header
		
	top_string += "╗"
	side_string += "║"
	bottom_string += "╝"
	header_string += "╢"
	
	var header_height = 2
	var final_window_string = top_string + "\n"
	if !title.empty():
		final_window_string += side_string + "\n"
		final_window_string += header_string + "\n"
		header_height = 4
	
	for i in range(0, repeat_height-header_height):
		final_window_string += side_string + "\n"
	
	final_window_string += bottom_string
	
	#print("repeat_width ", repeat_width, ", repeat_height ", repeat_height)
	
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

