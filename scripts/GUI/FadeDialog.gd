extends "res://scripts/GUI/GUILayoutBase.gd"

onready var _panel : ColorRect = get_node("ColorRect")
onready var _tween : Tween = get_node("Tween")
onready var _stars : Node2D = get_node("Starfield")
	
# {"color":??, "fade_in":2.0, "fade_out":5.0, "delay":1.0, "starfield":false}
func Init(init_param):
	var fade_time := 1.0
	var to_black := true
	var delay := 0.0
	var color := Color(0.0, 0.0, 0.0, 0.0)
	var stars := false
	
	if "fade_in" in init_param:
		fade_time = init_param.fade_in
		to_black = false
	elif "fade_out" in init_param:
		fade_time = init_param.fade_out
		to_black = true
	if "delay" in init_param:
		delay = init_param.delay
	if "color" in init_param:
		color = Color(init_param.color[0], init_param.color[1], init_param.color[2], 1.0)
	if "starfield" in init_param:
		stars = init_param.starfield
	
	_panel.color = color
	_stars.modulate = color
	_stars.visible = stars
	_panel.visible = not stars
	var target = _panel
	var property = "color:a"
	if stars:
		target = _stars
		property = "modulate:a"
		
	if to_black:
		_panel.color.a = 0.0
		_stars.modulate.a = 0.0
	else:
		_panel.color.a = 1.0
		_stars.modulate.a = 1.0
		
	if delay > 0.0:
		yield(get_tree().create_timer(delay), "timeout")
		
	var alpha_target := 0.0
	if to_black:
		alpha_target = 1.0
		
		
	_tween.interpolate_property(
		target, 
		property,
		null,
		alpha_target,
		fade_time, Tween.TRANS_CUBIC, Tween.EASE_OUT)
	_tween.start()
	
func _process(delta):
	var new_col = _stars.modulate.h + (delta*2.0)
	if new_col > 1.0:
		new_col = 0.0
	_stars.modulate.h = new_col
	
