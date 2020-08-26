extends Control

enum SLIDE_SIDE {
	left = 0,
	right = 1
}

export(float) var size_percent := 0.5
export(SLIDE_SIDE) var slide_side := SLIDE_SIDE.left

onready var initial_margin_right : int = self.margin_right
onready var initial_margin_left : int = self.margin_left

var move_by : int = 0
var extended : bool = false

func _ready():
	if slide_side == SLIDE_SIDE.left:
		move_by = initial_margin_right * size_percent
	else:
		move_by = initial_margin_left * size_percent
	self.margin_right -= move_by
	self.margin_left -= move_by


func _on_base_mouse_entered():
	if not extended:
		self.margin_right += move_by
		self.margin_left += move_by
		extended = true


func _on_base_mouse_exited():
	if extended:
		_ready()
		extended = false


func _on_Transfer_mouse_entered():
	_on_base_mouse_entered()

func _process(delta):
	var pos : Vector2 = get_global_mouse_position()
	var my_area : Rect2 = get_global_rect()
	if my_area.has_point(pos):
		_on_base_mouse_entered()
	elif extended:
		_on_base_mouse_exited()
