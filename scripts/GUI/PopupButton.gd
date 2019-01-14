extends Control

signal mount_pressed
signal look_pressed

onready var _more_btn = get_node("More")
onready var _close_btn = get_node("Close")
onready var _block = get_node("ScreenBlock")
onready var _popup = get_node("PopupSize/Popup")

func _ready():
	_more_btn.connect("pressed", self, "Pressed_More_Callback")
	_close_btn.connect("pressed", self, "Pressed_Close_Callback")
	
	#var repeat_height = _more_btn.get_height_line()
	#_popup.title_height = repeat_height

func Pressed_More_Callback():
	_more_btn.visible = false
	_popup.visible = true
	_popup.emit_signal("OnUpdateLayout")
	_close_btn.visible = true
	_block.visible = true
	
func Pressed_Close_Callback():
	_more_btn.visible = true
	_popup.visible = false
	_close_btn.visible = false
	_block.visible = false

func _on_Mount_pressed():
	emit_signal("mount_pressed")


func _on_Look_pressed():
	emit_signal("look_pressed")
