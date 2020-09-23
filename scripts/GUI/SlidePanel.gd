extends Control

enum SLIDE_SIDE {
	left = 0,
	right = 1
}

export(float) var size_percent := 0.5
export(SLIDE_SIDE) var slide_side := SLIDE_SIDE.left

onready var initial_width : float = self.rect_size.x
onready var tween : Tween = get_node("Tween")

var move_by : float = 0
var extended : bool = true
var initialized : bool = false
var current_target

var default_margin_left
var default_rect_size

func _ready():
	
	var n = get_node("/root/Root/Behaviors/Player")
	if has_node("VBoxContainer/Converter"):
		var conv_btn = get_node("VBoxContainer/Converter")
		if conv_btn.visible == true:
			n.conv_btn_ref = conv_btn
	if has_node("VBoxContainer/Weapon"):
		var weapon_btn = get_node("VBoxContainer/Weapon")
		if weapon_btn.visible == true:
			n.weapon_btn_ref = weapon_btn
	
	move_by = initial_width * size_percent
	_on_base_mouse_exited(0.0)


func _on_base_mouse_entered():
	if not extended:
		var offset := 0.0
		var time_scale = 1.0
		if tween.is_active():
			tween.remove_all()
			if slide_side == SLIDE_SIDE.left:
				offset = current_target.x - self.rect_size.x
			else:
				offset = current_target - self.margin_left
		var target_name := ""
		if slide_side == SLIDE_SIDE.left:
			current_target = Vector2(self.rect_size.x + move_by + offset, self.rect_size.y)
			target_name = "rect_size"
		elif slide_side == SLIDE_SIDE.right:
			current_target = self.margin_left - move_by + offset
			target_name = "margin_left"
		time_scale = abs(move_by - offset) / abs(move_by)
		_start_tween(target_name, current_target, time_scale)
		extended = true


func _on_base_mouse_exited(var overide_time_scale = 1.0):
	if extended:
		if not initialized:
			tween.connect("tween_all_completed", self, "init_clamps")
		var offset := 0.0
		var time_scale = 1.0
		if tween.is_active():
			tween.remove_all()
			if slide_side == SLIDE_SIDE.left:
				offset = current_target.x - self.rect_size.x
			else:
				offset = current_target - self.margin_left
		var target_name := ""
		if slide_side == SLIDE_SIDE.left:
			current_target = Vector2(self.rect_size.x - move_by + offset, self.rect_size.y)
			#print(str(self.rect_size.x) + " target " + str(current_target))
			if initialized and current_target.x < default_rect_size.x:
				print("CORRECTED LEFT!")
				current_target = default_rect_size
			target_name = "rect_size"
		elif slide_side == SLIDE_SIDE.right:
			current_target = self.margin_left + move_by + offset
			#print(str(self.margin_left) + " target " + str(current_target))
			if initialized and current_target > default_margin_left:
				print("CORRECTED RIGHT!")
				current_target = default_margin_left
			target_name = "margin_left"
		time_scale = abs(move_by + offset) / abs(move_by)
		_start_tween(target_name, current_target, time_scale * overide_time_scale)
		extended = false
		
func _start_tween(target_name : String, target_value, var time_scale : float=1.0):
	var default_time = 0.4
	tween.interpolate_property(
		self, 
		target_name, 
		null,
		target_value,
		default_time * time_scale, Tween.TRANS_CUBIC, Tween.EASE_OUT)
	tween.start()

func _process(delta):
	var pos : Vector2 = get_global_mouse_position()
	var my_area : Rect2 = get_global_rect()
	if my_area.has_point(pos):
		_on_base_mouse_entered()
	elif extended:
		_on_base_mouse_exited()

func init_clamps():
	if not initialized:
		tween.disconnect("tween_all_completed", self, "init_clamps")
		default_rect_size = self.rect_size
		default_margin_left = self.margin_left
		initialized = true
