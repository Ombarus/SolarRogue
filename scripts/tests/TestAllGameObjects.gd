extends Node2D


export(bool) var TestSpawnOnLoad := false

# Called when the node enters the scene tree for the first time.
func _ready():
	BehaviorEvents.connect("OnLevelLoaded", self, "OnLevelLoaded_Callback")
	
func OnLevelLoaded_Callback():
	if TestSpawnOnLoad == false:
		return
		
	yield(get_tree().create_timer(2.0), "timeout")
	call_deferred("do_spawn")
			
func do_spawn():
	
	var dir = Directory.new()
	dir.open("res://data/json")
	dir.list_dir_begin(true, false)
		
	var files = get_files(dir)
	
	print(str(files.size()))
		
	var n = null
	var coord = Vector2(0,0)
	for file in files:
		if "/effects/" in file:
			print("Effect %s skipped" % file)
			continue
		print("Loading %s" % file)
		n = Globals.LevelLoaderRef.RequestObject(file, coord)
		coord.x += 3
		if coord.x > 40:
			coord.x = 0
			coord.y += 3

func get_files(dir):
	var result = []
	var file_name = dir.get_next()
	while file_name != "":
		var file_path = dir.get_current_dir() + "/" + file_name
		if dir.current_is_dir():
			var subdir = Directory.new()
			subdir.open(file_path)
			subdir.list_dir_begin(true, false)
			result += get_files(subdir)
		elif file_name.get_extension() == "json":
			result.append(file_path)
		file_name = dir.get_next()
	dir.list_dir_end()
				
	return result
