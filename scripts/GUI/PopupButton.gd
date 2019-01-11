extends Control

# class member variables go here, for example:
# var a = 2
# var b = "textvar"

func _ready():
	get_node("More").connect("pressed", self, "Pressed_More_Callback")
	get_node("Close").connect("pressed", self, "Pressed_Close_Callback")

func Pressed_More_Callback():
	get_node("More").visible = false
	get_node("Popup").visible = true
	get_node("Close").visible = true
	
func Pressed_Close_Callback():
	get_node("More").visible = true
	get_node("Popup").visible = false
	get_node("Close").visible = false
	
#func _process(delta):
#	# Called every frame. Delta is time since last frame.
#	# Update game logic here.
#	pass
