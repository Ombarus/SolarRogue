extends "res://scripts/GUI/ItemList/DefaultRow.gd"

#{"player_name":"Ombarus the greatest", "final_score":100000, "status":END_GAME_STATE.won, "generated_levels":20, "died_on":-1},
func set_row_data(data):
	_metadata = data
	
	if data.index % 2 == 0:
		var new_style = StyleBoxFlat.new()
		new_style.set_bg_color(Color("#0fffffff"))
		var n = get_node("Panel")
		n.set('custom_styles/panel', new_style)
	else:
		var new_style = StyleBoxFlat.new()
		new_style.set_bg_color(Color("#00ffffff"))
		var n = get_node("Panel")
		n.set('custom_styles/panel', new_style)
	
	if not "final_score" in data:
		get_node("Panel/HBoxContainer/score").bbcode_text = ""
		get_node("Panel/HBoxContainer/richtext").bbcode_text = ""
		get_node("Panel/HBoxContainer/position").bbcode_text = ""
		return
		
	get_node("Panel/HBoxContainer/position").bbcode_text = "%d. " % (data.index + 1)
	get_node("Panel/HBoxContainer/score").bbcode_text = str(data.final_score)
	var result = ""
	if data.status == PermSave.END_GAME_STATE.won:
		result = "[color=lime]went HOME[/color]"
	elif data.status == PermSave.END_GAME_STATE.entropy:
		result = "[color=red]died alone[/color] on wormhole #%d" % (data.died_on+1)
	elif data.status == PermSave.END_GAME_STATE.destroyed:
		result = "[color=red]was destroyed[/color] on wormhole #%d" % (data.died_on+1)
	elif data.status == PermSave.END_GAME_STATE.suicide:
		result = "[color=red]self-destructed[/color] on wormhole #%d" % (data.died_on+1)
		
	var flavor_text = "%s, %s" % [data.player_name, result]
	
	get_node("Panel/HBoxContainer/richtext").bbcode_text = flavor_text
	
