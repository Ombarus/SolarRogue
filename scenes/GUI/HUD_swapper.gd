extends Control

export(PackedScene) var pc_hud
export(PackedScene) var mobile_hud


func _ready():
	var n
	if Globals.is_mobile():
		n = mobile_hud.instance()
	else:
		n = pc_hud.instance()
		
	call_deferred("add_child", n)
