extends Control


# Called when the node enters the scene tree for the first time.
#func _ready():
#	var safe_rect : Rect2 = OS.get_window_safe_area()
#	var screen_size : Vector2 = OS.get_window_size()
#
#	var vp_size = self.get_viewport().size
#	if get_viewport().is_size_override_enabled():
#		vp_size = get_viewport().get_size_override()
#
#	var test_margin_left = 100.0
#	var test_margin_right = 0.0
#	var test_margin_top = 100.0
#	var test_margin_bottom = 100.0
#	safe_rect = Rect2(test_margin_left, test_margin_top, screen_size.x - test_margin_left - test_margin_right, screen_size.y - test_margin_top - test_margin_bottom)
#
#	safe_rect.position.x = max(safe_rect.position.x, 0.0)
#	safe_rect.position.y = max(safe_rect.position.y, 0.0)
#	safe_rect.size.x = min(screen_size.x - safe_rect.position.x, safe_rect.size.x)
#	safe_rect.size.y = min(screen_size.y - safe_rect.position.y, safe_rect.size.y)
#
#	var layer : CanvasLayer = get_node("..")
#	var scale = safe_rect.size / screen_size
#	layer.transform = layer.transform.scaled(scale)
#	layer.transform = layer.transform.translated(safe_rect.position)

# https://github.com/godotengine/godot/issues/49887
func _ready():
	var window_to_root = Transform2D.IDENTITY.scaled(get_tree().root.size / OS.window_size)
	var safe_rect = OS.get_window_safe_area()

	# TEST
#	var test_margin_left = 100.0
#	var test_margin_right = 300.0
#	var test_margin_top = 200.0
#	var test_margin_bottom = 200.0
#	safe_rect = Rect2(test_margin_left, test_margin_top, OS.window_size.x - test_margin_left - test_margin_right, OS.window_size.y - test_margin_top - test_margin_bottom)
	# TEST ***
	
	var safe_area_root = window_to_root.xform(safe_rect)
	var control = get_node("..")
	var parent_to_root = get_viewport_transform() * get_global_transform() * get_transform().affine_inverse()
	var root_to_parent = parent_to_root.affine_inverse()

	var safe_area_relative_to_parent = root_to_parent.xform(safe_area_root)
	control.scale = safe_area_relative_to_parent.size / get_viewport_rect().size
	control.offset = safe_area_relative_to_parent.position
