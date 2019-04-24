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
	if Globals.LevelLoaderRef != null:
		OnLevelLoaded_Callback()

func OnTransferPlayer_Callback(old_player, new_player):
	UpdateStatusBar(new_player)

func OnEnergyChanged_Callback(obj):
	var is_player = obj.get_attrib("type") == "player"
	if not is_player:
		return
	UpdateStatusBar(obj)

func OnDamageTaken_Callback(target, shooter):
	var is_player = target.get_attrib("type") == "player"
	if not is_player:
		return
	UpdateStatusBar(target)
		
func OnLevelLoaded_Callback():
	UpdateStatusBar(Globals.LevelLoaderRef.objByType["player"][0])
	var levelinfo = get_node("StatusWindow/levelinfo")
	var leveldata = Globals.LevelLoaderRef.GetCurrentLevelData()
	var json_name = leveldata.src.get_file()
	json_name = json_name.replace(".json", "")
	levelinfo.text = json_name
	

# TODO: !!!!!!! UGLY UGLY UGLY COPY PASTE FROM SHIELD BEHAVIOR !!!!!!!!!!!!!!!!!
func _get_max_shield(obj):
	var shields = obj.get_attrib("mounts.shield")
	var shields_data = Globals.LevelLoaderRef.LoadJSONArray(shields)
	
	if shields_data.size() <= 0:
		return 0
	
	shields_data.sort_custom(self, "_sort_by_shield_size")
	var max_shield = 0
	var count = 0
	for data in shields_data:
		max_shield += (data.shielding.max_hp) / pow(2, count) # 1, 0.5, 0.25, 0.125, etc.
		count += 1
		
	return max_shield
		
#The Maveric Hull : [color=lime]==========[/color] Energy : [color=yellow]25000[/color] Shield : Up	
func UpdateStatusBar(player_obj):
	var ship_name = "The Maveric" #TODO: make dynamic when we have a title menu
	var p_name : String = player_obj.get_attrib("player_name")
	if p_name != null:
		ship_name = "The " + p_name
	var cur_hull = player_obj.get_attrib("destroyable.hull")
	var max_hull = player_obj.base_attributes.destroyable.hull
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
		
	var status_str = ship_name + " Hull : [color=" + hull_color + "]"
	#"gray"
	var health_per = cur_hull / max_hull
	var changed_color = false
	for i in range(hull_size):
		var bar_per = float(i) / float(hull_size)
		if bar_per >= health_per and not changed_color:
			status_str += "[/color][color=gray]"
			changed_color = true
		status_str += "="
	status_str += "[/color] Energy : [color=%s]%.f[/color] Shield : " % [energy_color, cur_energy]
	
	var shields = player_obj.get_attrib("mounts.shield")
	var missing_shield = true
	if shields != null:
		for shield in shields:
			if not shield.empty():
				missing_shield = false
				break
	var cur_shield = player_obj.get_attrib("shield.current_hp")
	if missing_shield:
		status_str += "[color=yellow]Missing[/color]"
	elif cur_shield != null and cur_shield < 1:
		status_str += "[color=red]Down![/color]"
	else:
		var max_shield = _get_max_shield(player_obj)
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
	
	_window.content = status_str
	
