extends Node

# This will implement a flip-flop save roundrobin because if anything
# happens between the moment we open the savefile for writing and write the whole
# document the savefile gets deleted.

# To avoid this we'll keep a backup and alternate between saves

var _save_thread := Thread.new()
var _thread_save_id : int = 0
const _basename := "user://savegame"
const _basename_ext := ".save"

func _ready():
	pass # Replace with function body.

func is_saving():
	return _save_thread.is_active()
	
func start_save(var savedata):
	_save_thread.start(self, "_run_save", savedata)
	
func save_and_quit(var savedata):
	if _save_thread.is_active():
		_save_thread.wait_to_finish()
	_save_thread.start(self, "_run_save", savedata)
	_save_thread.wait_to_finish()
	if Globals.is_ios():
		get_tree().change_scene("res://scenes/MainMenu.tscn")
	else:
		get_tree().quit()
	
func get_latest_save():
	_thread_save_id = 0
	var save1 = {}
	var save1_filename = "%s0%s" % [_basename, _basename_ext]
	var save2 = {}
	var save2_filename = "%s1%s" % [_basename, _basename_ext]
	if File.new().file_exists(save1_filename):
		save1 = Globals.LevelLoaderRef.LoadJSON(save1_filename)
	if File.new().file_exists(save2_filename):
		save2 = Globals.LevelLoaderRef.LoadJSON(save2_filename)
		
	var cur_save = save1
	var use_save2 := false
	if save1 == null and save2 != null:
		use_save2 = true
	elif save1 == {} and save2 != null and save2 != {}:
		use_save2 = true
	elif save1 != null and save2 != null and "timestamp" in save2 and "timestamp" in save1 and save2["timestamp"] > save1["timestamp"]:
		use_save2 = true
		
	if use_save2 == true:
		cur_save = save2
		_thread_save_id = 1
		
	if cur_save == null:
		print("!!!!!!!!!!!!CORRUPTED SAVE. RESETTING. THIS IS REALLY BAD!!!!!!!!!!!!!")
		cur_save = {}
		
	return cur_save
	
func delete_save():
	if _save_thread.is_active():
		_save_thread.wait_to_finish()
	var save1_filename = "%s0%s" % [_basename, _basename_ext]
	var save2_filename = "%s1%s" % [_basename, _basename_ext]
	var save_game = Directory.new()
	save_game.remove(save1_filename)
	save_game.remove(save2_filename)
	
func _run_save(savedata):
	_thread_save_id = (_thread_save_id + 1) % 2
	var save_name = "%s%d%s" % [_basename, _thread_save_id, _basename_ext]
	#var cur_time = OS.get_ticks_msec()
	var save_game = File.new()
	save_game.open(save_name, File.WRITE)
	# TODO: DELETE ME
	#OS.delay_msec(4000)
	####
	save_game.store_line(to_json(savedata))
	save_game.close()
	#print("save took %.4f sec" % ((OS.get_ticks_msec() - cur_time)/1000.0))
	_save_thread.call_deferred("wait_to_finish")
