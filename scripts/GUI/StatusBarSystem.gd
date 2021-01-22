extends Control

export(int) var warning_energy_level = 5000
export(int) var danger_energy_level = 1000
export(int) var hull_size = 20

var _window

func _ready():
	_window = get_node("StatusWindow")
	BehaviorEvents.connect("OnDamageTaken", self, "OnDamageTaken_Callback")
	BehaviorEvents.connect("OnEnergyChanged", self, "OnEnergyChanged_Callback")
	BehaviorEvents.connect("OnLevelLoaded", self, "OnLevelLoaded_Callback")
	BehaviorEvents.connect("OnTransferPlayer", self, "OnTransferPlayer_Callback")
	BehaviorEvents.connect("OnLocaleChanged", self, "OnLocaleChanged_Callback")
	BehaviorEvents.connect("OnSystemDisabled", self, "OnSystemDisabled_Callback")
	BehaviorEvents.connect("OnSystemEnabled", self, "OnSystemDisabled_Callback")
	if Globals.LevelLoaderRef != null:
		OnLevelLoaded_Callback()

func OnSystemDisabled_Callback(obj, system):
	var is_player = obj.get_attrib("type") == "player"
	if not is_player:
		return
	UpdateStatusBar(obj)

func OnLocaleChanged_Callback():
	var p := Globals.get_first_player()
	if p == null:
		return
	UpdateStatusBar(p)

func OnTransferPlayer_Callback(old_player, new_player):
	UpdateStatusBar(new_player)

func OnEnergyChanged_Callback(obj):
	var is_player = obj.get_attrib("type") == "player"
	if not is_player:
		return
	UpdateStatusBar(obj)

func OnDamageTaken_Callback(target, shooter, damage_type):
	var is_player = target.get_attrib("type") == "player"
	if not is_player:
		return
	UpdateStatusBar(target)
		
func OnLevelLoaded_Callback():
	var p := Globals.get_first_player()
	if p == null:
		return
		
	UpdateStatusBar(p)
	var levelinfo = get_node("StatusWindow/levelinfo")
	var leveldata = Globals.LevelLoaderRef.GetCurrentLevelData()
	var name = leveldata.display_name
	levelinfo.text = name
	

#The Maveric Hull : [color=lime]==========[/color] Energy : [color=yellow]25000[/color] Shield : Up	
func UpdateStatusBar(player_obj):
	var ship_name = "The Maveric"
	var p_name : String = player_obj.get_attrib("player_name")
	if p_name != null:
		ship_name = Globals.mytr("The %s", [p_name])
	var max_hull = player_obj.get_attrib("destroyable.hull")
	var cur_hull = player_obj.get_attrib("destroyable.current_hull", max_hull)
	var hull_color = "lime"
	if cur_hull < max_hull / 2.0:
		hull_color = "yellow"
	if cur_hull < max_hull / 4.0:
		hull_color="red"
	var cur_energy = player_obj.get_attrib("converter.stored_energy")
	var energy_color = "lime"
	if cur_energy < warning_energy_level:
		energy_color = "yellow"
	if cur_energy < danger_energy_level:
		energy_color = "red"
		
	var bottom_title_str = ship_name
	var status_str = Globals.mytr("Hull") + ":[color=" + hull_color + "]"
	#"gray"
	var health_per = cur_hull / max_hull
	var changed_color = false
	for i in range(hull_size):
		var bar_per = float(i) / float(hull_size)
		if bar_per >= health_per and not changed_color:
			status_str += "[/color][color=gray]"
			changed_color = true
		status_str += "="
	status_str += "[/color]   %s:[color=%s]%.f[/color]   %s:" % [Globals.mytr("Energy"), energy_color, cur_energy, Globals.mytr("Shield")]
	
	var shields = player_obj.get_attrib("mounts.shield")
	var missing_shield = true
	if shields != null:
		for shield in shields:
			if not shield.empty():
				missing_shield = false
				break
	var cur_shield = player_obj.get_attrib("shield.current_hp")
	if missing_shield:
		status_str += "[color=yellow]%s[/color]" % [Globals.mytr("Missing")]
	elif player_obj.get_attrib("offline_systems.shield", 0.0) > 0.0:
		status_str += "[color=red]%s[/color]" % [Globals.mytr("Disabled!")]
	elif cur_shield != null and cur_shield < 1:
		status_str += "[color=red]%s[/color]" % [Globals.mytr("Down!")]
	else:
		var max_shield = player_obj.get_max_shield()
		status_str += "[color=aqua]"
		var shield_per = floor(cur_shield) / max_shield
		changed_color = false
		for i in range(hull_size):
			var bar_per = float(i) / float(hull_size)
			if bar_per >= shield_per and not changed_color:
				status_str += "[/color][color=gray]"
				changed_color = true
			status_str += "="
		status_str += "[/color]"
		
	var disabled_systems = player_obj.get_attrib("offline_systems", [])
	if disabled_systems.size() > 0:
		status_str += " | [color=red]"
	for system in disabled_systems:
		if disabled_systems[system] > 0:
			status_str += " " + system
		
	if disabled_systems.size() > 0:
		status_str += "[/color]"
	
	_window.content = status_str
	_window.bottom_title = bottom_title_str
	
