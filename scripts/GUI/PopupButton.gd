extends Control

signal look_pressed
signal board_pressed
signal take_pressed
signal wait_pressed
signal crew_pressed
signal comm_pressed

onready var _more_btn = get_node("More")
onready var _close_btn = get_node("Close")
onready var _block = get_node("ScreenBlock")
onready var _popup = get_node("PopupSize/Popup")
onready var _popupsize = get_node("PopupSize")
onready var _animator = get_node("AnimationPlayer")
var _comm_btn

func EnableComm(is_enabled : bool):
	_comm_btn.Disabled = not is_enabled

func _ready():
	if has_node("PopupSize/HBoxContainer/Comm"):
		_comm_btn = get_node("PopupSize/HBoxContainer/Comm")
	else:
		_comm_btn = get_node("PopupSize/Popup/Comm")
	_more_btn.connect("pressed", self, "Pressed_More_Callback")
	_close_btn.connect("pressed", self, "Pressed_Close_Callback")
	
	var n = get_node("/root/Root/Behaviors/Player")
	n.comm_btn_ref = self
	
	#var repeat_height = _more_btn.get_height_line()
	#_popup.title_height = repeat_height

func Pressed_More_Callback():
	if _block.visible == false:
		#_more_btn.visible = false
		_popupsize.modulate = Color(1.0, 1.0, 1.0, 0.0)
		_popupsize.visible = true
		_popup.emit_signal("OnUpdateLayout")
		_animator.play("popin")
		var nodes = get_tree().get_nodes_in_group("more_btn")
		for n in nodes:
			n.get_node("base").emit_signal("OnUpdateLayout")
		#_close_btn.visible = true
		_block.visible = true
	else:
		_animator.play_backwards("popin")
		_animator.connect("animation_finished", self, "animation_finished_Callback")
		#_more_btn.visible = true
		#_popup.visible = false
		#_close_btn.visible = false
		_block.visible = false
		
	
func Pressed_Close_Callback():
	#_more_btn.visible = true
	_animator.play_backwards("popin")
	_animator.connect("animation_finished", self, "animation_finished_Callback")
	#_popup.visible = false
	_close_btn.visible = false
	_block.visible = false

func _on_Look_pressed():
	Pressed_Close_Callback()
	emit_signal("look_pressed")
	
func animation_finished_Callback(anim_name):
	_popupsize.visible = false
	_animator.disconnect("animation_finished", self, "animation_finished_Callback")


func _on_Board_pressed():
	Pressed_Close_Callback()
	emit_signal("board_pressed")


func _on_Take_pressed():
	Pressed_Close_Callback()
	emit_signal("take_pressed")


func _on_Wait_pressed():
	#Pressed_Close_Callback()
	emit_signal("wait_pressed")


func _on_Crew_pressed():
	Pressed_Close_Callback()
	emit_signal("crew_pressed")


func _on_Comm_pressed():
	Pressed_Close_Callback()
	emit_signal("comm_pressed")
