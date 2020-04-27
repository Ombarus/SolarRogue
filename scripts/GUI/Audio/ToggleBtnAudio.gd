extends Button

var _hover := AudioStreamPlayer.new()
var _click := AudioStreamPlayer.new()

func _ready():
	self.connect("mouse_entered", self, "mouse_entered_Callback")
	self.connect("pressed", self, "pressed_Callback")
	_hover.stream = preload("res://data/private/sounds/sfx/btn/hover2.wav")
	_hover.volume_db = -20.0
	_hover.bus = "Sfx"
	self.call_deferred("add_child", _hover)
	
	_click.stream = preload("res://data/private/sounds/sfx/btn/click.wav")
	_click.bus = "Sfx"
	self.call_deferred("add_child", _click)

func mouse_entered_Callback():
	_hover.play()
	
func pressed_Callback():
	_click.play()

