extends ScrollContainer

var content = [] setget set_content, get_content

var row_ref = null

func _ready():
	row_ref = get_node("List/Row")

#############	
#content ===> [{"mount_key":"small_weapon", "src_key":"data/json/item/shield.json"}]
#############
func get_content():
	var result = []
	for d in content:
		var inside = {}
		inside["mount_key"] = d.mount_key
		inside["src_key"] = d.src_key
		inside["checked"] = d.obj.get_node("Choice").pressed
		result.push_back(inside)
	return result

func set_content(val):
	for d in content:
		d.obj.get_parent().remove_child(d.obj)
		d.obj.queue_free()
	content.clear()
	for v in val:
		var copy = row_ref.duplicate()
		copy.visible = true
		row_ref.get_parent().add_child(copy)
		content.push_back({"obj": copy, "mount_key": v.mount_key, "src_key":v.src_key})
		var display = v.mount_key + " : Free"
		if v.src_key != null and v.src_key != "":
			var src_data = Globals.LevelLoaderRef.LoadJSON(v.src_key)
			display = v.mount_key + " : " + src_data.name_id
		copy.get_node("Choice/Name").bbcode_text = display
	
#func _process(delta):
#	# Called every frame. Delta is time since last frame.
#	# Update game logic here.
#	pass
