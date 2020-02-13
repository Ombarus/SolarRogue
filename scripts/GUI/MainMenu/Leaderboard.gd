extends Control

# class member variables go here, for example:
# var a = 2
# var b = "textvar"
var _cur_scroll = -400
var _step = 50
var _leader_size : int = 0
var _cancel_scroll = 0

func _ready():
	# Must be done with a str2var because the array AND the dictionaries need to be copies for my custom list view
	# otherwise we'll end up with dead references in a global objects that will be deleted and everything goes to hell
	BehaviorEvents.connect("OnLocaleChanged", self, "OnLocaleChanged_Callback")
	var leaders = str2var(var2str(PermSave.get_attrib("leaderboard")))
	for i in range(10):
		leaders.push_back({})
	_leader_size = leaders.size() + 2
	_cur_scroll = -(self.rect_size.y + (0.3*self.rect_size.y))
	var leaderlist = get_node("leaderlist")
	leaderlist.Content = leaders
	
	var scrollbar = leaderlist.get_v_scrollbar()
	
	scrollbar.allow_lesser = true
	scrollbar.allow_greater = true
	leaderlist.set_v_scroll(_cur_scroll)
	
func OnLocaleChanged_Callback():
	# We set the language at launch which means the leaderboard dynamic rows aren't setup yet, 
	# defer the call just for that case
	call_deferred("Deferred_LocaleChange")
	
func Deferred_LocaleChange():
	var leaderlist = get_node("leaderlist")
	leaderlist.Content = leaderlist.Content
	

func _process(delta):
	if _cancel_scroll > 0:
		_cancel_scroll -= delta
		var scrollbar = get_node("leaderlist").get_v_scrollbar()
		_cur_scroll = get_node("leaderlist").get_v_scroll()
		return
		
	# Called every frame. Delta is time since last frame.
	# Update game logic here.
	_cur_scroll += _step * delta
	get_node("leaderlist").set_v_scroll(_cur_scroll)
	var scrollbar = get_node("leaderlist").get_v_scrollbar()
	if _cur_scroll > (_leader_size * 20 + (self.rect_size.y)):
		#_step = 0
		_cur_scroll = -(self.rect_size.y + (0.3*self.rect_size.y))
		

func _gui_input(event):
	if event is InputEventMouseButton:
		_cancel_scroll = 10.0
