extends Control

# class member variables go here, for example:
# var a = 2
# var b = "textvar"
var _cur_scroll = -400
var _step = 50
var _leader_size : int = 0

func _ready():
	var leaders = PermSave.get_attrib("leaderboard")
	for i in range(10):
		leaders.push_back({})
	_leader_size = leaders.size() + 2
	_cur_scroll = - _leader_size * 20
	get_node("leaderlist").Content = leaders
	
	var scrollbar = get_node("leaderlist").get_v_scrollbar()
	scrollbar.allow_lesser = true
	scrollbar.allow_greater = true
	get_node("leaderlist").set_v_scroll(_cur_scroll)

func _process(delta):
	# Called every frame. Delta is time since last frame.
	# Update game logic here.
	_cur_scroll += _step * delta
	get_node("leaderlist").set_v_scroll(_cur_scroll)
	var scrollbar = get_node("leaderlist").get_v_scrollbar()
	if _cur_scroll > _leader_size * 20:
		#_step = 0
		_cur_scroll = - _leader_size * 20