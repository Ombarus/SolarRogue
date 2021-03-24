extends Control


# Called when the node enters the scene tree for the first time.
func _ready():
	var safe_rect : Rect2 = OS.get_window_safe_area()
	var screen_size : Vector2 = OS.get_window_size()
	
	var layer : CanvasLayer = get_node("..")
	var scale = safe_rect.size / screen_size
	layer.transform = layer.transform.scaled(scale)
	layer.transform = layer.transform.translated(safe_rect.position)


