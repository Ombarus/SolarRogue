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
	for i in range(5):
		leaders.push_back({})
	_leader_size = leaders.size()
	var leaderlist = get_node("leaderlist")
	leaderlist.Content = leaders
	
	var scrollbar = leaderlist.get_v_scrollbar()
	
	scrollbar.allow_lesser = true
	scrollbar.allow_greater = true
	call_deferred("init_scroll")
	
func OnLocaleChanged_Callback():
	# We set the language at launch which means the leaderboard dynamic rows aren't setup yet, 
	# defer the call just for that case
	call_deferred("Deferred_LocaleChange")
	
func Deferred_LocaleChange():
	var leaderlist = get_node("leaderlist")
	leaderlist.Content = leaderlist.Content
	
func init_scroll():
	var n = get_node("leaderlist")
	_cancel_scroll = 5.0
	_cur_scroll = 0
	n.set_v_scroll(_cur_scroll)

func _process(delta):
	var n = get_node("leaderlist")
	if _cancel_scroll > 0:
		_cancel_scroll -= delta
		var scrollbar = n.get_v_scrollbar()
		_cur_scroll = n.get_v_scroll()
		return
		
	var max_scroll_size : int = _leader_size * n.GetRowHeight()
	_cur_scroll += _step * delta
	if _cur_scroll > max_scroll_size:
		#_step = 0
		_cur_scroll = -(self.rect_size.y)
		
	n.set_v_scroll(_cur_scroll)
		

func _gui_input(event):
	if event is InputEventMouseButton:
		_cancel_scroll = 10.0
