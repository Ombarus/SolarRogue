extends Control


# Called when the node enters the scene tree for the first time.
func _ready():
	var safe_rect : Rect2 = OS.get_window_safe_area()
	var screen_size : Vector2 = OS.get_window_size()
	#print("safe_rect = " + str(safe_rect))
	#print("screen_size = " + str(screen_size))
	var new_anchor_top_left = safe_rect.position / screen_size
	var new_anchor_bottom_right = safe_rect.end / screen_size
	self.anchor_left = new_anchor_top_left.x
	self.anchor_top = new_anchor_top_left.y
	self.anchor_right = new_anchor_bottom_right.x
	self.anchor_bottom = new_anchor_bottom_right.y
	#self.rect_position = safe_rect.position
	#self.rect_size = safe_rect.size
	

